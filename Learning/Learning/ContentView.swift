//
//  ContentView.swift
//  Learning
//
//  Created by CNCEMNV02 on 2026/7/20.
//

import SwiftUI
import Foundation
import UIKit

// https://api.dictionaryapi.dev/media/pronunciations/en/{单词}-us.mp3

struct ContentView: View {
    @StateObject private var scorer = PronunciationScorer()

    var body: some View {
        StudyPage(scorer: scorer)
    }
}

#Preview {
    ContentView()
}
