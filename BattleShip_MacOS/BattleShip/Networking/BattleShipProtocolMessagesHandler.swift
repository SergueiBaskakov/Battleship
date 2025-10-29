//
//  BattleShipProtocolMessagesHandler.swift
//  BattleShip
//
//  Created by Serguei Diaz on 02.02.2025.
//

import Foundation

struct BattleShipProtocolMessagesHandler {
    
    public static let shared = BattleShipProtocolMessagesHandler()
    
    private init(){}
        
    private func handle<M: MapperProtocol, O>(message: [String: Any], operation: Int, mapper: M.Type, output: O.Type) -> Result<O, ErrorModel> {
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: []) else {return .failure(.init(code: 0, message: "Error on converting message to data"))}
        if let op = message["operation"] as? Int,
           op == operation, let mapper = try? JSONDecoder().decode(M.self, from: data),
           let response = mapper.execute() as? O
        {
            return .success(response)
        }
        else if let error = try? JSONDecoder().decode(ErrorMapper.self, from: data)  {
            return .failure(error.execute())
        }
        else {
            return .failure(.init(code: 1, message: "Error on parsing message"))
        }
    }
    
    public func newPlayerInRoom(message: [String: Any]) -> Result<Int, ErrorModel> {
        handle(message: message, operation: 0, mapper: NewPlayerInRoomMapper.self, output: Int.self)
    }
    
    public func gameStarted(message: [String: Any]) -> Result<GameStatusModel, ErrorModel> {
        handle(message: message, operation: 1, mapper: GameStartedMapper.self, output: GameStatusModel.self)
    }
    
    public func round0Status(message: [String: Any]) -> Result<Round0StatusModel, ErrorModel> {
        handle(message: message, operation: 2, mapper: Round0StatusMapper.self, output: Round0StatusModel.self)
    }
    
    public func round1StartStatus(message: [String: Any]) -> Result<Round1BasicStatusModel, ErrorModel> {
        handle(message: message, operation: 3, mapper: Round1BasicStatusMapper.self, output: Round1BasicStatusModel.self)
    }
    
    public func round1Status(message: [String: Any]) -> Result<Round1StatusModel, ErrorModel> {
        handle(message: message, operation: 4, mapper: Round1StatusMapper.self, output: Round1StatusModel.self)
    }
    
    public func round1BaseStatus(message: [String: Any]) -> Result<Round1BasicStatusModel, ErrorModel> {
        handle(message: message, operation: 6, mapper: Round1BasicStatusMapper.self, output: Round1BasicStatusModel.self)
    }
    
    public func endGame(message: [String: Any]) -> Result<String, ErrorModel> {
        handle(message: message, operation: 5, mapper: EndGameMapper.self, output: String.self)
    }
}
