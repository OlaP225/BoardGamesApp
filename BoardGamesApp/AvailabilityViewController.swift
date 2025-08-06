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
    @IBOutlet var durationFromButton: UIButton!
    @IBOutlet var durationToButton: UIButton!
    @IBOutlet var durationSummaryLabel: UILabel!
    @IBOutlet var repetitionLabel: UILabel!
    @IBOutlet var repetitionSwitch: UISwitch!
    @IBOutlet var gamesLimitLabel: UILabel!
    @IBOutlet var gamesLimitTextField: UITextField!
    @IBOutlet var gamesLimitButton: UIButton!
    @IBOutlet var addAvailabilityButton: UIButton!
    
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
    
    @IBAction func didTapDurationFromButton(_ sender: Any) {
    }
    
    @IBAction func didTapDurationToButton(_ sender: Any) {
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
