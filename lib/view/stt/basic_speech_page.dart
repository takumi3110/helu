import 'dart:math';

import 'package:flutter/material.dart';
import 'package:helu/utils/function_utils.dart';
import 'package:helu/utils/widget_utils.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class BasicSpeechPage extends StatefulWidget {
  const BasicSpeechPage({super.key});

  @override
  State<BasicSpeechPage> createState() => _BasicSpeechPageState();
}

class _BasicSpeechPageState extends State<BasicSpeechPage> {

  final SpeechToText _speech = SpeechToText();
  int _listenFor = 1;
  int _pauseFor = 5;
  bool _isLogEvents = false;
  bool _onDevice = false;
  bool _hasSpeech = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  String? _currentLocaleId = '';
  List<LocaleName> _localeNames = [];

  Future<void> initSpeechState() async {
    try {
      var hasSpeech = await _speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: _isLogEvents,
      );
      if (hasSpeech) {
        // Get the list of languages installed on the supporting platform so they
        // can be displayed in the UI for selection by the user.
        _localeNames = await _speech.locales();

        var systemLocale = await _speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        lastError = 'Speech recognition failed: ${e.toString()}';
        _hasSpeech = false;
      });
    }
  }

  void resultListener(SpeechRecognitionResult result) {
    FunctionUtils.logEvent(
        'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    setState(() {
      lastWords = result.recognizedWords;
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // FunctionUtils.logEvent('sound level $level: $minSoundLevel - $maxSoundLevel ');
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    FunctionUtils.logEvent(
        'Received error status: $error, listening: ${_speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    FunctionUtils.logEvent(
        'Received listener status: $status, listening: ${_speech.isListening}');
    setState(() {
      lastStatus = status;
    });
  }

  void startListening() {
    FunctionUtils.logEvent('start listening');
    lastWords = '';
    lastError = '';
    final pauseFor = _pauseFor;
    final listenFor = _listenFor;
    final options = SpeechListenOptions(
        onDevice: _onDevice,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
        autoPunctuation: true,
        enableHapticFeedback: true);
    _speech.listen(
      onResult: resultListener,
      // 記録する時間
      // listenFor: Duration(minutes: listenFor ?? 3),
      // 単語が検出されない状態の音声の一時停止の最大時間
      pauseFor: Duration(seconds: pauseFor ?? 3),
      localeId: _currentLocaleId,
      onSoundLevelChange: soundLevelListener,
      listenOptions: options,
    );
    setState(() {});
  }

  void stopListening() {
    FunctionUtils.logEvent('stop listening');
    _speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    FunctionUtils.logEvent('cancel listening');
    _speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initSpeechState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Text(
              lastWords,
              textAlign: TextAlign.start,
            ),
          ),
          // Row(
          //   children: [
          //     const Text('Languages'),
          //     const SizedBox(width: 20,),
          //     DropdownButton<String>(
          //       value: _currentLocaleId,
          //       icon: const Icon(Icons.arrow_downward),
          //       iconSize: 24,
          //       elevation: 16,
          //       style: const TextStyle(color: Colors.deepPurple),
          //       underline: Container(
          //         height: 2,
          //         color: Colors.deepPurpleAccent,
          //       ),
          //       onChanged: (String? newValue) {
          //         setState(() {
          //           _currentLocaleId = newValue;
          //         });
          //       },
          //       items: _localeNames.map<DropdownMenuItem<String>>((locale) => DropdownMenuItem<String>(
          //         value: locale.localeId,
          //         child: Text(locale.name),
          //       )).toList(),
          //     ),
          //   ],
          // ),
          // WidgetUtils.sliderRow(
          //     'SoundLevel: min',
          //     Slider(
          //         value: minSoundLevel,
          //         min: 5000,
          //         max: 50000,
          //         onChanged: (double value) {
          //           setState(() {
          //             minSoundLevel = value;
          //           });
          //         }
          //     ),
          //     '(${minSoundLevel.toStringAsFixed(2)})'
          // ),
          // WidgetUtils.sliderRow(
          //     'SoundLevel: max',
          //     Slider(
          //         value: maxSoundLevel,
          //         min: -5000,
          //         max: 5000,
          //         onChanged: (double value) {
          //           setState(() {
          //             maxSoundLevel = value;
          //           });
          //         }
          //     ),
          //     '(${maxSoundLevel.toStringAsFixed(2)})'
          // ),
          WidgetUtils.sliderRow(
              '無音停止時間',
              Slider(
                  value: _pauseFor.toDouble(),
                  min: 5,
                  max: 30,
                  onChanged: (double value) {
                    setState(() {
                      _pauseFor = value.round().toInt();
                    });
                  }
              ),
              '(${_pauseFor.toStringAsFixed(0)}秒)'
          ),
          const SizedBox(height: 20,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 10),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_hasSpeech || _speech.isNotListening) {
                          startListening();
                        }
                      },
                      icon: Icon(Icons.mic, color: _speech.isListening? Colors.greenAccent: Colors.deepPurple ,),
                      label: Text('START', style: TextStyle(color: _speech.isListening? Colors.greenAccent: Colors.deepPurple),),
                    ),
                  )
              ),
              Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(right: 10),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        stopListening();
                      },
                      icon: const Icon(Icons.mic_off),
                      label: const Text('STOP'),
                    ),
                  )
              ),
              Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      cancelListening();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('CANCEL'),
                  )
              ),
            ],
          )

        ],
      ),
    );
  }
}
