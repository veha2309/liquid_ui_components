import 'package:integration_test/integration_test.dart';

import '../test/ui_tester_test.dart' show registerGalleryUiTest;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerGalleryUiTest(device: true);
}
