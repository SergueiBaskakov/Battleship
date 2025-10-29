//
//  WebSocketService.swift
//  BattleShip
//
//  Created by Serguei Diaz on 19.01.2025.
//

import Foundation

class WebSocketService: ObservableObject {    
    static let shared = WebSocketService()
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    
    @Published var receivedMessage: [String: Any] = [:]
    @Published var isConnected: Bool = false
    
    @Published var messagesReceived: Int = 0
    
    @Published var errorMessage: (String, Int) = ("", 0)
    
    private init() {
        self.session = URLSession(configuration: .default)
    }
    
    func connect(to url: URL) {
        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true
        
        receiveMessages()
        
        print("webSocket connected to \(url)")
    }
    
    func sendMessage(_ message: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: message, options: [])
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            let webSocketMessage = URLSessionWebSocketTask.Message.string(jsonString)
            
            webSocketTask?.send(webSocketMessage) { [weak self] error in
                if let error = error {
                    self?.errorMessage = ("Error sending message: \(error)", 1)
                    print("Error sending message: \(error)")
                } else {
                    print("Message sent successfully. Message:")
                    print(message)
                    print("")
                }
            }
        } catch {
            self.errorMessage = ("Error serializing message: \(error)", 2)
            print("Error serializing message: \(error)")
        }
    }
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                Task { @MainActor in
                    self?.errorMessage = ("Error receiving message: \(error)", 3)
                }
                print("Error receiving message: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                DispatchQueue.main.async {
                                    Task { @MainActor in
                                        self?.receivedMessage = json
                                        self?.messagesReceived += 1
                                    }
                                    print("webSocket received message:")
                                    print(json)
                                    print("")
                                }
                            }
                        } catch {
                            Task { @MainActor in
                                self?.errorMessage = ("Error deserializing message: \(error)", 4)
                            }
                            print("Error deserializing message: \(error)")
                        }
                    }
                case .data(let data):
                    print("Received binary data: \(data)")
                @unknown default:
                    break
                }
            }
            
            self?.receiveMessages()
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
    }
}
