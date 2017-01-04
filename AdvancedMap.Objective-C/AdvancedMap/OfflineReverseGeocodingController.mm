#import "MapBaseController.h"
#import <UIKit/UIKit.h>

@interface OfflineReverseGeocodingController : MapBaseController

@property NTReverseGeocodingService *reverseGeocodingService;
@property NTLocalVectorDataSource *dataSource;

@end

@interface ReverseGeocodingMapEventListener : NTMapEventListener

-(void)setController:(OfflineReverseGeocodingController*)controller;
-(void)onMapClicked:(NTMapClickInfo *)mapClickInfo;

@property (strong, nonatomic) OfflineReverseGeocodingController* controller;
@property (strong, nonatomic) NTBalloonPopup* oldClickLabel;
@property (strong, nonatomic) NTVectorElement* oldGeometry;

@end

@implementation OfflineReverseGeocodingController

-(void) viewDidLoad
{
    NTProjection* proj = [[self.mapView getOptions] getBaseProjection];
    self.reverseGeocodingService = [[NTOSMOfflineReverseGeocodingService alloc] initWithProjection:proj path:[NTAssetUtils calculateResourcePath:@"estonia-latest.sqlite"]];
    
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

@end

@implementation ReverseGeocodingMapEventListener

-(void)setController:(OfflineReverseGeocodingController *)controller
{
    _controller = controller;
}

-(void)onMapClicked:(NTMapClickInfo*)clickInfo
{
    // Remove old click label
    if (_oldClickLabel)
    {
        [self.controller.dataSource remove:_oldClickLabel];
        _oldClickLabel = nil;
    }
    if (_oldGeometry)
    {
        [self.controller.dataSource remove:_oldGeometry];
        _oldGeometry = nil;
    }
    
    NTReverseGeocodingRequest* request = [[NTReverseGeocodingRequest alloc] initWithProjection:[self.controller.dataSource getProjection] point:[clickInfo getClickPos]];

    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    
    // Calculation should be in background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NTGeocodingResultVector* results = [self.controller.reverseGeocodingService calculateAddresses:request];
        
        dispatch_async(dispatch_get_main_queue(), ^{
    
            NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;

            NTBalloonPopupStyleBuilder* styleBuilder = [[NTBalloonPopupStyleBuilder alloc] init];
            // Configure style
            [styleBuilder setLeftMargins:[[NTBalloonPopupMargins alloc] initWithLeft:0 top:0 right:0 bottom:0]];
            [styleBuilder setTitleMargins:[[NTBalloonPopupMargins alloc] initWithLeft:6 top:3 right:6 bottom:3]];
            // Make sure this label is shown on top all other labels
            [styleBuilder setPlacementPriority:10];
            
            NTMapPos* pos = [clickInfo getClickPos];
            NSString* title = @"No close address found";
            NSString* desc = @"";
            if ([results size] > 0) {
                title = @"Found address";
                desc = [[results get:0] description];
                
                NTGeometry* geom = [[results get:0] getGeometry];
                if (geom) {
                    pos = [geom getCenterPos];

                    NTColor* color = [[NTColor alloc] initWithR:0 g:100 b:200 a:150];
                    
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

                    if (elem) {
                        [self.controller.dataSource add:elem];
                        _oldGeometry = elem;
                    }
                }
            }
            
            // for lines and polygons set label to click location
            NTBalloonPopup* clickPopup = [[NTBalloonPopup alloc] initWithPos:pos
                                                       style:[styleBuilder buildStyle]
                                                       title:title
                                                        desc:desc];
            [self.controller.dataSource add:clickPopup];
            _oldClickLabel = clickPopup;
            
            NSLog(@"Reverse geocoding: %@, took %0.3fs", desc, duration);
        });
    });
}

@end

