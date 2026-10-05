import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme/pokebinder_theme.dart';
import '../widgets/pokebinder_controls.dart';

const double _kViewport = 300;
const double _kOutputSize = 512;
const double _kMaxZoom = 4;
const double _kViewportRadius = 24;
const double _kSliderTrack = 4;

class AvatarCropScreen extends StatefulWidget {
  final Uint8List imageBytes;

  const AvatarCropScreen({super.key, required this.imageBytes});

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _controller = TransformationController();
  final _captureKey = GlobalKey();
  Size? _contentSize;
  bool _failed = false;
  bool _saving = false;

  double get _zoom =>
      _controller.value.getMaxScaleOnAxis().clamp(1.0, _kMaxZoom).toDouble();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransform);
    _load();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTransform)
      ..dispose();
    super.dispose();
  }

  void _onTransform() {
    if (mounted) setState(() {});
  }

  Matrix4 _matrix(double scale, double tx, double ty) =>
      Matrix4(scale, 0, 0, 0, 0, scale, 0, 0, 0, 0, 1, 0, tx, ty, 0, 1);

  double _clampOffset(double offset, double content, double scale) {
    final lower = _kViewport - content * scale;
    return lower >= 0 ? 0 : offset.clamp(lower, 0.0).toDouble();
  }

  Future<void> _load() async {
    try {
      final image = await decodeImageFromList(widget.imageBytes);
      final width = image.width.toDouble();
      final height = image.height.toDouble();
      image.dispose();
      if (!mounted) return;

      final fit = _kViewport / (width < height ? width : height);
      final size = Size(width * fit, height * fit);
      setState(() => _contentSize = size);
      _controller.value = _matrix(
        1,
        -(size.width - _kViewport) / 2,
        -(size.height - _kViewport) / 2,
      );
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _setZoom(double scale) {
    final size = _contentSize;
    if (size == null) return;
    final matrix = _controller.value;
    final current = matrix.getMaxScaleOnAxis();
    const center = _kViewport / 2;
    final tx = (center - (center - matrix.storage[12]) / current * scale);
    final ty = (center - (center - matrix.storage[13]) / current * scale);
    _controller.value = _matrix(
      scale,
      _clampOffset(tx, size.width, scale),
      _clampOffset(ty, size.height, scale),
    );
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary = _captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image =
          await boundary.toImage(pixelRatio: _kOutputSize / _kViewport);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (!mounted) return;
      Navigator.of(context).pop(data!.buffer.asUint8List());
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text("Couldn't crop that photo. Try a different one."),
          ),
        );
    }
  }

  Widget _body(Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: _kViewport,
          height: _kViewport,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kViewportRadius),
            boxShadow: kCardElevation,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              RepaintBoundary(
                key: _captureKey,
                child: InteractiveViewer(
                  transformationController: _controller,
                  constrained: false,
                  minScale: 1,
                  maxScale: _kMaxZoom,
                  boundaryMargin: EdgeInsets.zero,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _CircleMaskPainter()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PokeBinderSpacing.sp5),
        Container(
          width: _kViewport,
          padding: const EdgeInsets.symmetric(
            horizontal: PokeBinderSpacing.sp4,
            vertical: PokeBinderSpacing.sp1,
          ),
          decoration: BoxDecoration(
            color: PokeBinderColors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: kCardElevation,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.photo_size_select_small_rounded,
                size: 16,
                color: PokeBinderColors.inkSoft,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: _kSliderTrack,
                    activeTrackColor: PokeBinderColors.redDeep,
                    inactiveTrackColor: PokeBinderColors.cream2,
                    thumbColor: PokeBinderColors.redDeep,
                    overlayColor:
                        PokeBinderColors.red.withValues(alpha: 0.12),
                  ),
                  child: Slider(
                    min: 1,
                    max: _kMaxZoom,
                    value: _zoom,
                    onChanged: _setZoom,
                  ),
                ),
              ),
              const Icon(
                Icons.photo_size_select_large_rounded,
                size: 20,
                color: PokeBinderColors.inkSoft,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = _contentSize;

    return Scaffold(
      backgroundColor: PokeBinderColors.cream,
      body: SafeArea(
        child: Padding(
          padding: PokeBinderSpacing.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BackLink(onTap: () => Navigator.of(context).maybePop()),
              const SizedBox(height: PokeBinderSpacing.sp2),
              Text('Adjust Photo', style: PokeBinderText.heading),
              const SizedBox(height: PokeBinderSpacing.sp1),
              Text(
                'Drag and zoom to frame your photo inside the circle.',
                style: PokeBinderText.subtitle,
              ),
              Expanded(
                child: _failed
                    ? Center(
                        child: Text(
                          "That image couldn't be opened. Try a different one.",
                          textAlign: TextAlign.center,
                          style: PokeBinderText.subtitle,
                        ),
                      )
                    : size == null
                        ? const Center(child: CircularProgressIndicator())
                        : Center(child: _body(size)),
              ),
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Cancel',
                      ghost: true,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(width: PokeBinderSpacing.sp2),
                  Expanded(
                    child: PillButton(
                      label: _saving ? 'Saving…' : 'Use Photo',
                      icon: Icons.check,
                      enabled: size != null && !_saving,
                      onTap: _confirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleMaskPainter extends CustomPainter {
  const _CircleMaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addOval(rect);
    canvas.drawPath(
      mask,
      Paint()..color = PokeBinderColors.ink.withValues(alpha: 0.55),
    );
    canvas.drawOval(
      rect.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = PokeBinderColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleMaskPainter oldDelegate) => false;
}
