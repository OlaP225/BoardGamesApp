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
        // Symulacja pobierania danych (w prawdziwej aplikacji pobierałbyś z API)
        notifications = [
            NotificationItem(id: "1", date: Date(), message: "Gracz Jan Kowalski zaprasza Cię do gry 'Splendor' jutro o 19:00.", type: .action),
            NotificationItem(id: "2", date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, message: "Zaproszenie od Anny Nowak na 'Terraforming Mars' zostało odrzucone.", type: .info),
            NotificationItem(id: "3",date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, message: "Nowa aktualizacja gry 'Ticket to Ride' jest dostępna!", type: .info),
            NotificationItem(id: "4",date: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!, message: "Gracz Adam Wiśniewski zaprasza Cię do gry 'Catan' dzisiaj o 20:30.", type: .action)
        ]
        
        notificationsTableView.reloadData() // Odśwież tabelę po załadowaniu danych
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
        cell.delegate = self
        cell.configure(with: notification)
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = UIColor(named: "CardBackground") ?? .white
        cell.contentView.layer.cornerRadius = 8
        cell.contentView.layer.masksToBounds = true
        
        
        return cell
    }
}

extension NotificationsViewController: NotificationsTableViewCellDelegate {
    func notificationCell(_ cell: NotificationsTableViewCell, didTapAcceptFor notification: NotificationItem) {
        print("Powiadomienie zaakceptowane: \(notification.message)")
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications.remove(at: index)
            notificationsTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }
    
    func notificationCell(_ cell: NotificationsTableViewCell, didTapRejectFor notification: NotificationItem) {
        print("Powiadomienie odrzucone: \(notification.message)")
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications.remove(at: index)
            notificationsTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }
}
extension NotificationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 120.0
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

