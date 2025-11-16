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
    
    var upcomingEvents: [GameEvent] = []
    
    var pastEvents: [GameEvent] = []
    
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
        setupScrollViewAndStackView()
        setUpPastScrollViewAndStackView()
        loadEventsFromServer()

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
    private func loadEventsFromServer() {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else {
            print("No userID in UserDefaults")
            return
        }
        
        APIService.shared.fetchUserEvents(userID: userID) { [weak self] events in
            guard let self = self else { return }
            let now = Date()
            self.upcomingEvents = events.filter { $0.date >= now }.sorted { $0.date < $1.date }
            self.pastEvents = events.filter { $0.date < now }.sorted { $0.date > $1.date }
            DispatchQueue.main.async {
                self.reloadEventViews()
            }
        }
    }
    
    private func reloadEventViews() {
        clearStackView(daysStackView)
        clearStackView(stackViewPastDays)
        setUpcomingEvents()
        setUpPastEvents()
    }
    
    private func clearStackView(_ sv: UIStackView) {
        for view in sv.arrangedSubviews {
            sv.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
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
        displayTimeLine(for: upcomingData.sortedDays, with: upcomingData.groupedEvents, to: daysStackView, state: .active)
    }
    
    func setUpPastEvents() {
        let pastData = groupAndSort(events: pastEvents)
        displayTimeLine(for: pastData.sortedDays, with: pastData.groupedEvents, to: stackViewPastDays, state: .past)
        
    }
    
    func setupScrollViewAndStackView() {
        if scrollView.superview == nil {
            view.addSubview(scrollView)
            scrollView.translatesAutoresizingMaskIntoConstraints = false
        }
        
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
        if scrollViewPastEvents.superview == nil {
            view.addSubview(scrollViewPastEvents)
            scrollViewPastEvents.translatesAutoresizingMaskIntoConstraints = false
        }
        
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

