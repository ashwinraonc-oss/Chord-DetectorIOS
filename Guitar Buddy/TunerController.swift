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
    nonisolated private func processBuffer(_ buffer: AVAudioPCMBuffer){
        guard let channelData = buffer.floatChannelData else {return}
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(frameLength))
        guard rms > 0.02 else {
            DispatchQueue.main.async {
                self.detectedNote = "--"
                self.centsOff = 0
            }
            return
        }
        
        let realSize = 4096
        let fftSize = 8192
        let fftSamples = Array(samples.prefix(realSize))

        var window = [Float](repeating: 0, count: realSize)
        vDSP_hann_window(&window, vDSP_Length(realSize), Int32(vDSP_HANN_NORM))
        var windowedSamples = [Float](repeating: 0, count: realSize)
        vDSP_vmul(fftSamples, 1, window, 1, &windowedSamples, 1, vDSP_Length(realSize))
        windowedSamples += [Float](repeating: 0, count: fftSize - realSize)

        let halfLength = fftSize / 2
        var realParts = [Float](repeating: 0, count: halfLength)
        var imagParts = [Float](repeating: 0, count: halfLength)
        let log2n = vDSP_Length(13)

        guard let setup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return }
        defer { vDSP_destroy_fftsetup(setup) }

        realParts.withUnsafeMutableBufferPointer { realPtr in
            imagParts.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                windowedSamples.withUnsafeBytes { samplesPtr in
                    let typePtr = samplesPtr.bindMemory(to: DSPComplex.self)
                    vDSP_ctoz(typePtr.baseAddress!, 2, &splitComplex, 1, vDSP_Length(halfLength))
                }
                vDSP_fft_zrip(setup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
            }
        }

        var magnitudes = [Float](repeating: 0, count: halfLength)
        vDSP.squareMagnitudes(DSPSplitComplex(realp: &realParts, imagp: &imagParts), result: &magnitudes)
        magnitudes[0] = 0

        let (rawPeakIndex, _) = vDSP.indexOfMaximum(magnitudes)
        let peakIndex = Int(rawPeakIndex)

        let sampleRate = Float(buffer.format.sampleRate)
        let interpolatedOffset: Float
        if peakIndex > 0 && peakIndex < halfLength - 1 {
            let prev = magnitudes[peakIndex - 1]
            let curr = magnitudes[peakIndex]
            let next = magnitudes[peakIndex + 1]
            let denom = prev - 2 * curr + next
            interpolatedOffset = denom != 0 ? 0.5 * (prev - next) / denom : 0
        } else {
            interpolatedOffset = 0
        }
        let frequency = (Float(peakIndex) + interpolatedOffset) * sampleRate / Float(fftSize)
        let note = frequencyToNote(frequency)
        let centsOff = frequencyToCents(frequency)
        print("SR: \(buffer.format.sampleRate), frames: \(frameLength), peakIndex: \(peakIndex), freq: \(frequency)")
        
        DispatchQueue.main.async {
            if note == self.pendingNote {
                self.consecutiveCount += 1
            } else {
                self.pendingNote = note
                self.consecutiveCount = 1
            }
            if self.consecutiveCount >= 3 {
                self.detectedNote = note
                self.detectedFrequency = frequency
            }
            self.centsOff = self.centsOff * 0.8 + centsOff * 0.2
        }
        
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
