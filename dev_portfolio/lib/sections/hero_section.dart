import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.blueGrey,
      child: const Center(
        child: Text(
          'Hero Section\nYour Name',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 36, color: Colors.white),
        ),
      ),
    );
  }
}