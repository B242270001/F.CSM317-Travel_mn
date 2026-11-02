import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() => runApp(const TravelApp());

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Colors.teal;
    return MaterialApp(
      title: 'TRAVEL APP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed),
        fontFamily: 'RobotoSlab',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        fontFamily: 'RobotoSlab',
      ),
      themeMode: ThemeMode.system, // утасны тохиргоог дагана
      home: const HomeScreen(),
    );
  }
}
