//
//  TunerView.swift
//  Guitar Buddy
//
//  Created by Ashwin Rao on 9/4/26.
//

import AVFoundation
import SwiftUI
import Combine

struct TunerView: View {
    @ObservedObject var tuner: TunerController
    var needleAngle: Double {
        guard tuner.detectedNote != "--" else { return 0.0 }
        let positions = ["A": -45.0, "D": -15.0, "G": 15.0, "B": 45.0]
        let base: Double
        if tuner.detectedNote == "E" {
            base = tuner.detectedFrequency > 250 ? 75.0 : -75.0
        } else {
            base = positions[tuner.detectedNote] ?? 0.0
        }
        return base + Double(tuner.centsOff) * 0.3
    }
    
    var body: some View{
        let scale = 1.4
        let arcDiameter = 300.0 * scale
        let labelRadius = 120.0 * scale
        let tickRadius = 95.0 * scale
        let needleLength = 130.0 * scale
        let centerOffset = 75.0 * scale

        let guitarNotes = ["E", "A", "D", "G", "B", "E"]
        let noteAngles = [-75.0, -45.0, -15.0, 15.0, 45.0, 75.0]
        VStack{
            VStack{
                Text("Tuner")
                    .font(.system(size: 30, weight: .bold))
                    .padding(.top, 60)
                    .padding(.bottom, 50)
                ZStack {
                    ForEach(0..<6, id: \.self) { i in
                        let angle = noteAngles[i] * .pi / 180
                        Text(guitarNotes[i])
                            .font(.system(size: 16 * scale, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: labelRadius * sin(angle), y: -labelRadius * cos(angle) + centerOffset)
                    }
                    let allTickAngles = stride(from: -75.0, through: 75.0, by: 15.0).map { $0 }
                    ForEach(0..<allTickAngles.count, id: \.self) { i in
                        let angle = allTickAngles[i] * .pi / 180
                        let isMajor = allTickAngles[i].truncatingRemainder(dividingBy: 30) == 0
                        Rectangle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 2, height: isMajor ? 12 * scale : 7 * scale)
                            .rotationEffect(.degrees(allTickAngles[i]))
                            .offset(x: tickRadius * sin(angle), y: -tickRadius * cos(angle) + centerOffset)
                    }
                    Circle()
                        .trim(from: 0.5, to: 1.0)
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: arcDiameter, height: arcDiameter)
                        .offset(y: centerOffset)

                    Capsule()
                        .fill(Color.white)
                        .frame(width: 4, height: needleLength)
                        .rotationEffect(.degrees(needleAngle), anchor: .bottom)
                        .offset(y: 10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: needleAngle)
                }
                .frame(width: arcDiameter, height: arcDiameter / 2 + 5)
                .clipped()
                HStack{
                    Text("\(tuner.detectedNote)")
                }
                .font(.system(size: 60, weight: .bold))
                .onAppear{tuner.startTuning()}
                .onDisappear {tuner.stopTuning()}
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .offset(y: -200)
        .background(Color(red: 191/255, green: 64/255, blue: 191/255).ignoresSafeArea())

    }
    

}

#Preview {
    TunerView(tuner: TunerController())
}
