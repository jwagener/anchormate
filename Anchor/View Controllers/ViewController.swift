import UIKit
import MapKit
import CoreData

class ViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var anchorPlaceholderView: UIView!
    private var placeholderAnchorMarkerView: UIView?

    private var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }

    var fetchedResultsController: NSFetchedResultsController<Location>?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var anchor: Anchor?
    private var radiusOverlay: MKCircle?
    private var trackOverlay: MKPolyline?
    private var trackCoordinates: [CLLocationCoordinate2D] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        configureData()
        configureViews()

    }

    private func configureData() {
        anchor = Anchor.fetchCurrent(in: context)
        if let _ = anchor {
            configureAnchorLocationsFetch()
        }
    }

    private func configureAnchorLocationsFetch() {
        guard let anchor = anchor else { return }
        fetchedResultsController = NSFetchedResultsController(fetchRequest: anchor.locationsFetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self

        try! fetchedResultsController?.performFetch()
        NSLog("Initial Fetch Location \(fetchedResultsController?.fetchedObjects?.count)")

        trackCoordinates = (fetchedResultsController?.fetchedObjects ?? []).map { $0.coordinate }
        trackOverlay = MKPolyline(coordinates: trackCoordinates, count: trackCoordinates.count)
        mapView.add(trackOverlay!)
    }

    private func configureViews() {
        addPlaceholderAnchor()
        mapView.userTrackingMode = .follow
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.delegate = self

        if let anchor = anchor {
            addAnchorAnnotations(for: anchor)
        }

        updateViews()
    }

    private func updateViews() {
        if let _ = anchor {
            anchorPlaceholderView.isHidden = true
            primaryButton.backgroundColor = .mateRed
            primaryButton.setTitle("Stop Anchor Watch", for: .normal)
        }else {
            anchorPlaceholderView.isHidden = false
            primaryButton.backgroundColor = .mateBlue
            primaryButton.setTitle("Place Anchor", for: .normal)
        }
    }

    private func addPlaceholderAnchor() {
        let marker = MKMarkerAnnotationView(annotation: MKPointAnnotation(), reuseIdentifier: "Marker")
        marker.canShowCallout = false
        marker.glyphImage = UIImage(named: "anchor5")
        marker.markerTintColor = .gray
        marker.isSelected = true
        marker.translatesAutoresizingMaskIntoConstraints = false
        anchorPlaceholderView.addSubview(marker)
    }


    func addAnchorAnnotations(for anchor: Anchor) {
        radiusOverlay = MKCircle(center: anchor.coordinate, radius: anchor.radius)
        mapView.addAnnotation(anchor)
        mapView.add(radiusOverlay!)
        mapView.selectAnnotation(anchor, animated: true)
    }

    func removeAnchorAnnotations(){
        guard let anchor = anchor, let radiusAnnotation = radiusOverlay else { return }
        mapView.removeAnnotation(anchor)
        mapView.remove(radiusAnnotation)
        if let trackOverlay = trackOverlay {
            mapView.remove(trackOverlay)
        }
    }

    // IB Actions

    @IBAction func placeAnchor(_ sender: Any) {
        if anchor == nil {
            startAnchorWatch()
        } else {
            endAnchorWatch()
        }

        updateViews()
    }
    @IBAction func startAnchorWatch() {
        let userCoordinate = mapView.userLocation.coordinate

        appDelegate.userNotificationManager.requestPermission()
        appDelegate.locationManager.requestBackgroundPermission()

        anchor = Anchor.new(in: context)
        anchor!.coordinate = mapView.centerCoordinate
        anchor!.setRadius(for: userCoordinate)
        anchor!.activate()

        try! context.save()

        addAnchorAnnotations(for: anchor!)
        configureAnchorLocationsFetch()
    }

    @IBAction func endAnchorWatch() {
        guard let _ = anchor else { return }
        let userCoordinate = mapView.userLocation.coordinate

        removeAnchorAnnotations()
        mapView.setCenter(userCoordinate, animated: true)
        anchor = Anchor.fetchCurrent(in: context)
        anchor?.deacticate()

        try! context.save()
        anchor = nil
    }

    private func resetTrack() {
        trackCoordinates = []

    }

}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circleOverlay = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circleOverlay)
            renderer.fillColor = UIColor.mateRed.withAlphaComponent(0.2)
            renderer.strokeColor = UIColor.mateRed.withAlphaComponent(0.9)
            renderer.lineWidth = 4.0
            return renderer
        } else if let lineOverlay = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: lineOverlay)
            renderer.strokeColor = UIColor.mateYellow.withAlphaComponent(0.4)
            renderer.lineWidth = 4.0
            return renderer
        } else {
            return MKOverlayRenderer(overlay: overlay)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case is Anchor:   return viewForAnchorAnnotation(annotation as! Anchor)
        case is Location: return viewForLocationAnnotation(annotation as! Location)
        default: return nil
        }
    }

    private func viewForAnchorAnnotation(_ annotation: Anchor) -> MKMarkerAnnotationView {
        let reuseId = "Anchor"
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)

        annotationView.annotation = annotation
        annotationView.canShowCallout = false
        annotationView.glyphImage = UIImage(named: "anchor5")
        annotationView.markerTintColor = UIColor.mateBlue
        annotationView.animatesWhenAdded = true
        annotationView.canShowCallout = false
        return annotationView
    }

    private func viewForLocationAnnotation(_ annotation: Location) -> MKPinAnnotationView {
        let reuseId = "Location"

        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)

        annotationView.annotation = annotation
        return annotationView
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        switch type {
        case .insert:
            if let location = anObject as? Location {
                if let trackOverlay = trackOverlay {
                    mapView.remove(trackOverlay)
                    trackCoordinates.append(location.coordinate)
                    self.trackOverlay = MKPolyline(coordinates: trackCoordinates, count: trackCoordinates.count)
                    mapView.add(self.trackOverlay!)
                }
            }
        default:
            return
        }
    }
}
