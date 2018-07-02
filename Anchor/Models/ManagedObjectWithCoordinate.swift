import CoreData
import CoreLocation

protocol ManagedObjectWithCoordinate {
    var latitude: Double { get set }
    var longitude: Double { get set }

}

extension ManagedObjectWithCoordinate {
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
}
