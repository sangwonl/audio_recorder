import Flutter
import UIKit
import AVFoundation

public class SwiftAudioRecorderPlugin: NSObject, FlutterPlugin, AVAudioRecorderDelegate {
    var isRecording = false
    var hasPermissions = false
    var mPath = ""
    var mEncoderFormat = ""
    var mSampleRate = 0
    var startTime: Date!
    var audioRecorder: AVAudioRecorder!

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "audio_recorder", binaryMessenger: registrar.messenger())
        let instance = SwiftAudioRecorderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "start":
                print("start")
                let dic = call.arguments as! [String : Any]
                mPath = dic["path"] as? String ?? ""
                mEncoderFormat = dic["encoderFormat"] as? String ?? ""
                mSampleRate = dic["sampleRate"] as? Int ?? 0
                startTime = Date()
                
                let formatIdKey = getOutputFormatFromString(mEncoderFormat)
                if formatIdKey == 0 {
                    result(FlutterError(code: "", message: "Not supported encoder format", details: nil))
                }

                let settings = [
                    AVFormatIDKey: formatIdKey,
                    AVSampleRateKey: mSampleRate,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
                
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
                    try AVAudioSession.sharedInstance().setActive(true)

                    audioRecorder = try AVAudioRecorder(url: URL(string: mPath)!, settings: settings)
                    audioRecorder.delegate = self
                    audioRecorder.record()
                } catch {
                    print("fail")
                    result(FlutterError(code: "", message: "Failed to record", details: nil))
                }
                isRecording = true
                result(nil)
            case "stop":
                print("stop")
                audioRecorder.stop()
                audioRecorder = nil
                let duration = Int(Date().timeIntervalSince(startTime as Date) * 1000)
                isRecording = false
                var recordingResult = [String : Any]()
                recordingResult["duration"] = duration
                recordingResult["path"] = mPath
                recordingResult["audioEncoderFormat"] = mEncoderFormat
                result(recordingResult)
            case "isRecording":
                print("isRecording")
                result(isRecording)
            case "hasPermissions":
                print("hasPermissions")
                switch AVAudioSession.sharedInstance().recordPermission() {
                case AVAudioSessionRecordPermission.granted:
                    NSLog("granted")
                    hasPermissions = true
                    break
                case AVAudioSessionRecordPermission.denied:
                    NSLog("denied")
                    hasPermissions = false
                    break
                case AVAudioSessionRecordPermission.undetermined:
                    NSLog("undetermined")
                    AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
                        DispatchQueue.main.async {
                            if allowed {
                                self.hasPermissions = true
                            } else {
                                self.hasPermissions = false
                            }
                        }
                    }
                    break
                default:
                    break
                }
                result(hasPermissions)
            default:
                result(FlutterMethodNotImplemented)
        }
    }

    func getOutputFormatFromString(_ format : String) -> Int {
        switch format {
        case "AAC":
            return Int(kAudioFormatMPEG4AAC)
        case "LINEAR16":
            return Int(kAudioFormatLinearPCM)
        default:
            return 0
        }
    }
}

