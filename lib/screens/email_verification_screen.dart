import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import 'blurt_feed_screen.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isLoading = false;
  bool _emailSent = true; // Assume email was already sent during signup
  Timer? _timer;
  int _remainingSeconds = 0;
  
  @override
  void initState() {
    super.initState();
    // Start checking for verification
    _startVerificationCheck();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _startVerificationCheck() {
    // Check every 5 seconds if the email has been verified
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        await AuthService.reloadUser();
        
        if (AuthService.isEmailVerified()) {
          _timer?.cancel();
          
          // Navigate to the feed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Email verified successfully!')),
            );
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BlurtFeedScreen()),
            );
          }
        }
      } catch (e) {
        Logger.error('[EmailVerification] Error checking verification status', e);
      }
    });
  }
  
  Future<void> _resendVerificationEmail() async {
    if (_remainingSeconds > 0) return;
    
    setState(() {
      _isLoading = true;
      _emailSent = false;
    });
    
    try {
      await AuthService.resendVerificationEmail();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
          _remainingSeconds = 60; // Cooldown period of 60 seconds
        });
        
        // Start countdown timer
        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_remainingSeconds > 0) {
            if (mounted) {
              setState(() {
                _remainingSeconds--;
              });
            }
          } else {
            timer.cancel();
          }
        });
      }
    } catch (e) {
      Logger.error('[EmailVerification] Error resending verification email', e);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
  
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await AuthService.signOut();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      Logger.error('Error signing out', e);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser?.email ?? 'your email';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification email to:\n$email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'Please check your inbox and click the verification link to activate your account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading || _remainingSeconds > 0 ? null : _resendVerificationEmail,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
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
                    : Text(_remainingSeconds > 0
                        ? 'Resend in ${_remainingSeconds}s'
                        : 'Resend Email'),
              ),
              const SizedBox(height: 8),
              if (_emailSent && _remainingSeconds == 0)
                const Text(
                  'Verification email sent!',
                  style: TextStyle(color: Colors.green),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _signOut,
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 