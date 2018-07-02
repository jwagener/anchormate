import CoreData
import CoreLocation
import MapKit

class Anchor: NSManagedObject {
    static var entityName = "Anchor"

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var createdAt: Date
    @NSManaged var active: Bool
    @NSManaged var locations: [Location]


    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }

    class func new(in context: NSManagedObjectContext) -> Anchor {
        let anchor = NSEntityDescription.insertNewObject(forEntityName: Anchor.entityName, into: context) as! Anchor
        anchor.createdAt = Date(timeIntervalSinceNow: 0)
        return anchor
    }

    class func fetchCurrent(in context: NSManagedObjectContext) -> Anchor? {
        let request = NSFetchRequest<Anchor>(entityName: Anchor.entityName)
        request.predicate = NSPredicate(format: "active = true")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Anchor.createdAt, ascending: false)]
        request.returnsObjectsAsFaults = false
        let result = try! context.fetch(request)
        return result.first
    }


    var locationsFetchRequest: NSFetchRequest<Location>  {
        let request = NSFetchRequest<Location>(entityName: Location.entityName)
        request.predicate = NSPredicate(format: "anchor = %@", self)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Location.createdAt, ascending: true)]
        return request
    }

    func addLocations(_ locations: [CLLocation]) {
        guard let context = managedObjectContext else { fatalError() }
        for clLocation in locations {
            let location = Location.new(in: context)
            location.coordinate = clLocation.coordinate
            location.createdAt = clLocation.timestamp
            location.anchor = self
        }
    }

}


extension Anchor: MKAnnotation {
    var title: String? { return "Anchor" }
}
