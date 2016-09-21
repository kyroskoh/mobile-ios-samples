
#import "MapBaseController.h"

@implementation MapBaseController

- (void)loadView
{
    self.mapView = [[NTMapView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.view = self.mapView;
    
    [self.mapView.getOptions setPanningMode:NTPanningMode::NT_PANNING_MODE_STICKY_FINAL];
    
    [self.mapView.getOptions setWatermarkBitmap:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // GLKViewController-specific parameters for smoother animations
    [self setResumeOnDidBecomeActive:NO];
    [self setPreferredFramesPerSecond:60];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // GLKViewController-specific, do on-demand rendering instead of constant redrawing.
    // This is VERY IMPORTANT as it stops battery drain when nothing changes on the screen!
    [self setPaused:YES];
}

@end