import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF5F1EA),
                Color(0xFFE7F0EB),
                Color(0xFFF8EEE5),
              ],
            ),
          ),
        ),
        Positioned(
          right: -60,
          top: -40,
          child: _BlurBlob(color: const Color(0xFF87B8A5), size: 200),
        ),
        Positioned(
          left: -80,
          bottom: -40,
          child: _BlurBlob(color: const Color(0xFFE4BFA3), size: 220),
        ),
        SafeArea(child: child),
      ],
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.45),
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
