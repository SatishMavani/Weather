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
    }

    @IBAction func addPlaces(_ sender: UIButton) {
        
        let locationPicker = LocationPickerViewController()
        print("called")
        // ignored if initial location is given, shows that location instead
        locationPicker.showCurrentLocationInitially = true // default: true
        
        locationPicker.completion = { location in
            // do some awesome stuff with location
            if let loc = location {
                print("called")
//                self.cityList.addToHistory(loc)
//                self.refresh()
            }
        }
        
        self.navigationController?.present(locationPicker, animated: true, completion: nil)
        
//        self.present(locationPicker, animated: true, completion: nil)
//        navigationController?.pushViewController(locationPicker, animated: true)
        
        
//        let mapView = MapScreen()
//        self.present(mapView, animated: true, completion: nil)
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

