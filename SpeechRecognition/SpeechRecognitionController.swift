//
//  SpeechRecognitionController.swift
//  SpeechRecognition
//
//  Created by Man Kin Leung on 7/11/2020.
//

import Foundation
import Speech

public class SpeechRecognitionController: NSObject, ObservableObject, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_HK"))!
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let audioEngine = AVAudioEngine()
    
    @Published var recordButtonEnabled: Bool = true
    @Published var recordButtonText: String = "Start"
    
    @Published var speakButtonEnabled: Bool = true
    @Published var speakButtonText: String = "Speak"
    
    @Published var speechText: String = ""
    @Published var statusText: String = "Please Press Start"
    
    private func startRecording() throws {
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep speech recognition data on device
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
        // Create a recognition task for the speech recognition session.
        // Keep a reference to the task so that it can be canceled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // Update the text view with the results.
                self.speechText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                // Stop recognizing speech if there is a problem.
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.recognitionTask = nil

                self.recordButtonEnabled = true
                self.speakButtonEnabled = true
                self.recordButtonText = "Start"
                self.statusText = "Please Press Start"
            }
        }

        // Configure the microphone input.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Let the user know to start talking.
        self.recordButtonText = "Stop"
        self.statusText = "Listening"
    }
    
    public func getSpeech() {
        if (speechRecognizer.delegate == nil) {
            speechRecognizer.delegate = self
            SFSpeechRecognizer.requestAuthorization { authStatus in
                OperationQueue.main.addOperation {
                    switch authStatus {
                    case .authorized:
                        self.recordButtonEnabled = true
                        self.speakButtonEnabled = true
                        
                    case .denied:
                        self.recordButtonEnabled = false
                        self.speakButtonEnabled = false
                        self.statusText = "User denied access to speech recognition"
                        
                    case .restricted:
                        self.recordButtonEnabled = false
                        self.speakButtonEnabled = false
                        self.statusText = "Speech recognition restricted on this device"
                        
                    case .notDetermined:
                        self.recordButtonEnabled = false
                        self.speakButtonEnabled = false
                        self.statusText = "Speech recognition not yet authorized"
                        
                    default:
                        self.recordButtonEnabled = false
                        self.speakButtonEnabled = false
                    }
                    if (self.recordButtonEnabled) {
                        if self.audioEngine.isRunning {
                            self.audioEngine.stop()
                            self.recognitionRequest?.endAudio()
                            self.speakButtonEnabled = false
                            self.recordButtonText = "Translating"
                            self.statusText = "Translating"
                        } else {
                            self.speakButtonEnabled = false
                            do {
                                try self.startRecording()
                            } catch {
                                self.statusText = "Recording Not Available"
                            }
                        }
                    }
                }
            }
        } else if (self.recordButtonEnabled) {
            if audioEngine.isRunning {
                audioEngine.stop()
                recognitionRequest?.endAudio()
                speakButtonEnabled = false
                recordButtonText = "Translating"
                statusText = "Translating"
            } else {
                speakButtonEnabled = false
                do {
                    try startRecording()
                } catch {
                    statusText = "Recording Not Available"
                }
            }
        }
    }
    
    public func speak() {
        if (speechSynthesizer.delegate == nil) {
            speechSynthesizer.delegate = self
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // handle errors
        }
        let utterance = AVSpeechUtterance(string: self.speechText)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh_HK")
        speechSynthesizer.speak(utterance)
        self.recordButtonEnabled = false
        self.speakButtonEnabled = false
    }
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            self.recordButtonEnabled = true
            self.speakButtonEnabled = true
        } else {
            self.recordButtonEnabled = false
            self.speakButtonEnabled = false
        }
    }
    
    public func speechSynthesizer(_ speechSynthesizer: AVSpeechSynthesizer, didFinish: AVSpeechUtterance) {
        self.recordButtonEnabled = true
        self.speakButtonEnabled = true
    }
}
