//
//  HomeViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 29/07/2025.
//

import UIKit

class HomeViewController: BaseViewController{
    @IBOutlet var greeting: UILabel!
    @IBOutlet var upcomingTitle: UILabel!
    @IBOutlet var pastTitle: UILabel!
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var profileImageContainerView: UIView!
    
    let scrollView = UIScrollView()
    let daysStackView = UIStackView()
    let scrollViewPastEvents = UIScrollView()
    let stackViewPastDays = UIStackView()
    
    var upcomingEvents: [GameEvent] = [
        GameEvent(title: "Monopoly", currentPlayersCount: 3, maxPlayersCount: 4, time: "10:00 - 12:00", location: "Krzyki - pokój graczy", date: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 2))!, participantsIDs: []),
        GameEvent(title: "Catan", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Szczepin - klub mieszkańca", date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 12))!, participantsIDs: []),
        GameEvent(title: "Catan", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Graczowo", date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 12))!, participantsIDs: []),
        GameEvent(title: "Catan", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Osiedle Psie Pole", date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 12))!, participantsIDs: []),
        GameEvent(title: "Catan", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Leśnica - osiedle ABC", date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 13))!, participantsIDs: []),
        GameEvent(title: "Catan", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Develia osiedle tarnogaj", date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 13))!, participantsIDs: [])
        ]
    
    var pastEvents: [GameEvent] = [
        GameEvent(title: "Endgame", currentPlayersCount: 5, maxPlayersCount: 6, time: "10:00 - 12:00", location: "Osiedle Szczepin", date: Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 2))!, participantsIDs: []),
        GameEvent(title: "NeedForSpeed", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Oporów - klub mieszkańca", date: Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 10))!, participantsIDs: []),
        GameEvent(title: "CitySkylines", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Pwr sala gier", date: Calendar.current.date(from: DateComponents(year: 2025, month: 2, day: 15))!, participantsIDs: [])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        if let username = defaults.string(forKey: "username") {
            greeting.text = "Cześć, \(username)!"
            greeting.sizeToFit()
            greeting.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        } else {
            greeting.text = "Cześć!"
            greeting.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        }
        
        upcomingTitle.text = "Nadchodzące spotkania"
        pastTitle.text = "Zakończone spotkania"
        upcomingTitle.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        pastTitle.font = UIFont.systemFont(ofSize: 20, weight: .bold)


        setupProfileImageView()

        setUpcomingEvents()
        setUpPastEvents()

    }
    private func setupProfileImageView() {
        profileImageView.image = UIImage(named: "profile3")
        profileImageContainerView.layer.cornerRadius = 20
        print(profileImageView.frame.size.width)
        profileImageContainerView.backgroundColor = .white
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.borderWidth = 2.0
        profileImageView.layer.borderColor = UIColor.white.cgColor
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),
            upcomingTitle.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 20),
            upcomingTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
        ])
    
    }
    
    
    func groupAndSort(events: [GameEvent]) -> (sortedDays: [Date], groupedEvents: [Date: [GameEvent]]){
        let grouped = Dictionary(grouping: events) { event in
            return Calendar.current.startOfDay(for: event.date)
        }
        let sorted = grouped.keys.sorted()
        return (sorted, grouped)
        
    }
    
    func setUpcomingEvents()  {
        let upcomingData = groupAndSort(events: upcomingEvents)
        setupScrollViewAndStackView()
        displayTimeLine(for: upcomingData.sortedDays, with: upcomingData.groupedEvents, to: daysStackView, state: .active)
    }
    
    func setUpPastEvents() {
        let pastData = groupAndSort(events: pastEvents)
        setUpPastScrollViewAndStackView()
        displayTimeLine(for: pastData.sortedDays, with: pastData.groupedEvents, to: stackViewPastDays, state: .past)
        
    }
    
    func setupScrollViewAndStackView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        daysStackView.axis = .vertical
        daysStackView.spacing = 24
        scrollView.addSubview(daysStackView)
        daysStackView.translatesAutoresizingMaskIntoConstraints = false
        
        pastTitle.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: upcomingTitle.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 250),
            pastTitle.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 16),
            pastTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
            daysStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            daysStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            daysStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            daysStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            daysStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    func setUpPastScrollViewAndStackView() {
        view.addSubview(scrollViewPastEvents)
        scrollViewPastEvents.translatesAutoresizingMaskIntoConstraints = false
        
        stackViewPastDays.axis = .vertical
        stackViewPastDays.spacing = 24
        scrollViewPastEvents.addSubview(stackViewPastDays)
        stackViewPastDays.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollViewPastEvents.topAnchor.constraint(equalTo: pastTitle.bottomAnchor, constant: 16),
            scrollViewPastEvents.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollViewPastEvents.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollViewPastEvents.heightAnchor.constraint(equalToConstant: 250),
            
            stackViewPastDays.topAnchor.constraint(equalTo: scrollViewPastEvents.contentLayoutGuide.topAnchor),
            stackViewPastDays.leadingAnchor.constraint(equalTo: scrollViewPastEvents.contentLayoutGuide.leadingAnchor),
            stackViewPastDays.trailingAnchor.constraint(equalTo: scrollViewPastEvents.contentLayoutGuide.trailingAnchor),
            stackViewPastDays.bottomAnchor.constraint(equalTo: scrollViewPastEvents.contentLayoutGuide.bottomAnchor),
            stackViewPastDays.widthAnchor.constraint(equalTo: scrollViewPastEvents.frameLayoutGuide.widthAnchor)
        ])
        
    }
    
    func displayTimeLine(for sortedDays: [Date], with groupedEvents: [Date: [GameEvent]],to stackView: UIStackView, state: CardState) {
        for day in sortedDays {
            guard let eventsForDay = groupedEvents[day] else {continue}
            
            let dayRow = DayTimeLineRowView()
            dayRow.configure(day, and: eventsForDay, cardState: state)
            stackView.addArrangedSubview(dayRow)
        }
    }

}

