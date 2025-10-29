//
//  Round0View.swift
//  BattleShip
//
//  Created by Serguei Diaz on 14.01.2025.
//
import SwiftUI

struct Round0View: View {
    
    @State var table: [[Int]] = Array(repeating: Array(repeating: 0, count: 10), count: 10)
    
    let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
    
    @State var ships: [Int] = [2, 3, 3, 4, 5, 0]
    
    @State var currentShip = 0
    
    @State var currentShipPosition: [(Int, Int)] = []
    
    @State var round0Completed: Bool = false
        
    @StateObject var roomInfo: RoomInfoModel
    
    @ObservedObject var webSocketService = WebSocketService.shared
    
    private let navService = NavigationService.shared
    
    private let messageHandler = BattleShipProtocolMessagesHandler.shared
    
    func onCellTap(_ x: Int, _ y: Int) {
        if !isValidPosition(size: ships[currentShip], x: x, y: y, currentShipPosition: currentShipPosition) ||
            currentShip >= ships.count - 1
        {
            return
        }
        
        table[x][y] = ships[currentShip]
        currentShipPosition.append((x, y))
        let currentCount = currentShipPosition.count
        if currentCount >= ships[currentShip] {
            currentShip+=1
            currentShipPosition = []
        }
    }
    
    func readyButtonAction() {
        webSocketService.sendMessage([
            "operation": 2,
            "user_id": roomInfo.myUserId,
            "room_id": roomInfo.roomId,
            "player_table": table
        ])
    }
    
    var body: some View {
        
        HStack(spacing: 0) {
            Spacer()
            
            VStack() {
                Spacer()
                
                Text("Round 0")
                    .font(.system(size: 16))
                
                Spacer()
                
                Text("Players completed round 0: \(roomInfo.numberOfPlayersCompletedRounds0)/\(roomInfo.numberOfCurrentPlayers)")
                
                Spacer()
                
                Text("Put a ship of size:")
                    .font(.system(size: 16))
                
                Text("\(ships[currentShip])")
                    .font(.system(size: 32))
                
                if !round0Completed {
                    MainButton(
                        isActive: ships[currentShip] == 0,
                        text: "Ready!",
                        action: readyButtonAction
                    )
                }
                
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 24, alignment: .center)
                    
                    ForEach(table[0].indices, id: \.self) { i in
                        Rectangle()
                            .fill(Color.clear)
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay {
                                Text("\(i)")
                            }
                    }
                }
                ForEach(table.indices, id: \.self) { i in
                    let row = table[i]
                    
                    HStack(spacing: 0) {
                        Text("\(letters[i])")
                            .frame(width: 24, alignment: .center)
                        ForEach(row.indices, id: \.self) { j in
                            let cell = row[j]
                            Rectangle()
                                .fill(cell == 0 ? Color.white.opacity(0.0001) : Color.white.opacity(0.75))
                                .border(Color.white, width: 1)
                                .aspectRatio(1.0, contentMode: .fit)
                                .onTapGesture {
                                    onCellTap(i, j)
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
            
            Spacer()
        }
        .padding()
        .onChange(of: webSocketService.messagesReceived) { oldValue, newValue in
            if (newValue > oldValue && navService.items.last == .Round0(roomInfo: roomInfo)) {
                
                let message = webSocketService.receivedMessage
                
                if message["operation"] as? Int == 2 {
                    switch messageHandler.round0Status(message: message) {
                    case .success(let response):
                        let playersCompletedRound = response.playersCompletedRound
                        
                        Task { @MainActor in
                            roomInfo.numberOfPlayersCompletedRounds0 = playersCompletedRound.count
                        }
                        if playersCompletedRound.contains(where: { player in
                            player == roomInfo.userColor
                        }) {
                            Task { @MainActor in
                                round0Completed = true
                            }
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
                else if message["operation"] as? Int == 3 {
                    switch messageHandler.round1StartStatus(message: message) {
                    case .success(let response):
                        let round = response.round
                        let currentPlayerTurn = response.currentTurn
                        let playersOrder = response.playOrder
                        Task { @MainActor in
                            roomInfo.round = round
                            roomInfo.currentTurn = currentPlayerTurn
                            roomInfo.playersOrder = playersOrder
                            
                            for player in roomInfo.playersOrder {
                                roomInfo.playersTables[player] = Array(repeating: Array(repeating: 0, count: 10), count: 10)
                            }
                            roomInfo.playersTables[roomInfo.userColor] = table
                            
                            navService.goTo(.Round1(roomInfo: roomInfo))
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
        
    }
}

extension Round0View {
    func getHorientation(
        _ x: Int,
        _ y: Int,
        _ currentShipPosition: [(Int, Int)]
    ) -> (Orientation, Int){
        if currentShipPosition.count < 2 {
            return (.none, -2)
        }
        var h = -1
        var v = -1
        for pos in currentShipPosition {
            if h == -1 {
                h = pos.0
            }
            else if h != pos.0 {
                h = -2
            }
            
            if v == -1 {
                v = pos.1
            }
            else if v != pos.1 {
                v = -2
            }
        }
        
        if h != -2 {
            return (.horizontal, h)
        }
        else if v != -2 {
            return (.vertical, v)
        }
        else {
            return (.none, -2)
        }
    }
    
    func getMaxPossibleSize(_ x: Int, _ y: Int) -> (h: Int, v: Int) {
        var maxH = 1
        var maxV = 1
        if x < 9 {
            for i in (x+1)..<10 {
                if table[i][y] == 0 { maxH += 1 } else { break }
            }
        }
        if x > 0 {
            for i in 0..<x {
                if table[x-i-1][y] == 0 { maxH += 1 } else { break }
            }
        }
        if y < 9 {
            for i in (y+1)..<10 {
                if table[x][i] == 0 { maxV += 1 } else { break }
            }
        }
        if y > 0 {
            for i in 0..<y {
                if table[x][y-i-1] == 0 { maxV += 1 } else { break }
            }
        }
        
        return (maxH, maxV)
    }
    
    func isValidPosition(
        size: Int,
        x: Int,
        y: Int,
        currentShipPosition: [(Int, Int)]
    ) -> Bool {
        if currentShipPosition.contains(where: { pos in
            pos.0 == x && pos.1 == y
        }) {
            return false
        }
        if (
            x < 0 ||
            y < 0 ||
            x > 9 ||
            y > 9 ||
            table[x][y] != 0
        ) {
            return false
        }
        
        if currentShipPosition.isEmpty {
            let maxPossibleSize = getMaxPossibleSize(x, y)
            if maxPossibleSize.h >= size || maxPossibleSize.v >= size {
                return true
            }
            else {
                return false
            }
        }
        else if currentShipPosition.count == 1 {
            let maxPossibleSize = getMaxPossibleSize(currentShipPosition[0].0, currentShipPosition[0].1)
            if abs(currentShipPosition[0].0 - x) == 1 &&
                currentShipPosition[0].1 == y &&
                maxPossibleSize.h >= size
            {
                return true
            }
            else if abs(currentShipPosition[0].1 - y) == 1 &&
                        currentShipPosition[0].0 == x &&
                        maxPossibleSize.v >= size
            {
                return true
            }
            else {
                return false
            }
        }
        else {
            let orientation: (Orientation, Int) = getHorientation(x, y, currentShipPosition)
            if orientation.0 == .horizontal &&
                orientation.1 == x
            {
                guard let maxY = currentShipPosition.max(by: {$0.1 < $1.1})?.1,
                      let minY = currentShipPosition.min(by: {$0.1 < $1.1})?.1
                else {
                    return false
                }
                
                if abs(maxY - y) == 1 ||
                    abs(minY - y) == 1
                {
                    return true
                }
                else {
                    return false
                }
            }
            else if orientation.0 == .vertical &&
                        orientation.1 == y
            {
                guard let maxX = currentShipPosition.max(by: {$0.0 < $1.0})?.0,
                      let minX = currentShipPosition.min(by: {$0.0 < $1.0})?.0
                else {
                    return false
                }
                
                if abs(maxX - x) == 1 ||
                    abs(minX - x) == 1
                {
                    return true
                }
                else {
                    return false
                }
            }
        }
        
        return false
    }
}

#Preview {
    Round0View(roomInfo: .init(roomId: "7bf5a5", myUserId: "7c7796", webSocketUrl: "ws://localhost:3000/?userId=7c7796", numberOfPlayers: 4, numberOfCurrentPlayers: 1))
}
