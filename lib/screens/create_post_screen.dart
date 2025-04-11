import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import 'blurt_feed_screen.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  int _characterCount = 0;
  final int _maxCharacterCount = 280; // Twitter-like character limit

  @override
  void initState() {
    super.initState();
    // Listen for changes in the text field to update character count
    _contentController.addListener(() {
      setState(() {
        _characterCount = _contentController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createBlurt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user data from local storage
      final userData = await StorageService.getUserData();
      
      if (userData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You need to be logged in to post a blurt'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() { _isLoading = false; });
        return;
      }

      print('Attempting to post with user data: ${userData['handle']}');

      // Create the data structure first for better debugging
      final blurtData = {
        'content': _contentController.text.trim(),
        'userId': userData['id'],
        'handle': userData['handle'],
        'name': userData['name'],
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'profileImage': userData['profileImage'] ?? '',
      };
      
      print('Blurt data prepared: $blurtData');
      
      // Create blurt document
      final docRef = await FirebaseFirestore.instance
          .collection('blurts')
          .add(blurtData);
      
      print('Blurt posted successfully with ID: ${docRef.id}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Blurt posted with ID: ${docRef.id}'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back to feed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BlurtFeedScreen()),
        );
      }
    } catch (e, stackTrace) {
      print('Error posting blurt: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting blurt: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Blurt'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: "What's on your mind?",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      maxLength: _maxCharacterCount,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter some content';
                        }
                        if (value.length > _maxCharacterCount) {
                          return 'Content too long (max $_maxCharacterCount characters)';
                        }
                        return null;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        '$_characterCount/$_maxCharacterCount',
                        style: TextStyle(
                          color: _characterCount > _maxCharacterCount
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createBlurt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Post Blurt',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 