import 'package:flutter/material.dart';
import 'package:flutter_video_cast/flutter_video_cast.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ChromeCastController? _ctrl;
  String? _err;
  AppState _state = AppState.Disconnected;
  final vidLink =
      "https://player.vimeo.com/external/605412753.m3u8?s=b6e3a93a339e449ad7723e4458a54ddeebd309f9";

  late VideoPlayerController _vidCtrl;

  @override
  void initState() {
    _init();
    super.initState();
  }

  _init() async {
    setState(() {
      _state = AppState.Loading;
    });

    try {
      _vidCtrl = VideoPlayerController.network(vidLink);
      await _vidCtrl.initialize();
      _vidCtrl.play();
      setState(() {
        _state = AppState.Disconnected;
      });
    } catch (e) {
      setState(() {
        _state = AppState.Error;
        _err = e.toString();
      });
    }
  }

  final iconSize = 50.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("ChromeCast Mockup")),
        actions: [
          ChromeCastButton(
            onRequestFailed: (err) {
              setState(() {
                _err = err;
                _state = AppState.Error;
              });
            },
            onSessionEnded: () {
              setState(() {
                _err = null;
                _state = AppState.Disconnected;
              });
            },
            onButtonCreated: (ctr) async {
              _ctrl = ctr;
              await _ctrl?.addSessionListener();
            },
            onSessionStarted: () async {
              await _ctrl?.loadMedia(vidLink);
              setState(() {
                _err = null;
                _state = AppState.Casting;
              });
              _vidCtrl.pause();
            },
          ),
          AirPlayButton(
            onRoutesOpening: () => print('opening'),
            onRoutesClosed: () => print('closed'),
          ),
        ],
      ),
      body: Center(
        child: Container(
          child: _state == AppState.Error
              ? Text("$_err")
              : _state == AppState.Loading
                  ? CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: VideoPlayer(_vidCtrl),
                        ),
                        Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.fast_rewind,
                                  size: iconSize,
                                ),
                                onPressed: () async {
                                  if (_state == AppState.Casting) {
                                    await _ctrl?.seek(
                                        relative: true, interval: -10);
                                  } else if (_state == AppState.Disconnected) {
                                    final dur = _vidCtrl.value.duration +
                                        Duration(seconds: -10);
                                    await _vidCtrl.seekTo(dur);
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  _vidCtrl.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  size: iconSize,
                                ),
                                onPressed: () async {
                                  if (_state == AppState.Casting) {
                                    if ((await _ctrl?.isPlaying() ?? false)) {
                                      await _ctrl?.pause();
                                    } else {
                                      await _ctrl?.play();
                                    }
                                  } else if (_state == AppState.Disconnected) {
                                    if (_vidCtrl.value.isPlaying) {
                                      await _vidCtrl.pause();
                                    } else {
                                      await _vidCtrl.play();
                                    }
                                  }
                                  setState(() {});
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.stop,
                                  size: iconSize,
                                ),
                                onPressed: () async {
                                  if (_state == AppState.Casting) {
                                    await _ctrl?.stop();
                                  } else if (_state == AppState.Disconnected) {
                                    await _vidCtrl.pause();
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.fast_forward,
                                  size: iconSize,
                                ),
                                onPressed: () async {
                                  if (_state == AppState.Casting) {
                                    await _ctrl?.seek(
                                        relative: true, interval: 10);
                                  } else if (_state == AppState.Disconnected) {
                                    final dur = _vidCtrl.value.position +
                                        Duration(seconds: 10);
                                    await _vidCtrl.seekTo(dur);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cast,
                                color: _state == AppState.Casting
                                    ? Colors.green
                                    : Colors.grey,
                                size: 100,
                              ),
                              Text(
                                _state == AppState.Casting
                                    ? "Casting is On"
                                    : "Casting is Off \n click the cast button in the appbar to start casting",
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        )
                      ],
                    ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vidCtrl.dispose();

    super.dispose();
  }
}

enum AppState {
  Loading,
  Disconnected,
  Casting,

  Error,
}
