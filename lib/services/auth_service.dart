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
      Logger.log('Creating user account with email: $email');
      
      // Create the user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      Logger.log('User created successfully with ID: ${userCredential.user?.uid}');

      // Update display name in Firebase Auth
      await userCredential.user?.updateDisplayName(name);
      Logger.log('Display name updated to: $name');

      // Create the user document in Firestore (without password)
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': name,
          'handle': handle,
          'createdAt': FieldValue.serverTimestamp(),
          'profileImage': '',
          'uid': userCredential.user!.uid,
        });
        Logger.log('User document created in Firestore');

        // Save user data in local storage
        final userData = {
          'id': userCredential.user!.uid,
          'email': email,
          'name': name,
          'handle': handle,
          'createdAt': DateTime.now().toIso8601String(),
          'profileImage': '',
        };
        await StorageService.saveUserData(userData);
        Logger.log('User data saved to local storage');
      }

      return userCredential;
    } catch (e) {
      Logger.error('Error creating user with email and password', e);
      rethrow;
    }
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
        final docSnapshot = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data() as Map<String, dynamic>;
          userData['id'] = userCredential.user!.uid;

          // Store in local storage
          await StorageService.saveUserData(userData);
          Logger.log('User data from Firestore saved to local storage');
        } else {
          Logger.warning('User document not found in Firestore after login');
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
      final querySnapshot = await _firestore
          .collection('users')
          .where('handle', isEqualTo: handle)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      Logger.error('Error getting user by handle', e);
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
      final userData = await getUserByHandle(handle);
      return userData != null;
    } catch (e) {
      Logger.error('Error checking if handle is taken', e);
      return false;
    }
  }
} 