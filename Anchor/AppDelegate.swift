import UIKit
import CoreData

var appDelegate: AppDelegate { return UIApplication.shared.delegate as! AppDelegate }

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    var locationManager: LocationManager!
    var userNotificationManager: UserNotificationManager!

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    var backgroundContext: NSManagedObjectContext!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        persistentContainer = NSPersistentContainer(name: "Anchor")
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }

            DispatchQueue.main.async { self.setupApplication() }
        })

        return true
    }

    func setupApplication() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        backgroundContext = self.persistentContainer.newBackgroundContext()
        setupContextNotificationObserving()
        userNotificationManager = UserNotificationManager()
        locationManager = LocationManager()
        locationManager.requestPermission()
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
        self.saveContext()
    }

    // MARK: - Core Data stack

    var persistentContainer: NSPersistentContainer!

    fileprivate func setupContextNotificationObserving() {
        viewContext.addContextDidSaveNotificationObserver { [weak self] note in
            self?.backgroundContext.performMergeChanges(from: note)
        }

        backgroundContext.addContextDidSaveNotificationObserver { [weak self] note in
            self?.viewContext.performMergeChanges(from: note)
        }
    }

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
