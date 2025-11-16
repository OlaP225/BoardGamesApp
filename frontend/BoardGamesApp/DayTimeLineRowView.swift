//
//  DayTimeLineRowView.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 04/08/2025.
//

import UIKit

class DayTimeLineRowView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var timelineDotView: UIView!
    @IBOutlet var collectionView: UICollectionView!
    
    var cardDisplayState: CardState = .active
    var onRequestLeaveEvent: ((Int) -> Void)?
    
    var eventsForThisDay = [GameEvent]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    func configure(_ date: Date, and events: [GameEvent], cardState: CardState) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pl_PL")
        dateFormatter.dateFormat = "E"
        dayLabel.text =  dateFormatter.string(from: date).capitalized.replacingOccurrences(of: ".", with: "")
        
        dateFormatter.dateFormat = "d MMM"
        dateLabel.text = dateFormatter.string(from: date)
            
        self.eventsForThisDay = events
        self.cardDisplayState = cardState
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
        guard let view = Bundle.main.loadNibNamed("DayTimeLineRowView", owner: self, options: nil)?.first as? UIView else {
            print(" Could not load DayTimeLineRowView from nib")
            return
        }
        contentView = view
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.backgroundColor = .clear
        contentView.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        dayLabel.backgroundColor = .clear
        dateLabel.backgroundColor = .clear
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(GameCardCollectionViewCell.self, forCellWithReuseIdentifier: "GameCardCell")
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
        
        
        
    }

}

extension DayTimeLineRowView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return eventsForThisDay.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCardCell", for: indexPath) as? GameCardCollectionViewCell else {
            return UICollectionViewCell()
        }
        let event = eventsForThisDay[indexPath.item]

        let currentUserID = UserDefaults.standard.string(forKey: "userID") ?? ""
        let isUserJoined = event.participantsIDs.contains(currentUserID)

        cell.gameCardView.configure(with: event, state: self.cardDisplayState, isUserJoined: isUserJoined)

        cell.onLeaveJoinButtonTapped = { [weak self] in
            guard let self = self else { return }
            if isUserJoined {
                self.onRequestLeaveEvent?(event.id)
            } else {
                self.onRequestLeaveEvent?(event.id)
            }
        }

        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = 200
        let height: CGFloat = 80
        
        return CGSize(width: width, height: height)
    }
}
