import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/logger.dart';
import '../widgets/blurt_list.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'create_post_screen.dart';

class BlurtFeedScreen extends StatefulWidget {
  const BlurtFeedScreen({super.key});

  @override
  State<BlurtFeedScreen> createState() => _BlurtFeedScreenState();
}

class _BlurtFeedScreenState extends State<BlurtFeedScreen> {
  int _currentIndex = 0;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  // Stream for blurts
  late final Stream<QuerySnapshot> _blurtsStream = FirebaseFirestore.instance
      .collection('blurts')
      .orderBy('timestamp', descending: true)
      .snapshots();
  
  Future<void> _refreshBlurts() async {
    // Wait a bit to show the refresh indicator
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feed refreshed'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    
    // The StreamBuilder will automatically get updated data
    return Future.value();
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0: // Home
        // Already on home page
        break;
      case 1: // Search
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
        break;
      case 2: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  void _handleBlurtTap(String blurtId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tapped on Blurt: $blurtId'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blurt Feed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Manually trigger the refresh indicator
              _refreshIndicatorKey.currentState?.show();
            },
          ),
        ],
      ),
      body: BlurtList(
        blurtsStream: _blurtsStream,
        onBlurtTap: _handleBlurtTap,
        refreshIndicatorKey: _refreshIndicatorKey,
        onRefresh: _refreshBlurts,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          ).then((_) {
            // Refresh the feed when returning from create post screen
            _refreshIndicatorKey.currentState?.show();
          });
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
} 