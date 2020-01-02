#import "MapLauncherPlugin.h"
#import <MapKit/MapKit.h>

typedef enum {
  apple,
  google,
  amap,
  baidu,
  qq,
  waze,
  yandexNavi,
  yandexMaps,
} MapType;

extern NSString* const MapType_toString[];

NSString* const MapType_toString[] = {
  [apple] = @"apple",
  [google] = @"google",
  [amap] = @"amap",
  [baidu] = @"baidu",
  [qq] = @"qq",
  [waze] = @"waze",
  [yandexNavi] = @"yandexNavi",
  [yandexMaps] = @"yandexMaps",
};

@interface Map : NSObject
@property(readonly, nonatomic) NSString *name;
@property(readonly, nonatomic) MapType type;
@property(readonly, nonatomic) NSString *scheme;

- initWithName:(NSString *)name type:(MapType)type scheme:(NSString *)scheme;
@end

@implementation Map

- (id)initWithName:(NSString *)name type:(MapType)type scheme:(NSString *)scheme {
  self = [super init];
  _name = name;
  _type = type;
  _scheme = scheme;
  return self;
}

- (NSDictionary<NSString *, NSString *> *)toMap {
  return @{@"name": _name, @"type": MapType_toString[_type]};
}

@end

@implementation MapLauncherPlugin {
  NSArray *maps;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel
                                   methodChannelWithName:@"sososdk.github.com/map_launcher"
                                   binaryMessenger:[registrar messenger]];
  MapLauncherPlugin *instance = [[MapLauncherPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
  if (self = [super init]) {
    maps = @[
      [[Map alloc] initWithName:@"Apple Maps" type:apple scheme:@""],
      [[Map alloc] initWithName:@"Google Maps" type:google scheme:@"comgooglemaps://"],
      [[Map alloc] initWithName:@"Amap" type:amap scheme:@"iosamap://"],
      [[Map alloc] initWithName:@"Baidu Maps" type:baidu scheme:@"baidumap://"],
      [[Map alloc] initWithName:@"QQ Maps" type:qq scheme:@"qqmap://"],
      [[Map alloc] initWithName:@"Waze" type:waze scheme:@"waze://"],
      [[Map alloc] initWithName:@"Yandex Navigator" type:yandexNavi scheme:@"yandexnavi://"],
      [[Map alloc] initWithName:@"Yandex Maps" type:yandexMaps scheme:@"yandexmaps://"],
    ];
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"getInstalledMaps" isEqualToString:call.method]) {
    NSMutableArray *temp = [NSMutableArray array];
    for (Map *map in maps) {
      if ([self isMapAvailable:map]) {
        [temp addObject:[map toMap]];
      }
    }
    result(temp);
  } else if ([@"isMapAvailable" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    NSString *type = arguments[@"type"];
    result(@([self isMapAvailable:[self getMapByRawMapType:type]]));
  } else if ([@"showMaker" isEqualToString:call.method]) {
    NSDictionary *arguments = [call arguments];
    NSString *type = arguments[@"type"];
    Map *map = [self getMapByRawMapType:type];
    if ([self isMapAvailable:map]) {
      NSString *url = arguments[@"url"];
      NSString *title = arguments[@"title"];
      double latitude = [arguments[@"latitude"] doubleValue];
      double longitude = [arguments[@"longitude"] doubleValue];
      [self showMaker:map.type url:url title:title latitude:latitude longitude:longitude result:result];
    } else {
      result([FlutterError errorWithCode:@"MAP_NOT_AVAILABLE" message:@"Map is not installed on a device" details:nil]);
    }
  } else if ([@"showDirections" isEqualToString:call.method]) {
     NSDictionary *arguments = [call arguments];
     NSString *type = arguments[@"type"];
     Map *map = [self getMapByRawMapType:type];
     if ([self isMapAvailable:map]) {
       NSString *url = arguments[@"url"];
       NSString *startName = arguments[@"startName"];
       double startLatitude = [arguments[@"startLatitude"] doubleValue];
       double startLongitude = [arguments[@"startLongitude"] doubleValue];
       NSString *endName = arguments[@"endName"];
       double endLatitude = [arguments[@"endLatitude"] doubleValue];
       double endLongitude = [arguments[@"endLongitude"] doubleValue];
       NSString *directionsMode = [self convertDirectionsMode:arguments[@"directionsMode"]];
       [self showDirections:map.type url:url startName:startName startLatitude:startLatitude startLongitude:startLongitude endName:endName endLatitude:endLatitude endLongitude:endLongitude directionsMode:directionsMode result:result];
     } else {
       result([FlutterError errorWithCode:@"MAP_NOT_AVAILABLE" message:@"Map is not installed on a device" details:nil]);
     }
   } else {
    result(FlutterMethodNotImplemented);
  }
}

- (BOOL) isMapAvailable:(Map *)map {
  if (map == nil) return false;
  if (map.type == apple) return true;
  return [UIApplication.sharedApplication canOpenURL:[NSURL URLWithString:map.scheme]];
}

- (Map *)getMapByRawMapType:(NSString *)type {
  for (Map *map in maps) {
    if ([MapType_toString[map.type] isEqualToString:type]) {
      return map;
    }
  }
  return nil;
}

- (void)showMaker:(MapType)type url:(NSString *)url title:(NSString *)title latitude:(double)latitude longitude:(double)longitude result:(FlutterResult)result {
  if (type == apple) {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.01, 0.02));
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
    MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
    NSDictionary<NSString *, id> *options = @{
      MKLaunchOptionsMapCenterKey: [NSValue valueWithMKCoordinate:region.center],
      MKLaunchOptionsMapSpanKey: [NSValue valueWithMKCoordinateSpan:region.span],
    };
    [mapItem setName:title];
    [mapItem openInMapsWithLaunchOptions:options];
  } else {
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:url]];
  }
  result(nil);
}

- (void)showDirections:(MapType)type url:(NSString *)url startName:(NSString *)startName startLatitude:(double)startLatitude startLongitude:(double)startLongitude endName:(NSString *)endName endLatitude:(double)endLatitude endLongitude:(double)endLongitude directionsMode:(NSString *)directionsMode result:(FlutterResult)result {
  if (type == apple) {
    CLLocationCoordinate2D startCoordinate = CLLocationCoordinate2DMake(startLatitude, startLongitude);
    MKPlacemark *startPlacemark = [[MKPlacemark alloc] initWithCoordinate:startCoordinate addressDictionary:nil];
    MKMapItem *startMapItem = [[MKMapItem alloc] initWithPlacemark:startPlacemark];
    [startMapItem setName:startName];
    CLLocationCoordinate2D endCoordinate = CLLocationCoordinate2DMake(endLatitude, endLongitude);
    MKPlacemark *endPlacemark = [[MKPlacemark alloc] initWithCoordinate:endCoordinate addressDictionary:nil];
    MKMapItem *endMapItem = [[MKMapItem alloc] initWithPlacemark:endPlacemark];
    [endMapItem setName:endName];
    [MKMapItem openMapsWithItems:@[startMapItem, endMapItem]
                   launchOptions:@{
                     MKLaunchOptionsDirectionsModeKey: directionsMode,
                     MKLaunchOptionsShowsTrafficKey: [NSNumber numberWithBool:YES],
                   }];
  } else {
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:url]];
  }
  result(nil);
}

- (NSString *)convertDirectionsMode:(NSString *)mode {
  if ([@"driving" isEqualToString:mode]) {
    return MKLaunchOptionsDirectionsModeDriving;
  } else if ([@"transit" isEqualToString:mode]) {
    if (@available(iOS 9.0, *)) {
      return MKLaunchOptionsDirectionsModeTransit;
    } else {
      return MKLaunchOptionsDirectionsModeDriving;
    }
  } else if ([@"walking" isEqualToString:mode]) {
    return MKLaunchOptionsDirectionsModeWalking;
  } else {
    if (@available(iOS 10.0, *)) {
      return MKLaunchOptionsDirectionsModeDefault;
    } else {
      return MKLaunchOptionsDirectionsModeDriving;
    }
  }
}
@end
