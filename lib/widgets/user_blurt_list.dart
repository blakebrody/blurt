import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'user_blurt_card.dart';

class UserBlurtList extends StatelessWidget {
  final Stream<QuerySnapshot> blurtsStream;
  final Function(String)? onBlurtTap;
  final Function(String)? onBlurtDelete;
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;
  final Future<void> Function()? onRefresh;

  const UserBlurtList({
    Key? key,
    required this.blurtsStream,
    this.onBlurtTap,
    this.onBlurtDelete,
    this.refreshIndicatorKey,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = StreamBuilder<QuerySnapshot>(
      stream: blurtsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          Logger.error('Error in StreamBuilder', snapshot.error);
          return _buildErrorWidget(context, snapshot.error);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          Logger.log('No blurts found in the database');
          return _buildEmptyWidget();
        }

        Logger.log('Loaded ${snapshot.data!.docs.length} user blurts from database');
        
        return ListView.builder(
          // Make sure the list is always scrollable for refresh
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return UserBlurtCard(
              blurtData: data,
              blurtId: doc.id,
              onTap: onBlurtTap != null ? () => onBlurtTap!(doc.id) : null,
              onDelete: onBlurtDelete != null ? () => onBlurtDelete!(doc.id) : () async {
                try {
                  // Default delete behavior
                  await FirebaseFirestore.instance
                      .collection('blurts')
                      .doc(doc.id)
                      .delete();
                      
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Blurt deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Logger.error('Error deleting blurt', e);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting blurt: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );

    // Wrap with refresh indicator if needed
    if (refreshIndicatorKey != null && onRefresh != null) {
      return RefreshIndicator(
        key: refreshIndicatorKey!,
        onRefresh: onRefresh!,
        child: content,
      );
    }

    return content;
  }

  Widget _buildErrorWidget(BuildContext context, dynamic error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        const Center(child: Icon(Icons.error, color: Colors.red, size: 50)),
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
        Center(child: Icon(Icons.post_add, color: Colors.grey, size: 50)),
        SizedBox(height: 20),
        Center(child: Text('You haven\'t posted any blurts yet')),
      ],
    );
  }
} 