//
//  ButtonStyles.swift
//  BattleShip
//
//  Created by Serguei Diaz on 14.01.2025.
//

import SwiftUI


struct MainButton: View {
    let isActive: Bool
    let text: String
    let action: () -> Void
    var body: some View {
        if isActive {
            Button(text) {
                action()
            }
            .buttonStyle(.borderedProminent)
        }
        else {
            Button(text) {
            }
            .buttonStyle(.bordered)
            .disabled(true)
        }
    }
}
