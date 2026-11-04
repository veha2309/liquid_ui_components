import 'package:integration_test/integration_test.dart';
import 'package:ui_tester/testing.dart';

import '../test/support/gallery_ui_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  uiTest(galleryScenario(), config: galleryUiConfig);
}
