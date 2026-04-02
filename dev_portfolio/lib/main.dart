// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(DevPortfolioApp());
}

class DevPortfolioApp extends StatefulWidget {
  @override
  _DevPortfolioAppState createState() => _DevPortfolioAppState();
}

class _DevPortfolioAppState extends State<DevPortfolioApp> {
  ThemeMode _themeMode = ThemeMode.light;

  // ダークモード切り替え関数
  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DevPortfolio',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black), // ← ここを bodyText2 → bodyMedium に変更
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white), // ← ここも同様
        ),
      ),
      themeMode: _themeMode,
      home: HomePage(
        themeMode: _themeMode,
        onThemeChanged: _toggleTheme,
      ),
    );
  }
}