import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/blurt_feed_screen.dart';
import 'screens/email_verification_screen.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logger (enable debug logs for troubleshooting)
  Logger.initialize(isDebugMode: true); // Set to true during development
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blurt',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF3F8CFF),
          secondary: const Color(0xFF4ECDC4),
          background: const Color(0xFF121416),
          surface: const Color(0xFF1D2024),
          onBackground: Colors.white,
          onSurface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121416),
        cardTheme: CardTheme(
          color: const Color(0xFF1D2024),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1D2024),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF1D2024),
          selectedItemColor: const Color(0xFF3F8CFF),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F8CFF),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF262A2F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3F8CFF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Debug the snapshot state
        Logger.log('Auth state changed: ${snapshot.connectionState}');
        Logger.log('Has data: ${snapshot.hasData}');
        if (snapshot.hasData) {
          Logger.log('User ID: ${snapshot.data!.uid}');
        }
        
        if (snapshot.hasError) {
          Logger.error('Auth stream error', snapshot.error);
          return Scaffold(
            body: Center(
              child: Text('Authentication error: ${snapshot.error}'),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isLoggedIn = snapshot.hasData && snapshot.data != null;
        Logger.log('isLoggedIn: $isLoggedIn');
        
        // If logged in but no local user data, fetch and store it
        if (isLoggedIn) {
          _ensureUserDataLoaded(snapshot.data!);
          
          // Check if email is verified
          final isEmailVerified = snapshot.data!.emailVerified;
          Logger.log('Email verified: $isEmailVerified');
          
          if (!isEmailVerified) {
            // If email not verified, show the verification screen
            Logger.log('Navigating to: EmailVerificationScreen');
            return const EmailVerificationScreen();
          }
        }
        
        // Log navigation decision
        Logger.log('Navigating to: ${isLoggedIn ? 'BlurtFeedScreen' : 'LoginScreen'}');
        
        return isLoggedIn 
            ? const BlurtFeedScreen() 
            : const LoginScreen();
      },
    );
  }
  
  Future<void> _ensureUserDataLoaded(User user) async {
    try {
      Logger.log('Loading user data for: ${user.uid}');
      final userData = await StorageService.getUserData();
      
      // If we don't have the data locally, fetch it from Firestore
      if (userData == null || userData['id'] != user.uid) {
        Logger.log('User data not in local storage, fetching from Firestore');
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (docSnapshot.exists) {
          Logger.log('User data found in Firestore');
          final firestoreData = docSnapshot.data() as Map<String, dynamic>;
          firestoreData['id'] = user.uid;
          
          // Store in local storage
          await StorageService.saveUserData(firestoreData);
          Logger.log('User data saved to local storage');
        } else {
          Logger.error('User document does not exist in Firestore', 'No data found for ${user.uid}');
          
          // Create a minimal user record if doesn't exist
          final minimalUserData = {
            'id': user.uid,
            'email': user.email ?? '',
            'name': user.displayName ?? 'User',
            'handle': user.uid.substring(0, 8), // Use part of UID as temporary handle
            'profileImage': '',
          };
          
          // Save to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(minimalUserData);
              
          // Save locally
          await StorageService.saveUserData(minimalUserData);
          Logger.log('Created minimal user data record');
        }
      } else {
        Logger.log('User data found in local storage');
      }
    } catch (e) {
      Logger.error('Error ensuring user data loaded', e);
    }
  }
}
