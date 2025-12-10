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
    
    private let emptyUpcomingView = UIView()
    private let emptyUpcomingLabel = UILabel()
    private let emptyPastView = UIView()
    private let emptyPastLabel = UILabel()
    
    var upcomingEvents: [GameEvent] = []
    
    var pastEvents: [GameEvent] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        if let username = defaults.string(forKey: "username") {
            greeting.text = "Cześć, \(username)!"
         //   greeting.sizeToFit()
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
        NotificationCenter.default.addObserver(self, selector: #selector(updateNotificationsBadge), name: .newNotificationAdded, object: nil)


    }
    @objc private func updateNotificationsBadge() {
        guard let tabItems = tabBarController?.tabBar.items else { return }
        let notificationsTabIndex = 2
        if tabItems.indices.contains(notificationsTabIndex) {
            let unreadCount = NotificationStore.shared.loadAll().count
            tabItems[notificationsTabIndex].badgeValue = unreadCount > 0 ? "\(unreadCount)" : nil
            tabItems[notificationsTabIndex].badgeColor = .systemRed
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    func reloadEventViews() {
        clearStackView(daysStackView)
        clearStackView(stackViewPastDays)
        
        setUpcomingEvents()
        setUpPastEvents()
        
        updateUpcomingPlaceholderVisibility()
        updatePastPlaceholderVisibility()
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
    
    func displayTimeLine(for sortedDays: [Date], with groupedEvents: [Date: [GameEvent]], to stackView: UIStackView, state: CardState) {
        for day in sortedDays {
            guard let eventsForDay = groupedEvents[day] else { continue }
            
            let dayRow = DayTimeLineRowView()
            dayRow.configure(day, and: eventsForDay, cardState: state)
            dayRow.onRequestLeaveEvent = { [weak self] eventID in
                self?.handleLeave(eventID: eventID)
            }
            
            stackView.addArrangedSubview(dayRow)
        }
    }
    func handleLeave(eventID: Int) {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else { return }
        let event: GameEvent? = {
            if let e = self.upcomingEvents.first(where: { $0.id == eventID }) { return e }
            if let e = self.pastEvents.first(where: { $0.id == eventID }) { return e }
            return nil
        }()
        guard let foundEvent = event else {
            confirmAndLeave(eventID: eventID, userID: userID, eventToCreateNotification: nil)
            return
        }

        let title = "Potwierdź"
        let message = "Na pewno chcesz opuścić spotkanie „\(foundEvent.title)”?"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Anuluj", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Opuść", style: .destructive, handler: { [weak self] _ in
            self?.confirmAndLeave(eventID: eventID, userID: userID, eventToCreateNotification: foundEvent)
        }))

        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    private func confirmAndLeave(eventID: Int, userID: String, eventToCreateNotification: GameEvent?) {
        APIService.shared.leaveEvent(eventID: eventID, userID: userID) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.upcomingEvents.removeAll { $0.id == eventID }
                self.pastEvents.removeAll { $0.id == eventID }

                if let ev = eventToCreateNotification {
                    let dateNow = Date()
                    let idString = "leave-\(ev.id)-\(Int(dateNow.timeIntervalSince1970))"
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "d MMM, HH:mm"
                    let message = "Opuszczono spotkanie „\(ev.title)” zaplanowane na \(dateFormatter.string(from: ev.date))."

                    let noti = NotificationItem(id: idString, date: Date(), message: message, type: .info)

                    DispatchQueue.main.async {
                        NotificationStore.shared.add(noti)
                        NotificationCenter.default.post(name: .userDidLeaveEvent, object: noti)
                        NotificationCenter.default.post(name: .newNotificationAdded, object: nil)
                        print("[HomeVC] posted .userDidLeaveEvent id=\(noti.id) message=\(noti.message)")
                    }
                }

                DispatchQueue.main.async {
                    self.reloadEventViews()
                }
                
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Błąd", message: "Nie udało się opuścić wydarzenia. Spróbuj ponownie.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    private func setupEmptyUpcomingView() {
        guard emptyUpcomingView.superview == nil else { return }

        emptyUpcomingView.translatesAutoresizingMaskIntoConstraints = false
        emptyUpcomingView.backgroundColor = UIColor(named: "ActiveCardBackground")
        emptyUpcomingView.layer.cornerRadius = 12
        emptyUpcomingView.layer.shadowColor = UIColor.black.cgColor
        emptyUpcomingView.layer.shadowOpacity = 0.05
        emptyUpcomingView.layer.shadowOffset = CGSize(width: 0, height: 2)
        emptyUpcomingView.layer.shadowRadius = 6

        emptyUpcomingLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyUpcomingLabel.text = "Brak nadchodzących spotkań.\n Zaplanuj swoje dostępności na nadchodzące dni, dodaj je w panelu dostępności i poczekaj na przyporządkowanie gier :)."
        emptyUpcomingLabel.numberOfLines = 0
        emptyUpcomingLabel.textAlignment = .center
        emptyUpcomingLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        emptyUpcomingLabel.textColor = .darkGray

        emptyUpcomingView.addSubview(emptyUpcomingLabel)

        view.addSubview(emptyUpcomingView)

        NSLayoutConstraint.activate([
            emptyUpcomingView.topAnchor.constraint(equalTo: upcomingTitle.bottomAnchor, constant: 16),
            emptyUpcomingView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyUpcomingView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            emptyUpcomingView.bottomAnchor.constraint(equalTo: pastTitle.topAnchor, constant: -16),

            emptyUpcomingLabel.topAnchor.constraint(equalTo: emptyUpcomingView.topAnchor, constant: 70),
            emptyUpcomingLabel.leadingAnchor.constraint(equalTo: emptyUpcomingView.leadingAnchor, constant: 16),
            emptyUpcomingLabel.trailingAnchor.constraint(equalTo: emptyUpcomingView.trailingAnchor, constant: -16)
        ])
    }
    private func setupEmptyPastView() {
        guard emptyPastView.superview == nil else { return }

        emptyPastView.translatesAutoresizingMaskIntoConstraints = false
        emptyPastView.backgroundColor = UIColor(named: "ActiveCardBackground")
        emptyPastView.layer.cornerRadius = 12
        emptyPastView.layer.shadowColor = UIColor.black.cgColor
        emptyPastView.layer.shadowOpacity = 0.05
        emptyPastView.layer.shadowOffset = CGSize(width: 0, height: 2)
        emptyPastView.layer.shadowRadius = 6

        emptyPastLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyPastLabel.text =
           "Brak odbytych spotkań.\n"
        emptyPastLabel.numberOfLines = 0
        emptyPastLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        emptyPastLabel.textColor = .darkGray
        emptyPastLabel.textAlignment = .center

        emptyPastView.addSubview(emptyPastLabel)
        view.addSubview(emptyPastView)

        NSLayoutConstraint.activate([
            emptyPastView.topAnchor.constraint(equalTo: pastTitle.bottomAnchor, constant: 16),
            emptyPastView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyPastView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            emptyPastView.heightAnchor.constraint(equalToConstant: 220),

            emptyPastLabel.topAnchor.constraint(equalTo: emptyPastView.topAnchor, constant: 95),
            emptyPastLabel.leadingAnchor.constraint(equalTo: emptyPastView.leadingAnchor, constant: 16),
            emptyPastLabel.trailingAnchor.constraint(equalTo: emptyPastView.trailingAnchor, constant: -16),
        ])
    }

    
    
    
    
    private func updateUpcomingPlaceholderVisibility() {
        setupEmptyUpcomingView()

        if upcomingEvents.isEmpty {
            emptyUpcomingView.isHidden = false
            scrollView.isHidden = true
        } else {
            emptyUpcomingView.isHidden = true
            scrollView.isHidden = false
        }
    }
    private func updatePastPlaceholderVisibility() {
        setupEmptyPastView()

        if pastEvents.isEmpty {
            emptyPastView.isHidden = false
            scrollViewPastEvents.isHidden = true
        } else {
            emptyPastView.isHidden = true
            scrollViewPastEvents.isHidden = false
        }
    }



}
extension Notification.Name {
    static let newNotificationAdded = Notification.Name("newNotificationAdded")
}

