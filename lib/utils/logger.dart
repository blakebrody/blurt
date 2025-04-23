class Logger {
  // Always keep debug mode on during development
  static bool _isDebugMode = true;

  // Call this method at app startup to enable/disable logging
  static void initialize({bool isDebugMode = true}) {
    _isDebugMode = true; // Force debug mode on for testing
    print('🔧 Logger initialized, debug mode: $_isDebugMode');
  }

  // Log method that only prints in debug mode
  static void log(dynamic message) {
    // Always log during development
    print('📝 LOG: $message');
  }

  // Error logging - always print errors, but with more details in debug mode
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    // Always print errors, even in production
    print('❌ ERROR: $message');
    
    if (error != null) {
      print('⚠️ DETAILS: $error');
    }
    
    if (stackTrace != null) {
      print('📋 STACK: \n$stackTrace');
    }
  }
  
  // Warning logging
  static void warning(dynamic message) {
    // Always log warnings during development
    print('⚠️ WARNING: $message');
  }
} 