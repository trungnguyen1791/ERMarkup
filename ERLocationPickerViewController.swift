//
//  ERLocationPickerViewController.swift
//  Pods
//
//  Created by Eric Nguyen on 9/4/20.
//

import UIKit
import MapKit

class ERLocationPickerViewController: UIViewController {

    @IBOutlet weak var mapPin: UIImageView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            manager.desiredAccuracy = kCLLocationAccuracyBest
        }
        return manager
    }()
    let geocoder = CLGeocoder()
    public typealias CompletionHandler = (Location?) -> ()
    
    public var completion: CompletionHandler?
    var selectedLocation: Location?
    var searchTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if #available(iOS 11.0, *) {
            let userLocationBtn = MKUserTrackingButton(mapView: mapView)
            userLocationBtn.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(userLocationBtn)
            
            NSLayoutConstraint.activate([userLocationBtn.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -10), userLocationBtn.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -10)])
        } else {
            // Fallback on earlier versions
        }
        
        searchBar.delegate = self
        mapView.delegate = self
        searchBar.isHidden = true
    }
    @IBAction func doneBtnTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func selectLocation(location: CLLocation) {
        // add point annotation to map
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        self.mapView.addAnnotation(annotation)
        annotation.title = "test callout"
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { response, error in
            if let error = error as NSError?, error.code != 10 { // ignore cancelGeocode errors
                // show error and remove annotation
                let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
                    self.mapView.removeAnnotation(annotation)
                }))
                self.present(alert, animated: true, completion: nil)
                
            } else if let placemark = response?.first {
                // get POI name from placemark if any
                
                
                let address = Address(placemark: placemark)
                
                var name = "Geofence"
                if let item = placemark.areasOfInterest?.first, item.count > 0 {
                    name = item
                }else if let item = address.street, item.count > 0 {
                    name = item
                }else if let item = address.city, item.count > 0 {
                    name = item
                }else if let item = address.country, item.count > 0 {
                    name = item
                }
                annotation.title = name
                annotation.subtitle = (address.line1 ?? "") + "\n" + (address.line2 ?? "")
                
                self.selectedLocation = Location(lat: location.coordinate.latitude, long: location.coordinate.longitude, address: address)
                self.mapView.selectAnnotation(annotation, animated: true)
            }
        }
    }
    
}

extension ERLocationPickerViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
    }
}

extension ERLocationPickerViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapView.removeAnnotations(mapView.annotations)
        mapPin.alpha = 1
        
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Map view center will be :\(mapView.centerCoordinate)")
        selectLocation(location: CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude))
        mapPin.alpha = 0
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotation")
        // drop only on long press gesture
        let fromLongPress = annotation is MKPointAnnotation
        pin.animatesDrop = fromLongPress
        pin.rightCalloutAccessoryView = selectLocationButton()
        pin.canShowCallout = true
        return pin
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //call complete with location.
        dismiss(animated: true) {
            self.completion?(self.selectedLocation)
        }
    }
    
    func selectLocationButton() -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 30))
        button.setTitle("Select", for: UIControl.State())
        if let titleLabel = button.titleLabel {
            let width = titleLabel.textRect(forBounds: CGRect(x: 0, y: 0, width: Int.max, height: 30), limitedToNumberOfLines: 1).width
            button.frame.size = CGSize(width: width + 10, height: 30.0)
        }
        button.backgroundColor = UIColor.blue
        button.setTitleColor(.white, for: UIControl.State())
        button.layer.cornerRadius = 5
        button.titleEdgeInsets.left = 5
        button.titleEdgeInsets.right = 5
        return button
    }
}
struct Location {
    var lat: Double          = 0
    var long: Double         = 0
    var address: Address?
    
    public init(lat: Double, long: Double, address: Address?) {
        self.lat = lat
        self.long = long
        self.address = address
    }
}

struct Address {
    
    // MARK: - Properties
    
    var street: String?
    var building: String?
    var apt: String?
    var zip: String?
    var city: String?
    var state: String?
    var country: String?
    var ISOcountryCode: String?
    var timeZone: TimeZone?
    var latitude: CLLocationDegrees?
    var longitude: CLLocationDegrees?
    var placemark: CLPlacemark?
    
    // MARK: - Types
    
    init(placemark: CLPlacemark) {
        self.street = placemark.thoroughfare
        self.building = placemark.subThoroughfare
        self.city = placemark.locality
        self.state = placemark.administrativeArea
        self.zip = placemark.postalCode
        self.country = placemark.country
        self.ISOcountryCode = placemark.isoCountryCode
        self.timeZone = placemark.timeZone
        self.latitude = placemark.location?.coordinate.latitude
        self.longitude = placemark.location?.coordinate.longitude
        self.placemark = placemark
    }
    
    // MARK: - Helpers
    
    var coordinates: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude ?? 0.0, longitude: longitude ?? 0.0)
    }
    
    var line: String? {
        return [line1, line2].compactMap{$0}.joined(separator: ", ")
    }
    
    var line1: String? {
        return [[building, street].compactMap{$0}.joined(separator: " "), apt].compactMap{$0}.joined(separator: ", ")
    }
    
    var line2: String? {
        return [[city, zip].compactMap{$0}.joined(separator: " "), country].compactMap{$0}.joined(separator: ", ")
    }
}
