import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import '../utils/app_styles.dart';
import 'blurt_card.dart';

class BlurtList extends StatelessWidget {
  final Stream<QuerySnapshot> blurtsStream;
  final Function(String)? onBlurtTap;
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;
  final Future<void> Function()? onRefresh;

  const BlurtList({
    Key? key,
    required this.blurtsStream,
    this.onBlurtTap,
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
          return _buildLoadingWidget();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          Logger.log('No blurts found in the database');
          return _buildEmptyWidget();
        }

        Logger.log('Loaded ${snapshot.data!.docs.length} blurts from database');
        
        return ListView.builder(
          // Make sure the list is always scrollable for refresh
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return BlurtCard(
              blurtData: data,
              blurtId: doc.id,
              onTap: onBlurtTap != null ? () => onBlurtTap!(doc.id) : null,
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
        color: AppStyles.primaryColor,
        backgroundColor: AppStyles.surfaceColor,
        child: content,
      );
    }

    return content;
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppStyles.primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading blurts...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, dynamic error) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.error_outline, color: Colors.red[400], size: 70),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Oops! Something went wrong',
            style: AppStyles.subheadingStyle,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: ElevatedButton.icon(
            onPressed: () {
              refreshIndicatorKey?.currentState?.show();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: AppStyles.primaryButtonStyle,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyWidget() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.bubble_chart, color: Colors.grey[700], size: 70),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'No blurts yet',
            style: AppStyles.subheadingStyle,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Be the first to share something!',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
} 