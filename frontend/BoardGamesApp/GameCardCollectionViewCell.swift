//
//  GameCardCollectionViewCell.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 05/08/2025.
//

import UIKit

class GameCardCollectionViewCell: UICollectionViewCell {
    let gameCardView = GameCardView()
    var onLeaveJoinButtonTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
        gameCardView.onLeaveJoinButtonTapped = { [weak self] in
            self?.onLeaveJoinButtonTapped?()
        }
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCard()
        gameCardView.onLeaveJoinButtonTapped = { [weak self] in
            self?.onLeaveJoinButtonTapped?()
        }
    }
    
    private func setupCard() {
        contentView.addSubview(gameCardView)
        gameCardView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            gameCardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            gameCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gameCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gameCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
}

