import 'package:flutter/material.dart';
import 'package:helu/utils/colors.dart';
import 'package:helu/utils/widget_utils.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:avatar_glow/avatar_glow.dart';

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage> {
  final SpeechToText _stt = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = 'マイクをタップして音声を文字に変換します。';

  void _initSpeech() async {
    _speechEnabled = await _stt.initialize();
    setState(() {

    });
  }

  void _startListening() async{
    await _stt.listen(onResult: _onSpeechResult, localeId: 'ja-JP');
    setState(() {

    });
  }

  void _stopListening() async {
    await _stt.stop();
    setState(() {

    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initSpeech();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WidgetUtils.createAppBar('Speech To Text'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: <Widget>[
                const Text('Recognized words:', style: TextStyle(fontSize: 20),),
                Expanded(
                    child: Text(_lastWords),
                ),
              ],
            ),

          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     _stt.isNotListening ? _startListening(): _stopListening();
      //   },
      //   tooltip: 'Listen',
      //   child: Icon(_stt.isNotListening ? Icons.mic_off: Icons.mic),
      // ),
      floatingActionButton: AvatarGlow(
        animate: _stt.isListening,
        duration: const Duration(milliseconds: 2000),
        glowColor: bgColor,
        child: GestureDetector(
          onTapDown: (_) {
            if (_stt.isNotListening) {
              _startListening();
            }
          },
          onTapUp: (_) {
            _stopListening();
          },
          child: CircleAvatar(
            backgroundColor: bgColor,
            radius: 35,
            child: Icon(_stt.isNotListening ? Icons.mic_off: Icons.mic, color: Colors.white,),
          ),
        ),
      ),
    );
  }
}
