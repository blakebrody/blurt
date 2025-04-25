import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../utils/app_styles.dart';

class BlurtCard extends StatelessWidget {
  final Map<String, dynamic> blurtData;
  final String blurtId;
  final Function()? onTap;
  final bool showFullContent;

  const BlurtCard({
    Key? key,
    required this.blurtData,
    required this.blurtId,
    this.onTap,
    this.showFullContent = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppStyles.cardColor,
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
        boxShadow: AppStyles.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildUserAvatar(context),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blurtData['handle'] ?? 'Anonymous',
                            style: AppStyles.subheadingStyle,
                          ),
                          Text(
                            _formatTimestamp(blurtData['timestamp']),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.grey),
                      onPressed: () {
                        // Show options menu
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  blurtData['content'] ?? 'No content',
                  style: AppStyles.bodyStyle,
                  maxLines: showFullContent ? null : 3,
                  overflow: showFullContent ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                _buildInteractionBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(38),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _buildAvatarContent(context),
    );
  }

  Widget _buildAvatarContent(BuildContext context) {
    if (blurtData.containsKey('profileImage') && 
        blurtData['profileImage'] != null && 
        blurtData['profileImage'].toString().isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 22,
          backgroundImage: MemoryImage(base64Decode(blurtData['profileImage'])),
        );
      } catch (e) {
        return _buildInitialAvatar(context);
      }
    } else {
      return _buildInitialAvatar(context);
    }
  }

  Widget _buildInitialAvatar(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: AppStyles.blueGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          blurtData['handle']?.toString().substring(0, 1).toUpperCase() ?? '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return 'Just now';
    }
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    }
    
    return 'Just now';
  }

  Widget _buildInteractionBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInteractionButton(
          icon: Icons.favorite_border,
          label: '${blurtData['likes'] ?? 0}',
          onTap: () {
            // Handle like
          },
        ),
        _buildInteractionButton(
          icon: Icons.chat_bubble_outline,
          label: 'Reply',
          onTap: () {
            // Handle reply
          },
        ),
        _buildInteractionButton(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: () {
            // Handle share
          },
        ),
        _buildInteractionButton(
          icon: Icons.bookmark_border_outlined,
          label: 'Save',
          onTap: () {
            // Handle save
          },
        ),
      ],
    );
  }
  
  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 