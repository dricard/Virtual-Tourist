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
      
      
   }
}

extension PhotosViewController: UICollectionViewDelegate {
   
}

extension PhotosViewController: UICollectionViewDataSource {
   
   // MARK: - CollectionViewController subclass required methods
   
   func numberOfSections(in collectionView: UICollectionView) -> Int {
      //      let sections = self.frc?.sections?.count ?? 0
      //      return sections
      return 1
   }
   
   func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
      
      guard let photos = pin?.photos else { return 1 }
      
      return photos.count
      
   }
   
   func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
      
      // Create a cell
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
      
      guard let photo = pin?.photos?[indexPath.item] as Photo else { return cell }
      
      // Configure the cell
      
      if let imagePath = photo.imagePath {
         let imageURL = URL(string: imagePath)
         if let imageData = try? Data(contentsOf: imageURL!) {
            cell.imageView.image = UIImage(data: imageData)
         } else {
            print("Unable to get imageData from imageURL")
         }
      } else {
         cell.imageView.image = UIImage(named: "cube")
      }
      
      return cell
   }
   
}


