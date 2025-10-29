//
//  Mappers.swift
//  BattleShip
//
//  Created by Serguei Diaz on 19.01.2025.
//

protocol MapperProtocol: Codable {
    associatedtype Output
    func execute() -> Output
}

struct createRoomResponseMapper: MapperProtocol {
    
    typealias Output = RoomInfoModel
    
    let success: Bool?
    let user_id: String
    let room_id: String
    let websocket_url: String
    let number_of_players: Int?
    let number_of_current_players: Int?
    
    func execute() -> Output {
        //print("create room response: \(self)")
        return .init(
            roomId: room_id,
            myUserId: user_id,
            webSocketUrl: websocket_url,
            numberOfPlayers: number_of_players ?? 0,
            numberOfCurrentPlayers: number_of_current_players ?? 0
        )
    }
}

struct ErrorMapper: MapperProtocol {
    typealias Output = ErrorModel
    
    let message: String
    let error_code: Int
    
    func execute() -> Output {
        //print("error response: \(self)")
        return .init(code: error_code, message: message)
    }
}

struct NewPlayerInRoomMapper: MapperProtocol {
    typealias Output = Int
    
    let operation: Int
    let number_of_current_players: Int
    
    func execute() -> Output {
        //print("new player in room response: \(self)")
        return number_of_current_players
    }
}

struct GameStartedMapper: MapperProtocol {
    typealias Output = GameStatusModel
    
    let operation: Int
    let round: Int
    let user_color: String

    func execute() -> Output {
        return .init(round: round, userColor: user_color)
    }
}

struct Round0StatusMapper: MapperProtocol {
    typealias Output = Round0StatusModel
    
    let operation: Int
    let round: Int
    let completed_round0_players: [String]

    func execute() -> Output {
        return .init(round: round, playersCompletedRound: completed_round0_players)
    }
}

struct Round1BasicStatusMapper: MapperProtocol {
    typealias Output = Round1BasicStatusModel
    
    let operation: Int
    let round: Int
    let current_player_turn: String
    let players_order: [String]

    func execute() -> Output {
        return .init(round: round, playOrder: players_order, currentTurn: current_player_turn)
    }
}

struct Round1StatusMapper: MapperProtocol {
    typealias Output = Round1StatusModel
    
    let operation: Int
    let round: Int
    let current_player_turn: String?
    let players_order: [String]?
    let attack_emisor_color: String
    let attack_receptor_color: String
    let coordinates: Coordinates
    let result: Int


    func execute() -> Output {
        return .init(round: round, attackEmisor: attack_emisor_color, attackReceptor: attack_receptor_color, coordinates: coordinates, result: result, currentTurn: current_player_turn ?? "", playOrder: players_order ?? [])
    }
}

struct EndGameMapper: MapperProtocol {
    typealias Output = String
    
    let operation: Int
    let winner: String


    func execute() -> Output {
        return winner
    }
}
