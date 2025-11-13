//
//  NotificationsTableViewCell.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 03/11/2025.
//

import UIKit

protocol NotificationsTableViewCellDelegate: AnyObject {
    func notificationCell(_ cell: NotificationsTableViewCell, didTapAcceptFor notification: NotificationItem)
    func notificationCell(_ cell: NotificationsTableViewCell, didTapRejectFor notification: NotificationItem)
}

class NotificationsTableViewCell: UITableViewCell {
    
    static let identifier = "NotificationsTableViewCell"
    
    @IBOutlet var notiMessage: UILabel!
    @IBOutlet var notiDate: UILabel!
    @IBOutlet var acceptButton: UIButton!
    @IBOutlet var rejectButton: UIButton!

    weak var delegate: NotificationsTableViewCellDelegate?
    var notificationItem: NotificationItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    func configure(with notification: NotificationItem) {
        self.notificationItem = notification
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pl_PL")
        dateFormatter.dateFormat = "d MMM, HH:mm"
        notiDate.text = dateFormatter.string(from: notification.date)
        
        notiMessage.text = notification.message
        notiMessage.numberOfLines = 0
        let shouldShowButtons = (notification.type == .action)
        acceptButton.isHidden = !shouldShowButtons
        rejectButton.isHidden = !shouldShowButtons
        
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
        acceptButton.setTitle("Akceptuj", for: .normal)
        rejectButton.setTitle("Odrzuć", for: .normal)
        

    }
    
    @IBAction func didTapAcceptButton(_ sender: UIButton){
        if let notification = notificationItem {
            delegate?.notificationCell(self, didTapAcceptFor: notification)
        }
        
    }
    @IBAction func didTapRejectButton(_ sender: UIButton) {
        if let notification = notificationItem {
            delegate?.notificationCell(self, didTapRejectFor: notification)
        }
    }
    
    private func setupUI() {
        acceptButton.layer.cornerRadius = 8
        rejectButton.layer.cornerRadius = 8
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
