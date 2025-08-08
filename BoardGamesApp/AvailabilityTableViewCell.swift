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
    
    @IBAction func editAvailability(_ sender: UIButton) {
    }
    @IBAction func removeAvailability(_ sender: UIButton) {
    }
    static let identifier = "AvailabilityTableViewCell"
    
    func configure(with slot: AvailabilitySlot) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "PL_pl")
        dateFormatter.dateFormat = "E, d MMM"
        
        let formattedDate = dateFormatter.string(from: slot.date)
    
        dateLabel.text = formattedDate
        timeLabel.text = slot.time
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
