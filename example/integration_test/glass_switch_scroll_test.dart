import 'package:integration_test/integration_test.dart';

// Run the same gesture regression with the real device's Impeller renderer.
import '../../test/glass_switch_scroll_test.dart' as regression;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  regression.main();
}
