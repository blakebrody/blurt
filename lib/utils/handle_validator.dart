import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'logger.dart';
import 'dart:async';

/// A mixin that provides handle validation functionality
mixin HandleValidatorMixin<T extends StatefulWidget> on State<T> {
  // Controllers and state variables
  TextEditingController get handleController;
  bool isCheckingHandle = false;
  String? handleError;
  
  // Debounce timer
  Timer? _debounceTimer;
  
  // Get current user handle - can be overridden by subclasses
  String? get currentUserHandle => null;
  
  void initHandleValidator() {
    // Validate initially if there's text already
    if (handleController.text.isNotEmpty) {
      _validateHandle(handleController.text);
    }
    
    // Add listener for changes
    handleController.addListener(_onHandleChanged);
  }

  void disposeHandleValidator() {
    handleController.removeListener(_onHandleChanged);
    _debounceTimer?.cancel();
  }
  
  // Handler for text changes
  void _onHandleChanged() {
    final handle = handleController.text.trim();
    
    // Cancel any existing timer
    _debounceTimer?.cancel();
    
    // Reset any previous state and show loading immediately
    setState(() {
      isCheckingHandle = handle.isNotEmpty && !handle.contains(' ');
      // Clear previous validation result while checking
      if (isCheckingHandle) {
        handleError = null;
      }
    });
    
    // Set a very short debounce time to avoid too many API calls
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (handle.isNotEmpty) {
        Logger.log('[HandleValidator] Validating handle after debounce: $handle');
        _validateHandle(handle);
      }
    });
  }
  
  // Validation logic - combines both validation and Firebase checking
  Future<void> _validateHandle(String handle) async {
    try {
      // Skip validation if empty
      if (handle.isEmpty) {
        setState(() {
          handleError = null;
          isCheckingHandle = false;
        });
        Logger.log('[HandleValidator] Empty handle, skipping validation');
        return;
      }
      
      // Check for spaces immediately
      if (handle.contains(' ')) {
        setState(() {
          handleError = 'Handle cannot contain spaces';
          isCheckingHandle = false;
        });
        Logger.log('[HandleValidator] Handle contains spaces: $handle');
        return;
      }
      
      // Get the user's current handle if available
      final userCurrentHandle = currentUserHandle;
      
      // Skip check if handle is the same as current user's handle
      if (userCurrentHandle != null && handle == userCurrentHandle) {
        setState(() {
          handleError = null;
          isCheckingHandle = false;
        });
        Logger.log('[HandleValidator] Handle is unchanged, skipping check');
        return;
      }
      
      // Check availability in Firebase
      Logger.log('[HandleValidator] Checking availability for handle: "$handle"');
      final isHandleTaken = await AuthService.isHandleTaken(handle);
      Logger.log('[HandleValidator] Is handle "$handle" taken? $isHandleTaken');
      
      // Special case for editing - check if it's the current user's handle
      if (isHandleTaken && userCurrentHandle != null) {
        final handleOwnerData = await AuthService.getUserByHandle(handle);
        final handleOwnerId = handleOwnerData?['uid'] ?? '';
        final currentUserId = AuthService.currentUser?.uid;
        
        final isTakenByOtherUser = handleOwnerId != currentUserId;
        
        // Safe state update - handle may have changed while we were checking
        if (mounted && handle == handleController.text.trim()) {
          setState(() {
            isCheckingHandle = false;
            handleError = isTakenByOtherUser ? 'This handle is already taken' : null;
          });
          Logger.log('[HandleValidator] Handle "$handle" ${isTakenByOtherUser ? "is taken by another user" : "is your current handle"}');
        }
      } else {
        // Safe state update - only if we're still mounted and the handle hasn't changed
        if (mounted && handle == handleController.text.trim()) {
          setState(() {
            isCheckingHandle = false;
            handleError = isHandleTaken ? 'This handle is already taken' : null;
          });
          Logger.log('[HandleValidator] Handle "$handle" is ${isHandleTaken ? "taken" : "available"}');
        }
      }
    } catch (e) {
      Logger.error('[HandleValidator] Error in handle validation', e);
      // Safe state update
      if (mounted) {
        setState(() {
          isCheckingHandle = false;
        });
      }
    }
  }
  
  // Method to build the handle input field
  Widget buildHandleField({
    required String labelText,
    String? prefixText,
    String? Function(String?)? additionalValidator,
  }) {
    return TextFormField(
      controller: handleController,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixText: prefixText ?? '@',
        suffixIcon: isCheckingHandle 
          ? const SizedBox(
              height: 20,
              width: 20,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : handleController.text.isNotEmpty
              ? (handleError == null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.cancel, color: Colors.red))
              : null,
        errorText: handleError,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a handle';
        }
        if (value.contains(' ')) {
          return 'Handle cannot contain spaces';
        }
        if (handleError != null) {
          return handleError;
        }
        
        // Call additional validator if provided
        if (additionalValidator != null) {
          return additionalValidator(value);
        }
        
        return null;
      },
    );
  }
} 