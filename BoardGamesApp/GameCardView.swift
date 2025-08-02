//
//  GameCardView.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 02/08/2025.
//

import UIKit
@IBDesignable
class GameCardView: UIView {
    @IBOutlet var contentView : UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var peopleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        guard let view = Bundle.main.loadNibNamed("GameCardView", owner: self, options: nil)?.first as? UIView else {
            print(" Could not load GameCardView from nib")
            return
        }
        contentView = view
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func configure(with event: GameEvent){
        titleLabel.text = event.title
        timeLabel.text = event.time
        locationLabel.text = event.location
        peopleLabel.text = "\(event.currentPlayersCount)/\(event.maxPlayersCount)"
    }
}
