//
//  Models.swift
//  BattleShip
//
//  Created by Serguei Diaz on 02.02.2025.
//

struct GameStatusModel {
    let round: Int
    let userColor: String
}

struct Round0StatusModel {
    let round: Int
    let playersCompletedRound: [String]
}

struct Round1BasicStatusModel {
    let round: Int
    let playOrder: [String]
    let currentTurn: String
}

struct Round1StatusModel {
    let round: Int
    let attackEmisor: String
    let attackReceptor: String
    let coordinates: Coordinates
    let result: Int
    let currentTurn: String
    let playOrder: [String]
}

struct Coordinates: Codable {
    let x: Int
    let y: Int
}
