//
//  AudioRecorder.swift
//  Guitar Buddy
//
//  Created by Ashwin Rao on 8/31/26.
//

import AVFoundation
import Combine

struct DetectionResult: Codable {
    let chord: String
    let score: Double
    let notes: [Int]
    let note_names: [String]
    let root: Int?
    let voicing: [[Int]]
}

class AudioController: NSObject, ObservableObject, AVAudioRecorderDelegate {
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder?
    @Published var detectedChord: String?
    @Published var voicings: [[Int]]?
    @Published var isRecording = false
    @Published var failedConnection = false
    
    override init(){
        super.init()
//        guard !ProcessInfo.processInfo.environment.keys.contains("XCODE_RUNNING_FOR_PREVIEWS") else { return }
        recordingSession = AVAudioSession.sharedInstance()
        
        do{
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            AVAudioApplication.requestRecordPermission{[weak self] hasPermission in
                DispatchQueue.main.async{
                    if hasPermission{
                        print("ACCEPTED")
                    } else {
                        print("DENIED")
                    }
                }
                
            }
        } catch {
            print("Failed to set up recording session: \(error)")
        }
    }
    
    func getDirectory() -> URL{
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = path[0]
        return documentDirectory
    }
    
    func startRecording(){
        let filename = getDirectory().appendingPathComponent("recording.wav")
        let audioSettings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM,
                                          AVSampleRateKey: 44100.0,
                                    AVNumberOfChannelsKey: 1,
                                   AVLinearPCMBitDepthKey: 16]
        do {
            audioRecorder = try AVAudioRecorder(url: filename, settings: audioSettings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
        } catch {
            print("Failed to start recording: \(error)")
        }
        
    }
    
    func stopRecording(){
        audioRecorder?.stop()
        audioRecorder = nil
        uploadRecording()
        isRecording = false
        let url = getDirectory().appendingPathComponent("recording.wav")
           print("File exists: \(FileManager.default.fileExists(atPath: url.path))")
           print("File size: \(try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) bytes")
    }
    
    func uploadRecording(){
        let filename = getDirectory().appendingPathComponent("recording.wav")
        guard let backendURL = URL(string: "http://127.0.0.1:8000/detect") else{return}
        do{
            let fileData = try Data(contentsOf: filename)
            let boundary = UUID().uuidString
            var request = URLRequest(url: backendURL)
            request.timeoutInterval = 60
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"recording.wav\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = body
            
            URLSession.shared.dataTask(with: request) {data, response, error in
                guard let data = data, error == nil else{
                    DispatchQueue.main.async{
                        self.failedConnection = true
                    }
                    print("request failed: \(error?.localizedDescription ?? "unknown")")
                    return
                }
                if let result = try? JSONDecoder().decode(DetectionResult.self, from: data){
                    print(result.chord)
                    DispatchQueue.main.async{
                        self.detectedChord = result.chord
                        self.voicings = result.voicing
                    }
                }
            }.resume()
        
            
            
            
        }catch{
            print("error uploading audio")
        }
    }
}



