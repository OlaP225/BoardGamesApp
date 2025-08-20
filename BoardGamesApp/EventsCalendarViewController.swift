//
//  EventsCalendarViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 19/08/2025.
//

import UIKit

class EventsCalendarViewController: UIViewController {
    @IBOutlet var calendarContainerView: UIView!
    
    let allEvents : [GameEvent] = [
        GameEvent(title: "Monopoly", currentPlayersCount: 3, maxPlayersCount: 4, time: "10:00 - 12:00", location: "Planty Racławickie", date: Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 2))!)]
    
    let calendarView = UICalendarView()
    lazy var selection = UICalendarSelectionSingleDate(delegate: self)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCalendar()

    }
    private func setupCalendar() {
        calendarView.delegate = self
        calendarView.selectionBehavior = selection
        calendarView.locale = Locale(identifier: "pl_PL")
        calendarView.layer.cornerRadius = 15
       // calendarView.layer.borderWidth = 1
        calendarView.layer.borderColor = UIColor.systemGray5.cgColor
        calendarContainerView.addSubview(calendarView)
        
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: calendarContainerView.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: calendarContainerView.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: calendarContainerView.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: calendarContainerView.bottomAnchor)
        ])
    }
    private func presentDetails(for events: [GameEvent]){
        let detailsVC = DayDetailsViewController()
        detailsVC.events = events
        
        if let sheet = detailsVC.sheetPresentationController{
            let smallDetent = UISheetPresentationController.Detent.custom { context in
            return 350}
            sheet.detents = [smallDetent, .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 40
        }
        present(detailsVC, animated: true, completion: nil)
        
    }
    
    
}

extension EventsCalendarViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?){
        guard let selectedDateComponents = selection.selectedDate else { return }
        let calendar = Calendar.current
        guard let selectedDate = calendar.date(from: selectedDateComponents) else { return }
        
        let eventsForDay = allEvents.filter { event in
            return calendar.isDate(event.date, inSameDayAs: selectedDate)
        }
        if eventsForDay.isEmpty {
            print("Nie znaleizono wydarzeń dla tego dnia")
            return
        }
        
        presentDetails(for: eventsForDay)
    }

}

