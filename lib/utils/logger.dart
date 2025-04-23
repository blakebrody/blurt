class Logger {
  static bool _isDebugMode = false;

  // Call this method at app startup to enable/disable logging
  static void initialize({bool isDebugMode = false}) {
    _isDebugMode = isDebugMode;
    print('Logger initialized, debug mode: $_isDebugMode');
  }

  // Log method that only prints in debug mode
  static void log(dynamic message) {
    if (_isDebugMode) {
      print('LOG: $message');
    }
  }

  // Error logging - always print errors, but with more details in debug mode
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    // Always print errors, even in production
    print('ERROR: $message');
    
    if (error != null) {
      print('DETAILS: $error');
    }
    
    if (_isDebugMode && stackTrace != null) {
      print(stackTrace);
    }
  }
  
  // Warning logging
  static void warning(dynamic message) {
    if (_isDebugMode) {
      print('WARNING: $message');
    }
  }
} 