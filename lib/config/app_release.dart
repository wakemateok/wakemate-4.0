import 'package:flutter/services.dart' show appFlavor;

class AppRelease {
  static const version = '1.2.6';
  static const build = 11;
  static String get label => '$version+$build';
  static String get protocol {
    const configured = String.fromEnvironment('WAKEMATE_ALERTNESS_MODE');
    if (configured.isNotEmpty) return configured;
    return appFlavor == 'legacy'
        ? 'brief'
        : appFlavor == 'pvtb'
        ? 'pvtb'
        : 'combined';
  }
}
