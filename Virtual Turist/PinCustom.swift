//
//  PinCustom.swift
//  Virtual Turist
//
//  Created by Xavier Jorda Murria on 29/04/2016.
//  Got snipped Code from Michael Miller (https://github.com/mikemdev40/Virtual-Tourist/blob/master/Virtual%20Tourist/PinAnnotation.swift ) 
//  Copyright © 2016 MikeMiller & xjm. All rights reserved.
//

import Foundation
import MapKit
import CoreData

/**
 * When "upgrading" this class to an NSManaged class (i started with a non-Core Data MKAnnotation-conforming object and converted it to Core Data later in development),
 * it was neccessary to remove the inheritance from NSObject (which was initially added to allow for MKAnnotation protocol conformance); i wanted to have this class conform to the 
 * MKAnnotation protocol so that these objects, when returned from core data, could be used immediately as annotations on the map 
 * (rather than having to create an intermediate set of annotations from objects of a non-MKannotation conforming class).
**/
class PinCustom:
    NSManagedObject,
    MKAnnotation
{
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var title: String?
    @NSManaged var subtitle: String?
    
    //the photos property implements the one-to-many relationship that is defined in the core data model between a Pin and Photos; 
    //    @NSManaged var photos: [Photo]?
    
    //coordinate is required for the MKAnnotation protocol so it was included,
    var coordinate: CLLocationCoordinate2D
    {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    //standard init that is REQUIRED for loading data from core data on startup (without this, there will be a crash)
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?)
    {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    //custom initializer that takes a NSManagedContext as part its pargument and calls the superclass initializer
    init(latitude: Double, longitude: Double, title: String?, subtitle: String?, context: NSManagedObjectContext)
    {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.subtitle = subtitle
    }
}
