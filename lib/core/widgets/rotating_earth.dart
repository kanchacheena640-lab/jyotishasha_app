import 'package:flutter/material.dart';

class RotatingEarth extends StatefulWidget {
  const RotatingEarth({super.key});

  @override
  State<RotatingEarth> createState() => _RotatingEarthState();
}

class _RotatingEarthState extends State<RotatingEarth>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(); // infinite rotation
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: controller,
      child: Image.asset("assets/images/earth.png", width: 20, height: 20),
    );
  }
}
