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

        let local = NotificationStore.shared.loadAll()
        self.notifications = local
        fetchNotifications()

        NotificationCenter.default.addObserver(self, selector: #selector(handleUserDidLeaveEvent(_:)), name: .userDidLeaveEvent, object: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let tabItems = tabBarController?.tabBar.items {
            let notificationsTabIndex = 2
            if tabItems.indices.contains(notificationsTabIndex) {
                tabItems[notificationsTabIndex].badgeValue = nil
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .userDidLeaveEvent, object: nil)
    }
    
    @objc private func handleUserDidLeaveEvent(_ notification: Notification) {
        if let noti = notification.object as? NotificationItem {
            print("[NotificationsVC] received userDidLeaveEvent id=\(noti.id) message=\(noti.message)")
            DispatchQueue.main.async {
                if !self.notifications.contains(where: { $0.id == noti.id }) {
                    self.notifications.insert(noti, at: 0)
                    NotificationStore.shared.add(noti)
                    NotificationCenter.default.post(name: .newNotificationAdded, object: nil)
                    self.notificationsTableView.reloadData()
                } else {
                    print("[NotificationsVC] duplicate notification ignored id=\(noti.id)")
                }
            }
            return
        }
        print("[NotificationsVC] handleUserDidLeaveEvent: object is not NotificationItem")
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
            guard let self = self else { return }
            DispatchQueue.main.async {
                print("[NotificationsVC] fetched \(fetched.count) from server")
                
                var mergedMap: [String: NotificationItem] = [:]
                for n in self.notifications {
                    mergedMap[n.id] = n
                }
                for n in fetched {
                    mergedMap[n.id] = n
                }
                let merged = Array(mergedMap.values).sorted { $0.date > $1.date }

                self.notifications = merged
                self.notificationsTableView.reloadData()
                print("[NotificationsVC] merged notifications count=\(self.notifications.count)")
                if let tabItems = self.tabBarController?.tabBar.items {
                    if tabItems.indices.contains(2) {
                        tabItems[2].badgeValue = merged.isEmpty ? nil : "●"
                    }
                }
            }
        }
    }


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

