//
//  AvailabilityTableViewCell.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 08/08/2025.
//

import UIKit

protocol AvailabilityTableViewCellDelegate: AnyObject {
    func didTapDeleteButton(on cell: AvailabilityTableViewCell)
}

class AvailabilityTableViewCell: UITableViewCell {
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var removeButton: UIButton!
    @IBOutlet var cellBackground: UIView!
    
    weak var delegate: AvailabilityTableViewCellDelegate?
    
    @IBAction func removeAvailability(_ sender: UIButton) {
        delegate?.didTapDeleteButton(on: self)
    }
    
    static let identifier = "AvailabilityTableViewCell"
    
    func configure(with slot: AvailabilitySlot) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "PL_pl")
        dateFormatter.dateFormat = "EEEE, d MMM"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        
                
        let dateString = dateFormatter.string(from: slot.from).capitalized
        let fromTimeString = timeFormatter.string(from: slot.from)
        let toTimeString = timeFormatter.string(from: slot.to)
                
        dateLabel.text = dateString
        timeLabel.text = "\(fromTimeString) - \(toTimeString)"
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellBackground.layer.cornerRadius = 15
        cellBackground.layer.borderColor = UIColor.systemGray3.cgColor
        cellBackground.layer.borderWidth = 1
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
