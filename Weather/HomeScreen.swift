//
//  ViewController.swift
//  Weather
//
//  Created by Admin on 27/03/21.
//  Copyright © 2021 Satish. All rights reserved.
//

import UIKit

struct Place {
    var name: String
    var temprature: String    
}

class HomeScreen: UIViewController {

    @IBOutlet var placesTableView: UITableView!
    var places = [Place]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placesTableView.delegate = self
        placesTableView.dataSource = self
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension HomeScreen: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension HomeScreen: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PlaceCell", for: indexPath) as? PlaceTableViewCell {
            let place = places[indexPath.row]
            cell.timeLabel.text = "time"
            cell.nameLabel.text = place.name
            cell.tempratureLabel.text = place.temprature
            return cell
        
        }
        // Should well test at developmet time
        return UITableViewCell()
    }
}

