//
//  ERLocationPickerViewController.swift
//  Pods
//
//  Created by Eric Nguyen on 9/4/20.
//

import UIKit
import MapKit
import Contacts


public class ERLocationPickerViewController: UIViewController {

    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var mapPin: UIImageView!
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
    var localSearch: MKLocalSearch?
    var historyManager = SearchHistoryManager()
    
    public var locationPickerSuccessMessage: String = "Location successfully selected"
    public var locationPickerSuccessTitle: String = "Success"
    public var selectTitle: String = "Select"
    public var cancelTitle: String = "Cancel"
    
    lazy var results: LocationPickerResultsViewController = {
       let results = LocationPickerResultsViewController()
        results.onSelectLocation = {[weak self] in self?.selectLocationFromSearch($0) }
        results.searchHistoryLb = "History"
        return results
    }()
    
    lazy var searchController: UISearchController = {
        $0.delegate = self
        $0.searchResultsUpdater = self
        $0.searchBar.delegate = self
        $0.dimsBackgroundDuringPresentation = true
        /// true if search bar in tableView header
        $0.hidesNavigationBarDuringPresentation = false
//        $0.searchBar.placeholder = searchBarPlaceholder
        $0.searchBar.barStyle = .black
        $0.searchBar.searchBarStyle = .minimal
//        $0.searchBar.searchTextField.textColor = UIColor.darkGray
//        $0.searchBar.textField?.setPlaceHolderTextColor(UIColor(hex: 0xf8f8f8))
//        $0.searchBar.textField?.clearButtonMode = .whileEditing
        return $0
    }(UISearchController(searchResultsController: results))
    fileprivate lazy var searchViewTest: UIView = UIView()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        
        
        // Do any additional setup after loading the view.
        if #available(iOS 11.0, *) {
            let userLocationBtn = MKUserTrackingButton(mapView: mapView)
            userLocationBtn.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(userLocationBtn)
            
            NSLayoutConstraint.activate([userLocationBtn.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -15), userLocationBtn.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -10)])
        } else {
            // Fallback on earlier versions
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
            self.searchView.addSubview(self.searchController.searchBar)
            self.results.view.layer.cornerRadius = 10
//            self.searchController.searchBar.translatesAutoresizingMaskIntoConstraints = false
            self.searchController.searchBar.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            self.searchController.searchBar.sizeToFit()
        }
        
//        NSLayoutConstraint(item: searchController.searchBar, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: searchView, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0).isActive = true
//       NSLayoutConstraint(item: searchController.searchBar, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: searchView, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0).isActive = true
//       NSLayoutConstraint(item: searchController.searchBar, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: searchView, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0).isActive = true
//       NSLayoutConstraint(item: searchController.searchBar, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 56).isActive = true
        
        
        mapView.delegate = self
        
        if let item = selectedLocation {
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta:  0.1)
            let region = MKCoordinateRegion(center: item.location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        }
        
        cancelBtn.setTitle(cancelTitle, for: .normal)
        
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
//        searchController.searchBar.frame = CGRect(x: 0, y: 0, width: searchView.frame.width, height: searchView.frame.height)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            print(self.searchController.searchBar.frame)
            print(self.searchController.searchBar.constraints)
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.searchController.searchBar.frame.size.height = self.searchView.frame.height
        self.searchController.searchBar.frame.size.width = self.searchView.frame.width
//        searchController.searchBar.frame = CGRect(x: 0, y: 0, width: searchView.frame.width, height: searchView.frame.height)
//        self.results.view.frame = self.mapView.frame
    }
    
    //MARK: -
    @IBAction func doneBtnTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func selectLocationFromSearch(_ location: Location) {
        dismiss(animated: true) {
            self.selectedLocation = location
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta:  0.1)
            let region = MKCoordinateRegion(center: location.location.coordinate, span: span)
            self.mapView.setRegion(region, animated: true)
            
            self.historyManager.addToHistory(location)
        }
    }
    func selectLocation(location: CLLocation) {
        // add point annotation to map
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
//        self.mapView.addAnnotation(annotation)
        annotation.title = ""
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] response, error in
            guard let self = self else {return}
            
            if let error = error as NSError?, error.code != 10 { // ignore cancelGeocode errors
                // show error and remove annotation
                let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
                    self.mapView.removeAnnotation(annotation)
                }))
                self.present(alert, animated: true, completion: nil)
                
            } else if let placemark = response?.first {
                let address = Address(placemark: placemark)
                
                var name = ""
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
                
                
                self.selectedLocation = Location(name: placemark.areasOfInterest?.first, location: location, placemark: placemark)
                self.searchController.searchBar.text = self.selectedLocation.flatMap { $0.address } ?? ""
                self.mapView.addAnnotation(annotation)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
                    self.mapView.selectAnnotation(annotation, animated: true)
                }
                
            }
        }
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
//        let subtitleLb = UILabel()
//        subtitleLb.font = UIFont.systemFont(ofSize: 13)
//        subtitleLb.textColor = UIColor.gray
//        subtitleLb.text = annotation.subtitle ?? "1231232131231"
//        subtitleLb.text = "                       "
//        subtitleLb.text = "123"
//        if let text = annotation.subtitle,let value = text, value.count > 0 {
//
//        }
        pin.rightCalloutAccessoryView = selectLocationButton()
//        pin.conteiner(arrangedSubviews: [subtitleLb, selectLocationButton(), UILabel()])
        pin.canShowCallout = true
        return pin
    }
    
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        //call complete with location.
        
        let alert = UIAlertController(title: locationPickerSuccessTitle, message: locationPickerSuccessMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.dismiss(animated: true) {
                self.completion?(self.selectedLocation)
            }
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func selectLocationButton() -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        button.setTitle(selectTitle, for: UIControl.State())
        button.backgroundColor = UIColor.blue
        button.setTitleColor(.white, for: UIControl.State())
        button.layer.cornerRadius = 5
        button.titleEdgeInsets.left = 5
        button.titleEdgeInsets.right = 5
        return button
    }
}
extension ERLocationPickerViewController: UISearchBarDelegate {
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        print("Should begin")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.results.view.frame = self.mapView.frame
            self.searchController.searchBar.frame = CGRect(x: 0, y: 0, width: self.searchView.frame.width, height: self.searchView.frame.height)
        }
        return true
    }
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if let text = searchBar.text, text.isEmpty {
            searchBar.text = " "
        }
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchBar.text = " "
        }
    }
}

//Shit about searchresults view controller :(
extension ERLocationPickerViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    public func willPresentSearchController(_ searchController: UISearchController) {
        self.results.view.frame = self.mapView.frame
    }
    public func didPresentSearchController(_ searchController: UISearchController) {
        UIView.animate(withDuration: 0.17) {
            self.searchController.searchBar.frame = CGRect(x: 0, y: 0, width: self.searchView.frame.width, height: self.searchView.frame.height)
            self.results.tableView.contentInset = UIEdgeInsets(top: 70, left: 0, bottom: 0, right: 0)
        }
    }

    public func didDismissSearchController(_ searchController: UISearchController) {
        UIView.animate(withDuration: 0.1) {
            self.searchController.searchBar.frame = CGRect(x: 0, y: 0, width: self.searchView.frame.width, height: self.searchView.frame.height)
            self.results.tableView.contentInset = UIEdgeInsets(top: 70, left: 0, bottom: 0, right: 0)
        }
    }
    public func updateSearchResults(for searchController: UISearchController) {
        guard let term = searchController.searchBar.text else { return  }
        searchTimer?.invalidate()
        let searchTerm = term.trimmingCharacters(in: .whitespaces)
        if searchTerm.isEmpty {
            results.locations = historyManager.history()
            results.isShowingHistory = false
            results.tableView.reloadData()
        }else {
            showItemsForSearchResult(nil)
            searchTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self,
                                               selector: #selector(searchFromTimer(_:)),
                                               userInfo: ["query": searchTerm], repeats: false)
        }
    }
    
    @objc func searchFromTimer(_ timer: Timer) {
        guard let userInfo = timer.userInfo as? [String: AnyObject],
            let term = userInfo["query"] as? String
            else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = term
        
        localSearch?.cancel()
        localSearch = MKLocalSearch(request: request)
        localSearch!.start { response, _ in
            self.showItemsForSearchResult(response)
        }
    }
    
    func showItemsForSearchResult(_ searchResult: MKLocalSearch.Response?) {
        results.locations = searchResult?.mapItems.map { Location(name: $0.name, placemark: $0.placemark) } ?? []
        results.isShowingHistory = false
        results.tableView.reloadData()
    }
}


public class LocationPickerResultsViewController: UITableViewController {
    var locations: [Location] = []
    var onSelectLocation: ((Location) -> ())?
    var isShowingHistory: Bool = false
    var searchHistoryLb: String?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        extendedLayoutIncludesOpaqueBars = true
        tableView.contentInsetAdjustmentBehavior = .never
        
        tableView.tableFooterView = UIView()
        tableView.separatorColor = UIColor.lightGray.withAlphaComponent(0.4)
        tableView.backgroundColor = nil
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        tableView.backgroundView = blurEffectView
        tableView.separatorEffect = UIVibrancyEffect(blurEffect: blurEffect)
        
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return isShowingHistory ? searchHistoryLb : nil
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "LocationCell")
        
        let location = locations[indexPath.row]
        cell.imageView?.image = tableView.tintColor.toImage().imageWithSize(size: CGSize(width: 8, height: 8), roundedRadius: 4)
        cell.imageView?.layer.cornerRadius = 4
        cell.textLabel?.text = location.name
        cell.detailTextLabel?.text = location.address
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelectLocation?(locations[indexPath.row])
    }
}


internal extension UIColor {
    func toImage(size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect:CGRect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
        self.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image! // was image
    }
}

internal extension UIImage {
    /// Resizes an image to the specified size.
    ///
    /// - Parameters:
    ///     - size: the size we desire to resize the image to.
    ///
    /// - Returns: the resized image.
    ///
    func imageWithSize(size: CGSize) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale);
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height);
        draw(in: rect)
        
        let resultingImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return resultingImage
    }
    
    /// Resizes an image to the specified size and adds an extra transparent margin at all sides of
    /// the image.
    ///
    /// - Parameters:
    ///     - size: the size we desire to resize the image to.
    ///     - extraMargin: the extra transparent margin to add to all sides of the image.
    ///
    /// - Returns: the resized image.  The extra margin is added to the input image size.  So that
    ///         the final image's size will be equal to:
    ///         `CGSize(width: size.width + extraMargin * 2, height: size.height + extraMargin * 2)`
    ///
    func imageWithSize(size: CGSize, extraMargin: CGFloat) -> UIImage? {
        
        let imageSize = CGSize(width: size.width + extraMargin * 2, height: size.height + extraMargin * 2)
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.main.scale);
        let drawingRect = CGRect(x: extraMargin, y: extraMargin, width: size.width, height: size.height)
        draw(in: drawingRect)
        
        let resultingImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return resultingImage
    }
    
    /// Resizes an image to the specified size.
    ///
    /// - Parameters:
    ///     - size: the size we desire to resize the image to.
    ///     - roundedRadius: corner radius
    ///
    /// - Returns: the resized image with rounded corners.
    ///
    func imageWithSize(size: CGSize, roundedRadius radius: CGFloat) -> UIImage? {
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        if let currentContext = UIGraphicsGetCurrentContext() {
            let rect = CGRect(origin: .zero, size: size)
            currentContext.addPath(UIBezierPath(roundedRect: rect,
                                                byRoundingCorners: .allCorners,
                                                cornerRadii: CGSize(width: radius, height: radius)).cgPath)
            currentContext.clip()
            
            //Don't use CGContextDrawImage, coordinate system origin in UIKit and Core Graphics are vertical oppsite.
            draw(in: rect)
            currentContext.drawPath(using: .fillStroke)
            let roundedCornerImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return roundedCornerImage
        }
        return nil
    }
}

internal  extension CLPlacemark {
    
    var postalAddressIfAvailable: CNPostalAddress? {
        if #available(iOS 11.0, *) {
            return self.postalAddress
        }
        
        return nil
    }
    
}

struct SearchHistoryManager {
    
    fileprivate let HistoryKey = "RecentLocationsKey"
    fileprivate var defaults = UserDefaults.standard
    
    func history() -> [Location] {
        let history = defaults.object(forKey: HistoryKey) as? [NSDictionary] ?? []
        return history.compactMap(Location.fromDefaultsDic)
    }
    
    func addToHistory(_ location: Location) {
        guard let dic = location.toDefaultsDic() else { return }
        
        var history  = defaults.object(forKey: HistoryKey) as? [NSDictionary] ?? []
        let historyNames = history.compactMap { $0[LocationDicKeys.name] as? String }
        let alreadyInHistory = location.name.flatMap(historyNames.contains) ?? false
        if !alreadyInHistory {
            history.insert(dic, at: 0)
            defaults.set(history, forKey: HistoryKey)
        }
    }
}

