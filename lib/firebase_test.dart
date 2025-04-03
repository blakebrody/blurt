import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// A simple standalone script to test Firebase connectivity
Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('Firebase initialized');
  
  try {
    // Get a reference to Firestore
    final firestore = FirebaseFirestore.instance;
    
    // Try to write to Firestore
    print('Attempting to write to Firestore...');
    await firestore.collection('test').doc('testDoc').set({
      'message': 'Hello from Flutter test script',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print('Successfully wrote to Firestore');
    
    // Try to read from Firestore
    print('Attempting to read from Firestore...');
    final snapshot = await firestore.collection('test').get();
    print('Successfully read from Firestore. Documents: ${snapshot.docs.length}');
    
    for (var doc in snapshot.docs) {
      print('Document ID: ${doc.id}, Data: ${doc.data()}');
    }
    
    print('Firebase connection test completed successfully');
  } catch (e) {
    print('Firebase test error: $e');
  }
} 