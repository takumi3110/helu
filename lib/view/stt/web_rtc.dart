import 'dart:html';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:helu/utils/widget_utils.dart';

class WebRtc extends StatefulWidget {
  const WebRtc({super.key});

  @override
  State<WebRtc> createState() => _WebRtcState();
}

class _WebRtcState extends State<WebRtc> {
  List<MediaDeviceInfo> micList = [];
  List<MediaDeviceInfo> cameraList = [];
  List<MediaDeviceInfo> speakerList = [];
  String? selectedMicId;
  String? selectedCameraId;
  String? selectedSpeakerId;
  var recognition = SpeechRecognition();

  final RTCVideoRenderer _localVideoRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteVideoRenderer = RTCVideoRenderer();

  initRenderer() async {
    await _localVideoRenderer.initialize();
    await _remoteVideoRenderer.initialize();
  }

  _getUserMedia() async{
    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'deviceId': selectedMicId
      },
      'video': {
        'deviceId': selectedCameraId,
        'facingMode': 'user'
      },
    };
    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localVideoRenderer.srcObject = stream;
  }

  Future<void> getDeviceList() async{
    try {
      setState(() {
        micList = [];
        cameraList = [];
        speakerList = [];
      });
      await navigator.mediaDevices.getUserMedia({'audio': true, 'video': true});
      var devices = await navigator.mediaDevices.enumerateDevices();
      devices.sort((a, b) => a.deviceId.length.compareTo(b.deviceId.length));
      for (var device in devices) {
        if (device.kind == 'audioinput') {
          var id = device.deviceId;
          if (id != "") {
            setState(() {
              micList.add(device);
            });
          }
        } else if (device.kind == 'videoinput') {
          var id = device.deviceId;
          if (id != '') {
            setState(() {
              cameraList.add(device);
            });
          }
        } else if (device.kind == 'audiooutput') {
          var id = device.deviceId;
          if (id != '') {
            setState(() {
              speakerList.add(device);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('get devices error: $e');
    }
  }

  void stopStream(MediaStream stream ) {
    var tracks = stream.getTracks();
    if (tracks.isNotEmpty) {
      debugPrint('no tracks');
      return;
    }
    for (var track in tracks) {
      track.stop();
    }
    recognition.stop();
    _localVideoRenderer.srcObject = null;
  }

  @override
  void initState() {
    initRenderer();
    super.initState();
  }

  @override
  void dispose() async{
    await _localVideoRenderer.dispose();
    super.dispose();
  }

  SizedBox videoRenderers() {
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Flexible(
              child: Container(
                key: const Key('local'),
                margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                decoration: const BoxDecoration(color: Colors.blue),
                child: RTCVideoView(_localVideoRenderer),
              )
          ),
          Flexible(
              child: Container(
                key: const Key('remote'),
                margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                decoration: const BoxDecoration(color: Colors.blue),
                child: RTCVideoView(_remoteVideoRenderer),
              )
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WidgetUtils.createAppBar('RTC'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: ElevatedButton(
                    onPressed: () {
                      getDeviceList();
                    },
                    child: const Text('get device')
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      // width: 500,
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
                    ),
                  ),
                  Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          alignment: Alignment.centerLeft,
                          // width: 500,
                          child: DropdownButtonFormField<String>(
                            icon: const Icon(Icons.arrow_drop_down),
                            iconSize: 24,
                            elevation: 16,
                            style: const TextStyle(color: Colors.deepPurple),
                            decoration: const InputDecoration(
                                labelText: 'カメラ選択',
                                prefixIcon: Icon(Icons.video_camera_front)
                            ),
                            // value: micList[0].label,
                            onChanged: (String? value) {
                              setState(() {
                                selectedCameraId = value!;
                              });
                            },
                            items: cameraList.map<DropdownMenuItem<String>>((device) => DropdownMenuItem<String>(
                              value: device.deviceId,
                              child: Text(device.label),
                            )).toList(),
                          ),
                        )
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      // width: 500,
                      child: DropdownButtonFormField<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: 24,
                        elevation: 16,
                        style: const TextStyle(color: Colors.deepPurple),
                        decoration: const InputDecoration(
                            labelText: 'スピーカー選択',
                            prefixIcon: Icon(Icons.mic)
                        ),
                        // value: micList[0].label,
                        onChanged: (String? value) {
                          _localVideoRenderer.audioOutput(value!);
                          setState(() {
                            selectedSpeakerId = value;
                          });
                        },
                        items: speakerList.map<DropdownMenuItem<String>>((device) => DropdownMenuItem<String>(
                          value: device.deviceId,
                          child: Text(device.label),
                        )).toList(),
                      ),
                    ),
                  ),

                  // if (micList.isEmpty)
                  // ElevatedButton(onPressed: () {getDeviceList();}, child: Text('get device'))
                ],
              ),
              const SizedBox(height: 30,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(onPressed: () {_getUserMedia();}, child: const Text('start')),
                  ElevatedButton(onPressed: () {
                    stopStream(_localVideoRenderer.srcObject!);
                  }, child: const Text('stop')),
                ],
              ),
              const SizedBox(height: 30,),
              Flexible(
                  child: Container(
                    key: const Key('local'),
                    margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    decoration: const BoxDecoration(color: Colors.blue),
                    child: RTCVideoView(_localVideoRenderer),
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
