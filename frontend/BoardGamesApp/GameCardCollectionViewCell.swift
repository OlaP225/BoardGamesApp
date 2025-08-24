//
//  GameCardCollectionViewCell.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 05/08/2025.
//

import UIKit

class GameCardCollectionViewCell: UICollectionViewCell {

    let gameCardView = GameCardView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder) has not been implemented")
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
