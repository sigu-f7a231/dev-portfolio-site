import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.blueAccent,
      child: const Center(
        child: Text(
          'Welcome to My Portfolio',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 36, color: Colors.white),
        ),
      ),
    );
  }
}