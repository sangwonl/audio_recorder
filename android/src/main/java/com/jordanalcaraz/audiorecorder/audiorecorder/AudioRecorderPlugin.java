package com.jordanalcaraz.audiorecorder.audiorecorder;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.media.MediaRecorder;
import android.util.Log;

import java.io.IOException;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * AudioRecorderPlugin
 */
public class AudioRecorderPlugin implements MethodCallHandler {
  private final Registrar registrar;
  private boolean isRecording = false;
  private static final String LOG_TAG = "AudioRecorder";
  private MediaRecorder mRecorder = null;
  private static String mFilePath = null;
  private Date startTime = null;
  private String mEncoderFormat = null;
  private Integer mOutputFormat = null;
  private Integer mEncoderType = null;
  private int mSampleRate = 0;
  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "audio_recorder");
    channel.setMethodCallHandler(new AudioRecorderPlugin(registrar));
  }

  private AudioRecorderPlugin(Registrar registrar){
    this.registrar = registrar;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    switch (call.method) {
      case "start":
        Log.d(LOG_TAG, "Start");
        mEncoderFormat = call.argument("encoderFormat");
        mEncoderType = getAudioEncoderFromString(mEncoderFormat);
        mOutputFormat = getOutputFormatFromString(mEncoderFormat);
        if (mEncoderFormat == null || mOutputFormat == null) {
          result.error("Not supported encoder format", null, null);
          break;
        }

        mSampleRate = call.argument("sampleRate");
        mFilePath = call.argument("path");
        Log.d(LOG_TAG, mFilePath);

        startTime = Calendar.getInstance().getTime();
        startRecording();
        isRecording = true;
        result.success(null);
        break;
      case "stop":
        Log.d(LOG_TAG, "Stop");
        stopRecording();
        long duration = Calendar.getInstance().getTime().getTime() - startTime.getTime();
        Log.d(LOG_TAG, "Duration : " + String.valueOf(duration));
        isRecording = false;
        HashMap<String, Object> recordingResult = new HashMap<>();
        recordingResult.put("duration", duration);
        recordingResult.put("path", mFilePath);
        recordingResult.put("audioEncoderFormat", mEncoderFormat);
        result.success(recordingResult);
        break;
      case "isRecording":
        Log.d(LOG_TAG, "Get isRecording");
        result.success(isRecording);
        break;
      case "hasPermissions":
        Log.d(LOG_TAG, "Get hasPermissions");
        Context context = registrar.context();
        PackageManager pm = context.getPackageManager();
        int hasStoragePerm = pm.checkPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE, context.getPackageName());
        int hasRecordPerm = pm.checkPermission(Manifest.permission.RECORD_AUDIO, context.getPackageName());
        boolean hasPermissions = hasStoragePerm == PackageManager.PERMISSION_GRANTED && hasRecordPerm == PackageManager.PERMISSION_GRANTED;
        result.success(hasPermissions);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private void startRecording() {
    mRecorder = new MediaRecorder();
    mRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
    mRecorder.setOutputFormat(mOutputFormat);
    mRecorder.setOutputFile(mFilePath);
    mRecorder.setAudioEncoder(mEncoderType);
    mRecorder.setAudioSamplingRate(mSampleRate);

    try {
      mRecorder.prepare();
    } catch (IOException e) {
      Log.e(LOG_TAG, "prepare() failed");
    }

    mRecorder.start();
  }

  private void stopRecording() {
    if (mRecorder != null){
      mRecorder.stop();
      mRecorder.reset();
      mRecorder.release();
      mRecorder = null;
    }
  }

  private Integer getOutputFormatFromString(String fmt) {
    switch (fmt) {
      case "AAC":
        return MediaRecorder.OutputFormat.MPEG_4;
      case "AMR_WB":
        return MediaRecorder.OutputFormat.AMR_WB;
    }
    return null;
  }

  private Integer getAudioEncoderFromString(String fmt) {
    switch (fmt) {
      case "AAC":
        return MediaRecorder.AudioEncoder.AAC;
      case "AMR_WB":
        return MediaRecorder.AudioEncoder.AMR_WB;
    }
    return null;
  }
}
