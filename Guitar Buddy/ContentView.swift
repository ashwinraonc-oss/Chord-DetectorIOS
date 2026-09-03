//
//  ContentView.swift
//  Guitar Buddy
//
//  Created by Ashwin Rao on 8/31/26.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var recorder = AudioController()
    
    
    var body: some View {
        ZStack {
            // 1. Yellow background (bottom)
            Color(red: 255/255, green: 199/255, blue: 55/255)
                .ignoresSafeArea()
            
            // 2. Decorative circles (middle)
            ZStack {
                // Top circles
                HStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 300, height: 300)
                        .offset(x: 20, y: -370)
                    Spacer()
                    Circle()
                        .fill(Color.black)
                        .frame(width: 300, height: 300)
                        .offset(x: -20, y: -370)
                }
                
                // Side circles
                HStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 300, height: 300)
                        .offset(x: -170, y: 0)
                    Spacer()
                    Circle()
                        .fill(Color.black)
                        .frame(width: 300, height: 300)
                        .offset(x: 170, y: 0)
                }
            }
            
            // 3. Content (top)
            VStack {
                Text("Chord Detector")
                    .font(.system(size:40))
                    .foregroundStyle(Color(red:128/255,green:0/255,blue:0/255))
                    .bold()
                    .offset(y: 30)
                    .background(alignment: .bottom) {
                        Rectangle()
                            .fill(Color(red:92/255,green:67/255,blue:33/255))
                            .frame(width: 122, height: 200)
                            .offset(x:0, y:226)
                    }
                
                if let chord = recorder.detectedChord {
                    VStack {
                        Text("You played:")
                        Text(chord)
                            .foregroundStyle(Color(red:101/255,green:67/255,blue:33/255))
                    }
                    .font(.system(size: 33))
                    .bold()
                    .offset(y: 50)
                }
                if recorder.failedConnection == true {
                    Text("Connection Failed")
                        .font(.system(size: 20))
                        .foregroundStyle(.red)
                        .bold()
                        .offset(y: 50)
                }
                
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black)
                        .frame(width: 350, height: 60)
                        .offset(x:0, y: 60)
                    HStack { // Small Circles at the bottom
                        Circle()
                            .fill(Color.green)
                            .frame(width: 30, height: 30)
                            .offset(x: -25, y: 60)
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 30, height: 30)
                            .offset(x: -15, y: 60)
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 30, height: 30)
                            .offset(x: -5, y: 60)
                        Circle()
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                            .offset(x: 5, y: 60)
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 30, height: 30)
                            .offset(x: 15, y: 60)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                            .offset(x: 25, y: 60)
                    }
                }
                .offset(y: -10)
                
                Button { //Recording Button
                    if recorder.isRecording {
                        recorder.stopRecording()
                    } else {
                        recorder.startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color(red: 255/255, green: 250/255, blue: 241/255), lineWidth: 4)
                            .frame(width: 80, height: 80)

                        RoundedRectangle(cornerRadius: recorder.isRecording ? 8 : 40)
                            .fill(Color(red: 235/255, green: 55/255, blue: 34/255))
                            .frame(
                                width: recorder.isRecording ? 35 : 70,
                                height: recorder.isRecording ? 35 : 70
                            )
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: recorder.isRecording)
                .scaleEffect(3.0)
                .offset(x: 0, y: -350)
            }
            .frame(maxWidth: .infinity)
            
            // Border overlay
            Rectangle()
                .stroke(Color.black, lineWidth: 2)
                .ignoresSafeArea()
        }
    }
}
        

#Preview {
    ContentView()
}
