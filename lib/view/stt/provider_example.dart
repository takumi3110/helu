import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text_provider.dart';

class ProviderDemoApp extends StatefulWidget {
  const ProviderDemoApp({Key? key}) : super(key: key);

  @override
  State<ProviderDemoApp> createState() => _ProviderDemoAppState();
}

class _ProviderDemoAppState extends State<ProviderDemoApp> {
  final SpeechToText speech = SpeechToText();
  late SpeechToTextProvider speechProvider;

  @override
  void initState() {
    super.initState();
    speechProvider = SpeechToTextProvider(speech);
    initSpeechState();
  }

  Future<void> initSpeechState() async {
    await speechProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SpeechToTextProvider>.value(
      value: speechProvider,
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Speech to Text Provider Example'),
          ),
          body: const SpeechProviderExampleWidget(),
        ),
    );
  }
}

class SpeechProviderExampleWidget extends StatefulWidget {
  const SpeechProviderExampleWidget({Key? key}) : super(key: key);

  @override
  SpeechProviderExampleWidgetState createState() =>
      SpeechProviderExampleWidgetState();
}

class SpeechProviderExampleWidgetState
    extends State<SpeechProviderExampleWidget> {
  String _currentLocaleId = '';

  void _setCurrentLocale(SpeechToTextProvider speechProvider) {
    if (speechProvider.isAvailable && _currentLocaleId.isEmpty) {
      _currentLocaleId = speechProvider.systemLocale?.localeId ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    var speechProvider = Provider.of<SpeechToTextProvider>(context);
    if (speechProvider.isNotAvailable) {
      return const Center(
        child: Text(
            'Speech recognition not available, no permission or not available on the device.'),
      );
    }
    _setCurrentLocale(speechProvider);
    return Column(children: [
      const Center(
        child: Text(
          'Speech recognition available',
          style: TextStyle(fontSize: 22.0),
        ),
      ),
      Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              TextButton(
                onPressed:
                !speechProvider.isAvailable || speechProvider.isListening
                    ? null
                    : () => speechProvider.listen(
                    partialResults: true, localeId: _currentLocaleId),
                child: const Text('Start'),
              ),
              TextButton(
                onPressed: speechProvider.isListening
                    ? () => speechProvider.stop()
                    : null,
                child: const Text('Stop'),
              ),
              TextButton(
                onPressed: speechProvider.isListening
                    ? () => speechProvider.cancel()
                    : null,
                child: const Text('Cancel'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              DropdownButton(
                onChanged: (selectedVal) => _switchLang(selectedVal),
                value: _currentLocaleId,
                items: speechProvider.locales
                    .map(
                      (localeName) => DropdownMenuItem(
                    value: localeName.localeId,
                    child: Text(localeName.name),
                  ),
                )
                    .toList(),
              ),
            ],
          )
        ],
      ),
      const Expanded(
        flex: 4,
        child: RecognitionResultsWidget(),
      ),
      Expanded(
        flex: 1,
        child: Column(
          children: <Widget>[
            const Center(
              child: Text(
                'Error Status',
                style: TextStyle(fontSize: 22.0),
              ),
            ),
            Center(
              child: speechProvider.hasError
                  ? Text(speechProvider.lastError!.errorMsg)
                  : Container(),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        color: Theme.of(context).colorScheme.background,
        child: Center(
          child: speechProvider.isListening
              ? const Text(
            "I'm listening...",
            style: TextStyle(fontWeight: FontWeight.bold),
          )
              : const Text(
            'Not listening',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ]);
  }

  void _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    debugPrint(selectedVal);
  }
}

class RecognitionResultsWidget extends StatelessWidget {
  const RecognitionResultsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var speechProvider = Provider.of<SpeechToTextProvider>(context);
    return Column(
      children: <Widget>[
        const Center(
          child: Text(
            'Recognized Words',
            style: TextStyle(fontSize: 22.0),
          ),
        ),
        Expanded(
          child: Stack(
            children: <Widget>[
              Container(
                color: Theme.of(context).secondaryHeaderColor,
                child: Center(
                  child: Text(
                    speechProvider.lastResult?.recognizedWords ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Positioned.fill(
                bottom: 10,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            blurRadius: .26,
                            spreadRadius: speechProvider.lastLevel * 1.5,
                            color: Colors.black.withOpacity(.05))
                      ],
                      color: Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(50)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}