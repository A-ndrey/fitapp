import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';
import '../models/food_barcode.dart';

Future<String?> showBarcodeInput(BuildContext context) {
  return Navigator.of(
    context,
  ).push<String>(MaterialPageRoute(builder: (_) => const BarcodeInputScreen()));
}

/// Camera scanning and manual entry share the same validation and result.
class BarcodeInputScreen extends StatefulWidget {
  const BarcodeInputScreen({super.key});

  @override
  State<BarcodeInputScreen> createState() => _BarcodeInputScreenState();
}

class _BarcodeInputScreenState extends State<BarcodeInputScreen>
    with WidgetsBindingObserver {
  final _textController = TextEditingController();
  MobileScannerController? _camera;
  bool _completed = false;
  bool _invalid = false;
  bool _releasingCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camera = _createCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camera = _camera;
    if (camera == null || !camera.value.hasCameraPermission || _completed) {
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (!camera.value.isStarting) unawaited(camera.start());
    } else {
      unawaited(camera.stop());
    }
  }

  @override
  void dispose() {
    _completed = true;
    WidgetsBinding.instance.removeObserver(this);
    _textController.dispose();
    final camera = _camera;
    if (camera != null) unawaited(_releaseCamera(camera));
    super.dispose();
  }

  Future<void> _stopCamera(MobileScannerController camera) async {
    // Permission can resolve after the route closes. Wait for startup before
    // releasing the stream, so a late camera grant cannot leave it running.
    if (camera.value.isStarting) {
      final ready = Completer<void>();
      void onChanged() {
        if (!camera.value.isStarting && !ready.isCompleted) ready.complete();
      }

      camera.addListener(onChanged);
      await ready.future;
      camera.removeListener(onChanged);
    }
    await camera.stop();
  }

  Future<void> _releaseCamera(MobileScannerController camera) async {
    await _stopCamera(camera);
    await camera.dispose();
  }

  Future<void> _submit(String value) async {
    if (_completed) return;
    if (!FoodBarcode.isValid(value)) {
      setState(() => _invalid = true);
      return;
    }
    _completed = true;
    final camera = _camera;
    if (camera != null) await _stopCamera(camera);
    if (mounted) Navigator.of(context).pop(value.trim());
  }

  MobileScannerController _createCamera() {
    // mobile_scanner 7.4.x's native/WASM polling readers discard their stream
    // without stopping its tracks. ZXing-js reset releases the actual camera.
    // This setting is a no-op on non-web platforms.
    MobileScannerPlatform.instance.setWebBarcodeReader(
      WebBarcodeReader.zxingJs,
    );
    return MobileScannerController(
      facing: CameraFacing.back,
      formats: const [
        BarcodeFormat.ean8,
        BarcodeFormat.ean13,
        BarcodeFormat.upcA,
        BarcodeFormat.itf14,
      ],
    );
  }

  void _startCamera() {
    setState(() => _camera = _createCamera());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final camera = _camera;
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.barcodeScan ?? 'Scan barcode')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n?.barcodeScanHint ??
                        'Point the rear camera at the barcode on the packaging, or enter its digits below.',
                  ),
                  const SizedBox(height: 16),
                  if (camera == null)
                    FilledButton.icon(
                      onPressed: _releasingCamera ? null : _startCamera,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: Text(l10n?.barcodeStartCamera ?? 'Start camera'),
                    )
                  else ...[
                    SizedBox(
                      height: 240,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: MobileScanner(
                          controller: camera,
                          onDetect: (capture) {
                            for (final barcode in capture.barcodes) {
                              final value = barcode.rawValue;
                              if (value != null && FoodBarcode.isValid(value)) {
                                _submit(value);
                                break;
                              }
                            }
                          },
                          errorBuilder: (context, error) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                l10n?.barcodeCameraUnavailable ??
                                    'Camera unavailable. Allow camera access in your browser, or enter the barcode below.',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        setState(() {
                          _camera = null;
                          _releasingCamera = true;
                        });
                        await _releaseCamera(camera);
                        if (mounted) setState(() => _releasingCamera = false);
                      },
                      icon: const Icon(Icons.videocam_off_outlined),
                      label: Text(l10n?.barcodeStopCamera ?? 'Stop camera'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextField(
                    controller: _textController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.done,
                    onSubmitted: _submit,
                    decoration: InputDecoration(
                      labelText: l10n?.barcodeDigits ?? 'Barcode digits',
                      errorText: _invalid
                          ? l10n?.barcodeInvalid ??
                                'Enter 8, 12, 13 or 14 digits.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _submit(_textController.text),
                    child: Text(l10n?.barcodeUse ?? 'Use barcode'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
