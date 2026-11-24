import 'package:flutter/material.dart';
import 'package:newzen_mitjyu/pages/homePage.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: nzTheme(Brightness.light),
    darkTheme: nzTheme(Brightness.dark),
    themeMode: ThemeMode.dark,
    home: const HomePage(),
  ));
}

