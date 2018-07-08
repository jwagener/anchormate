import CoreData
import CoreLocation
import MapKit

private let minimumLocationDistance = 1.0
private let minimumLocationAccuracy = 10.0
private let minimumTimeBetweenAlarmNotifications = 5000.0
private let minimumBatteryLevel: Float = 0.2

class Anchor: NSManagedObject {
    static var entityName = "Anchor"

    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var createdAt: Date
    @NSManaged var lastAnchorAlarm: Date?
    @NSManaged var lastBatteryAlarm: Date?
    @NSManaged var active: Bool
    @NSManaged var locations: NSSet
    @NSManaged var radius: Double

    static let minimumAnchorRadius = 10.0
    static let maximumAnchorRadius = 100.0
    static let anchorRadiusFactor = 1.3
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
        let distance = coordinate.distanceTo(userCoordinate) * Anchor.anchorRadiusFactor
        if distance < Anchor.minimumAnchorRadius {
            radius = Anchor.defaultAnchorRadius
        } else {
            radius = distance
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

    func addCLLocations(_ newLocations: [CLLocation]) {
        for clLocation in newLocations {
            addCLLocation(clLocation)
        }
    }

    func addCLLocation(_ clLocation: CLLocation) {
        guard let context = managedObjectContext else { fatalError() }

        let distanceToLastLocation = clLocation.coordinate.distanceTo(orderedLocations.last?.coordinate ?? CLLocationCoordinate2D())
        let distanceToAnchor = clLocation.coordinate.distanceTo(coordinate)
        let isLocationOutOfAnchorArea = distanceToAnchor - clLocation.horizontalAccuracy - radius > 0.0

        if isLocationOutOfAnchorArea {
            NSLog("got location out of anchor area \(distanceToAnchor) \(clLocation.horizontalAccuracy)")
        }

        if clLocation.horizontalAccuracy <= minimumLocationAccuracy || isLocationOutOfAnchorArea {
            appDelegate.userNotificationManager.resetFallbackNotification()

            
            if distanceToLastLocation > minimumLocationDistance {
                let location = Location.new(in: context)
                location.coordinate = clLocation.coordinate
                location.createdAt = clLocation.timestamp
                location.anchor = self

                NSLog("Distance to Anchor \(distanceToAnchor), Last location: \(distanceToLastLocation)")
                checkAlarm()
            } else {
                NSLog("SKIP small distance \(distanceToLastLocation)")
            }
        } else {
            NSLog("SKIP inaccurate location \(clLocation.horizontalAccuracy)")
        }
    }

    func addLocationObject(_ value: Location) {
        self.mutableSetValue(forKey: "locations").add(value)
    }

    var orderedLocations: [Location] {
        return locations.compactMap { $0 as? Location }.sorted(by: { $0.createdAt < $1.createdAt })
    }

    var isOutOfAnchorArea: Bool {
        guard let lastLocation = orderedLocations.last else { return false }
        return lastLocation.coordinate.distanceTo(coordinate) > radius
    }

    var shouldSendAnchorAlarm: Bool {
        guard let lastAnchorAlarm = lastAnchorAlarm else { return true }
        return lastAnchorAlarm.timeIntervalSinceNow * -1.0 > minimumTimeBetweenAlarmNotifications
    }

    var shouldSendBatteryAlarm: Bool {
        guard let lastBatteryAlarm = lastBatteryAlarm else { return true }
        return lastBatteryAlarm.timeIntervalSinceNow * -1.0 > minimumTimeBetweenAlarmNotifications
    }

    func checkBatteryAlarm() {
        guard UIDevice.current.batteryState != .charging else { return }
        if UIDevice.current.batteryLevel <= minimumBatteryLevel && shouldSendBatteryAlarm {
            lastBatteryAlarm = Date(timeIntervalSinceNow: 0)
            appDelegate.userNotificationManager.sendBatteryAlarmNotification()
        }
    }

    func checkAlarm() {
        if isOutOfAnchorArea {
            if shouldSendAnchorAlarm {
                triggerAlarm()
            } else {
                NSLog("Skipping Alarm due to minimumTimeBetweenAlarmNotifications")
            }
        } else {
            lastAnchorAlarm = nil
        }
    }

    func triggerAlarm() {
        NSLog("Sending Alarm")
        lastAnchorAlarm = Date(timeIntervalSinceNow: 0)
        appDelegate.userNotificationManager.sendAnchorAlarmNotification()
    }
}

extension Anchor: MKAnnotation {
    var title: String? { return "Anchor" }
//    var subtitle: String? { return "\(radius)m Radius" }
}
