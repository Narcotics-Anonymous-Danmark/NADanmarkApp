import 'package:flutter/widgets.dart';

final class NaFadeClip extends StatelessWidget {
  const NaFadeClip({required this.maxHeight, required this.child, super.key});

  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxHeight: maxHeight),
    child: ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
        stops: [0, 0.5, 1],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: double.infinity,
          child: child,
        ),
      ),
    ),
  );
}
