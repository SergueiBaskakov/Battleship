//
//  JoinGameView.swift
//  BattleShip
//
//  Created by Serguei Diaz on 14.01.2025.
//

import SwiftUI

struct JoinGameView: View {
    @State private var roomID: String = ""
    @State private var maxNumOfPlayers: Int?
    @State private var showInsertMaxPlayers: Bool = false
    @State private var isLoading: Bool = false
    
    @ObservedObject var webSocketService = WebSocketService.shared
    private let navService = NavigationService.shared
    private let networkService = NetworkService.shared
    
    func openCreateNewRoom() {
        self.showInsertMaxPlayers = true
    }
    
    func createNewRoom() {
        guard let maxNumOfPlayers = maxNumOfPlayers else { return }
        isLoading = true
        Task {
            do {
                let response = try await networkService.createRoom(numberOfPlayers: maxNumOfPlayers)
                response.host = true
                response.numberOfCurrentPlayers = 1
                response.numberOfPlayers = maxNumOfPlayers
                self.showInsertMaxPlayers = false
                guard let url: URL = URL(string: response.webSocketUrl) else { return }
                webSocketService.connect(to: url)
                navService.goTo(.WaitingRoom(roomInfo: response))
            } catch {
                print("Error: \(error)")
            }
            isLoading = false
        }
    }
    
    func joinRoom() {
        isLoading = true
        Task {
            do {
                let response = try await networkService.JoinRoom(roomId: roomID)
                //print("joinRoom response: \(String(describing: response))")

                guard let url: URL = URL(string: response.webSocketUrl) else { return }
                webSocketService.connect(to: url)
                navService.goTo(.WaitingRoom(roomInfo: response))
            } catch {
                print("Error: \(error)")
            }
            isLoading = false
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter room ID", text: $roomID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                MainButton(
                    isActive: !roomID.isEmpty,
                    text: "Join room",
                    action: joinRoom
                )
                MainButton(
                    isActive: roomID.isEmpty,
                    text: "Create new room",
                    action: openCreateNewRoom
                )
            }
        }
        .padding()
        .sheet(isPresented: $showInsertMaxPlayers) {
            VStack {
                TextField("Enter the maximum number of players", value: $maxNumOfPlayers, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                MainButton(
                    isActive: (maxNumOfPlayers ?? 0) > 1,
                    text: "Create new room",
                    action: createNewRoom
                )
            }
            .padding()
        }
        .loading(isLoading)
    }
    
}

#Preview {
    JoinGameView()
}
