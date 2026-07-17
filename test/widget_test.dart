// Smoke test: la app arranca y muestra la pantalla principal en español.

import 'package:flutter_test/flutter_test.dart';

import 'package:fb_media_saver/main.dart';

void main() {
  testWidgets('La app arranca y muestra la pantalla de inicio',
      (WidgetTester tester) async {
    await tester.pumpWidget(const FbMediaSaverApp());
    await tester.pump();

    expect(find.text('FB Media Saver'), findsOneWidget);
    expect(
      find.text('Pegá el enlace de un video o foto público de Facebook'),
      findsOneWidget,
    );
  });
}
