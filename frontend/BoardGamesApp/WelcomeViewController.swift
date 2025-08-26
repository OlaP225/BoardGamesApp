//
//  WelcomeViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 25/08/2025.
//

import UIKit

class WelcomeViewController: UIViewController {
    @IBOutlet var welcomeLabel: UILabel!
    @IBOutlet var greetingLabel: UILabel!
    @IBOutlet var textFiled: UITextField!
    @IBOutlet var startButton: UIButton!
    
    @IBAction func didTapStartButton(_ sender: UIButton) {
        guard let username = textFiled.text, !username.isEmpty else {
            let ac = UIAlertController(title: "Podaj imię", message: "To pole nie może być puste", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            return present(ac, animated: true)
        }
        let userID = UUID().uuidString
        let defaults = UserDefaults.standard
        defaults.set(userID, forKey: "userID")
        defaults.set(username, forKey: "username")
        defaults.set(true, forKey: "userHasOnboarded")
        
        let registrationData = UserRegistrationData(username: username, userID: userID)
        APIService.shared.registerUser(userData: registrationData)
        
        switchToMainApp()
    }
    private func switchToMainApp() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainViewController = storyboard.instantiateInitialViewController()
        
        if let window = view.window {
            window.rootViewController = mainViewController
            UIView.transition(with: window, duration: 0.3,options: .transitionCrossDissolve,  animations: nil, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        welcomeLabel.text = "Witaj!"
        greetingLabel.text = "Jak się do Ciebie zwracać?"
        textFiled.placeholder = "Wpisz swoje imię"
        textFiled.textAlignment = .center
        startButton.setTitle("Zaczynajmy!", for: .normal)

    }
    
}


