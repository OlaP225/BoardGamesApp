//
//  AvailabilityTableViewCell.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 08/08/2025.
//

import UIKit

class AvailabilityTableViewCell: UITableViewCell {
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var editButton: UIButton!
    @IBOutlet var removeButton: UIButton!
    @IBOutlet var cellBackground: UIView!
    
    var deleteButtonTapped: (() -> Void)?
    
    @IBAction func editAvailability(_ sender: UIButton) {
    }
    @IBAction func removeAvailability(_ sender: UIButton) {
        deleteButtonTapped?()
    }
    static let identifier = "AvailabilityTableViewCell"
    
    func configure(with slot: AvailabilitySlot) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "PL_pl")
        dateFormatter.dateFormat = "EEEE, d MMM"
        
        let formattedDate = dateFormatter.string(from: slot.date).capitalized
    
        dateLabel.text = formattedDate
        timeLabel.text = slot.time
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellBackground.layer.cornerRadius = 15
        cellBackground.layer.borderColor = UIColor.systemGray5.cgColor
        cellBackground.layer.borderWidth = 1
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
