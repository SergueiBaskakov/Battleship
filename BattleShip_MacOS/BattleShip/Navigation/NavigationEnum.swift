//
//  NavigationEnum.swift
//  BattleShip
//
//  Created by Serguei Diaz on 14.01.2025.
//

enum navigationPath: Hashable {
    case JoinGame
    case WaitingRoom(roomInfo: RoomInfoModel)
    case Round0(roomInfo: RoomInfoModel)
    case Round1(roomInfo: RoomInfoModel)
    
    static func == (lhs: navigationPath, rhs: navigationPath) -> Bool {
        switch (lhs, rhs) {
        case (.JoinGame, .JoinGame):
            return true
        case (.WaitingRoom(_), .WaitingRoom(_)):
            return true
        case (.Round0(_), .Round0(_)):
            return true
        case (.Round1(_), .Round1(_)):
            return true
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .JoinGame:
            hasher.combine("JoinGame")
        case .WaitingRoom(_):
            hasher.combine("WaitingRoom")
        case .Round0(_):
            hasher.combine("Round0")
        case .Round1(_):
            hasher.combine("Round1")
        }
    }
}
