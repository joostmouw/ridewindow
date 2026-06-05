// lib/features/shared/weather_icon.dart
// Animated weather icon based on ride tier. Pure Flutter — no external deps.

import 'package:flutter/material.dart';
import 'package:ridewindow/domain/models/ride_tier.dart';

class WeatherIcon extends StatefulWidget {
  final RideTier tier;
  final double size;

  const WeatherIcon({super.key, required this.tier, this.size = 32});

  @override
  State<WeatherIcon> createState() => _WeatherIconState();
}

class _WeatherIconState extends State<WeatherIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: switch (widget.tier) {
        Perfect() => _buildSun(),
        Great() => _buildPartlyCloudy(),
        Acceptable() => _buildCloudy(),
        Poor() => _buildRainy(),
      },
    );
  }

  Widget _buildSun() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: child,
        );
      },
      child: Icon(
        Icons.wb_sunny_rounded,
        size: widget.size,
        color: const Color(0xFFFFA726),
      ),
    );
  }

  Widget _buildPartlyCloudy() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = (_controller.value * 2 - 1).abs() * 2 - 1; // -1 to 1
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Icon(
        Icons.cloud,
        size: widget.size,
        color: const Color(0xFF66BB6A),
      ),
    );
  }

  Widget _buildCloudy() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset = (_controller.value * 2 - 1).abs() * 3 - 1.5;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Icon(
        Icons.cloud_queue,
        size: widget.size,
        color: const Color(0xFFFFA726),
      ),
    );
  }

  Widget _buildRainy() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bounce = (_controller.value * 2 - 1).abs() * 2;
        return Transform.translate(
          offset: Offset(0, bounce),
          child: child,
        );
      },
      child: Icon(
        Icons.grain,
        size: widget.size,
        color: const Color(0xFFBDBDBD),
      ),
    );
  }
}
