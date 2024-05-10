import 'package:flutter/material.dart';
import 'package:helu/view/stt/audio_player_page.dart';
import 'package:helu/view/stt/basic_speech_page.dart';

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage> with TickerProviderStateMixin {
  late TabController _tabController;


  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech To Text'),
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'basic', icon: Icon(Icons.mic),),
            Tab(text: 'audio', icon: Icon(Icons.audio_file))
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
          child: TabBarView(
            controller: _tabController,
            children:<Widget>[
              BasicSpeechPage(),
              AudioPlayerPage(title: 'audio'),
            ]
          ),
        ),
      )
    );
  }

}
