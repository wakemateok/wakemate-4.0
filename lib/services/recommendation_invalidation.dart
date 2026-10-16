import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/services/auth_service.dart';

Future<void> invalidateFutureRecommendations({
  NotificationService? notifications,
  String? userId,
}) async {
  if (userId != null && AuthService.instance.userId != userId) return;
  final key =
      userId == null
          ? 'caffeine_recommendations'
          : 'caffeine_recommendations_$userId';
  // Input has already been saved on the server. A local failure must not make
  // users resubmit a non-idempotent intake or measurement.
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key) ?? '[]';
    List<dynamic> entries;
    try {
      final decoded = jsonDecode(raw);
      entries = decoded is List ? decoded : [];
    } catch (_) {
      entries = [];
    }
    final now = DateTime.now().toUtc();
    final past =
        entries.whereType<Map>().where((entry) {
          final time = DateTime.tryParse(
            entry['recommended_caffeine_intake_timing']?.toString() ?? '',
          );
          return time != null && !time.toUtc().isAfter(now);
        }).toList();
    await prefs.setString(key, jsonEncode(past));
  } catch (error) {
    debugPrint('Local recommendation invalidation failed: $error');
  }
  try {
    await (notifications ?? NotificationService.instance)
        .cancelCaffeineReminders();
  } catch (error) {
    debugPrint('Previous reminder cancellation failed: $error');
  }
}
