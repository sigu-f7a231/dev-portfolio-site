import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      color: Colors.teal,
      child: const Center(
        child: Text(
          'About Section',
          style: TextStyle(fontSize: 32, color: Colors.white),
        ),
      ),
    );
  }
}