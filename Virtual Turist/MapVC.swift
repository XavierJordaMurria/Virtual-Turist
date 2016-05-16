//
//  ViewController.swift
//  Virtual Turist
//
//  Created by Xavier Jorda Murria on 06/04/2016.
//  Copyright © 2016 xjm. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate
{
    //MARK: -------- PROPERTIES --------
    @IBOutlet weak var mapView: MKMapView!
    {
        didSet
        {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(MapVC.addAnnotation(_:)))
            longPress.minimumPressDuration = Constants.MapViewConstants.LongPressDuration
            mapView.addGestureRecognizer(longPress)
        }
    }
    
    //used to track the pin on the map when the user drags it
    var temporaryAnnotation: MKPointAnnotation!
    //used to track the currently (or last) selected annotation
    var activeAnnotation: PinCustom!
    
    //used to track the last annotation view that was tapped (used when toggling the color of the pin between red and purple when in edit mode)
    var lastPinTapped: MKPinAnnotationView?
    //used to track the current coordinate of the pin on the map, particularly useful for tracking a dragged pin (see the dropPin method)
    var coordinate = CLLocationCoordinate2D()
    var locationManager: CLLocationManager!
    var location:CLLocation?
    var savedLocation:Bool = false
    
    //The 1st time that we load the map after installing the map from scratch, we want to show the current location
    var firstLoad:Bool = true
    
    //Bocking flag for the 1st time that we go into the viewDidLoad in the MapVC
    var initiallyLoaded:Bool = false

    struct previousCoordinates
    {
        static var lat: Double = 0.0
        static var lon: Double = 0.0
    }
    
    //getting a reference to the singleton core data context
    var sharedContext: NSManagedObjectContext
    {
        return CoreDataManager.sharedInstance.managedObjectContect
    }
    
    //MARK: -------- ViewController life Cycle Methods --------
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print("viewDidLoad")
        
        mapView.delegate = self
        
        //Just need to check for the device location the very 1st time that this view is loaded, straig after the installation and open from scratch.
        if (firstLoad && CLLocationManager.locationServicesEnabled())
        {
            print("locationServicesEnabled")
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        //the block of code below only runs once: when initially launching the app (because initiallyLoaded is set to true below, this won't run when a user returns back to this view controller from the photo album view
        //loads a user's saved map zoom/pan/location setting from NSUserDefaults; this is performed in viewDIDappear rather than viewWILLappear because the map gets initially set to an app-determined location and regionDidChangeAnimated method gets called in BETWEEN viewWillAppear and viewDidAppear (and this initial location is NOT related to the loaded/saved location), so the code to load a user's saved preferences is delayed until now so that the saved location is loaded AFTER the app pre-sets the map, rather then before (and thus being overwritten, or "shifted" to a different location); it is ensured that the initial auotmatica "pre-set" region of the map is not saved as a user-based save (thus overwriting a user's save) via the mapViewRegionDidChangeFromUserInteraction method, which checks to make sure that when regionDidChangeAnimated is invoked, it is in response to user-generated input
        //get persistent data to set the map
        
        if(!initiallyLoaded)
        {
            print("1st time MapVC view appears")
            savedLocation = NSUserDefaults.standardUserDefaults().boolForKey(Constants.PersistenLabelKeys.savedLoc);
            
            if let savedRegion = NSUserDefaults.standardUserDefaults().objectForKey(Constants.PersistenLabelKeys.mapReg) as? [String: Double]
            {
                print("load saved region from the persisten data NSUserDefaults")
                let center = CLLocationCoordinate2D(latitude: savedRegion["mapRegionCenterLat"]!, longitude: savedRegion["mapRegionCenterLon"]!)
                
                let span = MKCoordinateSpan(latitudeDelta: savedRegion["mapRegionSpanLatDelta"]!, longitudeDelta: savedRegion["mapRegionSpanLonDelta"]!)
                
                mapView.region = MKCoordinateRegion(center: center, span: span)
            }
            
            //load all pins from the persistent store and add them to the map
            let annotationsToLoad = loadAllPins()
            mapView.addAnnotations(annotationsToLoad)
            
            //prevents this block of code from running again during the session
            initiallyLoaded = true
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: ----------------
    
    /**
    * It is the callback for when the CLLocationManagerDelegate gets the current position on the map.
    **/
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        location = locations.last! as CLLocation
        
        //just want to place the map in the current location once, after we want to let the user move the map freely.
        if let coords = location?.coordinate
        {
            if(firstLoad && !savedLocation)
            {
                print("locationManager firstLoad false")
                let center = CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude)
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09))
                mapView.setRegion(region, animated: true)
            }

            firstLoad = false
        }
        else
        {
            print("location coordinate is nil")
        }
    }

    // MARK: - MKMapViewDelegate methods
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        print("mapView viewForAnnotation")
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil
        {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinColor = .Red
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else
        {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl)
    {
        if control == view.rightCalloutAccessoryView
        {
            let app = UIApplication.sharedApplication()
            
            if let toOpen = view.annotation?.subtitle!
            {
            }
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        if mapViewRegionDidChangeFromUserInteraction()
        {
             print("region did change by USER to \(mapView.region.center)")
            
            let regionToSave = [
                "mapRegionCenterLat": mapView.region.center.latitude,
                "mapRegionCenterLon": mapView.region.center.longitude,
                "mapRegionSpanLatDelta": mapView.region.span.latitudeDelta,
                "mapRegionSpanLonDelta": mapView.region.span.longitudeDelta
            ]
            
            savedLocation = true
            NSUserDefaults.standardUserDefaults().setBool(savedLocation, forKey: Constants.PersistenLabelKeys.savedLoc)
            NSUserDefaults.standardUserDefaults().setObject(regionToSave, forKey: Constants.PersistenLabelKeys.mapReg)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    func mapViewRegionDidChangeFromUserInteraction() -> Bool
    {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers
        {
            print("mapViewRegionDidChangeFromUserInteraction")
            
            for recognizer in gestureRecognizers
            {
                if (recognizer.state == UIGestureRecognizerState.Began ||
                    recognizer.state == UIGestureRecognizerState.Ended)
                {
                    return true
                }
            }
        }
        return false
    }

    //MARK: -------- CUSTOM METHODS --------
    func addAnnotation(gesture:UIGestureRecognizer)
    {
        print("addAnnotation")
        switch gesture.state
        {
            case .Began:
                print("gesture .Began")
                updatePinLocation(gesture)
                temporaryAnnotation = MKPointAnnotation()
                mapView.addAnnotation(temporaryAnnotation)
                temporaryAnnotation.coordinate = coordinate
                
                //need to include .Changed so that the pin will move along with the finger drag
            case .Changed:
                print("gesture .Changed")
                updatePinLocation(gesture)
                temporaryAnnotation.coordinate = coordinate
                
            case .Ended:
                print("gesture .Ended")
                updatePinLocation(gesture)
                let newAnnotation = PinCustom(latitude: coordinate.latitude, longitude: coordinate.longitude, title: nil, subtitle: nil, context: sharedContext)
                //the globablly tracked activeAnnotation is set to the new PinAnnotation because activeAnnotation is used in other methods
                activeAnnotation = newAnnotation
                activeAnnotation.latitude = coordinate.latitude
                activeAnnotation.longitude = coordinate.longitude
                
                //the two lines below are where the temporary MKPointAnnotation (and associated pin)
                //is being "swapped out" for the new PinAnnnotation (and its associated pin);
                mapView.addAnnotation(activeAnnotation)
                mapView.removeAnnotation(temporaryAnnotation)
                
                //get the geotagged location information for the activeAnnotation, which will update the pin's "title" property and be used as the segued-to photo album's navigation bar's title
                lookUpLocation(activeAnnotation)
                
                do
                {
                    //save the new pin to the persistent store; 
                    //note: it's possible that the pin is being saved without the title on the pin having been set (since lookUpLocation occurs asycnhronously)
                    try sharedContext.save()
                }
                catch { }
                
                //call to the method to begin the execution of a flickr request to search for images at a given coordinate
    //            getPhotosAtLocation(activeAnnotation.coordinate)
                
            default:
                break
        }
    }
    
    /**
     * This method converts the location (CGPoint) of the gesture's location to a geographical coordinate 
     * that can be used and displayed on the map via the mapView's convertPoint method
     **/
    func updatePinLocation(gesture: UIGestureRecognizer)
    {
        //since the convertPoint is occurring on the same mapView as the destination mapView, the only conversion that is happening is a conversion of the point from a gesture-based CGPoint (where the user released the pin) to the geographical CLLocationCoordinate2D type that is required in order to add the location to a mapView
        coordinate = mapView.convertPoint(gesture.locationInView(mapView), toCoordinateFromView: mapView)
        
        //offsets the pin vertically by a small amount so the user can see with a finger placed on the screen where the tip of the pin is going to be located
        coordinate.latitude += Constants.MapViewConstants.PinDropLatitudeOffset
    }
    
    /** 
     * Method that determines a string-based location for the user's pin using reverse geocoding; 
     * the location that gets returned is the "locality" of the placemark, which corresponds to the city
    **/
    func lookUpLocation(annotation: MKAnnotation)
    {
        let geocoder = CLGeocoder()
        
        let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location)
        {
            [unowned self] (placemarksArray, error) in
            if let placemarks = placemarksArray
            {
                //checks to see if the locality (city) of the placemark is not nil, and if so, sets the title of the activeAnnotation to that locality and updates the PinCustom object in the persistent store; note that this is done on the main queue, since updates to core data should be done on the main queue
                dispatch_async(dispatch_get_main_queue(), {
                    if let locality = placemarks[0].locality
                    {
                        self.activeAnnotation.title = locality
                        do
                        {
                            try self.sharedContext.save()
                        }
                        catch { }
                    }
                })
            }
        }
    }
    
    ///this method loads all the Pins from the persistent store and returns an array of all currently saved "Pin" objects; this method is called exclusively on the first invocation of viewDidAppear (see comment near viewDidAppear for why it doesn't occur in viewWillAppear instead)
    func loadAllPins() -> [PinCustom]
    {
        //create a database search request on the "Pin" column; since there are no sorts or predicates added to this fetch request, all Pins are returned (which is what we want)
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do
        {
            //perform the fetch, which returns [AnyObject], then downcast it as [PinAnnotation] (since we know that is the NSManaged class associated with the Pin entity in the core data model)
            return try sharedContext.executeFetchRequest(fetchRequest) as! [PinCustom]
        }
        catch
        {
            //if there is a problem for some reason, return an empty array (i.e. no pins will appear on map)
            return [PinCustom]()
        }
    }
}

