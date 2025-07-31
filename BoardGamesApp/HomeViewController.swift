//
//  HomeViewController.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 29/07/2025.
//

import UIKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var greeting: UILabel!
    @IBOutlet var upcomingGames: UITableView!
    @IBOutlet var pastGames: UITableView!
    @IBOutlet var addAviability: UIButton!
    @IBOutlet var searchMeetings: UIButton!

    @IBOutlet var upcomingTitle: UILabel!
    @IBOutlet var pastTitle: UILabel!
    
    var upcomingGamesData = ["Gra 1 - wtorek", "Gra 2 - środa"]
    var pastGamesData = ["Gra monopoly - piątek", "Gra catan - niedziela"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        upcomingGames.dataSource = self
        pastGames.dataSource = self
        upcomingGames.delegate = self
        pastGames.delegate = self
        
        upcomingGames.layer.borderColor = UIColor.gray.cgColor
        upcomingGames.layer.borderWidth = 1
        upcomingGames.layer.cornerRadius = 8
        
        pastGames.layer.borderColor = UIColor.gray.cgColor
        pastGames.layer.borderWidth = 1
        pastGames.layer.cornerRadius = 8
        
        upcomingTitle.text = "Nadchodzące spotkania"
        upcomingTitle.font = UIFont.boldSystemFont(ofSize: 18)
        pastTitle.text = "Zakończone spotkania"

    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == upcomingGames {
            return upcomingGamesData.count
        } else if tableView == pastGames{
            return pastGamesData.count
        } else {return 0}
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == upcomingGames {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UpcomingCell", for: indexPath)
            cell.textLabel?.text = upcomingGamesData[indexPath.row]
            return cell
        } else if tableView == pastGames{
            let cell = tableView.dequeueReusableCell(withIdentifier: "PastCell", for: indexPath)
            cell.textLabel?.text = pastGamesData[indexPath.row]
            return cell
            }
        else {
            return UITableViewCell()
        }
        }
    
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
