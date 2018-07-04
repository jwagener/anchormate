import CoreData
import CoreLocation
import MapKit

private let minimumLocationDistance = 1.0
private let minimumLocationAccuracy = 10.0


class Anchor: NSManagedObject {
    static var entityName = "Anchor"

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var createdAt: Date
    @NSManaged var active: Bool
    @NSManaged var locations: [Location]
    @NSManaged var radius: Double

    static let minimumAnchorRadius = 5.0
    static let maximumAnchorRadius = 100.0
    static let anchorRadiusFactor = 1.1
    static let defaultAnchorRadius = 20.0

    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }

    func activate() {
        active = true
        appDelegate.userNotificationManager.scheduleFallbackNotification()
        appDelegate.locationManager.startMonitoring()
    }

    func deacticate() {
        appDelegate.userNotificationManager.cancelFallbackNotification()
        appDelegate.locationManager.stopMonitoring()
        active = false
    }

    func setRadius(for userCoordinate: CLLocationCoordinate2D) {
        let distance = coordinate.distanceTo(userCoordinate)
        if distance < Anchor.minimumAnchorRadius {
            radius = Anchor.defaultAnchorRadius
        } else {
            radius = distance * Anchor.anchorRadiusFactor
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
        request.predicate = NSPredicate(format: "anchor = %@", self.objectID)
        request.fetchLimit = 30
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Location.createdAt, ascending: false)]
        return request
    }

    func addLocations(_ newLocations: [CLLocation]) {
        guard let context = managedObjectContext else { fatalError() }
        for clLocation in newLocations {
            let distanceToLastLocation = clLocation.coordinate.distanceTo(locations.last?.coordinate ?? CLLocationCoordinate2D())
            let distanceToAnchor = clLocation.coordinate.distanceTo(coordinate)

            NSLog("last location date \(locations.last?.createdAt)")
            if clLocation.horizontalAccuracy < minimumLocationDistance {
                appDelegate.userNotificationManager.resetFallbackNotification()

                if distanceToLastLocation > minimumLocationDistance {
                    let location = Location.new(in: context)
                    location.coordinate = clLocation.coordinate
                    location.createdAt = clLocation.timestamp
                    location.anchor = self


                    //NSLog("last locatio\(locations.last?.coordinate)")

                    NSLog("Distance to Anchor \(distanceToAnchor), Last locaation: \(distanceToLastLocation)")

                    if distanceToAnchor > radius {
                        NSLog("alarm")
                        appDelegate.userNotificationManager.sendAnchorAlarmNotification()
                    }
                } else {
                    NSLog("skip inaccurate location \(clLocation.horizontalAccuracy)")
                }
            }
        }
    }
}

extension Anchor: MKAnnotation {
    var title: String? { return "Anchor" }
}
