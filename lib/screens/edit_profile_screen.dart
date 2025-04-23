import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../utils/handle_validator.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile_screen.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with HandleValidatorMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _handleController;
  late TextEditingController _emailController;
  bool _isLoading = false;
  String? _profileImageBase64;
  final ImagePicker _picker = ImagePicker();
  
  @override
  TextEditingController get handleController => _handleController;

  @override
  String? get currentUserHandle => widget.userData['handle'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _handleController = TextEditingController(
        text: widget.userData['handle'].toString().replaceAll('@', ''));
    _emailController = TextEditingController(text: widget.userData['email']);
    _profileImageBase64 = widget.userData['profileImage'];
    
    // Initialize handle validator
    initHandleValidator();
  }

  @override
  void dispose() {
    disposeHandleValidator();
    _nameController.dispose();
    _handleController.dispose();
    _emailController.dispose();
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profileImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newHandle = _handleController.text.trim();
      final currentHandle = widget.userData['handle'];
      
      // Only check for handle uniqueness if the handle has changed
      if (newHandle != currentHandle) {
        Logger.log('[SaveProfile] Handle changed from $currentHandle to $newHandle, checking uniqueness');
        
        // Make one final check to ensure handle is available
        final isHandleTaken = await AuthService.isHandleTaken(newHandle);
        if (isHandleTaken) {
          // Check if it's taken by someone else
          final handleOwnerData = await AuthService.getUserByHandle(newHandle);
          final handleOwnerId = handleOwnerData?['uid'] ?? '';
          final currentUserId = widget.userData['id'];
          
          Logger.log('[SaveProfile] Owner ID: $handleOwnerId, User ID: $currentUserId');
          
          if (handleOwnerId != currentUserId) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This handle is already taken by another user'),
                  backgroundColor: Colors.red,
                ),
              );
              setState(() {
                _isLoading = false;
                handleError = 'This handle is already taken by another user';
              });
            }
            return;
          }
        }
        
        // Final check for handle availability (from UI validation)
        if (handleError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(handleError!),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final updatedUserData = {
        ...widget.userData,
        'name': _nameController.text.trim(),
        'handle': newHandle,
        'email': _emailController.text.trim(),
        'profileImage': _profileImageBase64,
      };

      // Update Firestore user document
      final String userId = widget.userData['id'];
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'name': _nameController.text.trim(),
            'handle': newHandle,
            'email': _emailController.text.trim(),
            'profileImage': _profileImageBase64,
          });
      
      // Update all blurts made by this user
      final blurtsQuery = await FirebaseFirestore.instance
          .collection('blurts')
          .where('userId', isEqualTo: userId)
          .get();
      
      // Create a batch to update all blurts at once
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in blurtsQuery.docs) {
        batch.update(doc.reference, {
          'handle': newHandle,
          'userName': _nameController.text.trim(),
          'profileImage': _profileImageBase64,
        });
      }
      await batch.commit();
      
      // Update SharedPreferences
      final success = await StorageService.saveUserData(updatedUserData);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save profile locally. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.error('Error updating profile', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  Widget _buildProfileImage() {
    if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(base64Decode(_profileImageBase64!)),
        );
      } catch (e) {
        // If decoding fails, fall back to initial
        return _buildInitialAvatar();
      }
    } else {
      return _buildInitialAvatar();
    }
  }

  Widget _buildInitialAvatar() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        _nameController.text.isNotEmpty
            ? _nameController.text[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Stack(
                        children: [
                          _buildProfileImage(),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    buildHandleField(labelText: 'Handle'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isLoading || isCheckingHandle || handleError != null) 
                            ? null 
                            : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
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