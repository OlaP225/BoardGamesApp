//
//  NotificationsViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 03/11/2025.
//

import UIKit

class NotificationsViewController: BaseViewController {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var notificationsTableView: UITableView!
    
    var notifications: [NotificationItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        fetchNotifications()
    }
    
    private func setupUI() {
        titleLabel.text = "Twoje powiadomienia"
        notificationsTableView.backgroundColor = UIColor(named: "NotiTableBackground")
        notificationsTableView.layer.cornerRadius = 10
    }
    
    private func setupTableView() {
        notificationsTableView.delegate = self
        notificationsTableView.dataSource = self
        
        let nib = UINib(nibName: NotificationsTableViewCell.identifier, bundle: nil)
        notificationsTableView.register(nib, forCellReuseIdentifier: NotificationsTableViewCell.identifier)
        
        notificationsTableView.rowHeight = UITableView.automaticDimension
        notificationsTableView.estimatedRowHeight = 110
        
    }
    
    private func fetchNotifications() {
        guard let userID = UserDefaults.standard.string(forKey: "userID") else { return }
        APIService.shared.fetchUserNotifications(userID: userID) { [weak self] fetched in
            DispatchQueue.main.async {
                self?.notifications = fetched
                self?.notificationsTableView.reloadData()
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension NotificationsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        notifications.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NotificationsTableViewCell.identifier, for: indexPath) as? NotificationsTableViewCell else {
            fatalError("Could not dequeue NotificationsTableViewCell")
        }
        
        let notification = notifications[indexPath.section]
        cell.configure(with: notification)
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = UIColor(named: "CardBackground") ?? .white
        cell.contentView.layer.cornerRadius = 8
        cell.contentView.layer.masksToBounds = true
        
        
        return cell
    }
}


extension NotificationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 200.0
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

}

