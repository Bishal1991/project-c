import 'package:flutter/material.dart';

class Brand {
  static const purple = Color(0xFF7C55F0);
  static const night = Color(0xFF14111F);
  static const nightCard = Color(0xFF1D1A2E);
  static const nightCardTop = Color(0xFF2A2350);
  static const lavender = Color(0xFFC9B8F5);
  static const textSoft = Color(0xFFB9B3CC);
}

/// Logo box, app name and tagline (used on the splash and welcome screens).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: const Center(child: _Rings()),
        ),
        const SizedBox(height: 24),
        const Text(
          'NewZen Mitjyu',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 38,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A friend who becomes family',
          style: TextStyle(
            fontSize: 17,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _Rings extends StatelessWidget {
  const _Rings();

  Widget _ring() => Container(
    height: 28,
    width: 28,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 28,
      child: Stack(
        children: [
          Positioned(left: 0, child: _ring()),
          Positioned(right: 0, child: _ring()),
        ],
      ),
    );
  }
}