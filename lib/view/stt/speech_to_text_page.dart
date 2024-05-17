import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:helu/utils/function_utils.dart';
import 'package:helu/utils/widget_utils.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_web.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:translator/translator.dart';

class SpeechToTextPage extends StatefulWidget {
  const SpeechToTextPage({super.key});

  @override
  State<SpeechToTextPage> createState() => _SpeechToTextPageState();
}

class _SpeechToTextPageState extends State<SpeechToTextPage> {
  TextEditingController wordController = TextEditingController();
  TextEditingController translatedController = TextEditingController();

  bool isStarted = false;

  /// tts
  TextToSpeech tts = TextToSpeech();
  String? language;
  String? languageCode;
  List<String> languages = [];
  List<String> languageCodes = [];
  String? voice;
  final String defaultLanguage = 'en-US';
  bool isTtsStart = false;

  /// sttの設定値たち
  final SpeechToText _speech = SpeechToText();
  final bool _isLogEvents = false;
  final bool _onDevice = false;
  bool _hasSpeech = false;
  double level = 0.0;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  String _currentLocaleId = '';
  String _defaultLocaleId = 'ja-JP';
  List<MediaDeviceInfo> micList = [];
  String selectedMicId = '';
  MediaStream? localStream;
  // List<LocaleName> _localeNames = [];
  // double minSoundLevel = 50000;
  // double maxSoundLevel = -50000;
  // final int _listenFor = 1;
  // int _pauseFor = 5;

  /// initialize
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
        // _localeNames = await _speech.locales();
        var systemLocale = await _speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? _defaultLocaleId;
        // マイクの許可ほしいから一瞬だけlistenさせる
        // _speech.listen(
        //   listenFor: const Duration(milliseconds: 1)
        // );
        navigator.mediaDevices.getUserMedia({'audio': true});
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

  /// 喋った結果
  void resultListener(SpeechRecognitionResult result) {
    // FunctionUtils.logEvent(
    //     'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    wordController.text = result.recognizedWords;
  }

  // void soundLevelListener(double level) {
  //   minSoundLevel = min(minSoundLevel, level);
  //   maxSoundLevel = max(maxSoundLevel, level);
  //   // FunctionUtils.logEvent('sound level $level: $minSoundLevel - $maxSoundLevel ');
  //   setState(() {
  //     this.level = level;
  //   });
  // }

  /// error結果表示
  void errorListener(SpeechRecognitionError error) {
    FunctionUtils.logEvent(
        'Received error status: $error, listening: ${_speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  /// ステータス表示
  void statusListener(String status) {
    FunctionUtils.logEvent(
        'Received listener status: $status, listening: ${_speech.isListening}');
    setState(() {
      lastStatus = status;
    });
  }

  /// 録音スタート
  void startListening() async{
    FunctionUtils.logEvent('start listening');
    wordController.text = '';
    translatedController.text = '';
    lastError = '';
    // マイク選択
    await getUserAudioMedia();
    // lastWords = '';
    // final pauseFor = _pauseFor;
    // final listenFor = _listenFor;
    final options = SpeechListenOptions(
        onDevice: _onDevice,
        listenMode: ListenMode.confirmation,
        cancelOnError: true,
        partialResults: true,
        autoPunctuation: true,
        enableHapticFeedback: true);
    _speech.listen(
      // 結果
      // onResult: resultListener,
      onResult: (SpeechRecognitionResult result) => wordController.text = result.recognizedWords,
      // 記録する時間
      // listenFor: Duration(minutes: listenFor ?? 3),
      // 単語が検出されない状態の音声の一時停止の最大時間
      // 5分音が取れなければストップ
      pauseFor: const Duration(minutes: 5),
      localeId: _currentLocaleId,
      // onSoundLevelChange: soundLevelListener,
      listenOptions: options,
    );
    // setState(() {});
  }

  /// stop
  void stopListening() {
    if (_speech.isListening) {
      FunctionUtils.logEvent('stop listening');
      _speech.stop();
      if (wordController.text.isNotEmpty) {
        createTranslator();
      }
      setState(() {
        level = 0.0;
      });
    }
  }

  /// cancel
  void cancelListening() {
    if (_speech.isListening) {
      FunctionUtils.logEvent('cancel listening');
      _speech.cancel();
      setState(() {
        level = 0.0;
      });
    }
  }

  /// デバイスを取得
  Future<void> getDeviceList() async{
    try {
      setState(() {
        micList = [];
      });
      var devices = await navigator.mediaDevices.enumerateDevices();
      for (var device in devices) {
        if (device.kind == 'audioinput') {
          var id = device.deviceId;
          if (id != "") {
            setState(() {
              micList.add(device);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('get devices error: $e');
    }
  }

  //使用するデバイスを取得できる
  Future<void> getUserAudioMedia() async {
    try {
      final Map<String, dynamic> constraints = {
        'audio': {
          'deviceId': selectedMicId
        }
      };
      final MediaStream stream = await navigator.mediaDevices.getUserMedia(constraints);
      setState(() {
        localStream = stream;
      });
    } catch (e) {
      debugPrint('get user audio media error: $e');
    }
  }

  // 翻訳機能
  Future<void> createTranslator() async {
    final translator = GoogleTranslator();
    final translation = await translator.translate(wordController.text);
    translatedController.text = translation.text;
  }

  /// tts
  Future<void> initLanguages() async {
    /// languageコードを入力。（ex. en-US）
    languageCodes = await tts.getLanguages();

    /// 表示言語を入力。(ex. English)
    final List<String>? displayLanguages = await tts.getDisplayLanguages();
    if (displayLanguages == null) return;

    /// languagesの設定
    // languagesを初期化して、表示言語を追加
    languages.clear();
    for (final dynamic lang in displayLanguages) {
      languages.add(lang as String);
    }

    /// languageの設定
    final String? defaultLangCode = await tts.getDefaultLanguage();
    // defaultLangCodeがnullじゃなくてlanguageCodesにdefaultLangCodeがある時
    if (defaultLangCode != null && languageCodes.contains(defaultLangCode)) {
      languageCode = defaultLangCode;
    } else {
      // そうじゃない時は定義してあるdefaultLanguageに設定
      languageCode = defaultLanguage;
    }
    language = await tts.getDisplayLanguageByCode(languageCode!);

    voice = await getVoiceByLang(languageCode!);

    if (mounted) {
      setState(() {});
    }
  }


  Future<String?> getVoiceByLang(String lang) async {
    final List<String>? voices = await tts.getVoiceByLang(languageCode!);
    if (voices != null && voices.isNotEmpty) {
      return voices.first;
    }
    return null;
  }

  // 翻訳した結果を読み上げ
  void speak() {
    if (languageCode != null) {
      tts.setLanguage(languageCode!);
    }
    tts.speak(translatedController.text);
    setState(() {
      isTtsStart = true;
    });
  }

  @override
  void initState() {
    super.initState();
    initSpeechState();
    initLanguages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WidgetUtils.createAppBar('Speech To Text'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(10)
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_currentLocaleId == 'ja-JP' ? '日本語': _currentLocaleId, style: TextStyle(color: Colors.grey),),
                              InkWell(
                                  borderRadius: BorderRadius.circular(50),
                                onTap: () {
                                    wordController.text = '';
                                    translatedController.text = '';
                                },
                                  child: const Icon(Icons.close, color: Colors.grey,)
                              ),
                            ],
                          ),
                          TextField(
                            controller: wordController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.compare_arrows),
                  ),
                  Expanded(
                    child: Container(
                      height: 200,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(10)
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('英語', style: TextStyle(color: Colors.grey),),
                              InkWell(
                                borderRadius: BorderRadius.circular(50),
                                  onTap: () {
                                    translatedController.text = '';
                                  },
                                  child: const Icon(Icons.close, color: Colors.grey,)
                              ),
                            ],
                          ),
                          TextField(
                            controller: translatedController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            textAlign: TextAlign.start,
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: InkWell(
                                onTap: () {
                                  if (isTtsStart == false) {
                                    speak();
                                  } else {
                                    tts.stop();
                                    setState(() {
                                      isTtsStart = false;
                                    });
                                  }
                                },
                                  child: Icon(
                                    isTtsStart ? Icons.stop_circle_outlined: Icons.play_circle_outline,
                                    color: Colors.grey,
                                    size: 30,
                                  )
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      width: 500,
                      child: DropdownButtonFormField<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        style: const TextStyle(color: Colors.deepPurple),
                        decoration: const InputDecoration(
                          labelText: 'マイク選択',
                          prefixIcon: Icon(Icons.mic)
                        ),
                        // value: micList[0].label,
                        onChanged: (String? value) {
                          setState(() {
                            selectedMicId = value!;
                          });
                        },
                        items: micList.map<DropdownMenuItem<String>>((device) => DropdownMenuItem<String>(
                          value: device.deviceId,
                          child: Text(device.label),
                        )).toList(),
                      ),
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: ElevatedButton(
                        onPressed: () {
                          getDeviceList();
                        },
                        child: const Text('get device')
                    ),
                  ),
                  // if (micList.isEmpty)
                  // ElevatedButton(onPressed: () {getDeviceList();}, child: Text('get device'))
                ],
              ),
              const SizedBox(height: 20,),
              if (selectedMicId.isNotEmpty)
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
        ),
      ),

    );
  }
}
