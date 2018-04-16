//
//  AutoMapperWindowController.swift
//  Outlander
//
//  Created by Joseph McBride on 4/2/15.
//  Copyright (c) 2015 Joe McBride. All rights reserved.
//

import Cocoa

func loadMap <R> (
    _ backgroundClosure: @escaping () -> R,
    mainClosure: @escaping (R) -> ())
{
    DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
        let res = backgroundClosure()
        DispatchQueue.main.async(execute: {
            mainClosure(res)
        })
    }
}

func mainThread(_ mainClosure: @escaping () -> ()) {
    DispatchQueue.main.async(execute: {
        mainClosure()
    })
}

class MapsDataSource : NSObject, NSComboBoxDataSource {
    
    fileprivate var maps:[MapInfo] = []
    
    func loadMaps(_ mapsFolder:String, mapLoader:MapLoader, loaded: (()->Void)?) {
        
        { () -> [MapMetaResult] in
            
            return mapLoader.loadFolder(mapsFolder)
            
        } ~> { (results) ->() in
            
            var success:[MapInfo] = []
            
            for res in results {
                switch res {
                    
                case let .success(mapInfo):
                    success.append(mapInfo)
                    
                case let .error(error):
                    print("\(error)")
                }
            }
            
            self.maps = success.sorted { $0.id.compare($1.id, options: NSString.CompareOptions.numeric, range: $0.id.characters.indices, locale:nil) == ComparisonResult.orderedAscending }
            
            loaded?()
        }
    }
    
    func mapForZoneId(_ id:String) -> MapInfo? {
        return self.maps.filter { $0.id == id }.first
    }
    
    func mapForFile(_ file:String) -> MapInfo? {
        return self.maps.filter { $0.file == file }.first
    }
    
    func mapAtIndex(_ index:Int) -> MapInfo {
        return self.maps[index];
    }
    
    func indexOfMap(_ id:String) -> Int? {
        
        if let info = mapForZoneId(id) {
            return self.maps.index(of: info)
        }
        
        return nil
    }

    func initializeMaps(_ context:GameContext, loader: MapLoader) {
        guard let mapsFolder = context.pathProvider.mapsFolder() else { return }

        let start = Date()

        let maps = self.maps.filter { $0.zone == nil }

        context.events.echoText("[Automapper]: loading all maps...", preset: "automapper")

        loadMap({ () -> [MapLoadResult] in
            var results: [MapLoadResult] = []
            maps.forEach { m in
                let result = loader.load(mapsFolder.stringByAppendingPathComponent(m.file))
                switch result {

                case let .success(zone):
                    m.zone = zone

                case let .error(error):
                    print(error)
                }
                results.append(result)
            }
            return results
            }, mainClosure: { result -> () in
                let diff = Date().timeIntervalSince(start)
                self.maps.forEach { map in
                    context.maps[map.id] = map.zone!
                }
                context.events.echoText("[Automapper]: all \(self.maps.count) maps loaded in \(diff.format("0.2")) seconds", preset: "automapper")
                context.resetMap()
        })
    }
    
    // MARK - NSComboBoxDataSource
    
    func numberOfItems(in aComboBox: NSComboBox) -> Int {
        return self.maps.count
    }
    
    func comboBox(_ aComboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard index > -1 else { return "" }

        let map = self.maps[index]
        return "\(map.id). \(map.name)"
    }
}

class AutoMapperWindowController: NSWindowController, NSComboBoxDataSource {
    
    @IBOutlet weak var mapsComboBox: NSComboBox!
    @IBOutlet weak var nodesLabel: NSTextField!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var mapView: MapView!
    @IBOutlet weak var mapLevelLabel: NSTextField!
    @IBOutlet weak var nodeNameLabel: NSTextField!
    
    fileprivate var mapsDataSource: MapsDataSource = MapsDataSource()

    fileprivate var context:GameContext?
    fileprivate let mapLoader:MapLoader = MapLoader()
    
    var mapLevel:Int = 0 {
        didSet {
            self.mapView.mapLevel = self.mapLevel
            self.mapLevelLabel.stringValue = "Level: \(self.mapLevel)"
        }
    }
    
    var mapZoom:CGFloat = 1.0 {
        didSet {
            if self.mapZoom == 0 {
                self.mapZoom = 0.5
            }
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        self.nodeNameLabel.stringValue = ""
        
        self.mapsComboBox.dataSource = self.mapsDataSource
        self.mapView.nodeHover = { node in
            if let room = node {
                var notes = ""
                if room.notes != nil {
                    notes = "(\(room.notes!))"
                }
                self.nodeNameLabel.stringValue = "#\(room.id) - \(room.name) \(notes)"
            } else {
                self.nodeNameLabel.stringValue = ""
            }
        }
    }
    
    func setSelectedZone() {
        if let zone = self.context?.mapZone {
            
            if let idx = self.mapsDataSource.indexOfMap(zone.id) {
                
                self.mapsComboBox.selectItem(at: idx)
                
                self.renderMap(zone)
            }
        }

        if let charname = self.context?.globalVars.cacheObject(forKey: "charactername"), let game = self.context?.globalVars.cacheObject(forKey: "game") {
            self.window?.title = "AutoMapper - \(game): \(charname)"
        }
    }
    
    func setContext(_ context:GameContext) {
        self.context = context

        self.context?.globalVars.changed.subscribeNext { (obj:AnyObject?) -> Void in
            
            if let changed = obj as? Dictionary<String, String> {

                if changed.keys.first == "zoneid" {
                    if let zoneId = changed["zoneid"] {
                        
                        if let mapInfo = self.mapsDataSource.mapForZoneId(zoneId) {
                            self.setZoneFromMap(mapInfo)
                        }
                    }
                }
                
                if changed.keys.first == "roomid" {
                    
                    if let id = changed["roomid"] {
                        if let room = self.context!.mapZone?.roomWithId(id) {
                            
                            if room.notes != nil && room.notes!.range(of: ".xml") != nil {
                                
                                let groups = room.notes!["(.+\\.xml)"].groups()
                                
                                if groups.count > 1 {
                                    let mapfile = groups[1]
                                    
                                    if let mapInfo = self.mapsDataSource.mapForFile(mapfile) {
                                        
                                        self.setZoneFromMap(mapInfo)
                                    }
                                }
                            } else {
                                mainThread {
                                    if self.mapView != nil {
                                        self.mapView.mapLevel = room.position.z
                                        self.mapView.currentRoomId = id
                                        
                                        
//                                        if let rect = self.mapView?.rectForRoom(roomId) {
//                                            
//                                            var bounds = self.scrollView.convertRect(rect, toView: self.mapView!)
//                                            var bounds2 = self.scrollView.bounds
//                                            println("visible bounds: \(bounds) // \(rect) // \(bounds2)")
//                                            
////                                            var contentBounds = self.scrollView.contentView.bounds
////                                            var visRect = self.scrollView.contentView.documentVisibleRect
////                                            
////                                            var mapFrame = self.mapView.frame
////                                            
////                                            var frame = self.scrollView.contentView.frame
////                                            var mapRect = self.mapView.rect!
////                                            var midXPoint = bounds.size.width/2.0
////                                            var midYPoint = bounds.size.height/2.0
////                                            println("\(self.mapView.rect!) :: \(midXPoint),\(midYPoint)")
//                                            self.scrollView.contentView.scrollPoint(NSPoint(x: bounds.origin.x, y: bounds.origin.y))
//                                            self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
//                                            //self.scrollView.scrollRectToVisible(rect)
//                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func setZoneFromMap(_ mapInfo:MapInfo) {
        if let idx = self.mapsDataSource.indexOfMap(mapInfo.id) {
            
            mainThread {
                
                if self.mapsComboBox != nil && self.mapsComboBox.indexOfSelectedItem != idx {
                    self.mapsComboBox.selectItem(at: idx)
                }
                else {
                    
                    if mapInfo.zone != nil {
                        
                        self.renderMap(mapInfo.zone!)
                        self.context?.mapZone = mapInfo.zone!
                        
                    } else {
                        self.loadMapFromInfo(mapInfo)
                    }
                }
            }
        }
    }
    
    func findCurrentRoom(_ zone:MapZone) -> MapNode? {
        if let ctx = self.context {
            
            let roomId = ctx.globalVars.cacheObject(forKey: "roomid") as? String
            
            var name = ctx.globalVars.cacheObject(forKey: "roomtitle") as? String ?? ""
            name = name.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            
            let description = ctx.globalVars.cacheObject(forKey: "roomdesc") as? String ?? ""
            
            if let room = zone.findRoomFuzyFrom(roomId, name: name, description: description) {
                
                ctx.globalVars.setCacheObject(room.id, forKey: "roomid")
                
                return room
            }
        }
        
        return nil
    }
    
    func loadMaps() {
        if let mapsFolder = self.context?.pathProvider.mapsFolder() {
            
            if self.nodesLabel != nil {
                self.nodesLabel.stringValue = "Loading Maps ..."
            }
            
            self.mapsDataSource.loadMaps(mapsFolder, mapLoader: self.mapLoader, loaded: { ()->Void in
                if self.nodesLabel != nil {
                    self.nodesLabel.stringValue = ""
                }
                
                if let zoneId = self.context!.globalVars.cacheObject(forKey: "zoneid") as? String {
                    
                    if let idx = self.mapsDataSource.indexOfMap(zoneId) {
                        if self.mapsComboBox != nil {
                            self.mapsComboBox.selectItem(at: idx)
                        } else {
                            self.loadMapFromInfo(self.mapsDataSource.mapAtIndex(idx))
                        }
                    }
                }

                self.mapsDataSource.initializeMaps(self.context!, loader: self.mapLoader)
            })
        }
    }

    func renderMap(_ zone:MapZone) {
        
        if self.mapView == nil {
            return
        }

        let room = self.findCurrentRoom(zone)
        let rect = zone.mapSize(0, padding: 100.0)
        
        self.mapLevel = room?.position.z ?? 0
        
        self.mapView?.setFrameSize(rect.size)
        self.mapView?.currentRoomId = room != nil ? room!.id : ""
        self.mapView?.setZone(zone, rect: rect)
        
        let roomCount = zone.rooms.count
        
        self.nodesLabel.stringValue = "Map \(zone.id). \(zone.name), Rooms: \(roomCount)"
        
        if let rect = self.mapView?.rectForRoom(self.mapView?.currentRoomId) {
            self.scrollView.scrollToVisible(rect)
        }
    }
    
    func loadMapFromInfo(_ info:MapInfo) {

        if let loaded = info.zone {
            self.context?.mapZone = loaded
            
            info.zone = loaded
            
            if self.mapView != nil {
                
                self.renderMap(loaded)
            }
            return
        }
        
        if let mapsFolder = context?.pathProvider.mapsFolder() {
            
            let file = mapsFolder.stringByAppendingPathComponent(info.file)
           
            if self.nodesLabel != nil {
                self.nodesLabel.stringValue = "Loading ..."
            }

            self.context?.events.echoText("[Automapper]: loading selected map \(info.file)", preset: "automapper")
            
            let start = Date()

            loadMap({ () -> MapLoadResult in
                return self.mapLoader.load(file)
            }, mainClosure: { (result) -> () in
                
                let diff = Date().timeIntervalSince(start)
                
                switch result {
                    
                case let .success(zone):

                    self.context?.events.echoText("[Automapper]: \(zone.name) loaded in \(diff.format(".2")) seconds", preset: "automapper")
                    
                    self.context?.mapZone = zone
                    
                    info.zone = zone
                    
                    if self.mapView != nil {
                        
                        self.renderMap(zone)
                    }
                    
                case let .error(error):
                    self.context?.events.echoText("[Automapper]: map loaded with error in \(diff.format(".2")) seconds", preset: "automapper")
                    self.context?.events.echoText("\(error)")
                    if self.nodesLabel != nil {
                        self.nodesLabel.stringValue = "Error loading map: \(error)"
                    }
                }
            })
        }
    }
    
    @IBAction func mapLevelAction(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            self.mapLevel += 1
        } else {
            self.mapLevel -= 1
        }
    }
    
    @IBAction func mapZoomAction(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            self.mapZoom += 0.5
        } else {
            self.mapZoom -= 0.5
        }
        
        let clipView = self.scrollView.contentView
        var clipViewBounds = clipView.bounds
        let clipViewSize = clipView.frame.size
        
        clipViewBounds.size.width = clipViewSize.width / self.mapZoom
        clipViewBounds.size.height = clipViewSize.height / self.mapZoom
        
        clipView.setBoundsSize(clipViewBounds.size)
    }
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        let idx = self.mapsComboBox.indexOfSelectedItem
        let selectedMap = self.mapsDataSource.mapAtIndex(idx)
        
        if selectedMap.zone != nil {
            
            self.renderMap(selectedMap.zone!)
            
            self.context?.mapZone = selectedMap.zone!
            
            return
        }
        
        self.loadMapFromInfo(selectedMap)
    }
}
