import UIKit
import MapKit
import CoreData

private let radiusChangeFactor = 1.25

class ViewController: UIViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var anchorPlaceholderView: UIView!

    private var placeholderAnchorMarkerView: UIView?

    private var fetchedResultsController: NSFetchedResultsController<Location>?
    private var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }

    var anchor: Anchor?

    private var radiusOverlay: MKCircle?
    private var trackOverlay: MKPolyline?
    private var trackCoordinates: [CLLocationCoordinate2D] = []

    /// View Setup and Updating

    override func viewDidLoad() {
        super.viewDidLoad()
        configureData()
        configureViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        updateViews()
    }

    private func configureViews() {
        addPlaceholderAnchor()
        mapView.userTrackingMode = .follow
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.delegate = self
    }

    private func updateViews() {
        if let anchor = anchor {
            removeAnchorAnnotations()
            addAnchorAnnotations(for: anchor)

            anchorPlaceholderView.isHidden = true
            primaryButton.backgroundColor = .mateRed
            primaryButton.setTitle("Stop Anchor Watch", for: .normal)
        } else {
            anchorPlaceholderView.isHidden = false
            primaryButton.backgroundColor = .mateBlue
            primaryButton.setTitle("Place Anchor", for: .normal)
        }
    }

    /// Data Fetching

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

        trackCoordinates = (fetchedResultsController?.fetchedObjects ?? []).map { $0.coordinate }
        trackOverlay = MKPolyline(coordinates: trackCoordinates, count: trackCoordinates.count)
        mapView.add(trackOverlay!)
    }

    /// Map Annotations

    private func addPlaceholderAnchor() {
        let marker = MKMarkerAnnotationView(annotation: MKPointAnnotation(), reuseIdentifier: "Marker")
        marker.canShowCallout = false
        marker.glyphImage = UIImage.anchorSymbol
        marker.markerTintColor = .gray
        marker.rightCalloutAccessoryView = UIButton()
        marker.translatesAutoresizingMaskIntoConstraints = false
        anchorPlaceholderView.addSubview(marker)
    }


    private func addAnchorAnnotations(for anchor: Anchor) {
        mapView.addAnnotation(anchor)
        addRadiusOverlay()
    }

    private func addRadiusOverlay() {
        guard let anchor = anchor else { return }
        radiusOverlay = MKCircle(center: anchor.coordinate, radius: anchor.radius)
        mapView.add(radiusOverlay!)
    }

    private func removeRadiusOverlay() {
        guard let radiusOverlay = radiusOverlay else { return }
        mapView.remove(radiusOverlay)
        self.radiusOverlay = nil
    }

    private func removeAnchorAnnotations(){
        guard let anchor = anchor else { return }
        mapView.removeAnnotation(anchor)
        removeRadiusOverlay()
        if let trackOverlay = trackOverlay {
            mapView.remove(trackOverlay)
        }
    }

    // IB Actions

    @IBAction func handlePrimaryButtonTap(_ sender: Any) {
        if anchor == nil {
            startAnchorWatch()
        } else {
            endAnchorWatch()
        }
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

        configureAnchorLocationsFetch()
        updateViews()
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

        updateViews()
    }


    @IBAction private func slideRadius(_ sender: UISlider) {
        let value = sender.value - sender.value.truncatingRemainder(dividingBy: 5.0)
        changeRadius(to: Double(value))
    }

    private func changeRadius(to radius: Double) {
        guard let anchor = anchor else { return }
        anchor.setRadius(radius)
        try? context.save()
        removeRadiusOverlay()
        addRadiusOverlay()
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circleOverlay = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circleOverlay)
            renderer.fillColor   = UIColor.mateRed.withAlphaComponent(0.2)
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
        case is Anchor:
            return viewForAnchorAnnotation(annotation as! Anchor)
        default:
            return nil
        }
    }

    private func viewForAnchorAnnotation(_ annotation: Anchor) -> MKMarkerAnnotationView {
        let reuseId = "Anchor"
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)

        annotationView.annotation = annotation
        annotationView.canShowCallout = true
        annotationView.glyphImage = UIImage.anchorSymbol
        annotationView.markerTintColor = UIColor.mateRed
        annotationView.animatesWhenAdded = true

        let detailView = UISlider(frame: .zero)

        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: detailView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 250.0),
            NSLayoutConstraint(item: detailView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 40.0)
        ])

        detailView.isContinuous = true
        detailView.minimumValue = Float(Anchor.minimumAnchorRadius)
        detailView.value = Float(annotation.radius)
        detailView.maximumValue = Float(Anchor.maximumAnchorRadius)
        detailView.addTarget(nil, action: #selector(slideRadius(_:)), for: .valueChanged)
        annotationView.detailCalloutAccessoryView = detailView
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
