
#import "LauncherListController.h"

@interface LauncherListController ()
@end

@implementation LauncherListController

-(NSArray*) samples
{
    return @[
             @{ @"name": @"VisJson",
                @"description": @"Using high-level Carto VisJson API",
                @"controller": @"CartoVisJsonController"
                },
             @{ @"name": @"Raster Tile",
                @"description": @"How to use Carto PostGIS Raster data, as tiled raster layer",
                @"controller": @"CartoRasterTileController"
                },
             @{ @"name": @"SQL Map",
                @"description": @"Custom vector data source making queries to http://docs.cartodb.com/cartodb-platform/sql-api/",
                @"controller": @"CartoSQLController"
                },
             @{ @"name": @"UTF Grid",
                @"description": @"A sample demonstrating how to use Carto Maps API with Raster tiles and UTFGrid",
                @"controller": @"CartoUTFGridController"
                },
             @{ @"name": @"Torque Map",
                @"description": @"How to use Carto Torque tiles with CartoCSS styling",
                @"controller": @"CartoTorqueController"
                },
             ];
}

- (void)loadView
{
    // Create custom back button for navigation bar
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle: @"Back" style: UIBarButtonItemStylePlain target: nil action: nil];
    [self.navigationItem setBackBarButtonItem: backButton];
    
    // Create table view of samples
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] bounds] style:UITableViewStylePlain];
    
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView reloadData];
    
    self.view = tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Carto Map Samples";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    // Launch selected sample, use basic reflection to convert class name to class instance
    NSDictionary* sample = [[self samples] objectAtIndex:indexPath.row];
    UIViewController* subViewController = [[NSClassFromString([sample objectForKey:@"controller"]) alloc] init];
    
    [subViewController setTitle: [sample objectForKey:@"name"]];
    
    [self.navigationController pushViewController: subViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
    [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self samples] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString* cellIdentifier = @"sampleId";
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle  reuseIdentifier:cellIdentifier];
    }
    
    NSDictionary* sample = [[self samples] objectAtIndex:indexPath.row];
    cell.textLabel.text = [sample objectForKey:@"name"];
    cell.detailTextLabel.text = [sample objectForKey:@"description"];
    cell.detailTextLabel.numberOfLines = 0;
    
    return cell;
}

@end


