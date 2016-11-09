//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Denis Ricard on 2016-10-22.
//  Copyright © 2016 Hexaedre. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
   
   // MARK: - Properties
   
   var managedContext: NSManagedObjectContext!
   let longPressRec = UILongPressGestureRecognizer()
   var restoringRegion = false
   var region: MKCoordinateRegion?
   var pin: Pin?
   
   var pins: [Pin] = []
   var asyncFetchRequest: NSAsynchronousFetchRequest<Pin>!

   // MARK: - Outlets
   
   @IBOutlet weak var mapView: MKMapView!
   
   // MARK: - Life Cycle
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      // Configure the gesture recgnizer for long presses
      longPressRec.addTarget(self, action: #selector(MapViewController.userLongPressed))
      longPressRec.allowableMovement = 25
      longPressRec.minimumPressDuration = 1.0
      longPressRec.numberOfTouchesRequired = 1
      view!.addGestureRecognizer(longPressRec)
      
      // set the delegate
      mapView.delegate = self
      
      // Restore the saved state of the map view
      restoreMapRegion(animated: true)
      
      // check CoreData for all available Pins
      let pinFetch: NSFetchRequest<Pin> = Pin.fetchRequest()
      
      do {
         // execute the fetch request
         let pins = try managedContext.fetch(pinFetch)
         // validate that there are pins in Core Data
         if pins.isEmpty {
            // no pins in Core Data, display onboarding experience
            self.displayOnBoarding()
            return
         }
         // display the pins on the map
         self.pins = pins
         self.displayPinsOnMap(pins: pins)
         
      } catch let error as NSError {
         print("Fetch error: \(error), \(error.userInfo)")
      }
     
   }
   
   override func viewWillDisappear(_ animated: Bool) {
      // we're going to another view, let's save the current state
      saveMapRegion()
   }
   
   override func viewWillAppear(_ animated: Bool) {
      // Here we save the context for the following reason:
      // If the user pressed a pin and moved to the PhotosViewController
      // Photos might have been downloaded, deleted, etc. So we save here
      // to preserve the data when the user returns from that VC
      
      do {
         try managedContext.save()
      } catch let error as NSError {
         print("Could not save context \(error), \(error.userInfo)")
      }

   }
   
   
   // MARK: - Utilities
   
   // This is a utility function for the saveMapRegion method
   var filePath: String = {
      let manager = FileManager.default
      let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
      return url.appendingPathComponent("mapRegionArchive").path
   }()
   
   // MARK: - Map methods
   
   func saveMapRegion() {
      
      // Place the center and span of the map into a dictonary
      // Span is the width and the height of the map in degrees
      // It represents the zoom level of the map
      
      let dictionary = [
         Const.latitudeKey : mapView.region.center.latitude,
         Const.longitudeKey: mapView.region.center.longitude,
         Const.latitudeDeltaKey : mapView.region.span.latitudeDelta,
         Const.longitudeDeltaKey : mapView.region.span.longitudeDelta
      ]
      
      // Archive the dictionary using filePath computed property
      NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
   }
   
   func restoreMapRegion(animated: Bool) {
      
      // prevent update to save region while we're restoring
      restoringRegion = true
      
      // if we can unarchive a dictionary, we will use it to set the map
      // back to its previous state (center and span)
      
      if let regionDictionary = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [String:AnyObject] {
         
         let longitude = regionDictionary[Const.longitudeKey] as! CLLocationDegrees
         let latitude = regionDictionary[Const.latitudeKey] as! CLLocationDegrees
         let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
         
         let longitudeDelta = regionDictionary[Const.longitudeDeltaKey] as! CLLocationDegrees
         let latitudeDelta = regionDictionary[Const.latitudeDeltaKey] as! CLLocationDegrees
         let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
         
         let savedRegion = MKCoordinateRegion(center: center, span: span)
         
         mapView.setRegion(savedRegion, animated: animated)
      }
      
      restoringRegion = false
   }
   
   // MARK: - Display methods
   
   func displayPinsOnMap(pins: [Pin]) {
      
      for pin in pins {
         var locationCoordinate = CLLocationCoordinate2D()
         locationCoordinate.latitude = pin.lat
         locationCoordinate.longitude = pin.lon
         let annotation = MKPointAnnotation()
         annotation.coordinate = locationCoordinate
         
         mapView.addAnnotation(annotation)
      }
      
   }
   
   func displayOnBoarding() {
      print("onboarding experience")
   }
   
   // MARK: - User action methods
   
   func userLongPressed(_ sender: AnyObject) {
      
      if longPressRec.state == UIGestureRecognizerState.began {
         
         // Get location of the longpress in mapView
         let location = sender.location(in: mapView)
         
         // Get the map coordinate from the point pressed on the map
         let locationCoordinate = mapView.convert(location, toCoordinateFrom: mapView)
         
         // create annotation
         let annotation = MKPointAnnotation()
         annotation.coordinate = locationCoordinate
         
         // now create the pin
         let pin = Pin(context: managedContext)
         pin.lat = locationCoordinate.latitude
         pin.lon = locationCoordinate.longitude
         // save the context
         do {
            try managedContext.save()
         } catch let error as NSError {
            print("Unresolved error: \(error), \(error.userInfo)")
         }
         // add annotation
         mapView.addAnnotation(annotation)
         
      }
   }
   
   // MARK: - Segue methods
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      // pass the selected pin and the managedContext to the PhotosViewController
      let controller = segue.destination as! PhotosViewController
      controller.pin = pin
      controller.managedContext = managedContext
      controller.focusedRegion = region
   }
   
   func presentPhotosViewController(pin: Pin, coordinate: CLLocationCoordinate2D) {
      
      // first get the region to pass to PhotosViewController
      
      let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
      let lonDelta = mapView.region.span.longitudeDelta
      let latDelta = mapView.region.span.latitudeDelta / 3
      let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
      region = MKCoordinateRegion(center: center, span: span)
      
      performSegue(withIdentifier: "PhotosView", sender: self)
   }
   
   // MARK: - MapView Delegates
   
   func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      
      let reuseId = "pin"
      
      var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
      
      if pinView != nil {
         pinView!.annotation = annotation
      } else {
         pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
         pinView!.canShowCallout = false
         pinView!.pinTintColor = UIColor.black
         pinView!.animatesDrop = true
      }
      return pinView
   }
   
   func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      // if we're in the process or restoring the map region, do not save
      // otherwise save the region since it changed
      if restoringRegion == false {
         saveMapRegion()
      }
   }
   
   // User selected a pin, transition to PhotosViewController
   func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
      
      // first unselect the pin
      mapView.deselectAnnotation(view.annotation! , animated: true)

      guard view.annotation != nil else { return }
      
      let coordinate = view.annotation!.coordinate
      
      // check CoreData for corresponding Pin
      let pinFetch: NSFetchRequest<Pin> = Pin.fetchRequest()
      // we'll fetch the results with same latitude and longitude
      let precision = 0.0001
      pinFetch.predicate = NSPredicate(format: "(%K BETWEEN {\(coordinate.latitude - precision), \(coordinate.latitude + precision) }) AND (%K BETWEEN {\(coordinate.longitude - precision), \(coordinate.longitude + precision) })", #keyPath(Pin.lat), #keyPath(Pin.lon))
           
      do {
         let pins = try managedContext.fetch(pinFetch)
         
            if pins.count > 0 {
               if pins.count > 1 {
                  // more than one possibility, so we refine the search?
                  // TODO: - Resolve possibility of more than one matched pin
                  // For now just use the first one
                  self.pin = pins.first
                  // print data to fine tune precision
                  print("More than one pin returned from fetc: \(pins.count)")
                  
                  // present the photos view controller
                  self.presentPhotosViewController(pin: self.pin!, coordinate: coordinate)
               } else {
                  // there is only one match, so this is our pin
                  self.pin = pins.first
                  
                  // present the photos view controller
                  self.presentPhotosViewController(pin: self.pin!, coordinate: coordinate)
               }
            } else {
               // there are no pins returned from the fetch, something went wrong
               print("Could not find a matching pin for this latitude: \(coordinate.latitude) and longitude: \(coordinate.longitude)")
            }
         
      } catch let error as NSError {
         print("Fetch error: \(error), \(error.userInfo)")
      }
      
      
   }
   
}
