//
//  Constants.swift
//  Virtual Turist
//
//  Created by Xavier Jorda Murria on 28/04/2016.
//  Copyright © 2016 xjm. All rights reserved.
//

import Foundation
import MapKit

class Constants
{
    struct MapViewConstants
    {
        static let LongPressDuration = 0.5
        static let ShowPhotoAlbumSegue = "ShowPhotoAlbum"
        
        //used to offset where a user taps with a finger and the vertical location of the pin; this allows the pin to appear slightly ABOVE the user's finger, so the user can see where the tip is being placed
        static let PinDropLatitudeOffset: CLLocationDegrees = 1
        
        //for the constant below, i decided to use 36 because it seems like a reasonable size for an image collection, and also divisible by 3 and 4 (which are the number of columsn of photos within the collection view when in portrait and landscape modes); one enhancement i would make if i were to fully develop this app would be to enable the user to decide this value
        static let MaxNumberOfPhotosToSavePerPin = 36
    }
    
    struct PersistenLabelKeys
    {
        static let savedLoc = "savedLoc"
        static let mapReg = "savedMapRegion"
    }
}
