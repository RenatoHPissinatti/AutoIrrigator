import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'view/pages/home_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoIrrigator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.unboundedTextTheme(),
      ),
      home: const HomePage(),
      routes: {
        '/home': (context) => const HomePage(),
      },
    );
  }
}
