//
//  NotificationsTableViewCell.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 03/11/2025.
//

import UIKit

class NotificationsTableViewCell: UITableViewCell {
    
    @IBOutlet var notiMessage: UILabel!
    @IBOutlet var notiDate: UILabel!
    
    static let identifier = "NotificationsTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(with notification: NotificationItem) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pl_PL")
        dateFormatter.dateFormat = "d MMM, HH:mm"
        notiDate.text = dateFormatter.string(from: notification.date)
        
        notiMessage.text = notification.message
        notiMessage.numberOfLines = 0
        
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.masksToBounds = false
        

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
