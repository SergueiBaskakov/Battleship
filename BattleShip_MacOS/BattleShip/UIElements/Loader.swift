//
//  Loaders.swift
//  BattleShip
//
//  Created by Serguei Diaz on 19.01.2025.
//

import SwiftUI

struct LoaderViewModifier: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .opacity(0.5)
            }
            content
        }
    }
}

extension View {
    func loading(_ isLoading: Bool) -> some View {
        self.modifier(LoaderViewModifier(isLoading: isLoading))
    }
}
