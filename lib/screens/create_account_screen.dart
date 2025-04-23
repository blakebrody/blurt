import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'blurt_feed_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _handleController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Check if handle is already taken
        final isHandleTaken = await AuthService.isHandleTaken(_handleController.text);
        if (isHandleTaken) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'This handle is already taken';
          });
          return;
        }

        // Create user with Firebase Auth
        await AuthService.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          handle: _handleController.text.trim(),
        );

        // Reset loading state and show success message
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );
          
          // Manually navigate to the feed screen (workaround for auth state not triggering navigation)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BlurtFeedScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
          switch (e.code) {
            case 'email-already-in-use':
              _errorMessage = 'The email address is already in use';
              break;
            case 'weak-password':
              _errorMessage = 'The password is too weak';
              break;
            case 'invalid-email':
              _errorMessage = 'The email address is invalid';
              break;
            default:
              _errorMessage = 'Error: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error creating account: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _handleController,
                decoration: const InputDecoration(
                  labelText: 'Handle',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your handle';
                  }
                  if (value.contains(' ')) {
                    return 'Handle cannot contain spaces';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
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
                onPressed: _isLoading ? null : _handleCreateAccount,
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
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 