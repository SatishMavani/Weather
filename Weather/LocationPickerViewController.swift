//
//  LocationPickerViewController.swift
//  OpenWeather
//
//  Created by Satish Mavani on 10/14/18.
//  Copyright © 2018 SM. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

open class LocationPickerViewController: UIViewController {
    struct CurrentLocationListener {
        let once: Bool
        let action: (CLLocation) -> ()
    }
    
    public var completion: ((Location?) -> ())?
    
    // region distance to be used for creation region when user selects place from search results
    public var resultRegionDistance: CLLocationDistance = 600
    
    /// default: true
    // public var showCurrentLocationButton = true
    
    /// default: true
    public var showCurrentLocationInitially = true
    
    /// default: true
    /// Select current location only if `location` property is nil.
    public var selectCurrentLocationInitially = true
    
    /// see `region` property of `MKLocalSearchRequest`
    /// default: false
    public var useCurrentLocationAsHint = true
    
    /// default: "Select"
    public var selectButtonTitle = "Select"
    
    lazy public var currentLocationButtonBackground: UIColor = {
        if let navigationBar = self.navigationController?.navigationBar,
            let barTintColor = navigationBar.barTintColor {
            return barTintColor
        } else { return .white }
    }()
    
    var location: Location? {
        didSet {
            if isViewLoaded {
                updateAnnotation()
            }
        }
    }
    
    static let SearchTermKey = "SearchTermKey"
    
    let locationManager = CLLocationManager()
    let geocoder = CLGeocoder()
    var localSearch: MKLocalSearch?
    
    var currentLocationListeners: [CurrentLocationListener] = []
    
    var mapView: MKMapView!
    var locationButton: UIButton?
    
    deinit {
        geocoder.cancelGeocode()
    }
    
    open override func loadView() {
        mapView = MKMapView(frame: UIScreen.main.bounds)
        mapView.mapType = .standard
        view = mapView
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        mapView.delegate = self
        
        // gesture recognizer for adding by tap
        let locationSelectGesture = UILongPressGestureRecognizer(
            target: self, action: #selector(addLocation(_:)))
        locationSelectGesture.delegate = self
        mapView.addGestureRecognizer(locationSelectGesture)
        
        definesPresentationContext = true
        
        // user location
        mapView.userTrackingMode = .none
        mapView.showsUserLocation = showCurrentLocationInitially
        
        if useCurrentLocationAsHint {
            getCurrentLocation()
        }
    }
    
    open override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    var presentedInitialLocation = false
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let button = locationButton {
            button.frame.origin = CGPoint(
                x: view.frame.width - button.frame.width - 16,
                y: view.frame.height - button.frame.height - 20
            )
        }
        
        // setting initial location here since viewWillAppear is too early, and viewDidAppear is too late
        if !presentedInitialLocation {
            setInitialLocation()
            presentedInitialLocation = true
        }
    }
    
    func setInitialLocation() {
        if let location = location {
            // present initial location if any
            self.location = location
            showCoordinates(location.coordinate, animated: false)
            return
        } else if showCurrentLocationInitially || selectCurrentLocationInitially {
            if selectCurrentLocationInitially {
                let listener = CurrentLocationListener(once: true) { [weak self] location in
                    if self?.location == nil { // user hasn't selected location still
                        self?.selectLocation(location: location)
                    }
                }
                currentLocationListeners.append(listener)
            }
            showCurrentLocation(false)
        }
    }
    
    func getCurrentLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    @objc func currentLocationPressed() {
        showCurrentLocation()
    }
    
    func showCurrentLocation(_ animated: Bool = true) {
        let listener = CurrentLocationListener(once: true) { [weak self] location in
            self?.showCoordinates(location.coordinate, animated: animated)
        }
        currentLocationListeners.append(listener)
        getCurrentLocation()
    }
    
    func updateAnnotation() {
        mapView.removeAnnotations(mapView.annotations)
        if let location = location {
            mapView.addAnnotation(location)
            mapView.selectAnnotation(location, animated: true)
        }
    }
    
    func showCoordinates(_ coordinate: CLLocationCoordinate2D, animated: Bool = true) {
        //        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: resultRegionDistance, longitudinalMeters: resultRegionDistance)
        //        mapView.setRegion(region, animated: animated)
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

extension LocationPickerViewController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        currentLocationListeners.forEach { $0.action(location) }
        currentLocationListeners = currentLocationListeners.filter { !$0.once }
        manager.stopUpdatingLocation()
    }
}

// MARK: Selecting location with gesture

extension LocationPickerViewController {
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

// MARK: MKMapViewDelegate

extension LocationPickerViewController: MKMapViewDelegate {
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
    
    func selectLocationButton() -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
        button.setTitle(selectButtonTitle, for: UIControlState())
        if let titleLabel = button.titleLabel {
            let width = titleLabel.textRect(forBounds: CGRect(x: 0, y: 0, width: Int.max, height: 30), limitedToNumberOfLines: 1).width
            button.frame.size = CGSize(width: width, height: 30.0)
        }
        button.setTitleColor(view.tintColor, for: UIControlState())
        return button
    }
    
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        completion?(location)
        if let navigation = navigationController, navigation.viewControllers.count > 1 {
            navigation.popViewController(animated: true)
        } else {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        let pins = mapView.annotations.filter { $0 is MKPinAnnotationView }
        assert(pins.count <= 1, "Only 1 pin annotation should be on map at a time")
        
        if let userPin = views.first(where: { $0.annotation is MKUserLocation }) {
            userPin.canShowCallout = false
        }
    }
}

extension LocationPickerViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

