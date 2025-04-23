import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrHandleController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _resetEmailSent = false;

  @override
  void dispose() {
    _emailOrHandleController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _resetEmailSent = false;
      });

      try {
        final emailOrHandle = _emailOrHandleController.text.trim();
        
        // Send password reset email
        await AuthService.sendPasswordResetEmail(emailOrHandle);

        // Reset loading state and show success message
        if (mounted) {
          setState(() {
            _isLoading = false;
            _resetEmailSent = true;
          });
        }
      } catch (e) {
        Logger.error('Error sending password reset email', e);
        setState(() {
          _isLoading = false;
          if (e.toString().contains('No user found with this handle')) {
            _errorMessage = 'No user found with this handle';
          } else if (e.toString().contains('user-not-found') || e.toString().contains('No user found with this email')) {
            _errorMessage = 'No user found with this email address';
          } else if (e.toString().contains('Please enter a valid email address')) {
            _errorMessage = 'Please enter a valid email address';
          } else if (e.toString().contains('Account error')) {
            _errorMessage = 'Account error. Please contact support.';
          } else if (e.toString().contains('network-request-failed')) {
            _errorMessage = 'Network error. Please check your connection.';
          } else {
            _errorMessage = 'Error sending password reset email. Please try again.';
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_resetEmailSent) ...[
                Text(
                  'Enter your email address or handle to reset your password',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailOrHandleController,
                  decoration: const InputDecoration(
                    labelText: 'Email or Handle',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email or handle';
                    }
                    
                    // If it looks like an email, validate the format
                    if (value.contains('@')) {
                      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                    }
                    
                    return null;
                  },
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Send Reset Link'),
                ),
              ] else ...[
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Password reset email sent!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your email for instructions to reset your password.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Back to Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 