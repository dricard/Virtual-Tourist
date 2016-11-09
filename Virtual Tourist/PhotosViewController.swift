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
   var updatedCache: [IndexPath]!
   var selectedCache = [IndexPath]()
   
   // minimum space between cells
   let space: CGFloat = 3.0
   
   // MARK: - Outlets
   
   @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
   @IBOutlet weak var collectionView: UICollectionView!
   @IBOutlet weak var mapView: MKMapView!
   @IBOutlet weak var button: UIBarButtonItem!
   @IBOutlet weak var noImagesLabel: UILabel!
   @IBAction func buttonTapped(_ sender: Any) {
      
      if selectedCache.isEmpty {
         // Button is to delete all photos and load new ones
         deleteAllPhotos()
      } else {
         // Button is to delete selected photos
         deleteSelectedPhotos()
      }
   }
   
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
      
      // Lay out the collection view so that cells take up 1/3 of the width,
      // with no space in between.
      let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
      layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
      layout.minimumLineSpacing = 0
      layout.minimumInteritemSpacing = 0
      
      let width = floor(view.frame.width/3)
      layout.itemSize = CGSize(width: width, height: width)
      collectionView.collectionViewLayout = layout
      
      // set delegates for the collectionView
      
      collectionView.delegate = self
      collectionView.dataSource = self
      
      // new to iOS 10 - enable prefetcing
      collectionView.prefetchDataSource = self
      collectionView.isPrefetchingEnabled = true
      
      // Disable bottom button until photos are displayed
      tabBarController?.tabBar.isHidden = true
      button.isEnabled = false
      configureButton()
      
      // set-up the fetchedResultController
      
      // 1. set the fetchRequest
      let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
      fetchRequest.fetchBatchSize = 18
      
      let idSort = NSSortDescriptor(key: #keyPath(Photo.id), ascending: true)
      fetchRequest.sortDescriptors = [idSort]
      fetchRequest.predicate = NSPredicate(format: "pin = %@", pin!)
      
      // 2. create the fetchedResultsController
      
      fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
      
      // 3. set the delegate
      
      fetchedResultsController.delegate = self
      
      // 4. perform the fetch
      
      doFetch()
      
      
      if let photos = fetchedResultsController.fetchedObjects {
         
         if photos.count == 0 {
            // no photos at this location, fetch new ones
            //            print("photos is empty, fetch new photos")
            fetchPhotos(pin: pin!)
         } else {
            // there are photos in this location so display them
            //            print("photos is not empty, display photos")
            // we need to enable the bottom button
            tabBarController?.tabBar.isHidden = false
            button.isEnabled = true
            
         }
      } else {
         // photos is nil so there are no photos: fetch photos
         //         print("photos is nil, fetch photos")
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
         
         // Did we receive photos
         guard photosDict != nil else {
            print("Photos dictionay returned is nil")
            return
         }
         
         // Process the photos dictionary asynchronously on the main thread
         DispatchQueue.main.async {
            self.managedContext.performAndWait() {
               if let photosDict = photosDict {
                  if photosDict.count == 0 {
                     // NO photos in returned data
                     // Display label to indicate no photos to user
                     self.noImagesLabel.isHidden = false
                     // Disable interface for deleting or reloading photos
                     self.button.isEnabled = false
                     self.tabBarController?.tabBar.isHidden = true
                  } else {
                     self.noImagesLabel.isHidden = true
                  }
                  for photoDict in photosDict {
                     
                     // Here we download all the photos' URL and title,
                     // but not the actual photos, this is done in the cellForItemAtIndexpath method
                     // as each photo is required (and if needed)
                     let photo = Photo(context: self.managedContext)
                     photo.title = photoDict[Flickr.Title] as? String
                     photo.id = photoDict[Flickr.ID] as? String
                     photo.imageURL = photoDict[Flickr.ImagePath] as? String
                     photo.pin = pin
                  }
               }
               // when all photos objects are created, save the context
               do {
                  try self.managedContext.save()
               } catch let error as NSError {
                  print("Could not save: \(error), \(error.userInfo)")
               }
               
            }
            
            // re-enable the button if photos were found
            if (self.fetchedResultsController.fetchedObjects?.count)! > 0 {
               self.tabBarController?.tabBar.isHidden = false
               self.button.isEnabled = true
               
            }
            
         }
         
      }
   }
   
   // execute the fetch request
   func doFetch() {
      do {
         try fetchedResultsController.performFetch()
      } catch let error as NSError {
         print("Could not fetch \(error), \(error.userInfo)")
      }
   }
   
   func deleteAllPhotos() {
      
      // First prevent the button from being pressed a second time
      button.isEnabled = false
      tabBarController?.tabBar.isHidden = true
      
      // Then delete all photos from the context
      for photo in fetchedResultsController.fetchedObjects! {
         managedContext.delete(photo)
      }
      
      // save the context to persist the change
      do {
         try managedContext.save()
      } catch let error as NSError {
         print("Could not save context \(error), \(error.userInfo)")
      }
      
      // refetch new photos from network
      fetchPhotos(pin: pin!)
      
   }
   
   func deleteSelectedPhotos() {
      
      var photosToDelete = [Photo]()
      
      // get the list of Photos to delete
      for indexPath in selectedCache {
         photosToDelete.append(fetchedResultsController.object(at: indexPath))
      }
      
      // remove each photo from the managed context
      for photo in photosToDelete {
         managedContext.delete(photo)
      }
      
      // reset the selection of photos
      selectedCache.removeAll()
      // update the interface
      configureButton()
      // save the context
      do {
         try managedContext.save()
      } catch let error as NSError {
         print("Could not save context \(error), \(error.userInfo)")
      }
      
   }
   
}

// MARK: - EXTENSION - CollectionView Delegate

extension PhotosViewController: UICollectionViewDelegate {
   
   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      
      let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
      
      // Toggle selection of this cell
      if let index = selectedCache.index(of: indexPath) {
         selectedCache.remove(at: index)
      } else {
         selectedCache.append(indexPath)
      }
      
      // reconfigure the cell
      configure(cell, for: indexPath)
      
      // update interface
      configureButton()
   }
   
}

// MARK: - EXTENSION - Internals

extension PhotosViewController {
   
   // Configure the collectionView cell
   func configure(_ cell: UICollectionViewCell, for indexPath: IndexPath) {
      
      guard let cell = cell as? PhotoCell else { return }
      
      var image: UIImage
      cell.activityIndicator.hidesWhenStopped = true
      cell.activityIndicator.startAnimating()
      // get a reference to the object for the cell
      let photo = fetchedResultsController.object(at: indexPath)
      // default value for image
      image = UIImage(named: "logo_210")!
      // check to see if the image is already in core data
      if photo.image != nil {
         // image exists, use it
         cell.activityIndicator.stopAnimating()
         image = UIImage(data: photo.image!)!
      } else {
         // image has not been downloaded, try to download it
         if let imagePath = photo.imageURL {
            NetworkAPI.requestPhotoData(photoURL: imagePath) { (result, error) in
               
               // GUARD - check for error
               guard error == nil else {
                  print("Error fetching photo data: \(error)")
                  return
               }
               
               // GUARD - check for valid data
               guard let result = result else {
                  print("No data returned for photo")
                  return
               }
               
               // Dispatch on main queue to update photo image
               DispatchQueue.main.async {
                  cell.activityIndicator.stopAnimating()
                  photo.image = result as Data
                  cell.imageView.image = UIImage(data: result as Data)
               }
            }
         }
      }
      
      cell.imageView.image = image
      cell.imageView.contentMode = .scaleAspectFill
      
      // apply 'selected' to cell if appropriate
      if let _ = selectedCache.index(of: indexPath) {
         cell.alpha = 0.5
      } else {
         cell.alpha = 1.0
      }
      
   }
   
   func configureButton() {
      if selectedCache.isEmpty {
         // No photos selected, so option is to remove all photos
         button.title = "Remove all photos"
      } else {
         // Some photos are selected, so option is to remove those
         button.title = "Remove selected photos"
      }
   }
   
   
}

// MARK: - EXTENSION - CollectionView Datasource

extension PhotosViewController: UICollectionViewDataSource {
   
   // MARK: - CollectionView Datasource methods
   
   func numberOfSections(in collectionView: UICollectionView) -> Int {
      
      guard let sections = fetchedResultsController.sections else { return 1 }
      
      return sections.count
   }
   
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      
      guard let sectionInfo = fetchedResultsController.sections?[section] else {
         // we don't have photos yet, so fill a screen with placeholder images
         // while we wait
         return 9
      }
      
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
      updatedCache = [IndexPath]()
   }
   
   func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
      
      switch type {
      case .insert:
         
         insertedCache.append(newIndexPath!)
      case .delete:
         
         deletedCache.append(indexPath!)
      case .move:
         print("=== didChange .move type")
         //         deletedCache.append(indexPath!)
      //         insertedCache.append(newIndexPath!)
      case .update:
         updatedCache.append(indexPath!)
      }
   }
   
   func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
      
      collectionView.performBatchUpdates({
         for indexPath in self.insertedCache {
            self.collectionView.insertItems(at: [indexPath])
         }
         for indexPath in self.deletedCache {
            self.collectionView.deleteItems(at: [indexPath])
         }
         for indexPath in self.updatedCache {
            self.collectionView.reloadItems(at: [indexPath])
         }
      }, completion: nil)
   }
}

// MARK: - EXTENSION - collectionView Data Source Prefetching

extension PhotosViewController: UICollectionViewDataSourcePrefetching {
   
   func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
      
      for indexPath in indexPaths {
         // Create a cell
         
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
         
         configure(cell, for: indexPath)
      }
   }
}
