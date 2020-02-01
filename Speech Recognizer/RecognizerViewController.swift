//
//  RecognizerViewController.swift
//  Speech Recognizer
//
//  Created by Carmel Braga on 1/31/20.
//  Copyright © 2020 Carmel Braga. All rights reserved.
//

import UIKit
import Speech

class RecognizerViewController: UIViewController, SFSpeechRecognizerDelegate {

    @IBOutlet weak var microphone: UIButton!
    
    private let recognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    @IBOutlet weak var speechTextView: UITextView!
    
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let engine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        speechTextView.text = "Talk to me!"
        
        microphone.isEnabled = false
           
        recognizer!.delegate = self
           
           SFSpeechRecognizer.requestAuthorization { (authStatus) in  
               
               var isButtonEnabled = false
               
               switch authStatus {
               case .authorized:
                   isButtonEnabled = true
                   
               case .denied:
                   isButtonEnabled = false
                   print("Access denied.")
                   
               case .restricted:
                   isButtonEnabled = false
                   print("Access restricted.")
                   
               case .notDetermined:
                   isButtonEnabled = false
                   print("Access not authorized.")
               @unknown default:
                fatalError()
            }
               
               OperationQueue.main.addOperation() {
                   self.microphone.isEnabled = isButtonEnabled
               }
           }

        // Do any additional setup after loading the view.
    }
    
    @IBAction func micOn(_ sender: Any) {
        if engine.isRunning {
               engine.stop()
               request?.endAudio()
               microphone.isEnabled = false
               microphone.setTitle("Transcribe", for: .normal)
           } else {
               record()
               microphone.setTitle("Stop", for: .normal)
           }
    }
    
    func record() {
        
        if task != nil {
            task?.cancel()
            task = nil
        }
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.record)
            try session.setMode(AVAudioSession.Mode.measurement)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Property error.")
        }
        
        request = SFSpeechAudioBufferRecognitionRequest()
        
        let input = engine.inputNode
        
        guard let request = request else {
            fatalError("Unable to create request.")
        }
        
        request.shouldReportPartialResults = true
        
        task = recognizer?.recognitionTask(with: request, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.speechTextView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.engine.stop()
                input.removeTap(onBus: 0)
                
                self.request = nil
                self.task = nil
                
                self.microphone.isEnabled = true
            }
        })
        
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, when) in
            self.request?.append(buffer)
        }
        
        engine.prepare()
        
        do {
            try engine.start()
        } catch {
            print("Engine error.")
        }
        
        speechTextView.text = "Talk to me!"
        
    }
    
    func speechRecognizer(_ recognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphone.isEnabled = true
        } else {
            microphone.isEnabled = false
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
