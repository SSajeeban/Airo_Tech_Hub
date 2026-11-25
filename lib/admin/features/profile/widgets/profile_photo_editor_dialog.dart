import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';

class ProfilePhotoEditorDialog extends StatefulWidget {
  const ProfilePhotoEditorDialog({
    super.key,
    required this.image,
    required this.previewBytes,
    required this.isTamil,
  });

  final img.Image image;
  final Uint8List previewBytes;
  final bool isTamil;

  @override
  State<ProfilePhotoEditorDialog> createState() =>
      _ProfilePhotoEditorDialogState();
}

class _ProfilePhotoEditorDialogState extends State<ProfilePhotoEditorDialog> {
  static const double _viewportSize = 280;

  double _zoom = 1;
  Offset _offset = Offset.zero;

  double get _baseScale =>
      _viewportSize / math.min(widget.image.width, widget.image.height);

  Offset _clampOffset(Offset offset) {
    final scale = _baseScale * _zoom;
    final maxX = math.max(0, (widget.image.width * scale - _viewportSize) / 2);
    final maxY = math.max(0, (widget.image.height * scale - _viewportSize) / 2);
    return Offset(
      offset.dx.clamp(-maxX, maxX).toDouble(),
      offset.dy.clamp(-maxY, maxY).toDouble(),
    );
  }

  void _saveCrop() {
    final scale = _baseScale * _zoom;
    final cropSize = (_viewportSize / scale)
        .round()
        .clamp(1, math.min(widget.image.width, widget.image.height))
        .toInt();
    final centerX = widget.image.width / 2 - _offset.dx / scale;
    final centerY = widget.image.height / 2 - _offset.dy / scale;
    final left = (centerX - cropSize / 2)
        .round()
        .clamp(0, widget.image.width - cropSize)
        .toInt();
    final top = (centerY - cropSize / 2)
        .round()
        .clamp(0, widget.image.height - cropSize)
        .toInt();
    final square = img.copyCrop(
      widget.image,
      x: left,
      y: top,
      width: cropSize,
      height: cropSize,
    );
    final resized = img.copyResize(square, width: 512, height: 512);
    Navigator.of(context)
        .pop(Uint8List.fromList(img.encodeJpg(resized, quality: 85)));
  }

  @override
  Widget build(BuildContext context) {
    final displayWidth = widget.image.width * _baseScale * _zoom;
    final displayHeight = widget.image.height * _baseScale * _zoom;

    return AlertDialog(
      title: Text(widget.isTamil ? 'படத்தைச் சரிசெய்' : 'Adjust photo'),
      content: SizedBox(
        width: _viewportSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _viewportSize,
              height: _viewportSize,
              child: ClipOval(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    setState(
                      () => _offset = _clampOffset(_offset + details.delta),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        left: (_viewportSize - displayWidth) / 2 + _offset.dx,
                        top: (_viewportSize - displayHeight) / 2 + _offset.dy,
                        width: displayWidth,
                        height: displayHeight,
                        child: Image.memory(
                          widget.previewBytes,
                          fit: BoxFit.fill,
                        ),
                      ),
                      Center(
                        child: IgnorePointer(
                          child: Container(
                            width: _viewportSize - 2,
                            height: _viewportSize - 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.9),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.remove, size: 18),
                Expanded(
                  child: Slider(
                    value: _zoom,
                    min: 1,
                    max: 3,
                    onChanged: (value) => setState(() {
                      _zoom = value;
                      _offset = _clampOffset(_offset);
                    }),
                  ),
                ),
                const Icon(Icons.add, size: 18),
              ],
            ),
            Text(
              widget.isTamil
                  ? 'படத்தை இழுத்து இடத்தை மாற்றவும்'
                  : 'Drag to position the photo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.isTamil ? 'ரத்து' : 'Cancel'),
        ),
        FilledButton(
          onPressed: _saveCrop,
          child: Text(widget.isTamil ? 'பயன்படுத்து' : 'Use photo'),
        ),
      ],
    );
  }
}
