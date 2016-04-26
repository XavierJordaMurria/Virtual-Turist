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
    var firstLoad:Bool = false
    
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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print("viewDidLoad")
        
        if (CLLocationManager.locationServicesEnabled())
        {
            print("locationServicesEnabled")
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        //get persistent data to set the map
        savedLocation = NSUserDefaults.standardUserDefaults().boolForKey(persistenLabelKeys.savedLoc)
        
        if(savedLocation)
        {
            if let savedRegion = NSUserDefaults.standardUserDefaults().objectForKey("savedMapRegion") as? [String: Double]
            {
                let center = CLLocationCoordinate2D(latitude: savedRegion["mapRegionCenterLat"]!, longitude: savedRegion["mapRegionCenterLon"]!)
                
                let span = MKCoordinateSpan(latitudeDelta: savedRegion["mapRegionSpanLatDelta"]!, longitudeDelta: savedRegion["mapRegionSpanLonDelta"]!)
                
                mapView.region = MKCoordinateRegion(center: center, span: span)
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
    * It is the callback for when the CLLocationManagerDelegate gets the current position on the map.
    **/
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        location = locations.last! as CLLocation
        
        //just want to place the map in the current location once, after we want to let the user move the map freely.

        if let coords = location?.coordinate
        {
            if(!firstLoad)
            {
                print("locationManager savedLocation false")
                let center = CLLocationCoordinate2D(latitude: coords.latitude, longitude: coords.longitude)
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.09, longitudeDelta: 0.09))
                mapView.setRegion(region, animated: true)
            }

            firstLoad = true
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
        print("region did change to \(mapView.region.center)")
        
        if mapViewRegionDidChangeFromUserInteraction()
        {
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

