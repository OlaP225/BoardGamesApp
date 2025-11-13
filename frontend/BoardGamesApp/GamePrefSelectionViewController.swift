//
//  GamePrefSelectionViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 12/11/2025.
//

import UIKit

protocol GamePrefSelectionDelegate: AnyObject {
    func gamePrefSelectionDidFinish(preferences: [Int])
}

class GamePrefSelectionViewController: UITableViewController {

    weak var delegate: GamePrefSelectionDelegate?
    
    let options = [
        "Zaznacz wszystkie",
        "Strategiczne",
        "Karciane",
        "Imprezowe",
        "Przygodowe",
        "Kooperacyjne"
    ]
    var selected: [Bool] = [false, false, false, false, false, false]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Wybierz typy gier"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Gotowe", style: .done, target: self, action: #selector(doneTapped))
    }
    
    @objc func doneTapped() {
        var prefs5: [Int]
        if selected[0] {
            prefs5 = [1,1,1,1,1]
        } else {
            prefs5 = selected.dropFirst().map { $0 ? 1 : 0 }
        }
        delegate?.gamePrefSelectionDidFinish(preferences: prefs5)
        dismiss(animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { options.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = options[indexPath.row]
        cell.accessoryType = selected[indexPath.row] ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        selected[indexPath.row].toggle()

        if indexPath.row == 0 {
            if selected[0] {
                for i in 0..<selected.count { selected[i] = true }
            } else {
                for i in 0..<selected.count { selected[i] = false }
            }
        } else {
            if selected[0] && !selected[indexPath.row] {
                selected[0] = false
            }
            let allNonFirstChecked = selected.enumerated().filter { $0.offset != 0 }.allSatisfy { $0.element }
            selected[0] = allNonFirstChecked
        }

        tableView.reloadData()
    }

}
