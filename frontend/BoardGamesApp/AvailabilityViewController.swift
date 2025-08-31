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
            let ac = UIAlertController(title: "Brak danych", message: "Proszę, wybierz dzień oraz godzinę 'od' i 'do'.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Ok", style: .default))
            present(ac, animated: true)
            return
        }
        
        guard let userID = UserDefaults.standard.string(forKey: "userID") else {
            print("Nie znaleziono userID. Nie można zapisać dostępności")
            return
        }
        
        let calendar = Calendar.current
        let finalFromDate = calendar.date(bySettingHour: calendar.component(.hour, from: timeFrom), minute: calendar.component(.minute, from: timeFrom), second: calendar.component(.second, from: timeFrom), of: date)!
        let finalToDate = calendar.date(bySettingHour: calendar.component(.hour, from: timeTo), minute: calendar.component(.minute, from: timeTo), second: calendar.component(.second, from: timeTo), of: date)!
        
        guard finalToDate > finalFromDate else {
            let ac = UIAlertController(title: "Błąd", message: "Godzina 'od' nie może być późniejsza niż godzina 'do'.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Ok", style: .default))
            present(ac, animated: true)
            return
        }
        
        let availabilityData = AvailabilityCreateData(from_time: finalFromDate, to_time: finalToDate)
        // pokaż wskaźnik ładowania
        //showLoadingIndicator()
        
        APIService.shared.addAvailability(userID: userID, availabilityData: availabilityData) { [weak self] newSlotFromServer in
            guard let self = self, let newSlot = newSlotFromServer else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Błąd Sieci", message: "Nie udało się zapisać dostępności. Spróbuj ponownie.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
                return
            }
            
            DispatchQueue.main.async {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let formattedTimeFrom = timeFormatter.string(from: newSlot.from)
                let formattedTimeTo = timeFormatter.string(from: newSlot.to)
                let timeString = "\(formattedTimeFrom) - \(formattedTimeTo)"
                
                if !self.availabilities.contains(newSlot) {
                    self.availabilities.append(newSlot)
                    self.availabilities.sort()
                    self.availabilitiesTable.reloadData()
                    self.updateEmptyState()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        
    }
    private func setupUI() {
        availabilitiesTable.dataSource = self
        availabilitiesTable.delegate = self
        yourAvailabilitiesTitle.text = "Twoje dostępności"
        
        addAvailabilityContainer.layer.cornerRadius = 15
        addAvailabilityContainer.layer.borderWidth = 1
        addAvailabilityContainer.layer.borderColor = UIColor.systemGray.cgColor
    }
    
    private func setupTableView() {
        let nib = UINib(nibName: "AvailabilityTableViewCell", bundle: nil)
        availabilitiesTable.register(nib, forCellReuseIdentifier: AvailabilityTableViewCell.identifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateEmptyState()
        fetchAvailabilities()
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
        
        cell.delegate = self
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    private func fetchAvailabilities() {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else {
            print("Brak userID, nie można pobrać dostępności")
            return
        }
        
        APIService.shared.fetchAvailabilities(userID: userID) { [weak self] fetchedAvailabilities in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let slots = fetchedAvailabilities {
                    self.availabilities = slots
                    self.availabilities.sort()
                    self.availabilitiesTable.reloadData()
                    
                } else {
                    print("Nie udało się pobrać dostępności.")
                    self.availabilities = [] // Wyczyść listę w razie błędu
                    self.availabilitiesTable.reloadData()
                }
                
                
                self.updateEmptyState()
            }
        }
        
    }
}

extension AvailabilityViewController: AvailabilityTableViewCellDelegate {
    func didTapDeleteButton(on cell: AvailabilityTableViewCell) {
        guard let indexPath = availabilitiesTable.indexPath(for: cell) else { return }
        let slotToDelete = availabilities[indexPath.row]
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pl_PL")
        dateFormatter.dateFormat = "EEEE, d MMM"
        let formattedDate = dateFormatter.string(from: slotToDelete.from)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let fromTime = timeFormatter.string(from: slotToDelete.from)
        let toTime = timeFormatter.string(from: slotToDelete.to)
        
        let alert = UIAlertController(title: "Potwierdź usunięcie", message: "Czy na pewno chcesz usunąć dostępność \(formattedDate) od \(fromTime) do \(toTime)?", preferredStyle: .alert)
                
        alert.addAction(UIAlertAction(title: "Nie", style: .cancel))
        alert.addAction(UIAlertAction(title: "Tak", style: .destructive) { [weak self] _ in
            guard let self = self else {return}
            
            APIService.shared.deleteAvailability(availabilityID: slotToDelete.id) { success in
                DispatchQueue.main.async {
                    if success {
                        self.availabilities.remove(at: indexPath.row)
                        self.availabilitiesTable.deleteRows(at: [indexPath], with: .fade)
                        self.updateEmptyState()
                    } else {
                        print("Błąd podczas usuwania połączenia sieciowego.")
                    }
                }
                
            }
            
        })
        present(alert, animated: true)
    }
}
