
#import "MapBaseController.h"

@interface RendererListener : NTRendererCaptureListener

@property UIViewController *controller;

@property NTMapPos* position;
@property int number;

@property NTMapView* mapView;

@end

@interface CaptureController : MapBaseController

@property RendererListener* listener;

@end

@implementation CaptureController

-(void) viewDidLoad
{
    // Initialize projection and data source
    NTProjection* projection = [[self.mapView getOptions] getBaseProjection];
    NTLocalVectorDataSource* source = [[NTLocalVectorDataSource alloc]initWithProjection:projection];
    
    // Intialize a vector layer for our marker
    NTVectorLayer* layer = [[NTVectorLayer alloc] initWithDataSource:source];
    [[self.mapView getLayers] add:layer];
    
    // Load bitmap
    UIImage* image = [UIImage imageNamed:@"marker"];
    NTBitmap* bitmap = [NTBitmapUtils createBitmapFromUIImage: image];
    
    // Create a marker
    NTMarkerStyleBuilder* builder = [[NTMarkerStyleBuilder alloc] init];
    [builder setBitmap:bitmap];
    [builder setSize:30];
    
    NTMapPos* coordinates = [[NTMapPos alloc] initWithX:13.38933 y:52.51704];
    NTMapPos* berlin = [projection fromWgs84:coordinates];
    
    NTMarker* marker = [[NTMarker alloc] initWithPos:berlin style: [builder buildStyle]];
    [source add:marker];
    
    // Animate zoom to position
    [self.mapView setFocusPos:berlin durationSeconds:1];
    [self.mapView setZoom:12 durationSeconds:1];
}

-(void)viewWillAppear:(BOOL)animated
{
    // Initialize renderer
    self.listener = [[RendererListener alloc] init];
    self.listener.controller = self;
    self.listener.mapView = self.mapView;
    self.listener.number = 0;
    self.listener.position = [[NTMapPos alloc]init];
    
    [[self.mapView getMapRenderer] captureRendering:self.listener waitWhileUpdating:true];
}

-(void)viewWillDisappear:(BOOL)animated
{
    self.listener = nil;
}

@end

@implementation RendererListener

-(void) onMapRendered:(NTBitmap *)bitmap
{
    if (![[self.mapView getFocusPos] isEqualInternal:self.position]) {
        
        self.position = [self.mapView getFocusPos];
        self.number++;
        
        UIImage *image = [NTBitmapUtils createUIImageFromBitmap:bitmap];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *path = [paths objectAtIndex:0];
        path = [path stringByAppendingFormat:@"/%d.png", self.number];
        
        NSData* data = UIImagePNGRepresentation(image);
        
        BOOL success = [data writeToFile:path atomically:YES];
        
        NSString *result;
        
        if (success) {
            result = [@"Great success! Image saved to " stringByAppendingString:path];
            [self share:data];
        } else {
            result = [@"Unable to save image to " stringByAppendingString:path];
        }

        [(CaptureController*)self.controller alert:result];
    }
}

-(void) share:(NSData *)data
{
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObjects:@"I would like to share it.", data, nil] applicationActivities:nil];
    activityVC.excludedActivityTypes = @[ UIActivityTypeMessage ,UIActivityTypeAssignToContact,UIActivityTypeSaveToCameraRoll];
    [self.controller presentViewController:activityVC animated:YES completion:nil];
}

@end










