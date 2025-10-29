//
//  WaitingRoom.swift
//  BattleShip
//
//  Created by Serguei Diaz on 14.01.2025.
//

import SwiftUI

struct WaitingRoom: View {
    @StateObject var roomInfo: RoomInfoModel
    
    @ObservedObject var webSocketService = WebSocketService.shared
        
    private let navService = NavigationService.shared
    
    private let messageHandler = BattleShipProtocolMessagesHandler.shared

    func startGame() {
        webSocketService.sendMessage([
            "operation": 1,
            "user_id": roomInfo.myUserId,
            "room_id": roomInfo.roomId
        ])
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack {
                Text("Room ID:")
                    .font(.system(size: 8))
                
                Text(roomInfo.roomId)
                    .font(.system(size: 32))
                    .textSelection(.enabled)
            }
            
            VStack {
                Text("Players:")
                    .font(.system(size: 8))
                
                Text("\(roomInfo.numberOfCurrentPlayers)/\(roomInfo.numberOfPlayers)")
                    .font(.system(size: 16))
            }
            
            if roomInfo.host {
                MainButton(
                    isActive: roomInfo.numberOfCurrentPlayers > 1,
                    text: "Start game",
                    action: startGame
                )
            }
            
        }
        .padding(24)
        .onChange(of: webSocketService.messagesReceived) { oldValue, newValue in
            if (newValue > oldValue && navService.items.last == .WaitingRoom(roomInfo: roomInfo)) {
                
                let message = webSocketService.receivedMessage
                
                if message["operation"] as? Int == 0 {
                    switch messageHandler.newPlayerInRoom(message: message) {
                    case .success(let response):
                        Task{ @MainActor in
                            roomInfo.numberOfCurrentPlayers = response
                        }
                        return
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                else if message["operation"] as? Int == 1 {
                    switch messageHandler.gameStarted(message: message) {
                    case .success(let response):
                        Task{ @MainActor in
                            roomInfo.round = response.round
                            roomInfo.userColor = response.userColor
                            navService.goTo(.Round0(roomInfo: roomInfo))
                        }
                        return
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

#Preview {
    WaitingRoom(roomInfo: .init(roomId: "7bf5a5", myUserId: "7c7796", webSocketUrl: "ws://localhost:3000/?userId=7c7796", numberOfPlayers: 4, numberOfCurrentPlayers: 1))
}
