import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async => integrationDriver(
  responseDataCallback: (data) async {
    final directory = Directory('build/performance');
    await directory.create(recursive: true);
    const name = String.fromEnvironment(
      'PERFORMANCE_RUN',
      defaultValue: 'latest',
    );
    await File(
      '${directory.path}/$name.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  },
);
