//
//  Locations+CoreDataProperties.swift
//  SolarCalculator
//
//  Created by apple on 28/07/18.
//  Copyright © 2018 Aakash Srivastav. All rights reserved.
//

import CoreData

class Locations: NSManagedObject {
    
    enum Keys: String {
        case placeId
        case isPinned
        case latitude
        case longitude
        case name
        
        var name: String {
            return self.rawValue
        }
    }
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Locations> {
        return NSFetchRequest<Locations>(entityName: "Locations")
    }
    
    @nonobjc public class func fetch(using predicate: NSPredicate?) -> [Locations] {
        let request: NSFetchRequest<Locations> = Locations.fetchRequest()
        if let unwrappedPredicate = predicate {
            request.predicate = unwrappedPredicate
        }
        request.returnsObjectsAsFaults = false
        
        do {
            let locations = try AppDelegate.shared.persistentContainer.viewContext.fetch(request)
            return locations
        } catch {
            print_debug(error.localizedDescription)
            return []
        }
    }
    
    @nonobjc public class func deleteLocation(having placeId: String) {
        let predicate = NSPredicate(format: "\(Locations.Keys.placeId.name) = %@", placeId)
        let locations = fetch(using: predicate)
        
        for location in locations {
            AppDelegate.shared.persistentContainer.viewContext.delete(location)
        }
        AppDelegate.shared.saveContext()
    }
    
    @nonobjc public class func getBlankLocation() -> Locations {
        let context = AppDelegate.shared.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Locations", in: context)
        let object = NSManagedObject(entity: entity!, insertInto: nil)
        return object as! Locations
    }
    
    @nonobjc public class func saveLocationInDB(_ location: Locations) {
        
        let context = AppDelegate.shared.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Locations", in: context)
        let object = NSManagedObject(entity: entity!, insertInto: context)
        
        object.setValue(location.placeId, forKey: Locations.Keys.placeId.name)
        object.setValue(location.latitude, forKey: Locations.Keys.latitude.name)
        object.setValue(location.longitude, forKey: Locations.Keys.longitude.name)
        object.setValue(location.name, forKey: Locations.Keys.name.name)
        object.setValue(location.isPinned, forKey: Locations.Keys.isPinned.name)
        
        do {
            try context.save()
        } catch {
            print_debug(error.localizedDescription)
        }
    }
    
    @NSManaged public var placeId: String?
    @NSManaged public var isPinned: Bool
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
}
