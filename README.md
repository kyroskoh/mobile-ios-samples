## iOS sample app with CARTO Mobile SDK

* Official docs: https://carto.com/docs/carto-engine/mobile-sdk/
* Reference: http://cartodb.github.io/mobile-ios-samples/

## Installation Guide
  
* Via manually downloading the SDK:
  1. Get SDK package latest dev build: [sdk4-ios-snapshot-latest.zip](https://nutifront.s3.amazonaws.com/sdk_snapshots/sdk4-ios-snapshot-latest.zip)
  1. Unzip it and copy *CartoMobileSDK.framework*  to the xCode project root folder

* Via CocoaPods:
  1. Navigate to a project's folder in the **Terminal**. *Note that we have several subprojects, for different languages (Objective-C or Swift) and level of complexity (from HelloMap to AdvancedMap), each is separate projects in Xcode point of view.*
  2. Type `pod install` to download the SDK 
  3. Run the project via the **.xcworkspace** file

## Sample structure

1. **Hello Map**
    * Basic sample of how to initialize a map, set a market on the map, listen to map clicks and change the color and size of that marker.
2. **Advanced Map**
    * Base Maps
      * Base Maps - choice of different base maps, styles, tile type and language
    * Overlay Data Sources
        * Custom Raster Data Source - creating and using custom (merged) raster tile data source
        * Ground Overlay - Addoung ground-level raster overlay
        * WMS Map - WMS service raster on top of a vector base map
    * Vector Objects
        * Clustered Markers - reading data from .geojson and showing it as clusters (made from custom markers)
        * Overlays - shows how to set 2D &3D objects: lines, points, polygons, tests, popups and 3D models on the map and how to attach a click listener to them
        * Vector object editing - shows usage of an editable vector layer, with three different event listeners
    * Offline maps
        * Bundled Map - Shows usage of a numbled MBTiles file to display a map offline
        * Package Manager - Download offline map packaged with OSM
    *   Other
        *  Screencapture - Captures a rendered MapView as a Bitmap
        *  Custom Popup - Creating and using custom popups
        *  GPS Location - Shows user GPS location on the map
        *  Offline Routing - Offline routing with OpenStreetMap data packages
3. **Carto Map**
    * CARTO.js API
        * Countries Vis - Dislaying countries in different colors from a viz.json
        * Dots Vis - Showing specific dots on the map from a viz.json
        * Fonts Vis - Displaying text on the map from a viz.json
    * Maps API
        * Anonymous Raster Tile - Uses CARTO PostGIS raster data
        * Anonymous Vector Tile - Uses CARTO Maps API vector tiles
        * Named Map - CARTO data as vector tiles from a named map
    * SQL API
        *  SQL Service - Displays cities on the map vis a SQL query
    *  Torque API
        *  CARTO Torque Map - Shows Torque tiels of WWII ship movement

## Other Samples

* Android Studio (Android samples in Java): https://github.com/CartoDB/mobile-android-samples
* Xamarin (iOS, Android and Windows Phone samples in C#): https://github.com/CartoDB/mobile-dotnet-samples
