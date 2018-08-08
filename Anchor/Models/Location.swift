import CoreData
import CoreLocation
import MapKit

class Location: NSManagedObject {
    static var entityName = "Location"

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var createdAt: Date
    @NSManaged var horizontalAccuracy: Double
    @NSManaged var verticalAccuracy: Double
    @NSManaged var anchor: Anchor?

    class func new(in context: NSManagedObjectContext) -> Location {
        let location = NSEntityDescription.insertNewObject(forEntityName: Location.entityName, into: context) as! Location
        location.createdAt = Date(timeIntervalSinceNow: 0)
        return location
    }

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

extension Location: MKAnnotation {
    var title: String? { return "Location" }
}
