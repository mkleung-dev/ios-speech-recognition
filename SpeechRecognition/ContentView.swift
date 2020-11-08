//
//  ContentView.swift
//  SpeechRecognition
//
//  Created by Man Kin Leung on 7/11/2020.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var recognitionController: SpeechRecognitionController = SpeechRecognitionController()
    
    var body: some View {
        VStack {
            Text(recognitionController.speechText)
            Spacer()
            HStack {
                Spacer()
                Button(action: {recognitionController.getSpeech()}) {
                    VStack {
                        Image(systemName: "mic.circle")
                            .font(.system(size: 64))
                        Text(recognitionController.recordButtonText)
                    }
                }
                .disabled(!recognitionController.recordButtonEnabled)
                Spacer()
                Button(action: {recognitionController.speak()}) {
                    VStack {
                        Image(systemName: "speaker.wave.2.circle")
                            .font(.system(size: 64))
                        Text(recognitionController.speakButtonText)
                    }
                }
                .disabled(!recognitionController.speakButtonEnabled)

                Spacer()
            }
            Text(recognitionController.statusText)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
