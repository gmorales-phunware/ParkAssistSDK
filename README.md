# ParkAssist SDK
---

ParkAssistSDK is an attempt to create a generic use of ParkAssist's API. 

# Installation
* Drag the `ParkAssist.framework` into your project. 
* Check "Copy items if needed".
* Initialize with your SharedSecret and SiteSlug
* Have Phun!

### Dependencies: 
* MobileCoreServices
* SystemConfiguration

In your app delegate: 

```
#import <ParkAssist/ParkAssist.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [ParkAssist initWithSecret:@"AppSecret" andSiteSlug:@"SiteSlug"];
    ...
    return YES;
}
```

---

# Usage

### Search for license plate
```
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[ParkAssist sharedInstance] searchLicensePlate:@"091" withLat:12.123 andLon:-45.678 withCompletion:^(BOOL success, NSArray *results, NSError *error) {
        if (success) {
            // Show results
        }
    }];
    
}
```

### Get parking availability
```
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[ParkAssist sharedInstance] getAvailableParkingInfoWithLat:12.123 andLon:-45.678 withCompletion:^(BOOL success, NSArray *results, NSError *error) {
        if (success) {
            //Show results
        }
    }];
    
}
```

---
# Rate limit
* 10 request per hour to the search service.
* 100 requests per hour to any combination of other endpoints.  

---

# License Plate

## Generating requests
**Important:** All request **must** contain the following query parameters:

* device: a Universally Unique Identifier of the mobile device making the request.
* site: a string identifying the parking facility, also called a site slug.
* signature: a string that signs each request, validating that the request originated from an approved app.

## Query parameters
**Important:** In addition to the query parameters listed above, requests to the search service must contain the following query parameters: 

* plate: The license plate text to query, eg "ABC123", "XYZ". The plate text **must** only be comprised of uppercase Alphanumeric characters. (do not include whitespace, punctuation).

**Optional:**

* lat: The latitude of the device making the request, measured by the device's GPS.
* lon: The longitude of the device making the request, measured by the device's GPS.
* ts: The timestamp when the request was generated. 

## Response
The API returns a JSON formatted response containing an array of results. 
The API returns an empty array if there are no matches, or up to 3 reults in descending order of plate similarity to search criteria (best-match first).

Response example: 

```
[	{		"bay_group": "L1 - Row B",		"bay_id": 11021,		"map": "Level-1",		"position": {		"x": 659,		"y": 752	},		"uuid": "45b0d494-4b8e-45d3-ae3f-334fa1afcf5f",		"zone": "Level 1"	},	{		"bay_group": "L3 - Row F",		"bay_id": 13017,		"map": "Level-3",		"position": {		"x": 767,		"y": 660	},		"uuid": "755602d9-914a-432a-890a-f58c4be62bb5",		"zone": "Level 3"	}]
```

**Important:** Each result containts the bay identifier and location, as well as a generatated uuid that can be used to retreive a thumbnail image of the vehicle. The position attribute describes the x and y offset of the bay on the map. The coordinates are teh pixel offsets, as a measured from the top left corner of the map. 

## Security
When searching for a license plate, the actual plate text is never returned in the result. This prevents a malicious user of attacker attempting to scrape license plate data from the site by repeatedly querying the API with random license plates. 

---

# Thumbnail service
The thumbnail service returns a low-resolution image of a search result.

## Generating requests
**Important:** All requests **must** contain a **uuid**.

## Response
An image in JPG format with dimensions 320 x 240 pixels.

## Security
When a query to the search service is performed, the server generates a short-lived uuid token to access each the thumbnail of each result.
**Important:** These tokens expire **5** minutes after creation.

---

# Map Service
The map service returns an image of a map at the parking facility. 

## Generating requests
**Important:** All requests **must** contain a **map-name**.

## Response 
An image in PNG format. 

---

# Zones Service
The zones service returns teh vehicle counts in each zone at the property. For most installations, each level of the garage is a zone. 

## Response
The API returns a JSON array containing the vehicle counts in each zone of the parking facility. 

```
[
	{		"counts": {		"available": 63,		"occupied": 240,		"out_of_service": 0,		"reserved": 0,		"timestamp": "2013-08-19T11:46:59.4640000-04:00",		"total": 303,		"vacant": 63	},		"id": 3,		"name": "Level 4"	},
	{		"counts": {		"available": 48,		"occupied": 71,		"out_of_service": 0,		"reserved": 7,		"timestamp": "2013-08-19T11:40:11.0820000-04:00",		"total": 121,
		"vacant": 50	},		"id": 4,
		"name": "Level 1"	}]
```
For displaying available parking spaces to site visitors, the available figure is most appropriate. Count terminology is defined as:

* Total: All bays in the zone, regardless of status.
* Out of Service: Bays not currently monitored due to a malfunction or sensor downtime. 
* Occupied: Bays with a vehicle parked. 
* Vacant: Bays with no vehicle parked.
* Reserved: Bays with an assigned reservation; can overlap with out of service, vacant, and occupied bays.
* Available: Bays with no vehicle parked and no reservation.

---
# Signs Service
The signs service returns information about the signs at the parking facility.

## Response
The API returns a JSON array containing the sign counts for each sign in the parking facility. 

```
[	{		"counts": {		"available": 6,		"occupied": 163,		"out_of_service": 13,		"reserved": 9,		"timestamp": "2013-08-19T11:45:06.8120000-04:00",		"total": 172,		"vacant": 9	},		"id": 1,		"name": "Level 2 Sign"	},]
```

## Contributing to this project
If you have feature requests or bug reports, feel free to help out by sending [pull requests](https://github.com/gmorales-phunware/ParkAssistSDK/pulls) or by [creating new issues](https://github.com/gmorales-phunware/ParkAssistSDK/issues/new). 

Thanks to all of [our contributors](https://github.com/gmorales-phunware/ParkAssistSDK/graphs/contributors).

Please take a moment to review the guidelines written by [Nicolas Gallagher](https://github.com/necolas/):
* [Bug reports](https://github.com/necolas/issue-guidelines/blob/master/CONTRIBUTING.md#bugs)
* [Feature requests](https://github.com/necolas/issue-guidelines/blob/master/CONTRIBUTING.md#features)
* [Pull requests](https://github.com/necolas/issue-guidelines/blob/master/CONTRIBUTING.md#pull-requests)