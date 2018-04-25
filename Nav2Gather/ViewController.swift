//
//  ViewController.swift
//  Nav2Gather
//
//  Created by Apurva Patel on 4/24/18.
//  Copyright © 2018 Apurva Patel. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation

class ViewController : UIViewController {
    
    
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    let locationManager = CLLocationManager()
    var currentCoordinate : CLLocationCoordinate2D!
    
    var steps = [MKRouteStep]()
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var searchBarAndTableContainer: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var directionLabel: UILabel!
    @IBOutlet weak var searchBarAndTableContainerHeight: NSLayoutConstraint!
    @IBOutlet weak var searchResultsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        searchCompleter.delegate = self
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        
        //let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        //view.addGestureRecognizer(tapGesture)
    }
    
    
    
    func getDirections (to destination: MKMapItem) {
        
        
        let sourcePlaceMark = MKPlacemark(coordinate: currentCoordinate)
        let sourceMapItem = MKMapItem(placemark: sourcePlaceMark)
        
        let directionRequeset = MKDirectionsRequest()
        directionRequeset.source = sourceMapItem
        directionRequeset.destination = destination
        directionRequeset.transportType = .automobile
        let direction = MKDirections(request: directionRequeset)
        direction.calculate { (response, error) in
            if error != nil {
                print ("Error \(String(describing: error))")
                self.directionLabel.text = "Error calculating route."
            } else {
                if let primaryRoute = response?.routes.first {
                self.mapView.add(primaryRoute.polyline)
                self.steps = primaryRoute.steps
                    
                    self.locationManager.monitoredRegions.forEach({self.locationManager.stopMonitoring(for: $0)})
                    
                    for i in 0 ..< primaryRoute.steps.count {
                        
                        let step = primaryRoute.steps[i]
                        print (step.instructions)
                        print (step.distance)
                        
                        let region = CLCircularRegion(center: step.polyline.coordinate, radius: 5, identifier: "\(i)")
                        
                        self.locationManager.startMonitoring(for: region)
                        
                        let circle = MKCircle(center: region.center, radius: region.radius)
                        
                        self.mapView.add(circle)
                        
                    }
                    
                }
            }
            
        }
    }
    
}

//MARK :- CLLocationManager related functionalities

extension ViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //manager.stopUpdatingLocation()
        
        
        guard let currentLocation = locations.first else { return }
        currentCoordinate = currentLocation.coordinate
        mapView.userTrackingMode = .follow
        
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways :
            print ("Always Auth")
            authStatus(is: true)
            locationManager.startUpdatingLocation()
            break
        case .authorizedWhenInUse :
            print ("When in use")
            authStatus(is: true)
            locationManager.startUpdatingLocation()
            break
        case .denied :
            print ("Denied Auth")
            authStatus(is: false)
            locationManager.stopUpdatingLocation()
            break
        case .notDetermined :
            print ("Not selected")
            authStatus(is: false)
            locationManager.stopUpdatingLocation()
            break
        case .restricted :
            print ("Restricted")
            authStatus(is: false)
            locationManager.stopUpdatingLocation()
            break
        }
    }
    
    func authStatus (is status : Bool){
        if status != true {
            directionLabel.text = "Please allow app to use your location."
        }
        else {
            directionLabel.text = "Begin search for your destination."
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        }
    }
}

//MARK :- Mapview Related Functionality

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        print ("First phase2")
        if overlay is MKPolyline {
            print ("In Poly")
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 8
            return renderer
        }
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.fillColor = .red
            //renderer.alpha = 0.5
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    
}




    //MARK :- SearchBar Related Stuff

extension ViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        moveUpContainerView()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        moveDownContainerView()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        moveDownContainerView()
    }
    
    //MARK :- Search Bar Animation
    
    func moveUpContainerView () {
        UIView.animate(withDuration: 0.5) {
            self.searchBarAndTableContainerHeight.constant = self.view.frame.size.height - 125
            self.searchBar.showsCancelButton = true
            self.view.layoutIfNeeded()
        }
    }
    func moveDownContainerView () {
        UIView.animate(withDuration: 0.5) {
            self.searchBarAndTableContainerHeight.constant = 65
            self.searchBar.showsCancelButton = false
            self.view.layoutIfNeeded()
            self.searchBar.endEditing(true)
        }
    }
    
    //MARK :- Declare viewTapped here:
    @objc func viewTapped () {
        searchBar.endEditing(true)
    }
    
}

    //MARK :- MKLocalSearchCompleter Functionality

extension ViewController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        searchResultsTableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // handle error
    }
}


    //MARK :- Tableview Datasource to represent searched results

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchResult = searchResults[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }
}

    //MARK :- Tableview Delegate methods

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let completion = searchResults[indexPath.row]
        
        let searchRequest = MKLocalSearchRequest(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { (response, error) in
            if error == nil {
               // let coordinate = response?.mapItems.first.placemark.coordinate
               // print(String(describing: coordinate))
                guard let myDirTo = response?.mapItems[indexPath.row] else { return }
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = myDirTo.placemark.coordinate
                self.mapView.addAnnotation(annotation)
                
                self.getDirections(to: myDirTo)
            }
            else {
                self.directionLabel.text = "No location found. Try again."
            }
            
        }
        searchBar.endEditing(true)
        searchBar.text = ""
    }
}
