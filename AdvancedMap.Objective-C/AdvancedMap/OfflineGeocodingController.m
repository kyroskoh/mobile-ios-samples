#import "MapBaseController.h"
#import <UIKit/UIKit.h>

@interface OfflineGeocodingController : MapBaseController

@property NTGeocodingService *geocodingService;
@property NTLocalVectorDataSource *dataSource;
@property NTVectorElement* oldGeometry;

@end

@implementation OfflineGeocodingController

-(void) viewDidLoad
{
    UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, self.navigationController.navigationBar.frame.size.width - 20, 60)];
    tf.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    tf.font = [UIFont fontWithName:@"Helvetica" size:25];
    tf.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    tf.text = @"Type address...";

    float x = self.navigationController.navigationBar.frame.size.width;
    float y = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, y, x, 400)];
    [view addSubview:tf];
    
    [self.view addSubview:view];

    NTProjection* proj = [[self.mapView getOptions] getBaseProjection];
    self.geocodingService = [[NTOSMOfflineGeocodingService alloc] initWithProjection:proj path:[NTAssetUtils calculateResourcePath:@"estonia-latest.sqlite"]];
    
    self.dataSource = [[NTLocalVectorDataSource alloc] initWithProjection:proj];
    NTVectorLayer *layer = [[NTVectorLayer alloc] initWithDataSource:self.dataSource];
    
    [[self.mapView getLayers] add:layer];
    
    NTMapPos* pos = [proj fromWgs84:[[NTMapPos alloc] initWithX:26.7 y:58.38]];
    [self.mapView setFocusPos:pos durationSeconds:0];
    [self.mapView setZoom:14.5f durationSeconds:0];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.mapView setMapEventListener:nil];
}

- (void)showGeometry:(NTGeometry*)geom
{
    if (_oldGeometry)
    {
        [self.dataSource remove:_oldGeometry];
        _oldGeometry = nil;
    }

    if (geom) {
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
            [self.dataSource add:elem];
            _oldGeometry = elem;
        }
    }
}

/*
-(void)geocode
{
    NTGeocodingRequest* request = [[NTGeocodingRequest alloc] initWithQuery:];
    
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
 */

@end
