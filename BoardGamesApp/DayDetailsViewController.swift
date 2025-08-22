//
//  DayDetailsViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 19/08/2025.
//

import UIKit

class DayDetailsViewController: UIViewController {
    var events = [GameEvent]()
    
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
            gamesTableView.heightAnchor.constraint(equalToConstant: 80),
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
        
        let event = events[indexPath.row]
        let isUserJoined = false
        
        cell.configure(with: event, isUserJoined: isUserJoined)

        return cell
    }
        
    
}
