//
//  NDContactViewController.swift
//  News
//
//  Created by Sachin Vas on 7/17/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

let rowHeight: CGFloat = 50.0; //Row Height from storyboard

class NDContactViewController: UITableViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var navigationLabel: UILabel!
    @IBOutlet weak var websiteLabel: UILabel!
    @IBOutlet weak var emailId: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    private var locationManager:CLLocationManager!
    private var mapViewRect: CGRect!
    private var nearByContact: Contact!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10.0
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        NDNetworkManager.sharedManager.getContactDetailsFromDatalicicous {[weak self] (success:Bool, error:NSError?) in
            dispatch_async(dispatch_get_main_queue(), {
                if success {
                if self?.nearByContact == nil && CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
                    self?.nearByContact = self?.contactNearToUserLocation()
                    if self?.nearByContact != nil {
                        self?.updateTableView()
                    }
                }
                } else if let error = error {
                    let alertController = UIAlertController(title: "Error Occurred", message: error.localizedDescription, preferredStyle: .Alert)
                    let action = UIAlertAction(title: "Ok", style: .Cancel, handler: { (action:UIAlertAction) in
                        alertController.dismissViewControllerAnimated(true, completion: nil)
                    })
                    alertController.addAction(action)
                    self?.navigationController?.presentViewController(alertController, animated: true, completion: nil)
                }
            })
        }
    }
    
    func updateTableView() {
        navigationLabel.text = self.nearByContact.address
        websiteLabel.text = "http://www.datalicious.com/"
        emailId.text = self.nearByContact.emailId
        phoneNumberLabel.text = self.nearByContact.phoneNumber
    }
    
    func contactNearToUserLocation() -> Contact? {
        if mapView.userLocation.location != nil {
            let fetchRequest = NSFetchRequest(entityName: "Contact")
            let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]
            fetchRequest.resultType = .ManagedObjectResultType
            var closestContact: Contact?
            var smallestDistance: CLLocationDistance?
            do {
                let fetchedObjects = try NDCoreDataManager.sharedManager.mainQueueMOC.executeFetchRequest(fetchRequest)
                if let fetchedObjects = fetchedObjects as? Array<Contact> {
                    for contact in fetchedObjects {
                        if contact.latitude?.intValue == 0 && contact.latitude?.intValue == 0 {
                            continue
                        }
                        let location = CLLocation(latitude: contact.latitude!.doubleValue, longitude: contact.longitude!.doubleValue)
                        let distance = mapView.userLocation.location?.distanceFromLocation(location)
                        if smallestDistance == nil || distance < smallestDistance {
                            closestContact = contact
                            smallestDistance = distance!
                        }
                    }
                }
            } catch let error {
                print(error)
            }
            print("closestLocation: \(closestContact), distance: \(smallestDistance)")
            return closestContact
        }
        return nil
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if mapViewRect != nil {
            configureMapView()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        purgeMapView()
    }
    
    func purgeMapView() {
        autoreleasepool {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            tableView.tableHeaderView = nil
            mapView.showsUserLocation = false
            mapView.delegate = nil
            mapView.removeFromSuperview()
            mapView = nil
        }
    }
    
    func configureMapView() {
        mapView = MKMapView()
        mapView.frame = mapViewRect
        mapView.mapType = .Standard
        mapView.zoomEnabled = true
        mapView.scrollEnabled = true
        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    var navigationBarHeight:CGFloat {
        get {
            var height:CGFloat = 0.0
            if let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController {
                height = rootViewController.navigationBar.frame.size.height
            }
            return height
        }
    }
    
    var mapView:MKMapView!
    var pointAnnotation:MKPointAnnotation?
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if mapView == nil {
            mapViewRect = CGRect(x: 0.0, y: navigationBarHeight, width: tableView.frame.size.width, height: tableView.frame.size.height - 5*rowHeight - navigationBarHeight)
            configureMapView()
        }
        return mapView
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        let region = MKCoordinateRegionMakeWithDistance(newLocation.coordinate, 600, 600)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        let alertController = UIAlertController(title: "Location Services Not Enabled", message: "Please Check your Setting to enable the location services", preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "Ok", style: .Cancel) {[weak self] (action:UIAlertAction) in
            self?.mapView.hidden = true
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(alertAction)
        navigationController?.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 600, 600)
        mapView.setRegion(region, animated: true)
        
        if pointAnnotation == nil {
            pointAnnotation = MKPointAnnotation()
            mapView.addAnnotation(pointAnnotation!)
            if nearByContact == nil {
                nearByContact = contactNearToUserLocation()
                if nearByContact != nil {
                    updateTableView()
                }
            }
        }
        pointAnnotation!.coordinate = userLocation.coordinate
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableView.frame.size.height - 5*rowHeight
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.row == 0 {
            let coordinate = mapView.userLocation.coordinate
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
            mapItem.name = "Target location"
            mapItem.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        } else if indexPath.row == 1 {
            let url = NSURL(string: websiteLabel.text!)
            self.openURL(url!)
        } else if indexPath.row == 2 {
            let urlString = "mailto:" + emailId.text!
            let url = NSURL(string: urlString)
            self.openURL(url!)
        } else if indexPath.row == 3 {
            let urlString = "tel:" + phoneNumberLabel.text!
            let url = NSURL(string: urlString)
            self.openURL(url!)
        } else if indexPath.row == 4 {
            let supportEmailViewController = NDSupportMailViewController(nibName: "NDSupportMailViewController", bundle: nil)
            let navController = UINavigationController(rootViewController: supportEmailViewController)
            navigationController?.presentViewController(navController, animated: true, completion: nil)
        }
    }
    
    func openURL(url: NSURL) {
        if UIApplication.sharedApplication().canOpenURL(url) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}
