import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:helu/utils/widget_utils.dart';
import 'package:helu/view/stt/speech_to_text_page.dart';
import 'package:helu/view/tts/text_to_speech_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const TextToSpeechPage(),
      home: const Home()
      // home: const SpeechSamplePage(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WidgetUtils.createAppBar('demo'),
      body: SafeArea(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SpeechToTextPage()));
                },
                child: Card(
                  child: Container(
                      padding: const EdgeInsets.all(100),
                      child: const Text('Speech to Text')
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TextToSpeechPage()));
                },
                child: Card(
                  child: Container(
                      padding: const EdgeInsets.all(100),
                      child: const Text('Text to Speech')
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

