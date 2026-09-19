import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spatial_draft/core/models/draft_capture.dart';
import 'package:spatial_draft/services/app_log_service.dart';

/// Persistent service managing saved draft screenshots and gallery archive.
class GalleryService {
  GalleryService._();

  /// Shared singleton instance of [GalleryService].
  static final GalleryService instance = GalleryService._();

  static const String _storageKey = 'spatial_draft_gallery_captures_v1';
  static const int _maxCaptures = 50;

  SharedPreferences? _prefs;

  /// ValueNotifier emitting the latest list of [DraftCapture]s, newest first.
  final ValueNotifier<List<DraftCapture>> capturesNotifier =
      ValueNotifier<List<DraftCapture>>(<DraftCapture>[]);

  /// Returns current list of captures.
  List<DraftCapture> get captures => capturesNotifier.value;

  /// Initializes the service and loads persisted captures from storage.
  Future<void> init({SharedPreferences? prefs}) async {
    try {
      _prefs = prefs ?? await SharedPreferences.getInstance();
      final jsonString = _prefs?.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final dynamic decoded = jsonDecode(jsonString);
        if (decoded is List) {
          final loaded = decoded
              .whereType<Map<String, dynamic>>()
              .map(DraftCapture.fromJson)
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          capturesNotifier.value = loaded;
        }
      }
      AppLogService.instance.info(
        'GALLERY',
        'GalleryService initialized with ${captures.length} captures',
      );
    } catch (e, stack) {
      AppLogService.instance.error(
        'GALLERY',
        'Failed to initialize GalleryService: $e',
        stackTrace: stack,
      );
    }
  }

  /// Saves a new [DraftCapture] to the gallery archive and persists it.
  Future<void> saveCapture(DraftCapture capture) async {
    try {
      final current = List<DraftCapture>.from(capturesNotifier.value);
      // Remove any duplicate id if present
      current.removeWhere((c) => c.id == capture.id);
      current.insert(0, capture);

      // Enforce max captures cap
      if (current.length > _maxCaptures) {
        current.removeRange(_maxCaptures, current.length);
      }

      capturesNotifier.value = current;
      await _persist(current);

      AppLogService.instance.info(
        'GALLERY',
        'Saved capture "${capture.title}" (${capture.resolutionLabel})',
      );
    } catch (e, stack) {
      AppLogService.instance.error(
        'GALLERY',
        'Failed to save capture: $e',
        stackTrace: stack,
      );
    }
  }

  /// Deletes a capture by its unique [id].
  Future<void> deleteCapture(String id) async {
    try {
      final current = List<DraftCapture>.from(capturesNotifier.value)
        ..removeWhere((c) => c.id == id);
      capturesNotifier.value = current;
      await _persist(current);

      AppLogService.instance.info('GALLERY', 'Deleted capture with ID: $id');
    } catch (e, stack) {
      AppLogService.instance.error(
        'GALLERY',
        'Failed to delete capture $id: $e',
        stackTrace: stack,
      );
    }
  }

  /// Clears all captures from the gallery.
  Future<void> clearAll() async {
    try {
      capturesNotifier.value = <DraftCapture>[];
      await _persist(<DraftCapture>[]);
      AppLogService.instance.info('GALLERY', 'Cleared all captures from archive');
    } catch (e, stack) {
      AppLogService.instance.error(
        'GALLERY',
        'Failed to clear gallery: $e',
        stackTrace: stack,
      );
    }
  }

  Future<void> _persist(List<DraftCapture> items) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonList = items.map((c) => c.toJson()).toList();
    final encoded = jsonEncode(jsonList);
    await prefs.setString(_storageKey, encoded);
  }
}
