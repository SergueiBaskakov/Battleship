//
//  Round1+View.swift
//  BattleShip
//
//  Created by Serguei Diaz on 16.01.2025.
//

import SwiftUI

struct Round1View: View {
    let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
    
    @State var currentTable: [[Int]] = []
    
    @State var selectedPlayer: String = ""
    
    @StateObject var roomInfo: RoomInfoModel
        
    @ObservedObject var webSocketService = WebSocketService.shared
    
    private let navService = NavigationService.shared
    
    private let messageHandler = BattleShipProtocolMessagesHandler.shared
    
    func attack(x: Int, y: Int) {
        if selectedPlayer == roomInfo.userColor {
            return
        }
        webSocketService.sendMessage([
            "operation": 4,
            "user_id": roomInfo.myUserId,
            "room_id": roomInfo.roomId,
            "player_color": selectedPlayer,
            "coordinates": ["x": x, "y": y]
        ])
    }
    
    func selectPlayer(_ player: String) {
        selectedPlayer = player
        currentTable = roomInfo.playersTables[player] ?? []
    }
    
    var body: some View {
        HStack {
            if roomInfo.winner.isEmpty {
                VStack(spacing: 16) {
                    if roomInfo.loose {
                        Spacer()
                        Text("You loose!")
                            .font(.system(size: 32))
                    }
                    
                    Spacer()
                    Text("Round \(roomInfo.round)")
                        .font(.system(size: 28))
                                       
                    Spacer()
                    
                    Text("Turn of player:")
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, -12)
                    
                    Text(roomInfo.currentTurn)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 24))
                    
                    Spacer()
                    
                    Text("Alive Players:")
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, -12)
                    
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(roomInfo.playersOrder, id: \.self) { player in
                                HStack {
                                    
                                    Text(player == roomInfo.userColor ? "(Me) \(player)" : player)
                                        .font(.system(size: selectedPlayer == player ? 20 : 16))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .onTapGesture {
                                            selectPlayer(player)
                                        }
                                    
                                    if player == selectedPlayer {
                                        Circle()
                                            .frame(width: 16, height: 16, alignment: .center)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            else {
                Spacer()
                
                Text("The winner is:")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 20))
                
                Text(roomInfo.winner == roomInfo.userColor ? "(Me)\(roomInfo.winner)" : roomInfo.winner)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 32))
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 24, alignment: .center)
                    
                    ForEach(currentTable.first?.indices ?? [].indices, id: \.self) { i in
                        Rectangle()
                            .fill(Color.clear)
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay {
                                Text("\(i)")
                            }
                    }
                }
                ForEach(currentTable.indices, id: \.self) { i in
                    let row = currentTable[i]
                    
                    HStack(spacing: 0) {
                        Text("\(letters[i])")
                            .frame(width: 24, alignment: .center)
                        ForEach(row.indices, id: \.self) { j in
                            let cell = row[j]
                            let fill: Color = cell == 0 ? Color.white.opacity(0.0001) : (cell > 0 ? Color.white.opacity(0.75) : (cell == -1 ? Color.blue : Color.red))
                            
                            Rectangle()
                                .fill(fill)
                                .border(Color.white, width: 1)
                                .aspectRatio(1.0, contentMode: .fit)
                                .onTapGesture {
                                    attack(x: i, y: j)
                                }
                                .overlay {
                                    if cell > 0 {
                                        Text("\(cell)")
                                            .foregroundStyle(.black)
                                            .bold()
                                    }
                                }
                        }
                    }
                }
            }
            .padding()
            
        }
        .padding()
        .onAppear{
            if selectedPlayer.isEmpty {
                selectPlayer(roomInfo.userColor)
            }
        }
        .onChange(of: webSocketService.messagesReceived) { oldValue, newValue in
            if (newValue > oldValue && navService.items.last == .Round1(roomInfo: roomInfo)) {
                
                let message = webSocketService.receivedMessage
                
                if message["operation"] as? Int == 4 {
                    switch messageHandler.round1Status(message: message) {
                    case .success(let response):
                        Task { @MainActor in
                            roomInfo.currentTurn = response.currentTurn 
                            roomInfo.round = response.round
                            roomInfo.playersTables[response.attackReceptor]?[response.coordinates.x][response.coordinates.y] = response.result
                            currentTable = roomInfo.playersTables[selectedPlayer] ?? []
                            roomInfo.playersOrder = response.playOrder
                        }
                        
                        if !response.playOrder.contains(where: { player in
                            player == roomInfo.userColor
                        }) {
                            Task { @MainActor in
                                roomInfo.loose = true
                            }
                        }
                        
                        if !response.playOrder.contains(where: { player in
                            player == selectedPlayer
                        }) {
                            Task { @MainActor in
                                selectPlayer(roomInfo.userColor)
                            }
                        }
                        
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                else if message["operation"] as? Int == 6 {
                    switch messageHandler.round1BaseStatus(message: message) {
                    case .success(let response):
                        Task { @MainActor in
                            roomInfo.currentTurn = response.currentTurn
                            roomInfo.round = response.round
                            roomInfo.playersOrder = response.playOrder
                        }
                        
                        if !response.playOrder.contains(where: { player in
                            player == selectedPlayer
                        }) {
                            Task { @MainActor in
                                selectPlayer(roomInfo.userColor)
                            }
                        }
                        
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                else if message["operation"] as? Int == 5 {
                    switch messageHandler.endGame(message: message) {
                    case .success(let response):
                        Task { @MainActor in
                            roomInfo.winner = response
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
}

#Preview {
    Round1View(roomInfo: .init(roomId: "7bf5a5", myUserId: "7c7796", webSocketUrl: "ws://localhost:3000/?userId=7c7796", numberOfPlayers: 4, numberOfCurrentPlayers: 1))
}
