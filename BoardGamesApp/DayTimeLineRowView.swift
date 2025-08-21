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
        cell.gameCardView.configure(with: event, state: self.cardDisplayState)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Chcemy, żeby wysokość była obliczana automatycznie,
        // ale szerokość musi być zdefiniowana.
        
        // Ustawmy szerokość na jakąś rozsądną wartość, np. 240 punktów.
        // Możesz tu poeksperymentować.
        let width: CGFloat = 200
        
        // Dla wysokości używamy specjalnej wartości, która mówi systemowi:
        // "Oblicz wysokość automatycznie na podstawie zawartości i ograniczeń".
        let height: CGFloat = 80
        
        return CGSize(width: width, height: height)
    }
}
