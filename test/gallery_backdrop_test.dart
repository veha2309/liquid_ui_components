import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/gallery_backdrop.dart';

void main() {
  testWidgets('background tolerates zero width before a valid layout', (
    tester,
  ) async {
    Widget host(double width) => MaterialApp(
      home: Center(
        child: SizedBox(
          width: width,
          height: 400,
          child: const GalleryBackdrop(
            dark: false,
            animated: false,
            child: SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpWidget(host(0));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(host(390));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
