//
//  Fretboard.swift
//  Guitar Buddy
//
//  Created by Ashwin Rao on 9/3/26.
//

import SwiftUI
import AVFoundation

struct FretBoardDiagramView: View {
    let fretArray: [Int] //fret position for each string (6 strings)
    
    private var filteredNumbers: [Int] { fretArray.filter {$0 != -1 && $0 != 0}}
    private var minFret: Int {filteredNumbers.min() ?? 0}
    private var maxFret: Int {filteredNumbers.max() ?? 0}
    private var usesAbsolutePos: Bool {maxFret <= 3}
    
    var body: some View {
        let scale: CGFloat = 1.3
        let labelWidth: CGFloat = 45 * scale
        let canvasWidth: CGFloat = 240 * scale  // 117 + 273 = 390, fits exactly
        let canvasHeight: CGFloat = 300 * scale
        let fontSize: CGFloat = 30 * scale

        VStack(spacing: 4 * scale){
            HStack(spacing: 0){
                Text(" ")
                    .font(.system(size: 14 * scale))
                    .frame(width: labelWidth)
                    .opacity(0)
                HStack(spacing: 0) {
                    ForEach(0..<min(6, fretArray.count), id:\.self){i in
                        Text(marker(for: fretArray[i]))
                            .font(.system(size: fontSize))
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: canvasWidth)
                Spacer()
                    .frame(width: labelWidth)
            }
            HStack(alignment: .top, spacing: 0.05 * scale){
                Text("\(minFret)")
                    .font(.system(size: fontSize))
                    .frame(width: labelWidth)
                    .lineLimit(1)
                    .padding(.trailing, 0.2)
                    .opacity(usesAbsolutePos ? 0 : 1)
                Canvas { context, size in
                    let topPad: CGFloat = 15 * scale
                    let availHeight = size.height - topPad
                    let colWidth = size.width / 6
                    let rowHeight = availHeight / 5
                    let startX = 0.5 * colWidth
                    let endX = 5.5 * colWidth

                    for i in 0..<6 { //string lines
                        let x = (CGFloat(i) + 0.5) * colWidth
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: topPad))
                        path.addLine(to: CGPoint(x: x, y: topPad + 4 * rowHeight))
                        context.stroke(path, with: .color(.white), lineWidth: 4 * scale)
                    }
                    for i in 0..<5 { //fret lines
                        let y = topPad + CGFloat(i) * rowHeight
                        var path = Path()
                        path.move(to: CGPoint(x: startX, y: y))
                        path.addLine(to: CGPoint(x: endX, y: y))
                        context.stroke(path, with: .color(.white), lineWidth: 4 * scale)
                    }

                    for (j, fret) in fretArray.enumerated() {
                        guard fret != -1 && fret > 0 else { continue }
                        let rowFraction = usesAbsolutePos
                            ? CGFloat(fret) / 5
                            : CGFloat(fret - minFret) / 5
                        let x = (CGFloat(j) + 0.5) * colWidth
                        let y = topPad + rowFraction * availHeight
                        let r: CGFloat = 10 * scale
                        let dotRect = CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)
                        context.fill(Path(ellipseIn: dotRect), with: .color(Color.yellow))
                    }
                }
                .frame(width: canvasWidth, height: canvasHeight)
                Spacer()
                    .frame(width: labelWidth)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 30)
    }
    
    private func marker(for fret: Int) -> String{
        if fret == -1 {return "x"}
        if fret == 0 {return "o"}
        return ""
    }
    
    
}

struct VoicingsGridView: View {
    let voicings: [[Int]]
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 20)
    ]
    var body: some View {
        ScrollView{
            LazyVGrid(columns: columns, spacing: 20){
                ForEach(Array(voicings.enumerated()), id: \.offset){_,voicing in
                    FretBoardDiagramView(fretArray: voicing)
                        .containerRelativeFrame(.vertical)
                        .padding(.horizontal, 25)
                }
            }
            .padding()
        }
    }
}

struct VoicingsView: View {
    @ObservedObject var recorder: AudioController
    var body: some View {
        let sortedVoicings = (recorder.voicings ?? []).sorted { a, b in
            let minA = a.filter { $0 != -1 && $0 != 0 }.min() ?? 0
            let minB = b.filter { $0 != -1 && $0 != 0 }.min() ?? 0
            return minA < minB
        }
        VStack(spacing: 0){
            Text("Chord Diagrams:")
                .font(.system(size: 30, weight: .bold))
                .padding(.top, 120)
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    if recorder.voicings == nil || recorder.voicings!.isEmpty {
                        FretBoardDiagramView(fretArray: [0,0,0,0,0,0])
                            .containerRelativeFrame(.vertical)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    else{
                        ForEach(Array(sortedVoicings.enumerated()), id: \.offset) { _, voicing in
                                FretBoardDiagramView(fretArray: voicing)
                                    .containerRelativeFrame(.vertical)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
        }
        .background(Color(red: 235/255, green: 55/255, blue: 34/255).ignoresSafeArea()).ignoresSafeArea()
    }
}

#Preview{
    VoicingsView(recorder: AudioController())
}

