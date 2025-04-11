import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../widgets/bottom_nav_bar.dart';
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
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _testFirebaseConnection,
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _refreshBlurts,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('blurts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('Error in StreamBuilder: ${snapshot.error}');
              return _buildErrorWidget(snapshot.error);
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              print('No blurts found in the database');
              return _buildEmptyWidget();
            }

            print('Loaded ${snapshot.data!.docs.length} blurts from database');
            
            return ListView.builder(
              // Make sure the list is always scrollable for refresh
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                // Debug print first document
                if (index == 0) {
                  print('First blurt data: $data');
                }
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildUserAvatar(data),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['handle'] ?? 'Anonymous',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    data['timestamp'] != null
                                        ? (data['timestamp'] as Timestamp).toDate().toString().substring(0, 16)
                                        : 'Unknown time',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(data['content'] ?? 'No content'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
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
  
  Widget _buildErrorWidget(dynamic error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Center(child: Icon(Icons.error, color: Colors.red, size: 50)),
        const SizedBox(height: 20),
        Center(child: Text('Error: $error')),
      ],
    );
  }
  
  Widget _buildEmptyWidget() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Center(child: Icon(Icons.feed, color: Colors.grey, size: 50)),
        SizedBox(height: 20),
        Center(child: Text('No blurts yet. Be the first to blurt!')),
      ],
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> data) {
    if (data.containsKey('profileImage') && 
        data['profileImage'] != null && 
        data['profileImage'].toString().isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(base64Decode(data['profileImage'])),
        );
      } catch (e) {
        return _buildInitialAvatar(data);
      }
    } else {
      return _buildInitialAvatar(data);
    }
  }

  Widget _buildInitialAvatar(Map<String, dynamic> data) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        data['handle']?.toString().substring(0, 1).toUpperCase() ?? '?',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> _testFirebaseConnection() async {
    try {
      // Test read
      final testRead = await FirebaseFirestore.instance
          .collection('blurts')
          .limit(1)
          .get();
      
      // Test write (we'll delete it immediately)
      final testDoc = await FirebaseFirestore.instance
          .collection('_test_connection')
          .add({
            'timestamp': FieldValue.serverTimestamp(),
            'testValue': 'Connection test'
          });
      
      // Delete test document
      await testDoc.delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase connection works! ${testRead.docs.length} blurts found.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }
} 