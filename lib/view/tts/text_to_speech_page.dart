import 'package:helu/utils/widget_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:text_to_speech/text_to_speech.dart';

class TextToSpeechPage extends StatefulWidget {
  const TextToSpeechPage({super.key});

  @override
  State<TextToSpeechPage> createState() => _TextToSpeechPageState();
}

class _TextToSpeechPageState extends State<TextToSpeechPage> {
  TextEditingController textController = TextEditingController();

  final String defaultLanguage = 'ja-JP';

  TextToSpeech tts = TextToSpeech();

  String text = '';
  double volume = 1;
  double rate = 1.0;
  double pitch = 1.0;

  String? language;
  String? languageCode;
  List<String> languages = [];
  List<String> languageCodes = [];
  String? voice;

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

  @override
  void initState() {
    textController.text = text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initLanguages();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WidgetUtils.createAppBar('Text To Speech'),
      body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
              child: Center(
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: textController,
                      maxLines: 5,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'なんか文章入れて'),
                      onChanged: (String value) {
                        setState(() {
                          text = value;
                        });
                      },
                    ),
                    WidgetUtils.sliderRow(
                        'Volume',
                        Slider(
                          value: volume,
                          min: 0,
                          max: 1,
                          label: volume.round().toString(),
                          onChanged: (double value) {
                            initLanguages();
                            setState(() {
                              volume = value;
                            });
                          },
                        ),
                        '(${volume.toStringAsFixed(2)})'),
                    // TODO;
                    WidgetUtils.sliderRow(
                        'Rate',
                        Slider(
                          value: rate,
                          min: 0,
                          max: 2,
                          label: rate.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              rate = value;
                            });
                          },
                        ),
                        '(${rate.toStringAsFixed(2)})'),
                    WidgetUtils.sliderRow(
                        'Pitch',
                        Slider(
                            value: pitch,
                            min: 0,
                            max: 2,
                            onChanged: (double value) {
                              setState(() {
                                pitch = value;
                              });
                            }),
                        '(${pitch.toStringAsFixed(2)})'
                    ),
                    Row(
                      children: <Widget>[
                        const Text('Languages'),
                        const SizedBox(
                          width: 20,
                        ),
                        DropdownButton<String>(
                          value: language,
                          icon: const Icon(Icons.arrow_downward),
                          iconSize: 24,
                          elevation: 16,
                          style: const TextStyle(color: Colors.deepPurple),
                          underline: Container(
                              height: 2,
                              color: Colors.deepPurpleAccent
                          ),
                          onChanged: (String? newValue) async{
                            languageCode = await tts.getLanguageCodeByName(newValue!);
                            voice = await getVoiceByLang(languageCode!);
                            setState(() {
                              language = newValue;
                            });
                          },
                          items: languages.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                        )
                      ],
                    ),
                    const SizedBox(height: 20,),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          const Text('Voice'),
                          const SizedBox(width: 20,),
                          Text(voice ?? '-')
                        ]
                    ),
                    const SizedBox(height: 20,),
                    Row(
                      children: <Widget>[
                        Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(right: 10),
                              child: ElevatedButton(
                                child: const Text('Speak'),
                                onPressed: () {
                                  speak();
                                },
                              ),
                            )
                        ),
                        Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(right: 10),
                              child: ElevatedButton(
                                  child: const Text('STOP'),
                                  onPressed: () {
                                    tts.stop();
                                  }
                              ),
                            )
                        ),
                        if (supportPause)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(right: 10),
                              child: ElevatedButton(
                                child: const Text('Pause'),
                                onPressed: () {
                                  tts.pause();
                                },
                              ),
                            ),
                          ),
                        Expanded(
                            child: ElevatedButton(
                              child: const Text('Reset'),
                              onPressed: () {
                                setState(() {
                                  textController.text = '';
                                  text = '';
                                });
                              },
                            )
                        )

                        // if (supportResume)
                        //   Expanded(
                        //       child: Container(
                        //         padding: const EdgeInsets.only(right: 10),
                        //         child: ElevatedButton(
                        //           child: const Text('Resume'),
                        //           onPressed: () {
                        //             tts.resume();
                        //           },
                        //         ),
                        //       )
                        //   ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )),
    );
  }

  bool get supportPause => defaultTargetPlatform != TargetPlatform.android;
  bool get supportResume => defaultTargetPlatform != TargetPlatform.android;

  void speak() {
    tts.setVolume(volume);
    tts.setRate(rate);
    if (languageCode != null) {
      tts.setLanguage(languageCode!);
    }
    tts.setPitch(pitch);
    tts.speak(text);
  }
}

