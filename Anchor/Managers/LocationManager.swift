import CoreLocation
import CoreData

class LocationManager: NSObject {
    let clLocationManager = CLLocationManager()
    var backgroundContext: NSManagedObjectContext {
        return appDelegate.backgroundContext
    }

    override init() {
        super.init()
        clLocationManager.delegate = self
    }

    func requestPermission() {
        clLocationManager.requestWhenInUseAuthorization()
    }

    func requestBackgroundPermission() {
        clLocationManager.requestAlwaysAuthorization()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        backgroundContext.performAndWait {
            if let currentAnchor = Anchor.fetchCurrent(in: backgroundContext) {
                currentAnchor.addLocations(locations)
                NSLog("got locations \(locations.last)")
                try! backgroundContext.save()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        NSLog("didchange auth")

        if status == .authorizedAlways {
            clLocationManager.allowsBackgroundLocationUpdates = true
            clLocationManager.desiredAccuracy = 1.0
            clLocationManager.showsBackgroundLocationIndicator = true
            clLocationManager.startUpdatingLocation()
        }
    }
}

extension NotificationCenter {
    static var didUpdateLocationsNotification = Notification.Name("didReceiveData")
}

