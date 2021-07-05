import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'detail_screen.dart';

Future<void> main() async {
  runApp(
    MaterialApp(
      title: 'Camera Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExamplePage(),
    ),
  );
}
class ExamplePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ExamplePageState();
}

class ExamplePageState extends State<ExamplePage> {
  late CameraController cameraController;
  bool initialized = false;
  ////////
  // Takes picture with the selected device camera, and
  // returns the image path
  Future<String?> _takePicture() async {
    if (!cameraController.value.isInitialized) {
      print("Controller is not initialized");
      return null;
    }

    String? imagePath;

    if (cameraController.value.isTakingPicture) {
      print("Processing is progress ...");
      return null;
    }

    try {
      // Turning off the camera flash
      cameraController.setFlashMode(FlashMode.off);
      // Returns the image in cross-platform file abstraction
      final XFile file = await cameraController.takePicture();
      // Retrieving the path
      imagePath = file.path;
    } on CameraException catch (e) {
      print("Camera Exception: $e");
      return null;
    }

    return imagePath;
  }
  ////////

  @override
  void initState() {
    super.initState();

    _initCamera();
  }
  ////
  @override
  void dispose() {
    // dispose the camera controller when navigated
    // to a different page
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera example'),
      ),
      /*body: Stack(
        children: [
          _cameraPreview(),
          Align(alignment: Alignment.bottomCenter, child: _button()),
        ],
      ),
    );*/
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _cameraPreview(),
          const SizedBox(height: 48),
          _button(),
        ],
      ),
    );
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    if (cameras.length >= 0) {
      cameraController = CameraController(cameras.first, ResolutionPreset.max);
      cameraController.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          initialized = true;
        });
      });
    }
  }

  Widget _button() {
    return Ink(
      decoration: const ShapeDecoration(
        color: Colors.lightBlue,
        shape: CircleBorder(),
      ),
      child: IconButton(
        icon: Icon(Icons.camera_alt),
        color: Colors.white,
          onPressed: () async {
            // If the returned path is not null navigate
            // to the DetailScreen
            await _takePicture().then((String? path) {
              if (path != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(
                      imagePath: path,
                    ),
                  ),
                );
              } else {
                print('Image path not found!');
              }
            });
          },
/////
      ),
    );
  }
  Widget _cameraPreview() {
    if (initialized) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: _CroppedCameraPreview(
          cameraController: cameraController,
        ),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }
/*Widget _cameraPreview() {
    if (initialized) {
      return AspectRatio(
        aspectRatio: 1,
        child: ClipRect(
          child: Transform.scale(
            scale: cameraController.value.aspectRatio,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1 / cameraController.value.aspectRatio,
                child: CameraPreview(cameraController),
              ),
            ),
          ),
        ),
      );
    } else {
      return const Center(child: CircularProgressIndicator());
    }
  }*/

}
////////////
class _CroppedCameraPreview extends StatelessWidget {
  const _CroppedCameraPreview({
    required this.cameraController,
  });

  final CameraController cameraController;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          ClipRect(
            child: Transform.scale(
              scale: cameraController.value.aspectRatio,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1 / cameraController.value.aspectRatio,
                  child: CameraPreview(cameraController),
                ),
              ),
            ),
          ),
          Container(
            decoration: ShapeDecoration(
              shape: CardScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 12,
                borderLength: 32,
                borderWidth: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
////////////
// クレカ標準の比
const _CARD_ASPECT_RATIO = 1 / 6;
// 横の枠線marginを決める時用のfactor
// 横幅の5%のサイズのmarginをとる
const _OFFSET_X_FACTOR = 0.05;

class CardScannerOverlayShape extends ShapeBorder {
  const CardScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 8.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 12,
    this.borderLength = 32,
    this.cutOutBottomOffset = 0,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutBottomOffset;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(
        rect.right,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.bottom,
      )
      ..lineTo(
        rect.left,
        rect.top,
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final offsetX = rect.width * _OFFSET_X_FACTOR;
    final cardWidth = rect.width - offsetX * 2;
    final cardHeight = cardWidth * _CARD_ASPECT_RATIO;
    final offsetY = (rect.height - cardHeight) / 2;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + offsetX,
      rect.top + offsetY,
      cardWidth,
      cardHeight,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(
        rect,
        backgroundPaint,
      )
    // Draw top right corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.right - borderLength,
          cutOutRect.top,
          cutOutRect.right,
          cutOutRect.top + borderLength,
          topRight: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
    // Draw top left corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.left,
          cutOutRect.top,
          cutOutRect.left + borderLength,
          cutOutRect.top + borderLength,
          topLeft: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
    // Draw bottom right corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.right - borderLength,
          cutOutRect.bottom - borderLength,
          cutOutRect.right,
          cutOutRect.bottom,
          bottomRight: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
    // Draw bottom left corner
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.left,
          cutOutRect.bottom - borderLength,
          cutOutRect.left + borderLength,
          cutOutRect.bottom,
          bottomLeft: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          cutOutRect,
          Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..restore();
  }

  @override
  ShapeBorder scale(double t) {
    return CardScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
