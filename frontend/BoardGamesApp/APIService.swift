import Foundation

func iso8601DateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}

struct UserRegistrationData: Codable {
    let username: String
    let userID: String
    var preferences: [Int]
}

struct AvailabilityCreateData: Codable {
    let from_time: Date
    let to_time: Date
}

struct AvailabilityResponse: Codable {
    let id: Int
    let from_time: Date
    let to_time: Date
    let owner_id: String
}

struct EventNotification: Codable {
    let id: Int
    let game_name: String
    let from_time: Date
    let to_time: Date
    let participants: [String]?
    let participants_usernames: [String]?
    let suggested_game_types: [String]?
}

class APIService {
    static let shared = APIService()
    private init () {}
    private let baseURL = "http://127.0.0.1:8000"
    
    func registerUser(userData: UserRegistrationData) {
        guard let url = URL(string: "\(baseURL)/api/users") else {
            print("Incorrect URL for registerUser")
            return
        }
        
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(userData) else {
            print("Unable to encode UserRegistrationData to JSON")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error of request to API (registerUser): \(error.localizedDescription)")
                return
            }
            if let responseString = String(data: data ?? Data(), encoding: .utf8) {
                print("Answer from server (registerUser): \(responseString)")
            }
        }
        task.resume()
    }
    
    func addAvailability(userID: String, availabilityData: AvailabilityCreateData, completion: @escaping (AvailabilitySlot?) -> Void) {
        guard let url = URL(string:"\(baseURL)/api/users/\(userID)/availabilities") else {
            completion(nil)
            return
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let jsonData = try? encoder.encode(availabilityData) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                print("Error of request to API (addAvailability): \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                print("Error: Invalid response from server (addAvailability)")
                completion(nil)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(iso8601DateFormatter())
                let availabilityResponse = try decoder.decode(AvailabilityResponse.self, from: data)
                

                let newSlot = AvailabilitySlot(id: availabilityResponse.id, from: availabilityResponse.from_time, to: availabilityResponse.to_time)
                
                completion(newSlot)
                
            } catch {
                print("BŁĄD dekodowania JSON (addAvailability): \(error)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    func deleteAvailability(availabilityID: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/availabilities/\(availabilityID)") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if error != nil {
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                completion(true)
            } else {
                completion(false)
            }
        }
        task.resume()
    }
    
    func fetchAvailabilities(userID: String, completion: @escaping ([AvailabilitySlot]?) -> Void) {
            guard let url = URL(string: "\(baseURL)/api/users/\(userID)/availabilities") else {
                completion(nil)
                return
            }
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if error != nil {
                    print("Błąd zapytania (fetchAvailabilities): \(error!.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                    print("Błąd: Niepoprawna odpowiedź serwera (fetchAvailabilities)")
                    completion(nil)
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .formatted(iso8601DateFormatter())
                    let responseArray = try decoder.decode([AvailabilityResponse].self, from: data)
                    
                    let slots = responseArray.map { responseItem in
                        return AvailabilitySlot(id: responseItem.id, from: responseItem.from_time, to: responseItem.to_time)
                    }
                    completion(slots)
                    
                } catch {
                    print("Błąd dekodowania JSON (fetchAvailabilities): \(error)")
                    completion(nil)
                }
            }
            task.resume()
        }
    
}

extension APIService {
    func fetchUserNotifications(userID: String, completion: @escaping ([NotificationItem]) -> Void) {
         guard let url = URL(string: "\(baseURL)/api/users/\(userID)/events") else {
             DispatchQueue.main.async { completion([]) }
             return
         }

         let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
             if let error = error {
                 print("Error fetching notifications: \(error.localizedDescription)")
                 DispatchQueue.main.async { completion([]) }
                 return
             }

             guard let data = data else {
                 DispatchQueue.main.async { completion([]) }
                 return
             }

             do {
                 let decoder = JSONDecoder()
                 decoder.dateDecodingStrategy = .formatted(iso8601DateFormatter())
                 let events = try decoder.decode([EventNotification].self, from: data)

                 let notifications = events.map { event -> NotificationItem in
                     let formatter = DateFormatter()
                     formatter.dateFormat = "d MMM, HH:mm"
                     let dateText = formatter.string(from: event.from_time)
                     let formatter2 = DateFormatter()
                     formatter2.dateFormat = "HH:mm"
                     let dateText2 = formatter2.string(from: event.to_time)

                     // participants usernames (fall back to ids if usernames not provided)
                     let participantsText: String
                     if let names = event.participants_usernames, !names.isEmpty {
                         participantsText = "Uczestnicy: \(names.joined(separator: ", "))."
                     } else if let ids = event.participants, !ids.isEmpty {
                         participantsText = "Uczestnicy: \(ids.joined(separator: ", "))."
                     } else {
                         participantsText = "Uczestnicy: brak."
                     }

                     // suggested game types
                     let typesText: String
                     if let types = event.suggested_game_types, !types.isEmpty {
                         typesText = "Proponowane typy gier: \(types.joined(separator: ", "))."
                     } else {
                         typesText = "Brak proponowanych typów gier."
                     }

                     let message = "Wylosowano nową grę w dniu \(dateText) - \(dateText2).\n\(typesText)\n\(participantsText)"

                     return NotificationItem(
                         id: String(event.id),
                         date: Date(),
                         message: message,
                         type: .info
                     )
                 }

                 DispatchQueue.main.async { completion(notifications) }
             } catch {
                 print("Decode error notifications: \(error)")
                 DispatchQueue.main.async { completion([]) }
             }
         }
         task.resume()
     }
 
}

extension APIService {
    func updateUserPreferences(userID: String, preferences: [Int], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/users/\(userID)/preferences") else {
            completion(false); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["preferences": preferences]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let err = error {
                print("updateUserPreferences network error:", err.localizedDescription)
                completion(false); return
            }
            guard let http = response as? HTTPURLResponse else { completion(false); return }
            completion((200...299).contains(http.statusCode))
        }
        task.resume()
    }
}

extension APIService {
    func fetchUserEvents(userID: String, completion: @escaping ([GameEvent]) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/users/\(userID)/events") else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, response, error in
            if let error = error {
                print("Error fetching user events: \(error.localizedDescription)")
                DispatchQueue.main.async { completion([]) }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(iso8601DateFormatter())
                let events = try decoder.decode([EventNotification].self, from: data)

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm"

                let mapped: [GameEvent] = events.map { ev in
                    let start = ev.from_time
                    let end = ev.to_time
                    let timeString = "\(dateFormatter.string(from: start)) - \(dateFormatter.string(from: end))"
                    let title = ev.game_name
                    let location = "Klub osiedlowy ABC"
                    let playersCount = ev.participants?.count ?? 0
                    let maxPlayers = 4
                    return GameEvent(
                        id: ev.id,
                        title: title,
                        currentPlayersCount: playersCount,
                        maxPlayersCount: maxPlayers,
                        time: timeString,
                        location: location,
                        date: Calendar.current.startOfDay(for: ev.from_time) == ev.from_time ? ev.from_time : ev.from_time,
                        participantsIDs: ev.participants ?? []
                    )
                }

                DispatchQueue.main.async { completion(mapped) }
            } catch {
                print("Decode error fetchUserEvents: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }
        task.resume()
    }
}
extension APIService {
    func leaveEvent(eventID: Int, userID: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/events/\(eventID)/leave") else {
            completion(false); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["user_id": userID]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let err = error {
                print("leaveEvent network error:", err.localizedDescription)
                DispatchQueue.main.async { completion(false) }
                return
            }
            guard let http = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(false) }
                return
            }
            if (200...299).contains(http.statusCode) {
                DispatchQueue.main.async { completion(true) }
            } else {
                print("leaveEvent server returned \(http.statusCode)")
                DispatchQueue.main.async { completion(false) }
            }
        }
        task.resume()
    }
}

