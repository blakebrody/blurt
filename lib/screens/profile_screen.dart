import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/user_blurt_list.dart';
import '../utils/logger.dart';
import 'blurt_feed_screen.dart';
import 'search_screen.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  int _currentIndex = 2; // Profile is index 2 in the bottom nav bar
  Stream<QuerySnapshot>? _userBlurtsStream;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await StorageService.getUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
        
        // Set up the stream for user's blurts
        if (userData != null && userData['id'] != null) {
          _userBlurtsStream = FirebaseFirestore.instance
              .collection('blurts')
              .where('userId', isEqualTo: userData['id'])
              .orderBy('timestamp', descending: true)
              .snapshots();
        }
      });
    } catch (e) {
      Logger.error('Error loading user data', e);
      setState(() {
        _userData = null;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    await StorageService.clearUserData();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BlurtFeedScreen()),
        );
        break;
      case 1: // Search
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
        break;
      case 2: // Profile
        // Already on profile page
        break;
    }
  }

  Widget _buildProfileImage() {
    if (_userData != null && 
        _userData!.containsKey('profileImage') && 
        _userData!['profileImage'] != null &&
        _userData!['profileImage'].toString().isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 50,
          backgroundImage: MemoryImage(base64Decode(_userData!['profileImage'])),
        );
      } catch (e) {
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
        _userData!['name'][0].toUpperCase(),
        style: const TextStyle(
          fontSize: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  void _handleBlurtTap(String blurtId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing Blurt: $blurtId'))
    );
  }

  void _handleBlurtDelete(String blurtId) async {
    try {
      await FirebaseFirestore.instance
          .collection('blurts')
          .doc(blurtId)
          .delete();
          
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Blurt deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Logger.error('Error deleting blurt', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting blurt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshUserBlurts() async {
    // Wait a bit to show the refresh indicator
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your blurts refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    
    // The StreamBuilder will automatically get updated data
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData == null
              ? const Center(child: Text('No user data found'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProfileImage(),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProfileScreen(
                                    userData: _userData!,
                                  ),
                                ),
                              ).then((_) => _loadUserData());
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildInfoTile('Name', _userData!['name']),
                      _buildInfoTile('Handle', '@${_userData!['handle']}'),
                      _buildInfoTile('Email', _userData!['email']),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChangePasswordScreen(
                                  userData: _userData!,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.lock),
                          label: const Text('Change Password'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Your Blurts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _userBlurtsStream == null
                            ? const Center(child: Text('Unable to load your blurts'))
                            : UserBlurtList(
                                blurtsStream: _userBlurtsStream!,
                                onBlurtTap: _handleBlurtTap,
                                onBlurtDelete: _handleBlurtDelete,
                                refreshIndicatorKey: _refreshIndicatorKey,
                                onRefresh: _refreshUserBlurts,
                              ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
} 