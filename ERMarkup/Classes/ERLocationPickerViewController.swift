//
//  ERLocationPickerViewController.swift
//  Pods
//
//  Created by Eric Nguyen on 9/4/20.
//

import UIKit
import MapKit

public class ERLocationPickerViewController: UIViewController {

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
    
    public override func viewDidLoad() {
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
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
    }
}

extension ERLocationPickerViewController: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapView.removeAnnotations(mapView.annotations)
        mapPin.alpha = 1
        
    }
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("Map view center will be :\(mapView.centerCoordinate)")
        selectLocation(location: CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude))
        mapPin.alpha = 0
    }
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        
        let pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotation")
        // drop only on long press gesture
        let fromLongPress = annotation is MKPointAnnotation
        pin.animatesDrop = fromLongPress
        pin.rightCalloutAccessoryView = selectLocationButton()
        pin.canShowCallout = true
        return pin
    }
    
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
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
public struct Location {
    public var lat: Double          = 0
    public var long: Double         = 0
    public var address: Address?
    
    public init(lat: Double, long: Double, address: Address?) {
        self.lat = lat
        self.long = long
        self.address = address
    }
    
    public var locationString: String {
        return "\(lat),\(long)"
    }
}

public struct Address {
    
    // MARK: - Properties
    
    public var street: String?
    public var building: String?
    public var apt: String?
    public var zip: String?
    public var city: String?
    public var state: String?
    public var country: String?
    public var ISOcountryCode: String?
    public var timeZone: TimeZone?
    public var latitude: CLLocationDegrees?
    public var longitude: CLLocationDegrees?
    public var placemark: CLPlacemark?
    
    // MARK: - Types
    
    public init(placemark: CLPlacemark) {
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
    
    public var coordinates: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude ?? 0.0, longitude: longitude ?? 0.0)
    }
    
    public var line: String? {
        return [line1, line2].compactMap{$0}.joined(separator: ", ")
    }
    
    public var line1: String? {
        return [[building, street].compactMap{$0}.joined(separator: " "), apt].compactMap{$0}.joined(separator: ", ")
    }
    
    public var line2: String? {
        return [[city, zip].compactMap{$0}.joined(separator: " "), country].compactMap{$0}.joined(separator: ", ")
    }
}
