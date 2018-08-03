//
//  ViewController.swift
//  Helix_AI
//
//  Created by Emmanuel  Ogbewe on 8/3/18.
//  Copyright © 2018 Emmanuel Ogbewe. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import AudioUnit


class ViewController: UIViewController,SFSpeechRecognizerDelegate,AVSpeechSynthesizerDelegate {
    
    //MARK: IBOutets
    @IBOutlet weak var resultsTextView: UITextView!
    @IBOutlet weak var recordButton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private let audioEngine = AVAudioEngine()
    
    private var speechRequest : SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask : SFSpeechRecognitionTask?
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        try! startRecording()
        recordButton.isEnabled = false
        recordButton.addTarget(self, action: #selector(ViewController.recordButtonTapped), for: .touchUpInside)
        requestAuth()
    }
    func requestAuth(){
        speechRecognizer.delegate = self
        SFSpeechRecognizer.requestAuthorization { (status) in
            OperationQueue.main.addOperation {
                switch status {
                case .authorized:
                    self.recordButton.isEnabled = true
                case .denied:
                    self.recordButton.isEnabled = false
                    print("not denied")
                case .restricted:
                    self.recordButton.isEnabled = false
                    print("not restricted")
                case .notDetermined:
                    self.recordButton.isEnabled = false
                    print("not deteremined")
                }
            }
        }
    }
    func startRecording()throws{
        //This will cancel the previous task if it was running
        if let recognitionTask = recognitionTask{
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeDefault)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        speechRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = speechRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        //Congiure to get results before finishing
        recognitionRequest.shouldReportPartialResults = true
        // We keep a reference to the task so that it can be cancelled.
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.resultsTextView.text = result.bestTranscription.formattedString
                self.viloRespond(text: result.bestTranscription.formattedString.lowercased())
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.speechRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
                self.recordButton.setTitle("Start Recording", for: [])
                
                do {
                    try self.audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                    try self.audioSession.setMode(AVAudioSessionModeDefault)
                    try self.audioSession.setActive(false, with: .notifyOthersOnDeactivation)
                    try self.audioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
                } catch let error as NSError {
                    // handle errors
                    print(error.localizedDescription)
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.speechRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
        
        resultsTextView.text = "(Go ahead, I'm listening)"
        
    }
    
    // MARK: Responses
    public func viloRespond (text: String){
        switch(text){
        case "what is":
            tempAlert(message: "25", quest: "What is 5x5")
        default:
            print("default")
        }
    }
    
    //MARK: Reading Methods
    func startReading(text: String){
        let speechUtterance = AVSpeechUtterance(string: text)
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        speechUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechUtterance.rate = 0.5
        synthesizer.speak(speechUtterance)
    }
    func tempAlert(message: String, quest: String) {
        let alert = UIAlertController(title: quest, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    // MARK: Alerts
    public func createTaskAlert(){
        let alert = UIAlertController(title: "New Task", message: "What would you like me to say", preferredStyle: .alert)
        let helloAction = UIAlertAction(title: "Hello", style: .default, handler: nil)
        let wassupAction = UIAlertAction(title: "Wassup", style: .default, handler: nil)
        let cancelAction = UIAlertAction(title: "Wassup", style: .cancel, handler: nil)
        let arr  : [UIAlertAction] = [helloAction,wassupAction,cancelAction]
        for i in arr{
            alert.addAction(i)
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // MARK: SFSpeechRecognizerDelegate
    
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
            recordButton.setTitle("Start Recording", for: [])
        } else {
            recordButton.isEnabled = false
            recordButton.setTitle("Recognition not available", for: .disabled)
        }
    }
    // MARK: Interface Builder actions
    @objc func recordButtonTapped(){
        if audioEngine.isRunning {
            audioEngine.stop()
            speechRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("Stopping", for: .disabled)
            self.startReading(text: self.resultsTextView.text)
        } else {
            try! startRecording()
            recordButton.setTitle("Stop recording", for: [])
        }
    }
    func SetSessionPlayerOn()
    {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
        } catch _ {
        }
    }
}




