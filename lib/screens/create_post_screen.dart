import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import 'blurt_feed_screen.dart';
import '../utils/logger.dart';
import '../utils/app_styles.dart';
import '../widgets/app_logo.dart';

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
            SnackBar(
              content: const Text('You need to be logged in to post a blurt'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
        setState(() { _isLoading = false; });
        return;
      }

      Logger.log('Attempting to post with user data: ${userData['handle']}');

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
      
      Logger.log('Blurt data prepared');
      
      // Create blurt document
      final docRef = await FirebaseFirestore.instance
          .collection('blurts')
          .add(blurtData);
      
      Logger.log('Blurt posted successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Blurt posted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
        // Navigate back to feed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BlurtFeedScreen()),
        );
      }
    } catch (e, stackTrace) {
      Logger.error('Error posting blurt', e, stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting blurt: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
            duration: const Duration(seconds: 5),
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
      backgroundColor: AppStyles.backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppStyles.primaryColor),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppStyles.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppStyles.cardShadow,
                      ),
                      child: TextFormField(
                        controller: _contentController,
                        decoration: InputDecoration(
                          hintText: "What's on your mind?",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        style: AppStyles.bodyStyle,
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
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        '$_characterCount/$_maxCharacterCount characters',
                        style: TextStyle(
                          color: _characterCount > _maxCharacterCount
                              ? Colors.red[400]
                              : Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: AppStyles.blueGradient,
                        boxShadow: AppStyles.buttonShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createBlurt,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Post Blurt',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Row(
        children: [
          const AppLogo(size: 40),
          const SizedBox(width: 10),
          Text(
            'Create Blurt',
            style: AppStyles.headingStyle,
          ),
        ],
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppStyles.surfaceColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, size: 20),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
} 