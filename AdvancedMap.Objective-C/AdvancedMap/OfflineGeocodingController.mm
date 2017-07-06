#import "MapBaseController.h"
#import <UIKit/UIKit.h>

@interface OfflineGeocodingController : MapBaseController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate>

@property NTOSMOfflineGeocodingService* geocodingService;
@property NTLocalVectorDataSource* dataSource;
@property NSMutableArray* addresses;
@property UITextField* searchField;
@property UITableView* autocompleteTableView;
@property int searchQueueSize;
@property dispatch_queue_t queue;

@end

@implementation OfflineGeocodingController

-(void)viewDidLoad
{
    self.geocodingService = [[NTOSMOfflineGeocodingService alloc] initWithPath:[NTAssetUtils calculateResourcePath:@"estonia-latest.sqlite"]];
    
    NTProjection* proj = [[self.mapView getOptions] getBaseProjection];
    self.dataSource = [[NTLocalVectorDataSource alloc] initWithProjection:proj];
    NTVectorLayer *layer = [[NTVectorLayer alloc] initWithDataSource:self.dataSource];
    
    [[self.mapView getLayers] add:layer];
    
    NTMapPos* pos = [proj fromWgs84:[[NTMapPos alloc] initWithX:26.7 y:58.38]];
    [self.mapView setFocusPos:pos durationSeconds:0];
    [self.mapView setZoom:14.5f durationSeconds:0];

    // Create search UI
    float width = self.navigationController.navigationBar.frame.size.width;
    float height = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
    
    self.addresses = [[NSMutableArray alloc] init];
    
    UITextField* tf = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, width - 20, 60)];
    tf.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    tf.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    tf.placeholder = @"Type address...";
    tf.delegate = self;
    self.searchField = tf;
    
    UITableView* tv = [[UITableView alloc] initWithFrame:CGRectMake(10, 70, width - 20, 240) style:UITableViewStylePlain];
    tv.delegate = self;
    tv.dataSource = self;
    tv.scrollEnabled = YES;
    tv.hidden = YES;
    self.autocompleteTableView = tv;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, height, width, 400)];
    [view addSubview:tf];
    [view addSubview:tv];
    
    [self.view addSubview:view];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.delegate = self;
    
    self.queue = dispatch_queue_create("com.carto.GeocodeQueue", NULL);
    
    [self.view addGestureRecognizer:tap];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.mapView setMapEventListener:nil];
}

-(NSString*)printableAddress:(NTGeocodingResult*)result
{
    NTAddress* addr = [result getAddress];
    NSString* str = @"";
    if ([[addr getName] length] > 0) {
        str = [str stringByAppendingFormat:@"%@", [addr getName]];
    }
    if ([[addr getStreet] length] > 0) {
        if ([str length] > 0) {
            str = [str stringByAppendingString:@", "];
        }
        str = [str stringByAppendingFormat:@"%@", [addr getStreet]];
        if ([[addr getHouseNumber] length] > 0) {
            str = [str stringByAppendingFormat:@" %@", [addr getHouseNumber]];
        }
    }
    if ([[addr getNeighbourhood] length] > 0) {
        if ([str length] > 0) {
            str = [str stringByAppendingString:@", "];
        }
        str = [str stringByAppendingFormat:@"%@", [addr getNeighbourhood]];
    }
    if ([[addr getLocality] length] > 0) {
        if ([str length] > 0) {
            str = [str stringByAppendingString:@", "];
        }
        str = [str stringByAppendingFormat:@"%@", [addr getLocality]];
    }
    if ([[addr getCounty] length] > 0) {
        if ([str length] > 0) {
            str = [str stringByAppendingString:@", "];
        }
        str = [str stringByAppendingFormat:@"%@", [addr getCounty]];
    }
    if ([[addr getRegion] length] > 0) {
        if ([str length] > 0) {
            str = [str stringByAppendingString:@", "];
        }
        str = [str stringByAppendingFormat:@"%@", [addr getRegion]];
    }
    if ([[addr getCountry] length] > 0) {
        if ([str length] > 0) {
            str = [str stringByAppendingString:@", "];
        }
        str = [str stringByAppendingFormat:@"%@", [addr getCountry]];
    }
    return str;
}

-(void)geocode:(NSString*)text autocomplete:(BOOL)autocomplete
{
    [self hideGeocodingResult];
    
    // Calculation should be in background thread
    @synchronized (self) {
        self.searchQueueSize++;
    }
    dispatch_async(self.queue, ^{
        @synchronized (self) {
            if (--self.searchQueueSize > 0) {
                NSLog(@"Geocoding: pending request, skipping");
                return; // cancel the request if we have additional pending requests queued
            }
        }
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
        
        NTGeocodingRequest* request = [[NTGeocodingRequest alloc] initWithProjection:[self.dataSource getProjection] query:text];
//        [request setLocation:[[self.dataSource getProjection] fromLat:58.383 lng:26.717]];
//        [request setLocationRadius:100000];
        
        [self.geocodingService setAutocomplete:autocomplete];
        NTGeocodingResultVector* results = [self.geocodingService calculateAddresses:request];
        
        NSTimeInterval duration = [NSDate timeIntervalSinceReferenceDate] - start;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // In autocomplete mode just fill the autocomplete address list and reload tableview
            // In full geocode mode, show the result
            if (autocomplete)
            {
                [self.addresses removeAllObjects];
                for (int i = 0; i < [results size]; i++) {
                    [self.addresses addObject:[results get:i]];
                }
                [self.autocompleteTableView reloadData];
            }
            else
            {
                if ([results size] > 0)
                {
                    [self showGeocodingResult:[results get:0]];
                }
            }
            
            NSLog(@"Geocoding: %d results, took %0.3fs", [results size], duration);
        });
    });
}

-(void)hideGeocodingResult
{
    [self.dataSource clear];
}

-(void)showGeocodingResult:(NTGeocodingResult*)result
{
    // Configure style
    NTBalloonPopupStyleBuilder* styleBuilder = [[NTBalloonPopupStyleBuilder alloc] init];
    [styleBuilder setLeftMargins:[[NTBalloonPopupMargins alloc] initWithLeft:0 top:0 right:0 bottom:0]];
    [styleBuilder setTitleMargins:[[NTBalloonPopupMargins alloc] initWithLeft:6 top:3 right:6 bottom:3]];
    // Make sure this label is shown on top all other labels
    [styleBuilder setPlacementPriority:10];
    
    NTMapPos* pos = nil;
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
        
        pos = [geom getCenterPos];
    }
    
    if (pos) {
        // Show popup
        NSString* title = @"";
        NSString* desc = [self printableAddress:result];
        NTBalloonPopup* clickPopup = [[NTBalloonPopup alloc] initWithPos:pos style:[styleBuilder buildStyle] title:title desc:desc];
        [self.dataSource add:clickPopup];
    }
}

-(void)dismissKeyboard
{
    [self.searchField resignFirstResponder];
    self.autocompleteTableView.hidden = YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch
{
    // Make sure our views get touch events
    if (touch.view == self.autocompleteTableView || touch.view == self.searchField) {
        return YES;
    }
    return NO;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.searchField resignFirstResponder];
    self.autocompleteTableView.hidden = YES;

    [self geocode:self.searchField.text autocomplete:NO];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.autocompleteTableView.hidden = NO;
    NSString *substring = [NSString stringWithString:textField.text];
    substring = [substring stringByReplacingCharactersInRange:range withString:string];

    [self geocode:substring autocomplete:YES];
    return YES;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section
{
    return self.addresses.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *AutoCompleteRowIdentifier = @"AutoCompleteRowIdentifier";
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:AutoCompleteRowIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AutoCompleteRowIdentifier];
    }
    
    NTGeocodingResult* result = [self.addresses objectAtIndex:indexPath.row];
    cell.tag = indexPath.row;
    cell.textLabel.text = [self printableAddress:result];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    [self.searchField resignFirstResponder];
    self.autocompleteTableView.hidden = YES;
    
    [self hideGeocodingResult];
    [self showGeocodingResult:[self.addresses objectAtIndex:selectedCell.tag]];
}

@end
 
