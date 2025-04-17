import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'blurt_card.dart';

class UserBlurtCard extends StatelessWidget {
  final Map<String, dynamic> blurtData;
  final String blurtId;
  final Function()? onTap;
  final Function()? onDelete;
  final bool showFullContent;

  const UserBlurtCard({
    Key? key,
    required this.blurtData,
    required this.blurtId,
    this.onTap,
    this.onDelete,
    this.showFullContent = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Use the existing BlurtCard
        BlurtCard(
          blurtData: blurtData,
          blurtId: blurtId,
          onTap: onTap,
          showFullContent: showFullContent,
        ),
        
        // Add a delete button in the top right
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => _confirmDelete(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red[600],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Blurt'),
        content: const Text('Are you sure you want to delete this blurt? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleDelete();
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _handleDelete() async {
    if (onDelete != null) {
      onDelete!();
    } else {
      // Default delete behavior if no callback provided
      try {
        await FirebaseFirestore.instance
            .collection('blurts')
            .doc(blurtId)
            .delete();
      } catch (e) {
        print('Error deleting blurt: $e');
      }
    }
  }
} 