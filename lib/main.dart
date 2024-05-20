import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:helu/view/stt/speech_to_text_page.dart';
import 'package:helu/view/stt/web_rtc.dart';
import 'package:helu/view/stt/websocket_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STT Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Align(
              alignment: Alignment.center,
                child: Text('demo')),
            bottom: const TabBar(tabs: [
              Tab(text: 'STT',),
              Tab(text: 'WebRTC'),
              Tab(text: 'WebSocket')
            ]),
          ),
          body: const TabBarView(
            children: [
              SpeechToTextPage(),
              WebRtc(),
              WebsocketDemo()
            ],
          ),
        ),
      )
      // home: const SpeechToTextPage()
    );
  }
}


