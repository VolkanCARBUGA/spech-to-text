import 'package:flutter/material.dart';
import 'package:flutter_spech_to_text/provider/spech_to_text_provider.dart';
import 'package:flutter_spech_to_text/spech_to_text_page.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => SpeechToTextProvider(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: const SpechToTextPage(),
    );
  }
}

