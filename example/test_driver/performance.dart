import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final file =
        Platform.environment['GLASS_PERFORMANCE_REPORT'] ??
        'build/glass_performance.json';
    await File(file).parent.create(recursive: true);
    await File(
      file,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    stdout.writeln('Frame timings saved to $file');
  },
);
