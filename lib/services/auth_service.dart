import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_service.dart';
import '../utils/logger.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current authenticated user
  static User? get currentUser => _auth.currentUser;

  // Create user with email and password
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String handle,
  }) async {
    try {
      Logger.log('[AuthService] Creating user account with email: $email, handle: $handle');
      
      // Validate email format
      if (!_isValidEmail(email)) {
        Logger.error('[AuthService] Invalid email format', 'Email: $email is not a valid format');
        throw Exception('Please enter a valid email address');
      }
      
      // Check if email is already in use
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(email);
        if (methods.isNotEmpty) {
          Logger.error('[AuthService] Email already in use', 'Email: $email already has an account');
          throw Exception('The email address is already in use by another account');
        }
      } catch (e) {
        // If error is not about existing email, rethrow it
        if (!e.toString().contains('email-already-in-use')) {
          rethrow;
        }
        Logger.error('[AuthService] Email already in use', 'Email: $email already has an account');
        throw Exception('The email address is already in use by another account');
      }
      
      // Check if handle is already taken before creating the account
      final isHandleTaken = await AuthService.isHandleTaken(handle);
      if (isHandleTaken) {
        Logger.error('[AuthService] Handle is already taken', 'Cannot create account with handle: $handle');
        throw Exception('This handle is already taken');
      }
      
      // Create the user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        Logger.error('[AuthService] User object is null after creation', 'This should not happen');
        throw Exception('Error creating account: user object is null');
      }
      
      Logger.log('[AuthService] User created successfully with ID: ${userCredential.user?.uid}');

      try {
        // Update display name in Firebase Auth
        await userCredential.user?.updateDisplayName(name);
        Logger.log('[AuthService] Display name updated to: $name');
        
        // Send email verification
        await userCredential.user?.sendEmailVerification();
        Logger.log('[AuthService] Verification email sent to: $email');
      } catch (e) {
        // Don't fail the whole process if just the verification email fails
        Logger.error('[AuthService] Error in post-creation steps', e);
      }

      // Create the user document in Firestore (without password)
      try {
        final userData = {
          'email': email,
          'name': name,
          'handle': handle,
          'createdAt': FieldValue.serverTimestamp(),
          'profileImage': '',
          'uid': userCredential.user!.uid,
          'emailVerified': false,
        };
        
        Logger.log('[AuthService] Creating user document in Firestore with data: $userData');
        await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);
        Logger.log('[AuthService] User document created in Firestore');

        // Save user data in local storage
        final localUserData = {
          'id': userCredential.user!.uid,
          'email': email,
          'name': name,
          'handle': handle,
          'createdAt': DateTime.now().toIso8601String(),
          'profileImage': '',
          'emailVerified': false,
        };
        await StorageService.saveUserData(localUserData);
        Logger.log('[AuthService] User data saved to local storage');
      } catch (e) {
        // If Firestore fails but Auth worked, log the error but return the credential
        Logger.error('[AuthService] Error storing user data after auth creation', e);
      }

      return userCredential;
    } catch (e) {
      Logger.error('[AuthService] Error creating user with email and password', e);
      rethrow;
    }
  }

  // Helper to validate email
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Sign in with email and password
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      Logger.log('Signing in with email: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      Logger.log('Sign in successful with ID: ${userCredential.user?.uid}');

      // Get user data from Firestore
      if (userCredential.user != null) {
        // Check email verification status and update in Firestore if needed
        if (userCredential.user!.emailVerified) {
          try {
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .update({'emailVerified': true});
          } catch (e) {
            // Non-critical error, just log it
            Logger.error('Error updating email verification status in Firestore', e);
          }
        }
        
        final docSnapshot = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data() as Map<String, dynamic>;
          userData['id'] = userCredential.user!.uid;
          
          // Add email verification status if missing
          userData['emailVerified'] = userCredential.user!.emailVerified;

          // Store in local storage
          await StorageService.saveUserData(userData);
          Logger.log('User data from Firestore saved to local storage');
        } else {
          Logger.warning('User document not found in Firestore after login');
          
          // Create minimal user data based on Auth user
          final minimalUserData = {
            'id': userCredential.user!.uid,
            'email': userCredential.user!.email ?? '',
            'name': userCredential.user!.displayName ?? 'User',
            'handle': 'user_${userCredential.user!.uid.substring(0, 5)}',
            'createdAt': DateTime.now().toIso8601String(),
            'profileImage': '',
            'emailVerified': userCredential.user!.emailVerified,
          };
          
          // Store minimal data in local storage
          await StorageService.saveUserData(minimalUserData);
          Logger.log('Created minimal user data record');
          
          // Try to create the user document in Firestore
          try {
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .set(minimalUserData);
          } catch (e) {
            Logger.error('Error creating minimal user data in Firestore', e);
          }
        }
      }

      return userCredential;
    } catch (e) {
      Logger.error('Error signing in with email and password', e);
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await StorageService.clearUserData();
    } catch (e) {
      Logger.error('Error signing out', e);
      rethrow;
    }
  }

  // Update password
  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is signed in');
      }

      // Re-authenticate the user to confirm current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update the password
      await user.updatePassword(newPassword);
    } catch (e) {
      Logger.error('Error updating password', e);
      rethrow;
    }
  }

  // Get user data from Firestore by handle
  static Future<Map<String, dynamic>?> getUserByHandle(String handle) async {
    try {
      Logger.log('[AuthService] Searching for user with handle: $handle');
      final querySnapshot = await _firestore
          .collection('users')
          .where('handle', isEqualTo: handle)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        Logger.log('[AuthService] Found user with handle: $handle');
        return querySnapshot.docs.first.data();
      }
      Logger.log('[AuthService] No user found with handle: $handle');
      return null;
    } catch (e) {
      Logger.error('[AuthService] Error getting user by handle', e);
      return null;
    }
  }

  // Get user email from handle (for login by handle)
  static Future<String?> getEmailFromHandle(String handle) async {
    try {
      final userData = await getUserByHandle(handle);
      return userData?['email'];
    } catch (e) {
      Logger.error('Error getting email from handle', e);
      return null;
    }
  }

  // Check if a handle is already taken
  static Future<bool> isHandleTaken(String handle) async {
    try {
      Logger.log('[AuthService] Checking if handle is taken: $handle');
      final userData = await getUserByHandle(handle);
      final isTaken = userData != null;
      Logger.log('[AuthService] Handle "$handle" is ${isTaken ? 'taken' : 'available'}');
      return isTaken;
    } catch (e) {
      Logger.error('[AuthService] Error checking if handle is taken', e);
      return false;
    }
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String emailOrHandle) async {
    try {
      String email;
      
      // Check if input is email or handle
      if (emailOrHandle.contains('@')) {
        // Input is an email
        email = emailOrHandle;
        
        // Validate email format
        if (!_isValidEmail(email)) {
          Logger.error('[AuthService] Invalid email format', 'Email: $email is not a valid format');
          throw Exception('Please enter a valid email address');
        }
      } else {
        // Input is a handle, get the email
        final userEmail = await getEmailFromHandle(emailOrHandle);
        if (userEmail == null) {
          Logger.error('[AuthService] No user found with handle', emailOrHandle);
          throw Exception('No user found with this handle');
        }
        email = userEmail;
      }
      
      // Send the password reset email directly without checking sign-in methods
      // This works even for newly created accounts
      try {
        Logger.log('[AuthService] Sending password reset email to: $email');
        await _auth.sendPasswordResetEmail(email: email);
        Logger.log('[AuthService] Password reset email sent successfully');
      } catch (e) {
        // Handle Firebase errors properly
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') {
            Logger.error('[AuthService] No user found with email', 'Email: $email does not exist in Firebase Auth');
            throw FirebaseAuthException(
              code: 'user-not-found',
              message: 'No user found with this email address'
            );
          }
        }
        // Rethrow if it's not a user-not-found error
        rethrow;
      }
    } catch (e) {
      Logger.error('[AuthService] Error sending password reset email', e);
      rethrow;
    }
  }

  // Check if email is verified
  static bool isEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }
  
  // Resend verification email
  static Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is signed in');
      }
      
      await user.sendEmailVerification();
      Logger.log('[AuthService] Verification email resent to: ${user.email}');
    } catch (e) {
      Logger.error('[AuthService] Error resending verification email', e);
      rethrow;
    }
  }
  
  // Reload user to check for email verification status updates
  static Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        
        // If email is now verified, update Firestore
        if (user.emailVerified) {
          await _firestore.collection('users').doc(user.uid).update({
            'emailVerified': true
          });
          
          // Update local storage
          final userData = await StorageService.getUserData();
          if (userData != null) {
            userData['emailVerified'] = true;
            await StorageService.saveUserData(userData);
          }
          
          Logger.log('[AuthService] User email verified status updated');
        }
      }
    } catch (e) {
      Logger.error('[AuthService] Error reloading user', e);
      rethrow;
    }
  }
} 