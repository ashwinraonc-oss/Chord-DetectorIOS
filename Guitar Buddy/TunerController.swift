//
//  Tuner.swift
//  Guitar Buddy
//
//  Created by Ashwin Rao on 9/3/26.
//
import AVFoundation
import SwiftUI
import Accelerate
import Combine

class TunerController: NSObject, ObservableObject{
    private var engine = AVAudioEngine()
    nonisolated (unsafe) private var rollingBuffer: [Float] = []
    @Published var detectedNote: String = "--"
    @Published var detectedFrequency: Float = 0
    @Published var isRunning = false
    @Published var centsOff = Float(0)
    private var consecutiveCount = 0
    private var pendingNote = "--"
    
    func startTuning(){
        let inputNode = engine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        inputNode.installTap(onBus:0, bufferSize: 1024, format: format){buffer, _ in
            self.processBuffer(buffer)
        }
        do {
            try engine.start()
            DispatchQueue.main.async{
                self.isRunning = true
            }
        } catch let error{
            print(error.localizedDescription)
        }
    }
    func stopTuning(){
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        DispatchQueue.main.async{
            self.isRunning = false
        }
    }
    nonisolated private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))

        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(frameLength))
        guard rms > 0.001 else {
            DispatchQueue.main.async {
                self.detectedNote = "--"
                self.centsOff = 0
            }
            return
        }

        rollingBuffer.append(contentsOf: samples)
        if rollingBuffer.count > 4096 {
            rollingBuffer.removeFirst(rollingBuffer.count - 4096)
        }
        guard rollingBuffer.count == 4096 else { return }

        let sampleRate = Float(buffer.format.sampleRate)
        let frequency = yin(rollingBuffer, sampleRate: sampleRate)
        guard frequency > 0 else { return }

        let note = frequencyToNote(frequency)
        let centsOff = frequencyToCents(frequency)

        DispatchQueue.main.async {
            if note == self.pendingNote {
                self.consecutiveCount += 1
            } else {
                self.pendingNote = note
                self.consecutiveCount = 1
            }
            if self.consecutiveCount >= 3 {
                if self.detectedNote != note {
                    self.centsOff = 0
                }
                self.detectedNote = note
                self.detectedFrequency = frequency
            }
            self.centsOff = self.centsOff * 0.5 + centsOff * 0.5
        }
    }

    nonisolated private func yin(_ samples: [Float], sampleRate: Float) -> Float {
        let bufferSize = samples.count
        let minTau = Int(sampleRate / 1000)  // highest detectable frequency ~1000 Hz
        let maxTau = Int(sampleRate / 50)    // lowest detectable frequency ~50 Hz
        guard maxTau < bufferSize / 2 else { return -1 }

        let windowSize = bufferSize - maxTau
        var yinBuffer = [Float](repeating: 0, count: maxTau + 1)

        // Step 1: difference function using vDSP for SIMD speed
        var diff = [Float](repeating: 0, count: windowSize)
        samples.withUnsafeBufferPointer { ptr in
            let base = ptr.baseAddress!
            for tau in 1...maxTau {
                vDSP_vsub(base + tau, 1, base, 1, &diff, 1, vDSP_Length(windowSize))
                var sumSq: Float = 0
                vDSP_svesq(diff, 1, &sumSq, vDSP_Length(windowSize))
                yinBuffer[tau] = sumSq
            }
        }

        // Step 2: cumulative mean normalized difference
        yinBuffer[0] = 1.0
        var runningSum: Float = 0
        for tau in 1...maxTau {
            runningSum += yinBuffer[tau]
            if runningSum > 0 {
                yinBuffer[tau] = yinBuffer[tau] * Float(tau) / runningSum
            }
        }

        // Step 3: find first dip below threshold
        let threshold: Float = 0.12
        var tau = minTau
        while tau < maxTau - 1 {
            if yinBuffer[tau] < threshold {
                while tau + 1 < maxTau && yinBuffer[tau + 1] < yinBuffer[tau] {
                    tau += 1
                }
                break
            }
            tau += 1
        }
        guard tau < maxTau - 1 else { return -1 }

        // Step 4: parabolic interpolation for sub-sample accuracy
        let s0 = yinBuffer[tau - 1]
        let s1 = yinBuffer[tau]
        let s2 = yinBuffer[tau + 1]
        let denom = 2 * (2 * s1 - s2 - s0)
        let adjustment = denom != 0 ? (s2 - s0) / denom : 0
        let betterTau = Float(tau) + adjustment

        return sampleRate / betterTau
    }
    
    nonisolated private func frequencyToNote(_ frequency: Float) -> String {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        if frequency < 50{
            return "--"
        }
        let MIDI = Int(round(12 * log2(frequency / 440)) + 69)
        let note = notes[((MIDI%12)+12)%12]
        
        return note
    }
    nonisolated private func frequencyToCents(_ frequency: Float) -> Float{
        let exactMIDI = 12 * log2(frequency / 440) + 69
        let nearestMIDI = round(exactMIDI)
        let centsOff = (exactMIDI - nearestMIDI) * 100
        
        return centsOff
    }
    
    
}
