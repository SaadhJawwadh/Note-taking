import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:in_app_review/in_app_review.dart';
import 'dart:io';

class UpdateRatingService {
  static final InAppReview _inAppReview = InAppReview.instance;

  /// Checks for app updates. Uses the native Android In-App Update API.
  static Future<void> checkForUpdates() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          // Perform a flexible update so it downloads in the background
          await InAppUpdate.startFlexibleUpdate();
          // Once downloaded, prompt the user to complete it
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint('In-app update check failed: $e');
    }
  }

  /// Increments launch counter or action counter, and triggers rating if eligible.
  static Future<void> incrementMilestoneAndCheckRating() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Increment app use count
      final useCount = (prefs.getInt('app_use_count') ?? 0) + 1;
      await prefs.setInt('app_use_count', useCount);

      final hasPrompted = prefs.getBool('has_prompted_rating') ?? false;
      if (hasPrompted) return;

      // We only prompt after at least 5 launches/milestones
      if (useCount >= 5) {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
          await prefs.setBool('has_prompted_rating', true);
          debugPrint('In-app review requested successfully.');
        } else {
          debugPrint('In-app review API is not available.');
        }
      }
    } catch (e) {
      debugPrint('In-app review request failed: $e');
    }
  }
}
