import 'dart:async';
import 'dart:io';

import 'package:file/local.dart';
import 'package:flutter/services.dart';

enum AudioEncoderFormat {
  AAC,
  AMR_WB,
  LINEAR16
}

class Recording {
  String path;                            // File path
  String extension;                       // File extension
  Duration duration;                      // Audio duration in milliseconds
  AudioEncoderFormat audioEncoderFormat;  // Audio output format

  Recording({this.duration, this.path, this.audioEncoderFormat, this.extension});
}

class AudioRecorder {
  static const MethodChannel _channel = const MethodChannel('audio_recorder');

  /// use [LocalFileSystem] to permit widget testing
  static LocalFileSystem fs = LocalFileSystem();

  static const EncodeFormatToExtensions = {
    AudioEncoderFormat.AAC: ".m4a",
    AudioEncoderFormat.AMR_WB: ".amr",
    AudioEncoderFormat.LINEAR16: ".wav"
  };

  static _enumToString(AudioEncoderFormat fmt) {
    return fmt.toString().split(".")[1];
  }

  static Future start({
      String path,
      AudioEncoderFormat audioEncoderFormat,
      int sampleRate}) async {

      String fullPath = path + EncodeFormatToExtensions[audioEncoderFormat];
      File file = fs.file(fullPath);
      if (await file.exists()) {
        throw new Exception("A file already exists at the path :" + fullPath);
      } else if (!await file.parent.exists()) {
        throw new Exception("The specified parent directory does not exist");
      }

    return _channel
      .invokeMethod('start', {
        "path": fullPath,
        "encoderFormat": _enumToString(audioEncoderFormat),
        "sampleRate": sampleRate
      });
  }

  static Future<Recording> stop() async {
    Map<String, Object> response =
      Map.from(await _channel.invokeMethod('stop'));
    
    String encoderFormat = response['audioEncoderFormat'];
    AudioEncoderFormat fmt = AudioEncoderFormat.values.firstWhere((e) => _enumToString(e) == encoderFormat);
    
    Recording recording = new Recording(
      duration: new Duration(milliseconds: response['duration']),
      path: response['path'],
      audioEncoderFormat: fmt,
      extension: EncodeFormatToExtensions[fmt]
    );
    return recording;
  }

  static Future<bool> get isRecording async {
    bool isRecording = await _channel.invokeMethod('isRecording');
    return isRecording;
  }

  static Future<bool> get hasPermissions async {
    bool hasPermission = await _channel.invokeMethod('hasPermissions');
    return hasPermission;
  }
}

