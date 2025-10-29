//
//  Requests.swift
//  BattleShip
//
//  Created by Serguei Diaz on 19.01.2025.
//

import Foundation

extension NetworkService {
    public func createRoom(numberOfPlayers: Int) async throws -> RoomInfoModel {
        return try await self.httpRequest(
            endpoint: "https://127.0.0.1:3000/create-room",
            method: .post,
            body: ["number_of_players": numberOfPlayers],
            responseType: createRoomResponseMapper.self
        )
        .execute()
    }
    
    public func JoinRoom(roomId: String) async throws -> RoomInfoModel {
        return try await self.httpRequest(
            endpoint: "https://127.0.0.1:3000/join-room",
            method: .post,
            body: ["room_id": roomId],
            responseType: createRoomResponseMapper.self
        )
        .execute()
    }
}
