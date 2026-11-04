import 'package:ui_tester/testing.dart';

import 'support/gallery_ui_scenario.dart';

// Explicit target: exploration may exhaust its budget and report incomplete.
// Keep it separate from the deterministic smoke suite and normal test discovery.
void main() => uiTest(galleryScenario(), config: galleryUiConfig);
