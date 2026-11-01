import 'dart:async';

import 'package:fitapp/widgets/barcode_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../support/fake_barcode_camera.dart';

void main() {
  late FakeBarcodeCamera camera;
  late MobileScannerPlatform original;
  setUp(() {
    original = MobileScannerPlatform.instance;
    camera = FakeBarcodeCamera();
    MobileScannerPlatform.instance = camera;
  });
  tearDown(() async {
    MobileScannerPlatform.instance = original;
    await camera.close();
  });

  Future<void> open(WidgetTester tester, ValueChanged<String?> onResult) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => onResult(await showBarcodeInput(context)),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(camera.starts, 1);
    expect(camera.reader, WebBarcodeReader.zxingJs);
    expect(find.text('Start camera'), findsNothing);
  }

  testWidgets('camera starts on entry with manual input below the preview', (
    tester,
  ) async {
    await open(tester, (_) {});
    expect(camera.options!.cameraDirection, CameraFacing.back);
    expect(
      tester.getBottomLeft(find.byType(MobileScanner)).dy,
      lessThan(
        tester.getTopLeft(find.widgetWithText(TextField, 'Barcode digits')).dy,
      ),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(camera.disposed, isTrue);
  });

  testWidgets('camera denial still allows manual barcode entry', (
    tester,
  ) async {
    camera.denied = true;
    String? result;
    await open(tester, (code) => result = code);
    expect(find.textContaining('Camera unavailable.'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Barcode digits'),
      '0012345678905',
    );
    await tester.tap(find.text('Use barcode'));
    await tester.pumpAndSettle();
    expect(result, '0012345678905');
    expect(camera.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving during camera permission releases a late camera grant', (
    tester,
  ) async {
    camera.startGate = Completer<void>();
    await open(tester, (_) {});
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(camera.disposed, isFalse);
    camera.startGate!.complete();
    await tester.pumpAndSettle();
    expect(camera.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rear camera detection returns one result and releases camera', (
    tester,
  ) async {
    final results = <String?>[];
    await open(tester, results.add);
    expect(camera.options!.cameraDirection, CameraFacing.back);
    camera.captures.add(
      const BarcodeCapture(
        barcodes: [
          Barcode(
            rawValue: 'https://example.com',
            format: BarcodeFormat.qrCode,
          ),
        ],
      ),
    );
    await tester.pump();
    expect(results, isEmpty);
    const capture = BarcodeCapture(
      barcodes: [
        Barcode(rawValue: '0012345678905', format: BarcodeFormat.ean13),
      ],
    );
    camera.captures.add(capture);
    camera.captures.add(capture);
    await tester.pumpAndSettle();
    expect(results, ['0012345678905']);
    expect(camera.stops, 1);
    expect(camera.running, isFalse);
    expect(camera.disposed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'scan result waits for camera shutdown before closing the route',
    (tester) async {
      final results = <String?>[];
      await open(tester, results.add);
      camera.stopGate = Completer<void>();
      camera.captures.add(
        const BarcodeCapture(
          barcodes: [
            Barcode(rawValue: '0012345678905', format: BarcodeFormat.ean13),
          ],
        ),
      );
      await tester.pump();
      expect(camera.stops, 1);
      expect(results, isEmpty);
      expect(camera.running, isTrue);
      expect(find.byType(BarcodeInputScreen), findsOneWidget);
      camera.stopGate!.complete();
      await tester.pumpAndSettle();
      expect(results, ['0012345678905']);
      expect(camera.running, isFalse);
      expect(camera.disposed, isTrue);
    },
  );

  testWidgets('camera pauses when hidden and resumes when visible', (
    tester,
  ) async {
    await open(tester, (_) {});
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(camera.stops, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.starts, 2);
    await tester.tap(find.text('Stop camera'));
    await tester.pumpAndSettle();
    expect(camera.disposed, isTrue);
    expect(find.byType(MobileScanner), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
