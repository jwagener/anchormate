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

    override func viewDidLoad() {
        super.viewDidLoad()
        configureData()
        configureViews()

    }

    private func configureData() {
        anchor = Anchor.fetchCurrent(in: context)
        if let anchor = anchor {

            fetchedResultsController = NSFetchedResultsController(fetchRequest: anchor.locationsFetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController?.delegate = self

            try! fetchedResultsController?.performFetch()

            NSLog("feteched \(fetchedResultsController?.fetchedObjects?.count)")
        }
    }


    private func configureViews() {
        addPlaceholderAnchor()
        mapView.userTrackingMode = .follow
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.delegate = self

        if let anchor = anchor {
            mapView.addAnnotation(anchor)
            mapView.selectAnnotation(anchor, animated: true)
        }
        updateViews()

    }

    private func updateViews() {
        if let _ = anchor {
            anchorPlaceholderView.isHidden = true
            primaryButton.backgroundColor = .alertRed
            primaryButton.setTitle("Stop Anchor Watch", for: .normal)
        }else {
            anchorPlaceholderView.isHidden = false
            primaryButton.backgroundColor = .placedAnchor
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


    // IB Actions

    @IBAction func placeAnchor(_ sender: Any) {
        if let currentAnchor = anchor {
            mapView.removeAnnotation(currentAnchor)
            mapView.setCenter(currentAnchor.coordinate, animated: true)

            anchor = Anchor.fetchCurrent(in: context)
            anchor?.active = false
            try! context.save()
            anchor = nil
        } else {
            appDelegate.userNotificationManager.requestPermission()
            appDelegate.locationManager.requestBackgroundPermission()
            anchor = Anchor.new(in: context)
            anchor?.coordinate = mapView.centerCoordinate
            try! context.save()

            mapView.addAnnotation(anchor!)
            mapView.selectAnnotation(anchor!, animated: true)

            configureData()
        }

        updateViews()
    }

}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? Anchor else { return nil }

        let reuseId = "Anchor"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)

        if let annotationView = annotationView {
            annotationView.annotation = annotation
        } else {
            let newAnnotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            newAnnotationView.canShowCallout = false
            newAnnotationView.glyphImage = UIImage(named: "anchor5")
            newAnnotationView.markerTintColor = UIColor(named: "PlacedAnchor")!
            newAnnotationView.animatesWhenAdded = true
            annotationView = newAnnotationView
        }

        return annotationView
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        NSLog("got a change")
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {


        NSLog("got a change")
    }


}
