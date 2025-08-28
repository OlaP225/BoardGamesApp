//
//  APIService.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 25/08/2025.
//

import Foundation

struct UserRegistrationData: Codable {
    let username: String
    let userID: String
}

class APIService {
    static let shared = APIService()
    private init () {}
    private let baseURL = "http://127.0.0.1:8000"
    
    func registerUser(userData: UserRegistrationData){
        guard let url = URL(string: "\(baseURL)/api/users") else {
            print("Incorrect URL")
            return
        }
        
        guard let jsonData = try? JSONEncoder().encode(userData) else {
            print("Unable to code data to JSON")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request){ data, response, error in
            if let error = error {
                print("Error of request to API: \(error.localizedDescription)")
            }
            
            if let responseString = String(data: data ?? Data(), encoding: .utf8){
                print("Answer from server: \(responseString)")
            }
        }
        task.resume()
    
    }
    
    
    
}
