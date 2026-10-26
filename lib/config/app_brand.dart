import 'package:flutter/material.dart';
import 'app_release.dart';

class AppBrand {
  static bool get enabled => AppRelease.protocol == 'pvtb';
  static const symbolAsset = 'assets/brand/wakemate_symbol.png';
  static const logoAsset = 'assets/brand/wakemate_logo.png';
  static const wordmarkColor = Color(0xFFE79219);
}
