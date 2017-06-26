//
//  StyleChoiceController.swift
//  Feature Demo
//
//  Created by Aare Undo on 19/06/2017.
//  Copyright © 2017 CARTO. All rights reserved.
//

import Foundation
import  UIKit

class BboxRoutingController : BaseController, PackageDownloadDelegate, RouteMapEventDelegate {
    
    let ROUTING_TAG = "routing:"
    let ROUTING_SOURCE = "valhalla.osm"
    let MAP_SOURCE = "nutiteq.osm"
    let TRANSPORT_MODE = ".car"
    
    var routing: Routing!
    
    var contentView: BboxRoutingView!
    
    var boundingBox: BoundingBox!
    
    var mapPackageListener: MapPackageListener!
    var routingPackageListener : RoutingPackageListener!
    
    var routingManager: NTCartoPackageManager!
    var mapManager: NTCartoPackageManager!
    
    var mapListener: RouteMapEventListener!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        contentView = BboxRoutingView()
        
        view = contentView
        
        routing = Routing(mapView: contentView.map)
        
        var folder = createDirectory(name: "mappackages")
        mapManager = NTCartoPackageManager(source: MAP_SOURCE, dataFolder: folder)
        
        folder = createDirectory(name: "routingpackages")
        routingManager = NTCartoPackageManager(source: ROUTING_TAG + ROUTING_SOURCE, dataFolder: folder)
        
        setOnlineMode()
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.downloadButtonTapped(_:)))
        contentView.downloadButton.addGestureRecognizer(recognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        contentView.addRecognizers()
        
        mapListener = RouteMapEventListener()
        mapListener.delegate = self
        contentView.map.setMapEventListener(mapListener)
        
        mapPackageListener = MapPackageListener()
        mapPackageListener.delegate = self
        mapManager.setPackageManagerListener(mapPackageListener)
        mapManager.start()
        
        routingPackageListener = RoutingPackageListener()
        routingPackageListener.delegate = self
        routingManager.setPackageManagerListener(routingPackageListener)
        routingManager.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        contentView.removeRecognizers()
        
        mapListener = nil
        
        mapManager.stop(true)
        mapPackageListener = nil
        
        routingManager.stop(true)
        routingPackageListener = nil
    }
    
    func downloadButtonTapped(_ sender: UITapGestureRecognizer) {
        
        let id = boundingBox.toString()
        mapManager.startPackageDownload(id)
    }
    
    func setOnlineMode() {
        routing.service = NTCartoOnlineRoutingService(source: MAP_SOURCE + TRANSPORT_MODE)
    }
    
    func setOfflineMode() {
        
        /*
         * NB! AdvancedMap.Swift requires CartoMobileSDK 4.1.0 Valhalla build,
         * which is not yet (as of 26 June 2017) on cocoapods, because cocoapods do not support semantic versioning
         * Contact CARTO to get the new version of the framework!
         */
        routing.service = NTPackageManagerValhallaRoutingService(packageManager: routingManager)
    }
    
    func startClicked(event: RouteMapEvent) {
        routing.setStartMarker(position: event.clickPosition)
        contentView.downloadButton.disable()
    }
    
    func stopClicked(event: RouteMapEvent) {
        routing.setStopMarker(position: event.clickPosition)
        showRoute(start: event.startPosition, stop: event.stopPosition)
    }
    
    func showRoute(start: NTMapPos, stop: NTMapPos) {
        DispatchQueue.global().async {
            
            let result: NTRoutingResult? = self.routing.getResult(startPos: start, stopPos: stop)

            DispatchQueue.main.async(execute: {
                
                if (result == nil) {
                    self.contentView.progressLabel.complete(message: "Routing failed. Please try again")
                } else {
                    self.contentView.progressLabel.complete(message: self.routing.getMessage(result: result!))
                }
                
                let color = NTColor(r: 14, g: 122, b: 254, a: 150)
                self.routing.show(result: result!, lineColor: color!, complete: {
                    (route: Route) in
                    
                    let projection = self.contentView.map.getOptions().getBaseProjection()
                    self.boundingBox = BoundingBox.fromMapBounds(projection: projection!, bounds: route.bounds!, extraMeters: 0)
                    
                    self.contentView.downloadButton.enable()
                    
                    if (!self.contentView.progressLabel.isVisible()) {
                        self.contentView.progressLabel.show()
                    }
                })
            })
        }
    }
    
    func downloadComplete(sender: PackageListener, id: String) {
        
        if (type(of: sender) == MapPackageListener.self) {
            routingManager.startPackageDownload(id)
        } else {
            let bounds = boundingBox.bounds
            
            DispatchQueue.main.async(execute: {
                self.contentView.addPolygonTo(bounds: bounds!)
            })
        }
    }
    
    func downloadFailed(sender: PackageListener, errorType: NTPackageErrorType) {
        
        var text = ""
        
        if (type(of: sender) == MapPackageListener.self) {
            text = "Map download failed"
        } else {
            text = "Route download failed"
        }
        
        DispatchQueue.main.async(execute: {
            self.contentView.progressLabel.update(text: text)
        })
    }
    
    func statusChanged(sender: PackageListener, status: NTPackageStatus) {
        
        let progress = CGFloat(status.getProgress())
        var text = "Downloading map: " + String(describing: progress) + "%"
 
        if (type(of: sender) == RoutingPackageListener.self) {
            text = "Downloading route: " + String(describing: progress) + "%"
        }
        
        DispatchQueue.main.async(execute: {
            self.contentView.progressLabel.update(text: text, progress: progress)
        })
    }
    
    func createDirectory(name: String) -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let folder = path + "/" + name
        
        do {
            try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: false, attributes: nil)
        } catch {
            // Folder already exists, nothing to catch
        }
        
        return folder
    }
}





