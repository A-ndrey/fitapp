import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class FakeBarcodeCamera extends MobileScannerPlatform {
  final captures = StreamController<BarcodeCapture?>.broadcast();
  Future<void> close() => captures.close();
  bool denied = false;
  bool disposed = false;
  int starts = 0;
  int stops = 0;
  StartOptions? options;
  Completer<void>? startGate;
  Completer<void>? stopGate;
  bool running = false;
  WebBarcodeReader? reader;

  @override
  void setWebBarcodeReader(WebBarcodeReader reader) => this.reader = reader;

  @override
  Stream<BarcodeCapture?> get barcodesStream => captures.stream;
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
  @override
  Widget buildCameraView() => const ColoredBox(color: Colors.black);
  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    starts++;
    options = startOptions;
    await startGate?.future;
    if (denied) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
    }
    running = true;
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(640, 480),
    );
  }

  @override
  Future<void> stop() async {
    stops++;
    await stopGate?.future;
    running = false;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
