import CoreLocation
import MapKit

extension CLLocationCoordinate2D {
    func distanceTo(_ otherCoordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        return MKMapPoint(self).distance(to: MKMapPoint(otherCoordinate))
    }
}
