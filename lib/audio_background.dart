import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:rxdart/rxdart.dart';


///TODO : lire et comprendre ça  :https://itnext.io/create-an-awesome-background-running-music-player-like-amazon-music-in-flutter-341a59efa936
///


class ScreenState {
  final List<MediaItem> queue;
  final MediaItem mediaItem;
  final PlaybackState playbackState;

  ScreenState(this.queue, this.mediaItem, this.playbackState);
}



// NOTE: Your entrypoint MUST be a top-level function.
void _textToSpeechTaskEntrypoint() async {
  AudioServiceBackground.run(() => TextPlayerTask());
}

/// This task defines logic for speaking a sequence of numbers using
/// text-to-speech.
class TextPlayerTask extends BackgroundAudioTask {
  FlutterTts _tts = FlutterTts();
  bool _finished = false;

  Completer _completer = Completer();

  bool get _playing => AudioServiceBackground.state.playing;

  //Initialize audio task

  Future<void> onStart(Map<String, dynamic> params) async {


  }
}


