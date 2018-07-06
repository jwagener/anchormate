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

    func startMonitoring() {
        clLocationManager.allowsBackgroundLocationUpdates = true
        clLocationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        //            clLocationManager.distanceFilter = 1.0
        clLocationManager.showsBackgroundLocationIndicator = true
        clLocationManager.pausesLocationUpdatesAutomatically = false
        clLocationManager.startUpdatingLocation()
    }

    func stopMonitoring() {
        clLocationManager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        backgroundContext.performAndWait {
            if let currentAnchor = Anchor.fetchCurrent(in: backgroundContext) {
                currentAnchor.checkBatteryAlarm()
                currentAnchor.addCLLocations(locations)
                try! backgroundContext.save()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            startMonitoring()
        }
    }
}

extension NotificationCenter {
    static var didUpdateLocationsNotification = Notification.Name("didReceiveData")
}

