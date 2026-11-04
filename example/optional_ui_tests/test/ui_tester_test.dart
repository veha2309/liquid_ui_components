import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_tester/testing.dart';

import 'support/gallery_ui_scenario.dart';

/// Shared registration for widget tests and the Android integration entrypoint.
void registerGalleryUiTest({bool device = false}) {
  const filter = String.fromEnvironment('UI_TESTER_SCENARIO');
  if (filter.isNotEmpty && filter != 'liquid-glass-gallery') return;
  testWidgets('liquid-glass-gallery', (tester) async {
    if (!device) {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    const replay = String.fromEnvironment('UI_TESTER_REPLAY');
    final actions = replay.isEmpty
        ? gallerySmokeActions
        : (jsonDecode(replay) as List)
              .map((a) => UiAction.fromJson(Map<String, dynamic>.from(a)))
              .toList();
    final session = UiSession(
      tester,
      galleryScenario(),
      config: galleryUiConfig,
    );
    final result = await session.replay(actions);
    expect(
      result.status,
      'passed',
      reason:
          '${result.reason}: ${result.findings.map((f) => f.message).join('\n')}',
    );
  });
}

void main() => registerGalleryUiTest();
