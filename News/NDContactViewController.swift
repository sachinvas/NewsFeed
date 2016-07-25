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

let rowHeight: CGFloat = 50.0; //Row Height from storyboard

class NDContactViewController: UITableViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NDNetworkManager.sharedManager.getContactDetailsFromDatalicicous { (success:Bool) in
            
        }
    }
    
    var navigationBarHeight:CGFloat {
        get {
            var height:CGFloat = 0.0
            if let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController {
                height = rootViewController.navigationBar.frame.size.height;
            }
            return height
        }
    }
    
    let mapView:MKMapView = MKMapView()
    var pointAnnotation:MKPointAnnotation?
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if mapView.frame == CGRectZero {
            mapView.frame = CGRect(x: 0.0, y: navigationBarHeight, width: tableView.frame.size.width, height: tableView.frame.size.height - 5*rowHeight - navigationBarHeight)
            mapView.mapType = .Standard
            mapView.delegate = self
            mapView.zoomEnabled = true
            mapView.scrollEnabled = true
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .Follow
        }
        return mapView
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        let region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 200, 200)
        mapView.setRegion(region, animated: true)
        
        if pointAnnotation == nil {
            pointAnnotation = MKPointAnnotation()
            mapView.addAnnotation(pointAnnotation!)
        }
        pointAnnotation!.coordinate = userLocation.coordinate
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableView.frame.size.height - 5*rowHeight
    }
}
