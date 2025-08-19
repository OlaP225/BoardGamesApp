//
//  EventsCalendarViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 19/08/2025.
//

import UIKit

class EventsCalendarViewController: UIViewController {
    @IBOutlet var calendarContainerView: UIView!
    
    let calendarView = UICalendarView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCalendar()

    }
    private func setupCalendar() {
        calendarView.delegate = self
        calendarView.locale = Locale(identifier: "pl_PL")
        calendarView.layer.cornerRadius = 15
        calendarView.layer.borderWidth = 1
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
    
}

extension EventsCalendarViewController: UICalendarViewDelegate {

}

