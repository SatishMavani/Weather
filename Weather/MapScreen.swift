import UIKit
import MapKit
import CoreLocation

class MapScreen: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var cancelButton: UIButton!
    
    let geocoder = CLGeocoder()
    public var completion: ((Location?) -> ())?
    
    var location: Location? {
        didSet {
            if isViewLoaded {
                updateAnnotation()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // gesture recognizer for adding by tap
        let locationSelectGesture = UILongPressGestureRecognizer(
            target: self, action: #selector(addLocation(_:)))
        locationSelectGesture.delegate = self
        mapView.addGestureRecognizer(locationSelectGesture)
    }
    
    @IBAction func dismissMapView(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateAnnotation() {
        mapView.removeAnnotations(mapView.annotations)
        if let location = location {
            mapView.addAnnotation(location)
            mapView.selectAnnotation(location, animated: true)
        }
    }
    
    func selectLocation(location: CLLocation) {
        // add point annotation to map
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
        
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { response, error in
            if let error = error as NSError?, error.code != 10 { // ignore cancelGeocode errors
                // show error and remove annotation
                let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in }))
                self.present(alert, animated: true) {
                    self.mapView.removeAnnotation(annotation)
                }
            } else if let placemark = response?.first {
                // get POI name from placemark if any
                let name = placemark.areasOfInterest?.first
                
                // pass user selected location too
                self.location = Location(name: name, location: location, placemark: placemark)
            }
        }
    }
}

// MARK: MKMapViewDelegate

extension MapScreen: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotation")
        pin.pinTintColor = .green
        // drop only on long press gesture
        let fromLongPress = annotation is MKPointAnnotation
        pin.animatesDrop = fromLongPress
        pin.rightCalloutAccessoryView = selectLocationButton()
        pin.canShowCallout = !fromLongPress
        return pin
    }
    
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        completion?(location)
        presentingViewController?.dismiss(animated: true, completion: nil)
       
    }
    
    public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        let pins = mapView.annotations.filter { $0 is MKPinAnnotationView }
        assert(pins.count <= 1, "Only 1 pin allowed at a tim on map")
        
        if let userPin = views.first(where: { $0.annotation is MKUserLocation }) {
            userPin.canShowCallout = false
        }
    }
    
    func selectLocationButton() -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
        button.setTitle("Select", for: UIControlState())
        if let titleLabel = button.titleLabel {
            let width = titleLabel.textRect(forBounds: CGRect(x: 0, y: 0, width: Int.max, height: 30), limitedToNumberOfLines: 1).width
            button.frame.size = CGSize(width: width, height: 30.0)
        }
        button.setTitleColor(view.tintColor, for: UIControlState())
        return button
    }
}

// MARK: Selecting location with gesture

extension MapScreen {
    @objc func addLocation(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(point, toCoordinateFrom: mapView)
            let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            
            // clean location, cleans out old annotation too
            self.location = nil
            selectLocation(location: location)
        }
    }
}

extension MapScreen: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
