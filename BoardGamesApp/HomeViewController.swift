//
//  HomeViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 29/07/2025.
//

import UIKit

class HomeViewController: UIViewController{
    @IBOutlet var greeting: UILabel!
    @IBOutlet var addAviability: UIButton!
    @IBOutlet var searchMeetings: UIButton!
    @IBOutlet var upcomingTitle: UILabel!
    @IBOutlet var pastTitle: UILabel!
    
    let cardsStackView = UIStackView()
    
    
    var events: [GameEvent] = [
        GameEvent(title: "Monopoly", currentPlayersCount: 3, maxPlayersCount: 4, time: "10:00 - 12:00", location: "Planty Racławickie", date: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 2))!),
        GameEvent(title: "Catan", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Planty Racławickie", date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 12))!)
                  
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        upcomingTitle.text = "Nadchodzące spotkania"
        pastTitle.text = "Zakończone spotkania"

        
        setupCardsStackView()
        displayGameCards()
        

    }
    
    func setupCardsStackView() {
        view.addSubview(cardsStackView)
        
        cardsStackView.axis = .vertical
        cardsStackView.spacing = 8
        cardsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardsStackView.topAnchor.constraint(equalTo: upcomingTitle.bottomAnchor, constant: 10),
            cardsStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 70),
            cardsStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -70)
        ])
    }
    
    func displayGameCards() {
        for event in events {
            let card = GameCardView()
            card.configure(with: event)
            cardsStackView.addArrangedSubview(card)
        }
    }

}
