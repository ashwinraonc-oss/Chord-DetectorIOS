//
//  RootView.swift
//  Guitar Buddy
//
//  Created by Ashwin Rao on 9/2/26.
//

import SwiftUI
import AVFoundation

struct RootView: View {
    @State var selectedTab = 0
    @State var dimmed = false
    @StateObject private var recorder = AudioController()
    @StateObject private var tuner = TunerController()
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab){
                ContentView(recorder: recorder)
                    .tag(0)
                VoicingsView(recorder: recorder)
                    .tag(1)
                TunerView(tuner: tuner)
                    .tag(2)
                Text("Tab4")
                    .tag(3)
                Text("Tab5")
                    .tag(4)
                Text("Tab6")
                    .tag(5)
            } .tabViewStyle(.page(indexDisplayMode: .never)).ignoresSafeArea()
            VStack{
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black)
                        .frame(width: 350, height: 60)
//                        .offset(x: 0, y: 60)
                    HStack(spacing: 15) {
                        Button{
                            selectedTab = 0
                        }label:{
                            Circle().fill(Color.orange).frame(width: 35, height: 35)/*.offset(x: -25, y: 60)*/
                        }.opacity(selectedTab == 0 ? 0.3 : 1.0)
                        Button{
                            selectedTab = 1
                        }label:{
                            Circle().fill(Color.red).frame(width: 35, height: 35)/*.offset(x: -15, y: 60)*/
                        }.opacity(selectedTab == 1 ? 0.3 : 1.0)
                        Button{
                            selectedTab = 2
                        }label:{
                            Circle().fill(Color.purple).frame(width: 35, height: 35)/*.offset(x:  -5, y: 60)*/
                        }.opacity(selectedTab == 2 ? 0.3 : 1.0)
                        Button{
                            selectedTab = 3
                        }label:{
                            Circle().fill(Color.green).frame(width: 35, height: 35)/*.offset(x:   5, y: 60)*/
                        }.opacity(selectedTab == 3 ? 0.3 : 1.0)
                        Button{
                            selectedTab = 4
                        }label:{
                            Circle().fill(Color.blue).frame(width: 35, height: 35)/*.offset(x: 15, y: 60)*/
                        }.opacity(selectedTab == 4 ? 0.3 : 1.0)
                        Button{
                            selectedTab = 5
                        }label:{
                            Circle().fill(Color.white).frame(width: 35, height: 35)/*.offset(x:  25, y: 60)*/
                        }.opacity(selectedTab == 5 ? 0.3 : 1.0)
                    }
                } .padding(.bottom, 0)
            }
        }
    }
}

#Preview {
    RootView()
}
