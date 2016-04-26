//
//  ViewController.swift
//  Virtual Turist
//
//  Created by Xavier Jorda Murria on 06/04/2016.
//  Copyright © 2016 xjm. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate
{
    @IBOutlet weak var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var location:CLLocation?
    var savedLocation:Bool = false
    
    //The 1st time that we load the map after installing the map from scratch, we want to show the current location
    var firstLoad:Bool = true
    
    //Bocking flag for the 1st time that we go into the viewDidLoad in the MapVC
    var initiallyLoaded:Bool = false
    
    struct persistenLabelKeys
    {
        static let savedLoc = "savedLoc"
        static let mapReg = "savedMapRegion"
    }
    
    struct previousCoordinates
    {
        static var lat: Double = 0.0
        static var lon: Double = 0.0
    }
    
    //MARK: -------- ViewController life Cycle Methods --------
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print("viewDidLoad")
        mapView.delegate = self
        
        if (CLLocationManager.locationServicesEnabled())
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
            savedLocation = NSUserDefaults.standardUserDefaults().boolForKey(persistenLabelKeys.savedLoc);
            
            if let savedRegion = NSUserDefaults.standardUserDefaults().objectForKey(persistenLabelKeys.mapReg) as? [String: Double]
            {
                print("load saved region from the persisten data NSUserDefaults")
                let center = CLLocationCoordinate2D(latitude: savedRegion["mapRegionCenterLat"]!, longitude: savedRegion["mapRegionCenterLon"]!)
                
                let span = MKCoordinateSpan(latitudeDelta: savedRegion["mapRegionSpanLatDelta"]!, longitudeDelta: savedRegion["mapRegionSpanLonDelta"]!)
                
                mapView.region = MKCoordinateRegion(center: center, span: span)
            }
            
            //load all pins from the persistent store and add them to the map
//                let annotationsToLoad = loadAllPins()
//                mapView.addAnnotations(annotationsToLoad)
            
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
    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
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
            NSUserDefaults.standardUserDefaults().setBool(savedLocation, forKey: persistenLabelKeys.savedLoc)
            NSUserDefaults.standardUserDefaults().setObject(regionToSave, forKey: persistenLabelKeys.mapReg)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    func mapViewRegionDidChangeFromUserInteraction() -> Bool
    {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers
        {
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
}

