import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../utils/handle_validator.dart';
import '../utils/app_styles.dart';
import '../widgets/app_logo.dart';
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
      backgroundColor: AppStyles.backgroundColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppStyles.primaryColor),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _buildProfileImage(),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppStyles.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(38),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    buildHandleField(
                      labelText: 'Handle',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your handle is unique and is how others can find you.',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: AppStyles.blueGradient,
                        boxShadow: AppStyles.buttonShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
            'Edit Profile',
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
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppStyles.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppStyles.cardShadow,
        ),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(color: Colors.grey[500]),
            errorText: errorText,
            prefixIcon: Icon(icon, color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppStyles.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          style: AppStyles.bodyStyle,
          validator: validator,
          onChanged: onChanged,
        ),
      ),
    );
  }
} 