import CoreData

class Event: NSManagedObject {
    static var entityName = "Event"
    class func new(in context: NSManagedObjectContext) -> Event {
        return NSEntityDescription.insertNewObject(forEntityName: Event.entityName, into: context) as! Event
    }

}
