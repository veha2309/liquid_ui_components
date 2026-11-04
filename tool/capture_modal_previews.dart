// Run explicitly with `flutter test tool/capture_modal_previews.dart`.
// These deterministic presentation frames are not performance measurements.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_ui_components/liquid_glass.dart';

void main() {
  testWidgets('record modal presentation frames', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 480));
    const sdk = String.fromEnvironment('FLUTTER_SDK');
    await tester.runAsync(() async {
      for (final font in {
        'Roboto': 'roboto-regular.ttf',
        'MaterialIcons': 'materialicons-regular.otf',
      }.entries) {
        final bytes = await File(
          '$sdk/bin/cache/artifacts/material_fonts/${font.value}',
        ).readAsBytes();
        await (FontLoader(
          font.key,
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    });
    for (final mode in ['prompt-light', 'prompt-dark', 'panel']) {
      final key = GlobalKey();
      final dark = mode == 'prompt-dark';
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'Roboto',
              brightness: dark ? Brightness.dark : Brightness.light,
              colorSchemeSeed: const Color(0xff62518a),
            ),
            home: LiquidGlassTheme(
              settings: const LiquidGlassSettings(
                rendering: LiquidGlassRendering.frosted,
              ),
              child: Builder(
                builder: (context) => Scaffold(
                  body: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? [
                                const Color(0xff192641),
                                const Color(0xff483747),
                                const Color(0xff484139),
                              ]
                            : [
                                const Color(0xff90a7ef),
                                const Color(0xffe9bdd1),
                                const Color(0xffe4b28d),
                              ],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: LiquidGlassButton(
                          onPressed: () {
                            if (mode == 'panel') {
                              LiquidGlassPanel.show<void>(
                                context,
                                builder: (context) => LiquidGlassPanel(
                                  title: 'Your collection',
                                  subtitle: 'Keep your favorites close.',
                                  icon: Icons.layers_outlined,
                                  actions: [
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Done'),
                                    ),
                                  ],
                                  child: const Text(
                                    'A little space for your next idea.',
                                  ),
                                ),
                              );
                            } else {
                              LiquidGlassPrompt.confirm(
                                context,
                                title: 'A fresh start',
                                message:
                                    'Create a space for your favorite discoveries.',
                                confirmLabel: 'Create collection',
                                icon: Icons.create_new_folder_outlined,
                              );
                            }
                          },
                          child: Text(
                            mode == 'panel' ? 'Open panel' : 'New collection',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      var index = 0;
      Future<void> capture() async {
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('build/modal/$mode');
          await directory.create(recursive: true);
          await File(
            '${directory.path}/frame_${index.toString().padLeft(3, '0')}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        index++;
      }

      await capture();
      await tester.tap(
        find.text(mode == 'panel' ? 'Open panel' : 'New collection'),
      );
      await tester.pump();
      for (var frame = 0; frame < 22; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
        await capture();
      }
      await tester.tap(find.text(mode == 'panel' ? 'Done' : 'Cancel'));
      await tester.pump();
      for (var frame = 0; frame < 22; frame++) {
        await tester.pump(const Duration(milliseconds: 20));
        await capture();
      }
      expect(tester.takeException(), isNull);
    }
  });
}
