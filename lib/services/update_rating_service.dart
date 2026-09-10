import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:in_app_review/in_app_review.dart';
import 'dart:io';
import '../utils/app_globals.dart';

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
          // Show a non-intrusive floating SnackBar prompt to complete the update
          appScaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              duration: const Duration(minutes: 30),
              behavior: SnackBarBehavior.floating,
              content: const Row(
                children: [
                  Icon(Icons.system_update_rounded, size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text('New update downloaded and ready.')),
                ],
              ),
              action: SnackBarAction(
                label: 'RESTART NOW',
                onPressed: () {
                  InAppUpdate.completeFlexibleUpdate();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('In-app update check failed: $e');
    }
  }

  /// Increments milestone counter (e.g. note created, transaction logged, split settled)
  /// and prompts for rating when appropriate with cooldown support.
  static Future<void> incrementMilestoneAndCheckRating({bool forceMilestone = false}) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final hasRated = prefs.getBool('has_completed_rating') ?? false;
      if (hasRated) return;

      final lastRemindedStr = prefs.getString('last_rating_remind_time');
      if (lastRemindedStr != null) {
        final lastReminded = DateTime.tryParse(lastRemindedStr);
        if (lastReminded != null && DateTime.now().difference(lastReminded).inDays < 7) {
          return; // Respect 7-day cooldown
        }
      }

      // Increment milestone counter
      final milestoneCount = (prefs.getInt('app_milestone_count') ?? 0) + 1;
      await prefs.setInt('app_milestone_count', milestoneCount);

      // Prompt on positive milestones (e.g. 5, 15, 30 actions)
      if (forceMilestone || milestoneCount == 5 || milestoneCount == 15 || milestoneCount == 30) {
        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
          await prefs.setString('last_rating_remind_time', DateTime.now().toIso8601String());
          debugPrint('In-app review requested successfully at milestone $milestoneCount.');
        } else {
          debugPrint('In-app review API is not available.');
        }
      }
    } catch (e) {
      debugPrint('In-app review request failed: $e');
    }
  }
}
