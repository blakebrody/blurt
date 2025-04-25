import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/app_styles.dart';
import '../widgets/blurt_list.dart';
import '../widgets/app_logo.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'create_post_screen.dart';

class BlurtFeedScreen extends StatefulWidget {
  const BlurtFeedScreen({super.key});

  @override
  State<BlurtFeedScreen> createState() => _BlurtFeedScreenState();
}

class _BlurtFeedScreenState extends State<BlurtFeedScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  
  // Stream for blurts
  late final Stream<QuerySnapshot> _blurtsStream = FirebaseFirestore.instance
      .collection('blurts')
      .orderBy('timestamp', descending: true)
      .snapshots();
  
  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _fabAnimationController.forward();
  }
  
  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }
  
  Future<void> _refreshBlurts() async {
    // Wait a bit to show the refresh indicator
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Feed refreshed'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppStyles.primaryColor.withAlpha(204), // 0.8 opacity = 204 alpha
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
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
      SnackBar(
        content: Text('Viewing Blurt: $blurtId'),
        backgroundColor: AppStyles.primaryColor.withAlpha(204), // 0.8 opacity = 204 alpha
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: _buildAppBar(),
      body: BlurtList(
        blurtsStream: _blurtsStream,
        onBlurtTap: _handleBlurtTap,
        refreshIndicatorKey: _refreshIndicatorKey,
        onRefresh: _refreshBlurts,
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: _buildFloatingActionButton(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
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
            'Blurt Feed',
            style: AppStyles.headingStyle,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppStyles.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.refresh, size: 20),
          ),
          onPressed: () {
            _refreshIndicatorKey.currentState?.show();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
  
  Widget _buildFloatingActionButton() {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(bottom: 8, right: 8),
      decoration: BoxDecoration(
        gradient: AppStyles.blueGradient,
        shape: BoxShape.circle,
        boxShadow: AppStyles.buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _fabAnimationController.reverse().then((_) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const CreatePostScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    var curve = Curves.easeInOut;
                    var tween = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
                    return FadeTransition(
                      opacity: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              ).then((_) {
                // Refresh the feed when returning from create post screen
                _refreshIndicatorKey.currentState?.show();
                _fabAnimationController.forward();
              });
            });
          },
          customBorder: const CircleBorder(),
          child: const Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
} 