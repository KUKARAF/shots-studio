import 'package:flutter/services.dart';

class TaskerIntegrationService {
  static const MethodChannel _channel = MethodChannel('tasker_integration');
  
  static const String eventTypeScreenshotAdded = 'screenshot_added';
  static const String eventTypeScreenshotTagged = 'screenshot_tagged';
  static const String eventTypeScreenshotDeleted = 'screenshot_deleted';
  
  /// Broadcast a Tasker event
  static Future<bool> broadcastEvent(String eventType, Map<String, dynamic> eventData) async {
    try {
      final result = await _channel.invokeMethod('broadcastScreenshotEvent', {
        'eventType': eventType,
        'eventData': eventData,
      });
      return result as bool;
    } on PlatformException catch (e) {
      print('Tasker integration error: ${e.message}');
      return false;
    } catch (e) {
      print('Tasker integration error: $e');
      return false;
    }
  }
  
  /// Broadcast when a new screenshot is added
  static Future<bool> broadcastScreenshotAdded({
    required String screenshotId,
    String? title,
    List<String>? tags,
    String? path,
  }) async {
    return broadcastEvent(eventTypeScreenshotAdded, {
      'screenshot_id': screenshotId,
      'title': title ?? '',
      'tags': tags ?? [],
      'path': path ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Broadcast when a screenshot is tagged
  static Future<bool> broadcastScreenshotTagged({
    required String screenshotId,
    required String newTag,
    List<String>? allTags,
    String? title,
  }) async {
    return broadcastEvent(eventTypeScreenshotTagged, {
      'screenshot_id': screenshotId,
      'new_tag': newTag,
      'all_tags': allTags ?? [],
      'title': title ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
  
  /// Broadcast when a screenshot is deleted
  static Future<bool> broadcastScreenshotDeleted({
    required String screenshotId,
    String? title,
  }) async {
    return broadcastEvent(eventTypeScreenshotDeleted, {
      'screenshot_id': screenshotId,
      'title': title ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
