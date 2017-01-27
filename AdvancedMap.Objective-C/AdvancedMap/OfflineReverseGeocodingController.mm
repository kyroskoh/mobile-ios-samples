#import "MapBaseController.h"
#import <UIKit/UIKit.h>

@interface OfflineReverseGeocodingController : MapBaseController

@property NTOSMOfflineReverseGeocodingService* reverseGeocodingService;
@property NTLocalVectorDataSource* dataSource;

@end

@interface ReverseGeocodingMapEventListener : NTMapEventListener

-(void)setController:(OfflineReverseGeocodingController*)controller;
-(void)onMapClicked:(NTMapClickInfo *)mapClickInfo;

@property (strong, nonatomic) OfflineReverseGeocodingController* controller;

@end

@implementation OfflineReverseGeocodingController

-(void) viewDidLoad
{
    self.reverseGeocodingService = [[NTOSMOfflineReverseGeocodingService alloc] initWithPath:[NTAssetUtils calculateResourcePath:@"estonia-latest.sqlite"]];
    
    NTProjection* proj = [[self.mapView getOptions] getBaseProjection];
    self.dataSource = [[NTLocalVectorDataSource alloc] initWithProjection:proj];
    NTVectorLayer *layer = [[NTVectorLayer alloc] initWithDataSource:self.dataSource];
        
    [[self.mapView getLayers] add:layer];
    
    ReverseGeocodingMapEventListener* listener = [[ReverseGeocodingMapEventListener alloc] init];
    [listener setController:self];
    [self.mapView setMapEventListener:listener];

    NTMapPos* pos = [proj fromWgs84:[[NTMapPos alloc] initWithX:26.7 y:58.38]];
    [self.mapView setFocusPos:pos durationSeconds:0];
    [self.mapView setZoom:14.5f durationSeconds:0];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.mapView setMapEventListener:nil];
}

-(void)hideGeocodingResult
{
    [self.dataSource clear];
}

-(void)showGeocodingResult:(NTGeocodingResult*)result position:(NTMapPos*)pos
{
    // Configure style
    NTBalloonPopupStyleBuilder* styleBuilder = [[NTBalloonPopupStyleBuilder alloc] init];
    [styleBuilder setLeftMargins:[[NTBalloonPopupMargins alloc] initWithLeft:0 top:0 right:0 bottom:0]];
    [styleBuilder setTitleMargins:[[NTBalloonPopupMargins alloc] initWithLeft:6 top:3 right:6 bottom:3]];
    // Make sure this label is shown on top all other labels
    [styleBuilder setPlacementPriority:10];
    
    NTFeatureCollection* featureCollection = [result getFeatureCollection];
    for (int i = 0; i < [featureCollection getFeatureCount]; i++) {
        NTGeometry* geom = [[featureCollection getFeature:i] getGeometry];
        NTColor* color = [[NTColor alloc] initWithR:0 g:100 b:200 a:150];
        
        // Build styles for the displayed geometry
        NTPointStyleBuilder* pointStyleBuilder = [[NTPointStyleBuilder alloc] init];
        [pointStyleBuilder setColor: color];
        
        NTLineStyleBuilder* lineStyleBuilder = [[NTLineStyleBuilder alloc] init];
        [lineStyleBuilder setColor: color];
        
        NTPolygonStyleBuilder* polygonStyleBuilder = [[NTPolygonStyleBuilder alloc] init];
        [polygonStyleBuilder setColor: color];
        
        NTVectorElement* elem = nil;
        if ([geom isKindOfClass:[NTPointGeometry class]]) {
            elem = [[NTPoint alloc] initWithGeometry:(NTPointGeometry*)geom style:[pointStyleBuilder buildStyle]];
        }
        if ([geom isKindOfClass:[NTLineGeometry class]]) {
            elem = [[NTLine alloc] initWithGeometry:(NTLineGeometry*)geom style:[lineStyleBuilder buildStyle]];
        }
        if ([geom isKindOfClass:[NTPolygonGeometry class]]) {
            elem = [[NTPolygon alloc] initWithGeometry:(NTPolygonGeometry*)geom style:[polygonStyleBuilder buildStyle]];
        }
        if ([geom isKindOfClass:[NTMultiGeometry class]]) {
            NTGeometryCollectionStyleBuilder* geomCollectionStyleBuilder = [[NTGeometryCollectionStyleBuilder alloc] init];
            [geomCollectionStyleBuilder setPointStyle:[pointStyleBuilder buildStyle]];
            [geomCollectionStyleBuilder setLineStyle:[lineStyleBuilder buildStyle]];
            [geomCollectionStyleBuilder setPolygonStyle:[polygonStyleBuilder buildStyle]];
            elem = [[NTGeometryCollection alloc] initWithGeometry:(NTMultiGeometry*)geom style:[geomCollectionStyleBuilder buildStyle]];
        }
        
        // Show the element and pan/zoom the view to the element
        if (elem) {
            [self.dataSource add:elem];
            
            NTScreenBounds* screenBounds = [[NTScreenBounds alloc] initWithMin:[[NTScreenPos alloc] initWithX:10 y:10] max:[[NTScreenPos alloc] initWithX:self.mapView.drawableWidth - 20 y:self.mapView.drawableHeight - 20]];
            [self.mapView moveToFitBounds:[geom getBounds] screenBounds:screenBounds integerZoom:NO durationSeconds:0.3f];
        }
        
        // Use geometry center point for popup
        pos = [geom getCenterPos];
    }

    // Show popup
    NSString* title = @"";
    NSString* desc = result ? [result description] : @"No address found";
    NTBalloonPopup* clickPopup = [[NTBalloonPopup alloc] initWithPos:pos style:[styleBuilder buildStyle] title:title desc:desc];
    [self.dataSource add:clickPopup];
}

@end

@implementation ReverseGeocodingMapEventListener

-(void)setController:(OfflineReverseGeocodingController *)controller
{
    _controller = controller;
}

-(void)onMapClicked:(NTMapClickInfo*)clickInfo
{
    [self.controller hideGeocodingResult];
    
    // Calculation should be in background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
        
        NTReverseGeocodingRequest* request = [[NTReverseGeocodingRequest alloc] initWithProjection:[self.controller.dataSource getProjection] location:[clickInfo getClickPos]];
        
        [self.controller.reverseGeocodingService setSearchRadius:125.0f]; // in meters
        
        NTGeocodingResultVector* results = [self.controller.reverseGeocodingService calculateAddresses:request];
        
        // Scan the results list. If we found relatively close point-based match,
        // use this instead of the first result. In case of POIs within buildings,
        // this allows us to hightlight POI instead of the building
        NTGeocodingResult* result = [results size] > 0 ? [results get:0] : nil;
        for (int i = 0; i < [results size]; i++) {
            NTGeocodingResult* otherResult = [results get: i];
            if ([otherResult getRank] > 0.8f) { // 0.8f means 125 * (1.0 - 0.8) = 25 meters
                NTGeometry* geom = [[[otherResult getFeatureCollection] getFeature:0] getGeometry];
                if ([geom isKindOfClass:[NTPointGeometry class]]) {
                    result = otherResult;
                    break;
                }
            }
        }
        
        NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
        
        [self.controller showGeocodingResult:result position:[clickInfo getClickPos]];
        
        NSLog(@"Reverse geocoding: %d results, took %0.3fs", [results size], duration);
    });
}

@end

