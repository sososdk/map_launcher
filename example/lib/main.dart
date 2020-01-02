import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';

enum ShowType { marker, plan }

void main() => runApp(MapLauncherDemo());

class MapLauncherDemo extends StatelessWidget {
  void showMaker(AvailableMap map) {
    final title = "Shanghai Tower";
    final description = "Asia's tallest building";
    final coords = Coords(31.233568, 121.505504);
    map.showMarker(
      title: title,
      description: description,
      coords: coords,
    );
  }

  void showPlan(AvailableMap map) {
    final startName = "Shanghai Tower";
    final startCoords = Coords(31.233568, 121.505504);
    final endName = "BeiJing";
    final endCoords = Coords(39.908692, 116.397477);
    map.showDirections(
      startName: startName,
      startCoords: startCoords,
      endName: endName,
      endCoords: endCoords,
    );
  }

  openMapsSheet(context, ShowType type) async {
    final availableMaps = await MapLauncher.installedMaps;

    print(availableMaps);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
              child: Wrap(
                children: <Widget>[
                  for (var map in availableMaps)
                    ListTile(
                      onTap: () => type == ShowType.plan
                          ? showPlan(map)
                          : showMaker(map),
                      title: Text(map.name),
                      leading: Icon(Icons.map),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Map Launcher Demo'),
        ),
        body: Center(child: Builder(
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                MaterialButton(
                  onPressed: () => openMapsSheet(context, ShowType.marker),
                  child: Text('Show Maps'),
                ),
                MaterialButton(
                  onPressed: () => openMapsSheet(context, ShowType.plan),
                  child: Text('Show Plans'),
                ),
              ],
            );
          },
        )),
      ),
    );
  }
}
