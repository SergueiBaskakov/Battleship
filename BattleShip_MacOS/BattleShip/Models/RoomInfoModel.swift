//
//  GameInfoModel.swift
//  BattleShip
//
//  Created by Serguei Diaz on 19.01.2025.
//

import Foundation

class RoomInfoModel: ObservableObject {
    let roomId: String
    let myUserId: String
    let webSocketUrl: String
    var userColor: String = ""
    var host: Bool
    @Published var numberOfPlayers: Int
    @Published var numberOfCurrentPlayers: Int
    @Published var numberOfPlayersCompletedRounds0: Int = 0
    @Published var round: Int = -1
    @Published var playersTables: [String: [[Int]]] = [:]
    @Published var currentTurn: String = ""
    @Published var playersOrder: [String] = []
    @Published var winner: String = ""
    @Published var loose: Bool = false
        
    
    init(roomId: String, myUserId: String, webSocketUrl: String, numberOfPlayers: Int, numberOfCurrentPlayers: Int, host: Bool = false) {
        self.roomId = roomId
        self.myUserId = myUserId
        self.webSocketUrl = webSocketUrl
        self.numberOfPlayers = numberOfPlayers
        self.numberOfCurrentPlayers = numberOfCurrentPlayers
        self.host = host
    }
}



