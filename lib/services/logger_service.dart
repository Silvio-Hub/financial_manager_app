class LoggerService {
  

  static void _log(String level, String message) {
    
    return;
  }

  static void debug(String message) {
    _log('DEBUG', message);
  }

  static void info(String message) {
    _log('INFO', message);
  }

  static void warning(String message) {
    _log('WARN', message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    final extra = error != null ? ' | error=$error' : '';
    final st = stackTrace != null ? '\n$stackTrace' : '';
    _log('ERROR', '$message$extra$st');
  }

  static void verbose(String message) {
    _log('VERBOSE', message);
  }
}