class Logger {
  static bool _isDebugMode = false;

  // Call this method at app startup to enable/disable logging
  static void initialize({bool isDebugMode = false}) {
    _isDebugMode = isDebugMode;
  }

  // Log method that only prints in debug mode
  static void log(dynamic message) {
    if (_isDebugMode) {
      print(message);
    }
  }

  // Error logging
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (_isDebugMode) {
      print('ERROR: $message');
      if (error != null) print('DETAILS: $error');
      if (stackTrace != null) print(stackTrace);
    }
  }
} 