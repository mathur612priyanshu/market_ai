import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized server URL resolver.
/// Uses loopback configuration for emulators and localhosts.
String get baseUrl {
  if (kIsWeb) return 'http://localhost:5001';
  if (Platform.isAndroid) return 'http://192.168.1.2:5001';
  return 'http://localhost:5001';
}
