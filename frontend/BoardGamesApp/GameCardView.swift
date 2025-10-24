//
//  GameCardView.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 02/08/2025.
//

enum CardState {
    case active
    case past
}

import UIKit
@IBDesignable
class GameCardView: UIView {
    @IBOutlet var contentView : UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var peopleLabel: UILabel!
    @IBOutlet var leaveJoinButton: UIButton!
    @IBOutlet var detailsButton: UIButton!
    
    var onDetailsButtonTapped: (() -> Void)?
    var onLeaveJoinButtonTapped: (() -> Void)?
    

    @IBAction func didTapDetailsButton(_ sender: UIButton) {
    }
    
    @IBAction func didTapLeaveJoinButton(_ sender: UIButton) {
        onLeaveJoinButtonTapped?()
    }
    
    
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
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: self.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
    
    func configure(with event: GameEvent, state: CardState = .active, isUserJoined: Bool){
        titleLabel.text = event.title
        timeLabel.text = event.time
        locationLabel.text = event.location
        peopleLabel.text = "\(event.currentPlayersCount)/\(event.maxPlayersCount)"
        leaveJoinButton.layer.cornerRadius = 8
        
        switch state {
        case .active:
            titleLabel.textColor = .black
            timeLabel.textColor = .black
            locationLabel.textColor = .black
            peopleLabel.textColor = .black
            contentView.backgroundColor = UIColor(named: "ActiveCardBackground")
            
        case .past:
            titleLabel.textColor = .black
            timeLabel.textColor = .black
            locationLabel.textColor = .black
            peopleLabel.textColor = .black
            contentView.backgroundColor = UIColor(named: "InactiveCardBackground")
        }
        
        if isUserJoined {
            leaveJoinButton.setTitle("Opuść", for: .normal )
           // leaveJoinButton.backgroundColor = .systemRed
           //leaveJoinButton.tintColor = .white
        } else {
            leaveJoinButton.setTitle("Dołącz", for: .normal)
            //leaveJoinButton.backgroundColor = .systemBlue
            //leaveJoinButton.tintColor = .white
        }
        

    }
    
}
