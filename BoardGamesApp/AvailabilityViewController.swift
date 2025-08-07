//
//  AvaiabilityViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 05/08/2025.
//

import UIKit

class AvailabilityViewController: UIViewController {
    @IBOutlet var addAvailabilityContainer: UIView!
    @IBOutlet var addAvailabilityTitle: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var chooseDateButton: UIButton!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var durationTitleLabel: UILabel!
    @IBOutlet var durationFromButton: UIButton!
    @IBOutlet var durationToButton: UIButton!
    @IBOutlet var durationSummaryLabel: UILabel!
    @IBOutlet var repetitionLabel: UILabel!
    @IBOutlet var repetitionSwitch: UISwitch!
    @IBOutlet var gamesLimitLabel: UILabel!
    @IBOutlet var gamesLimitTextField: UITextField!
    @IBOutlet var gamesLimitButton: UIButton!
    @IBOutlet var addAvailabilityButton: UIButton!
    
    var selectedDurationFrom: Date?
    var selectedDurationTo: Date?
    
    private func updateDurationLabel() {
        guard let startTime = selectedDurationFrom, let endTime = selectedDurationTo else {
            durationLabel!.text = ""
            return
        }
        guard endTime>startTime else {
            durationLabel.text = "Niepoprawny czas!"
            durationLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            durationLabel.textColor = .red
            return
        }
        
        let difference = endTime.timeIntervalSince(startTime)
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        
        let formattedDifference = formatter.string(from: difference)
        durationLabel.text = "\(formattedDifference!)"
    }
    
    @IBAction func didTapChooseDateButton(_ sender: UIButton) {
        let datePickerViewController = UIViewController()
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .inline
        datePicker.minimumDate = Date()
        
        let selectAction = UIAction { [weak self] action in
            guard let self = self, let picker = action.sender as? UIDatePicker else { return }
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "pl_PL")
            dateFormatter.dateFormat = "E, d MMM yyyy"
            let formatedString = dateFormatter.string(from: picker.date)
            self.chooseDateButton.setTitle(formatedString, for: .normal)
            updateDurationLabel()
            datePickerViewController.dismiss(animated: true)
        }
        datePicker.addAction(selectAction, for: .valueChanged)
        datePickerViewController.view.addSubview(datePicker)
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: datePickerViewController.view.topAnchor),
            datePicker.leadingAnchor.constraint(equalTo: datePickerViewController.view.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: datePickerViewController.view.trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: datePickerViewController.view.bottomAnchor)
        ])
        
        if let sheet = datePickerViewController.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        present(datePickerViewController, animated: true)
        
    }
    
    @IBAction func didTapDurationFromButton(_ sender: UIButton) {
        let timePickerController = UIViewController()
        let timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.minuteInterval = 5
        let calendar = Calendar.current
        let minTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())
        let maxTime = calendar.date(bySettingHour: 21, minute: 30, second: 0, of: Date())
        timePicker.minimumDate = minTime
        timePicker.maximumDate = maxTime
        
        let selectAction = UIAction { [weak self] action in
            guard let self = self, let timePicker = action.sender as? UIDatePicker else { return }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let formattedTime = dateFormatter.string(from: timePicker.date)
            selectedDurationFrom = timePicker.date
            self.durationFromButton.setTitle(formattedTime, for: .normal)
            updateDurationLabel()
            timePickerController.dismiss(animated: true)
        }
        timePicker.addAction(selectAction, for: .valueChanged)
        timePickerController.view.addSubview(timePicker)
        
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timePicker.topAnchor.constraint(equalTo: timePickerController.view.topAnchor),
            timePicker.leadingAnchor.constraint(equalTo: timePickerController.view.leadingAnchor),
            timePicker.trailingAnchor.constraint(equalTo: timePickerController.view.trailingAnchor),
            timePicker.bottomAnchor.constraint(equalTo: timePickerController.view.bottomAnchor)
        ])
        
        if let sheet = timePickerController.sheetPresentationController {
            sheet.detents = [.custom(resolver: {context in return 300})]
        }
        present(timePickerController, animated: true)
        
        
    }
    
    @IBAction func didTapDurationToButton(_ sender: UIButton) {
        let timePickerController = UIViewController()
        let timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        timePicker.preferredDatePickerStyle = .wheels
        timePicker.minuteInterval = 5
        let calendar = Calendar.current
        let minTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())
        let maxTime = calendar.date(bySettingHour: 22, minute: 5, second: 0, of: Date())
        timePicker.minimumDate = minTime
        timePicker.maximumDate = maxTime
        
        let selectAction = UIAction { [weak self] action in
            guard let self = self, let timePicker = action.sender as? UIDatePicker else { return }
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let formattedTime = dateFormatter.string(from: timePicker.date)
            selectedDurationTo = timePicker.date
            updateDurationLabel()
            self.durationToButton.setTitle(formattedTime, for: .normal)
            timePickerController.dismiss(animated: true)
        }
        
        timePicker.addAction(selectAction, for: .valueChanged)
        timePickerController.view.addSubview(timePicker)
        
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timePicker.topAnchor.constraint(equalTo: timePickerController.view.topAnchor),
            timePicker.bottomAnchor.constraint(equalTo: timePickerController.view.bottomAnchor),
            timePicker.leadingAnchor.constraint(equalTo: timePickerController.view.leadingAnchor),
            timePicker.trailingAnchor.constraint(equalTo: timePickerController.view.trailingAnchor)
        ])
        
        if let sheet = timePickerController.sheetPresentationController {
            sheet.detents = [.custom(resolver: {context in return 300})]
        }
        present(timePickerController, animated: true)
        
    }
    
    @IBAction func didChangedRepetitionSwitch(_ sender: UISwitch) {
    }
    
    @IBAction func didTapGamesLimitButton(_ sender: Any) {
    }
    
    @IBAction func didTapAddAvailabilityButton(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

}
