//
//  PhotosViewController.swift
//  Virtual Tourist
//
//  Created by Denis Ricard on 2016-10-23.
//  Copyright © 2016 Hexaedre. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotosViewController: UIViewController {
   
   // MARK: - properties
   var pin: Pin?
   var managedContext: NSManagedObjectContext!
   var focusedRegion: MKCoordinateRegion?
   var fetchedResultsController: NSFetchedResultsController<Photo>!
   
   var insertedCache: [IndexPath]!
   var deletedCache: [IndexPath]!
   
   // MARK: - Outlets
   
   @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
   @IBOutlet weak var collectionView: UICollectionView!
   @IBOutlet weak var mapView: MKMapView!
   
   // MARK: - Life cycle
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      // set up portion of the map with the selected pin
      mapView.setRegion(focusedRegion!, animated: true)
      // Drop a pin at that location
      
      let lat = focusedRegion!.center.latitude
      let lon = focusedRegion!.center.longitude
      
      let locationCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
      
      let annotation = MKPointAnnotation()
      annotation.coordinate = locationCoordinate
      annotation.title = "Photos from here"
      
      mapView.addAnnotation(annotation)
      
      // set delegates for the collectionView
      
      collectionView.delegate = self
      collectionView.dataSource = self
      
      // set-up the fetchedResultController
      
      // 1. set the fetchRequest
      let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
      
      let idSort = NSSortDescriptor(key: #keyPath(Photo.id), ascending: true)
      fetchRequest.sortDescriptors = [idSort]
      fetchRequest.predicate = NSPredicate(format: "pin = %@", pin!)
      
      // 2. create the fetchedResultsController
      
      fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
      
      // 3. set the delegate
      
      fetchedResultsController.delegate = self
      
      // 4. perform the fetch
      
      do {
         try fetchedResultsController.performFetch()
      } catch let error as NSError {
         print("Could not fetch \(error), \(error.userInfo)")
      }

      
      if let photos = fetchedResultsController.fetchedObjects {
         
         if photos.count == 0 {
            // no photos at this location, fetch new ones
            print("photos is empty, fetch new photos")
            fetchPhotos(pin: pin!)
         } else {
            // there are photos in this location so display them
            print("photos is not empty, display photos")
         }
      } else {
         // photos is nil so there are no photos: fetch photos
         print("photos is nil, fetch photos")
         fetchPhotos(pin: pin!)
      }

   }
   
   override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      navigationController?.navigationBar.isHidden = false
   }

   // MARK: - Photos methods

   func fetchPhotos(pin: Pin) {
      NetworkAPI.sendRequest(pin) { (photosDict, success, error) in
         
         // GUARD: was there an error?
         guard error == nil else {
            print("Network request returned with error: \(error), \(error?.userInfo)")
            return
         }
         
         // GUARD: was it successful?
         guard success else {
            print("The request was unsuccessful: \(error), \(error?.userInfo)")
            return
         }
         
         // Process the photos dictionary
         
         if let photosDict = photosDict {
            for photoDict in photosDict {
               
               let photo = Photo(context: self.managedContext)
               photo.title = photoDict[Flickr.Title] as! String?
               photo.imageURL = photoDict[Flickr.ImagePath] as! String?
               photo.pin = pin
            }
         }
         
         do {
            try self.managedContext.save()
         } catch let error as NSError {
            print("Could not save: \(error), \(error.userInfo)")
         }
         
      }
   }
      
}

extension PhotosViewController: UICollectionViewDelegate {
   
}

// MARK: - Internals
extension PhotosViewController {
   
   func configure(_ cell: UICollectionViewCell, for indexPath: IndexPath) {
      
      guard let cell = cell as? PhotoCell else { return }
      
      let photo = fetchedResultsController.object(at: indexPath)
      
      if let imagePath = photo.imageURL {
         let imageURL = URL(string: imagePath)
         if let imageData = try? Data(contentsOf: imageURL!) {
            cell.imageView.image = UIImage(data: imageData)
         } else {
            print("Unable to get imageData from imageURL")
            cell.imageView.image = UIImage(named: "logo_210")
         }
      } else {
         cell.imageView.image = UIImage(named: "logo_210")
      }

   }
}

extension PhotosViewController: UICollectionViewDataSource {
   
   // MARK: - CollectionViewController subclass required methods
   
   func numberOfSections(in collectionView: UICollectionView) -> Int {
      
      guard let sections = fetchedResultsController.sections else { return 0 }
      
      return sections.count
   }
   
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      
      guard let sectionInfo = fetchedResultsController.sections?[section] else { return 0 }
      
      return sectionInfo.numberOfObjects
      
   }
   
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      
      // Create a cell
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
      
      configure(cell, for: indexPath)
      
      return cell
   }
   
}

// MARK: - NSFetchedResultsControllerDelegate
extension PhotosViewController: NSFetchedResultsControllerDelegate {
   
   func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      insertedCache = [IndexPath]()
      deletedCache = [IndexPath]()
   }
   
   func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
      
      switch type {
      case .insert:
         insertedCache.append(newIndexPath!)
      case .delete:
         deletedCache.append(indexPath!)
      case .move:
         deletedCache.append(indexPath!)
         insertedCache.append(newIndexPath!)
      default:
         break
      }
   }
   
   func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      collectionView.performBatchUpdates({ 
         self.collectionView.insertItems(at: self.insertedCache)
         self.collectionView.deleteItems(at: self.deletedCache)
         }, completion: nil)
   }
}
