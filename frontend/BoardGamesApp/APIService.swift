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

struct AvailabilityCreateData: Codable {
    let from_time: Date
    let to_time: Date
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
    
    func addAvailability(userID: String, addAvailability: AvailabilityCreateData, completion: @escaping (Bool)-> Void) {
        guard let url = URL(string:"\(baseURL)/api/users/\(userID)/availabilities") else {
            completion(false)
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let jsonData = try? encoder.encode(addAvailability) else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request){ data, response, error in
            if error != nil {
                completion(false)
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
               
        }
        task.resume()
    }
    
    
    
}
