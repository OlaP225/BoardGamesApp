//
//  GameCardCell.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 22/08/2025.
//

import UIKit

class GameCardCell: UITableViewCell {
    
    static let identifier = "GameCardCell"
    
    let gameCardView = GameCardView()
    var onLeaveJoinButtonTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        self.backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(gameCardView)
        gameCardView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            gameCardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            gameCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            gameCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            gameCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        gameCardView.onLeaveJoinButtonTapped = { [weak self] in
            self?.onLeaveJoinButtonTapped?()
            
        }
    }
    func configure(with event: GameEvent, isUserJoined: Bool){
        gameCardView.configure(with: event, state: .active, isUserJoined: isUserJoined)
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
