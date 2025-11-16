//
//  DayDetailsViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 19/08/2025.
//

import UIKit

class DayDetailsViewController: UIViewController {
    var events = [GameEvent]()
    var currentUserID: String {
        return UserDefaults.standard.string(forKey: "userID") ?? ""
    }
    
    private let gamesTableView = UITableView()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        setupTableView()

    }
    private func setupTableView() {
        view.addSubview(gamesTableView)
        gamesTableView.delegate = self
        gamesTableView.dataSource = self
        
        gamesTableView.translatesAutoresizingMaskIntoConstraints = false
        
        gamesTableView.register(GameCardCell.self, forCellReuseIdentifier: GameCardCell.identifier)
        
        NSLayoutConstraint.activate([
            gamesTableView.topAnchor.constraint(equalTo: view.topAnchor),
            gamesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gamesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gamesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            gamesTableView.heightAnchor.constraint(equalToConstant: 70),
            gamesTableView.widthAnchor.constraint(equalToConstant: 200)
        ])
    }
    

}

extension DayDetailsViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = gamesTableView.dequeueReusableCell(withIdentifier: GameCardCell.identifier, for: indexPath) as? GameCardCell else {
            fatalError("Could not dequeue GameCardCell")
        }
        
        let event = self.events[indexPath.row]
        let isUserJoined = event.participantsIDs.contains(currentUserID)
        
        cell.configure(with: event, isUserJoined: isUserJoined)
        
        cell.onLeaveJoinButtonTapped = { [weak self] in
            guard let self = self else { return }
            let event = self.events[indexPath.row]
            let isUserJoined = event.participantsIDs.contains(self.currentUserID)

            if isUserJoined {
                let alert = UIAlertController(title: "Potwierdź", message: "Na pewno chcesz opuścić spotkanie „\(event.title)”?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Anuluj", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Opuść", style: .destructive, handler: { _ in
                    APIService.shared.leaveEvent(eventID: event.id, userID: self.currentUserID) { success in
                        if success {
                            self.events.removeAll { $0.id == event.id }

                            let dateNow = Date()
                            let idString = "leave-\(event.id)-\(Int(dateNow.timeIntervalSince1970))"
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "d MMM, HH:mm"
                            let message = "Opuszczono spotkanie „\(event.title)” zaplanowane na \(dateFormatter.string(from: event.date))."

                            let noti = NotificationItem(id: idString, date: Date(), message: message, type: .info)
                            DispatchQueue.main.async {
                                NotificationStore.shared.add(noti)
                                NotificationCenter.default.post(name: .userDidLeaveEvent, object: noti)
                                print("[DayDetailsVC] posted .userDidLeaveEvent id=\(noti.id) message=\(noti.message)")
                            }

                            DispatchQueue.main.async {
                                self.gamesTableView.reloadData()
                            }
                        } else {
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "Błąd", message: "Nie udało się opuścić wydarzenia", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .default))
                                self.present(alert, animated: true)
                            }
                        }
                    }
                }))
                DispatchQueue.main.async {
                    self.present(alert, animated: true)
                }
            } else {
                // in the future join button :)
            }
        }


        return cell
    }
        
    
}
