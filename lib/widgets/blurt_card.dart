import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildUserAvatar(context),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          blurtData['handle'] ?? 'Anonymous',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTimestamp(blurtData['timestamp']),
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
              Text(
                blurtData['content'] ?? 'No content',
                maxLines: showFullContent ? null : 3,
                overflow: showFullContent ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildInteractionBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    if (blurtData.containsKey('profileImage') && 
        blurtData['profileImage'] != null && 
        blurtData['profileImage'].toString().isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 20,
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
    return CircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        blurtData['handle']?.toString().substring(0, 1).toUpperCase() ?? '?',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return 'Unknown time';
    }
    
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return date.toString().substring(0, 16); // Format: YYYY-MM-DD HH:MM
    }
    
    return 'Unknown time';
  }

  Widget _buildInteractionBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.favorite_border, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${blurtData['likes'] ?? 0}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.reply, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Reply',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        Icon(Icons.share, size: 16, color: Colors.grey[600]),
      ],
    );
  }
} 