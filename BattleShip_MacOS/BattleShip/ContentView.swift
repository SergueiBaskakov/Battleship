//
//  ContentView.swift
//  BattleShip
//
//  Created by Serguei Diaz on 11.12.2024.
//

import SwiftUI

struct ContentView: View {
    
    @State var selectedPath: navigationPath = .JoinGame
    
    @StateObject var navService = NavigationService.shared

    
    var body: some View {
        NavigationStack(path: $navService.items) {
            JoinGameView()
                .navigationDestination(for: navigationPath.self) { item in
                    switch item {
                    case .JoinGame:
                        JoinGameView()
                            .navigationBarBackButtonHidden(true)
                    
                    case .WaitingRoom(let roomInfo):
                        WaitingRoom(roomInfo: roomInfo)
                            .navigationBarBackButtonHidden(true)
                        
                    case .Round0(let roomInfo):
                        Round0View(roomInfo: roomInfo)
                            .navigationBarBackButtonHidden(true)
                        
                    case .Round1(let roomInfo):
                        Round1View(roomInfo: roomInfo)
                            .navigationBarBackButtonHidden(true)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
