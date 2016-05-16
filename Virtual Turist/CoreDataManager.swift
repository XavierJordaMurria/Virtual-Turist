//
//  CoreDataManager.swift
//  Virtual Turist
//
//  Created by Xavier Jorda Murria on 29/04/2016.
//  Copyright © 2016 xjm. All rights reserved.
//

import Foundation
import CoreData

/**
 * CoreDataManager class is the interactive layer between the VirtualTuristModel.xcdatamodeld and the project, being in charge of "getting/posting" data
**/
class CoreDataManager
{
    //singleton object for instantiating only a single core data stack
    static let sharedInstance = CoreDataManager()
    
    lazy var managedObjectContect: NSManagedObjectContext =
    {
        
        //gets the URL for where the core data model file is located within the app's bundle (the "Model.xcdatamodeld" file)
        guard let modelURL = NSBundle.mainBundle().URLForResource("VirtualTuristModel", withExtension: "momd")
        else
        {
            fatalError("Error loading the model from the bundle")
        }
        
        //creates a managed object model from the data model file using the URL above
        guard let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL)
        else
        {
            fatalError("Error initializing the managed object model")
        }
        
        //creates an NSPersistentStoreCoordinate and associates it with the managed object model
        let persistentCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        //creates the managed object context which will be configured and ultimately returned by this closure; the context is created with the Main Queue concurrency type, since according to the documentation, "you use this queue type for contexts linked to controllers and UI objects that are required to be used only on the main thread" (and this context will used heavily in both the collection view and map view)
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        
        context.persistentStoreCoordinator = persistentCoordinator //attach the persistent coordinator to the context so it can mediate between the context and the persistent store
        
        //sets a URL for where the SQL database should be stored on the file system
        let urlForDocDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let urlForSQLDB = urlForDocDirectory?.URLByAppendingPathComponent("DataModel.sqlite")
        
        //establishes a SQL persistent store on the disk at the specified URL and associates it with the persistent coordinator
        do
        {
            try persistentCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: urlForSQLDB, options: nil)
        }
        catch
        {
            fatalError("Error adding persistent store")
        }
        
        return context
    }()
    
    ///this method takes the photo array data from the flickr search, pulls out up to the maximum number of photos per pin (defined in the Constants and set for this project to be 36), creates a new core data Photo object from each returned image, and "attaches" each Photo to the specific Pin (see comment in Photo class for why i didn't include the pin as part of the Photo object's initialization, opting to set it separately after - and how it could have been done differntly)
//    func savePhotosToPin(photoDataToSave: [[String : AnyObject]], pinToSaveTo: PinAnnotation, maxNumberToSave: Int)
//    {
//        
//        var photoDataToSaveMutable = photoDataToSave
//        
//        if photoDataToSave.count > Constants.MapViewConstants.MaxNumberOfPhotosToSavePerPin {
//            
//            //see Array extension in the Constants file for the array-based shuffle method below; this is used to shuffle the array of photos (since it will typically contain many more than needed - up to 250), so that the user is getting a random set of photos from whatever page of image results gets returned from flickr; this decreases the likelihood that when the user taps the "get new collection" button that the 36 photos that are reloaded are the same ones!
//            photoDataToSaveMutable.shuffle()
//        }
//        
//        //if the number of results passed into this method is more than a specified max (36 for this app), then we only take out the max number, which is done by taking the first 36 of the photo array and making Photo objects from them; note that the Pin to which each photo should be associated is set here as well
//        if photoDataToSaveMutable.count > maxNumberToSave {
//            for photoNum in 0...(maxNumberToSave - 1) {
//                if let imgURL = photoDataToSaveMutable[photoNum]["url_m"] as? String, let photoID = photoDataToSaveMutable[photoNum]["id"] as? String {
//                    let newPhoto = Photo(photoID: photoID, flickrURL: imgURL, context: managedObjectContect)
//                    newPhoto.pin = pinToSaveTo
//                }
//            }
//            
//            //else, there re already fewer than the max number of photos in the photo array, so just make Photos from all of them
//        } else {
//            for photo in photoDataToSaveMutable {
//                if let imgURL = photo["url_m"] as? String, let photoID = photo["id"] as? String {
//                    let newPhoto = Photo(photoID: photoID, flickrURL: imgURL, context: managedObjectContect)
//                    newPhoto.pin = pinToSaveTo
//                }
//            }
//        }
//        
//        //save the added Photo objects to the persistent store
//        do {
//            try managedObjectContect.save()
//        } catch { }
//    }
    
    private init() {}
}
