//
//  LocationModel.swift
//  ERMarkup
//
//  Created by Eric Nguyen on 9/24/20.
//

//MARK:-
import Contacts
import CoreLocation
import MapKit

public class Location: NSObject {
    public var name: String?
   
    public let location: CLLocation
    public let placemark: CLPlacemark
    
    public var address: String    {
        if let item = placemark.postalAddressIfAvailable {
            let formatter = CNPostalAddressFormatter()
            formatter.style = .mailingAddress
            return formatter.string(from: item)
        } else {
            return "\(location.coordinate.latitude), \(location.coordinate.longitude)"
        }
    }
    public init(name: String?, location: CLLocation? = nil, placemark: CLPlacemark) {
        self.name = name
        self.location = location ?? placemark.location!
        self.placemark = placemark
    }
    
    public var locationString: String {
        return "\(location.coordinate.latitude), \(location.coordinate.longitude)"
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


extension MKAnnotationView {

    func conteiner(arrangedSubviews: [UIView]) {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.alignment = .fill
        stackView.spacing = 5
        stackView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleLeftMargin, .flexibleBottomMargin, .flexibleWidth, .flexibleHeight]
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.detailCalloutAccessoryView = stackView
    }
}

struct LocationDicKeys {
    static let name = "Name"
    static let locationCoordinates = "LocationCoordinates"
    static let placemarkCoordinates = "PlacemarkCoordinates"
    static let placemarkAddressDic = "PlacemarkAddressDic"
}

struct CoordinateDicKeys {
    static let latitude = "Latitude"
    static let longitude = "Longitude"
}

extension CLLocationCoordinate2D {
    
    func toDefaultsDic() -> NSDictionary {
        return [CoordinateDicKeys.latitude: latitude, CoordinateDicKeys.longitude: longitude]
    }
    
    static func fromDefaultsDic(_ dic: NSDictionary) -> CLLocationCoordinate2D? {
        guard let latitude = dic[CoordinateDicKeys.latitude] as? NSNumber,
            let longitude = dic[CoordinateDicKeys.longitude] as? NSNumber else { return nil }
        return CLLocationCoordinate2D(latitude: latitude.doubleValue, longitude: longitude.doubleValue)
    }
}

extension Location {
    
    func toDefaultsDic() -> NSDictionary? {
        
        guard let postalAddress = placemark.postalAddressIfAvailable,
            let placemarkCoordinatesDic = placemark.location?.coordinate.toDefaultsDic()
            else { return nil }
        
        let formatter = CNPostalAddressFormatter()
        let addressDic = formatter.string(from: postalAddress)
        
        var dic: [String: AnyObject] = [
            LocationDicKeys.locationCoordinates: location.coordinate.toDefaultsDic(),
            LocationDicKeys.placemarkAddressDic: addressDic as AnyObject,
            LocationDicKeys.placemarkCoordinates: placemarkCoordinatesDic
        ]
        if let name = name { dic[LocationDicKeys.name] = name as AnyObject? }
        return dic as NSDictionary?
    }
    
    class func fromDefaultsDic(_ dic: NSDictionary) -> Location? {
        guard let placemarkCoordinatesDic = dic[LocationDicKeys.placemarkCoordinates] as? NSDictionary,
            let placemarkCoordinates = CLLocationCoordinate2D.fromDefaultsDic(placemarkCoordinatesDic),
            let placemarkAddressDic = dic[LocationDicKeys.placemarkAddressDic] as? [String: AnyObject]
            else { return nil }
        
        let coordinatesDic = dic[LocationDicKeys.locationCoordinates] as? NSDictionary
        let coordinate = coordinatesDic.flatMap(CLLocationCoordinate2D.fromDefaultsDic)
        let location = coordinate.flatMap { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
        return Location(name: dic[LocationDicKeys.name] as? String,
            location: location, placemark: MKPlacemark(
                coordinate: placemarkCoordinates, addressDictionary: placemarkAddressDic))
    }
}
