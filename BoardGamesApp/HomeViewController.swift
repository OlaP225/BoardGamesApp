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
    
    let scrollView = UIScrollView()
    let daysStackView = UIStackView()
    
    
    var events: [GameEvent] = [
        GameEvent(title: "Monopoly", currentPlayersCount: 3, maxPlayersCount: 4, time: "10:00 - 12:00", location: "Planty Racławickie", date: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 2))!),
        GameEvent(title: "Catan", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Planty Racławickie", date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 12))!),
        GameEvent(title: "Catan", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Planty Racławickie", date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 12))!),
        GameEvent(title: "Catan", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Planty Racławickie", date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 12))!),
        GameEvent(title: "Catan", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Planty Racławickie", date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 13))!),
        GameEvent(title: "Catan", currentPlayersCount: 2, maxPlayersCount: 4, time: "12:00 - 14:00", location: "Planty Racławickie", date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 13))!)
        ]
    var groupedEvents = [Date: [GameEvent]]()
    var sortedDays = [Date]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        upcomingTitle.text = "Nadchodzące spotkania"
        pastTitle.text = "Zakończone spotkania"
        upcomingTitle.text! += " 🗓️"
        upcomingTitle.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        pastTitle.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        groupEventsByDate()
        setupScrollViewAndStackView()
        displayTimeLine()
        

    }
    
    func groupEventsByDate(){
        groupedEvents = Dictionary(grouping: events) { event in
            return Calendar.current.startOfDay(for: event.date)
        }
        sortedDays = groupedEvents.keys.sorted()
        
    }
    
    func setupScrollViewAndStackView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
     //   scrollView.backgroundColor = .blue
        
        daysStackView.axis = .vertical
        daysStackView.spacing = 24
        scrollView.addSubview(daysStackView)
        daysStackView.translatesAutoresizingMaskIntoConstraints = false
        
        pastTitle.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: upcomingTitle.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 200),
            pastTitle.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 8),
            pastTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
            daysStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            daysStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            daysStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            daysStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            daysStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }
    
    func displayTimeLine() {
        for day in sortedDays {
            guard let eventsForDay = groupedEvents[day] else {continue}
            
            let dayRow = DayTimeLineRowView()
            dayRow.configure(day, and: eventsForDay)
            daysStackView.addArrangedSubview(dayRow)
        }
    }

}
