//
//  NetworkingService.swift
//  BattleShip
//
//  Created by Serguei Diaz on 19.01.2025.
//
import Foundation

class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    func httpRequest<T: Decodable>(
        endpoint: String,
        method: httpMethod,
        body: Codable? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        print("HTTP Request:")
        print(endpoint)
        print(method.rawValue)
        print("Content-Type: application/json")
        print(body ?? "")
        print("")
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        print("HTTP Response from server:")
        print(try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? "")
        print("")

        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum httpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
