//
//  AvailabilityViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 05/08/2025.
//

import UIKit

class AvailabilityViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var addAvailabilityContainer: UIView!
    @IBOutlet var addAvailabilityTitle: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var chooseDateButton: UIButton!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var durationTitleLabel: UILabel!
    @IBOutlet var durationFromButton: UIButton!
    @IBOutlet var durationToButton: UIButton!
    @IBOutlet var durationSummaryLabel: UILabel!
    @IBOutlet var addAvailabilityButton: UIButton!
    @IBOutlet var availabilitiesTable: UITableView!
    @IBOutlet var yourAvailabilitiesTitle: UILabel!
    
    var availabilities = [AvailabilitySlot]()
    
    var selectedDay: Date?
    var selectedDurationFrom: Date?
    var selectedDurationTo: Date?
    
    private func updateEmptyState() {
        if availabilities.isEmpty {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: availabilitiesTable.bounds.size.width, height: availabilitiesTable.bounds.size.height))
            messageLabel.text = "Twoja lista dostępności jest pusta.\nDodaj swoje wolne terminy powyżej, aby nasz system mógł znaleźć dla Ciebie najlepsze gry."
            messageLabel.textColor = .secondaryLabel
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont.systemFont(ofSize: 15)
            messageLabel.sizeToFit()
            
            availabilitiesTable.backgroundView = messageLabel
            availabilitiesTable.backgroundView?.layer.cornerRadius = 15
            availabilitiesTable.backgroundView?.layer.borderWidth = 1
            availabilitiesTable.backgroundView?.layer.borderColor = UIColor.systemGray4.cgColor
        } else {
            availabilitiesTable.backgroundView = nil }
    }
    
    private func removePastAvailabilities() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        
        availabilities.removeAll(){ slot in
            return slot.date < todayStart
        }
        availabilitiesTable.reloadData()
    }
    
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
        datePicker.backgroundColor = .white
        datePicker.minimumDate = Date()
        
        let selectAction = UIAction { [weak self] action in
            guard let self = self, let picker = action.sender as? UIDatePicker else { return }
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "pl_PL")
            dateFormatter.dateFormat = "EEEE, d MMM yyyy"
            let formatedString = dateFormatter.string(from: picker.date)
            self.chooseDateButton.setTitle(formatedString, for: .normal)
            selectedDay = picker.date
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
        timePicker.backgroundColor = .white
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
        timePicker.backgroundColor = .white
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
    
    @IBAction func didTapAddAvailabilityButton(_ sender: Any) {
        
        guard let date = selectedDay, let timeFrom = selectedDurationFrom, let timeTo = selectedDurationTo else {
            print("Wypełnij wszystkie pola!!")
            return
        }
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let formattedTimeFrom = timeFormatter.string(from: timeFrom)
        let formattedTimeTo = timeFormatter.string(from: timeTo)
        let time = "\(formattedTimeFrom) - \(formattedTimeTo)"
        
        let newSlot = AvailabilitySlot(date: date, time: time)
        
        if !availabilities.contains(newSlot) {
            availabilities.append(newSlot)
            availabilities.sort()
            if let newIndex = availabilities.firstIndex(of: newSlot) {
                let indexPath = IndexPath(row: newIndex, section: 0)
                availabilitiesTable.insertRows(at: [indexPath], with: .automatic)
            }
            updateEmptyState()
        } else {
            let ac = UIAlertController(title: "Podaj nową dostepność." , message: "Taka dostępność już istnieje!", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Ok", style: .cancel))
            present(ac, animated: true)
        }
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        availabilitiesTable.dataSource = self
        availabilitiesTable.delegate = self
        yourAvailabilitiesTitle.text = "Twoje dostępności"
        
        addAvailabilityContainer.layer.cornerRadius = 15
        addAvailabilityContainer.layer.borderWidth = 1
        addAvailabilityContainer.layer.borderColor = UIColor.systemGray.cgColor
        
        let nib = UINib(nibName: "AvailabilityTableViewCell", bundle: nil)
        availabilitiesTable.register(nib, forCellReuseIdentifier: AvailabilityTableViewCell.identifier)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        removePastAvailabilities()
        updateEmptyState()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availabilities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AvailabilityTableViewCell.identifier, for: indexPath) as? AvailabilityTableViewCell else {
            fatalError("Could not dequeue cell with identifier: \(AvailabilityTableViewCell.identifier)")
        }
        let slot = availabilities[indexPath.row]
        cell.configure(with: slot)
        
        cell.deleteButtonTapped = { [weak self] in
            guard let self = self else { return }
            
            let rowToDelete = availabilities[indexPath.row]
            let dateFormatter =  DateFormatter()
            dateFormatter.locale = Locale(identifier: "PL_pl")
            dateFormatter.dateFormat = "EEEE, d MMM"
            let formattedDate = dateFormatter.string(from: rowToDelete.date)
        
            
            let ac = UIAlertController(title: "Potwierdź usunięcie", message: "Czy na pewno chcesz usunąć dostępność \(formattedDate) o \(rowToDelete.time)?", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Nie", style: .cancel))
            ac.addAction(UIAlertAction(title: "Tak", style: .destructive){ _ in
                self.availabilities.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.updateEmptyState()
            })
            self.present(ac, animated: true)
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

}
