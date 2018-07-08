import CoreLocation
import MapKit

extension CLLocationCoordinate2D {
    func distanceTo(_ otherCoordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        return MKMapPoint(self).distance(to: MKMapPoint(otherCoordinate))
    }
}


// TODO skip in new cocoa sdk
extension MKMapPoint {
    init(_ coordinate: CLLocationCoordinate2D) {
        self = MKMapPointForCoordinate(coordinate)
    }
    func distance(to otherPoint: MKMapPoint) -> CLLocationDistance {
        return MKMetersBetweenMapPoints(self, otherPoint)
    }
}
