import 'package:flutter/material.dart';
import 'package:oshinowoa_firebase_gis/models/model.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<Model> _data;
  late MapShapeSource _mapSource;

  @override
  void initState() {
    _data = const <Model>[
      Model('Angola', Color.fromRGBO(204, 9, 47, 1.0), 'Angola'),
      Model('Burundi', Color.fromRGBO(67, 176, 42, 1.0), 'Burundi'),
      Model('Benin', Color.fromRGBO(232, 17, 45, 1.0), 'Benin'),
      Model('Botswana', Color.fromRGBO(255, 255, 255, 1.0), 'Botswana'),
      Model('Central African Rep.', Color.fromRGBO(210, 16, 52, 1.0),
          'Central\nAfrican\nRepuplic'),
      Model('South Africa', Color.fromRGBO(0, 35, 149, 1.0), 'South\nAfrica'),
      Model('Kenya', Color.fromRGBO(153, 41, 45, 1.0), 'Kenya'),
      Model('Nigeria', Color.fromRGBO(0, 135, 81, 1.0), 'Nigeria'),
      Model('Burkina Faso', Color.fromRGBO(0, 158, 73, 1.0), 'Burkina\nFaso'),
      Model('C�te d\'Ivoire', Color.fromRGBO(255, 130, 0, 1.0), 'Ivory\nCoast'),
      Model('Cameroon', Color.fromRGBO(206, 17, 38, 1.0), 'Cameroon'),
      Model('Egypt', Color.fromRGBO(16, 52, 166, 1.0), 'Egypt'),
      Model('Gabon', Color.fromRGBO(0, 158, 96, 1), 'Gabon'),
      Model('Ghana', Color.fromRGBO(252, 209, 22, 1), 'Ghana'),
      Model('Malawi', Color.fromRGBO(206, 17, 38, 1), 'Malawi'),
      Model('Sudan', Colors.teal, 'Sudan')
    ];

    _mapSource = MapShapeSource.asset(
      'assets/africa.json',
      shapeDataField: 'name',
      dataCount: _data.length,
      primaryValueMapper: (int index) => _data[index].state,
      dataLabelMapper: (int index) => _data[index].stateCode,
      shapeColorValueMapper: (int index) => _data[index].color,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIS App'),
      ),
      body: const SizedBox(
        child: SfMaps(
          layers: [
            MapTileLayer(
                urlTemplate:
                    'https://ibasemaps-api.arcgis.com/arcgis/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}?apiKey=AAPKc025b874e0d4483ab9dc13d1375d51f2x29YhHxFBE2k6K4c8eT7DMIB6WyFAruIvmuLq4gB0LhmSJYmSTg3ahL5UwDd_zSr',
                initialFocalLatLng: MapLatLng(-23.698042, 133.880753),
                initialZoomLevel: 3),
          ],
        ),
      ),
    );
  }
}





// MapShapeLayer(
//                 source: _mapSource,
//                 showDataLabels: true,
//                 legend: const MapLegend(MapElement.shape),
//                 tooltipSettings: MapTooltipSettings(
//                   color: Colors.grey[700],
//                   strokeColor: Colors.white,
//                   strokeWidth: 2,
//                 ),
//                 strokeColor: Colors.white,
//                 strokeWidth: 0.5,
//                 shapeTooltipBuilder: (BuildContext context, int index) {
//                   return Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Text(
//                       _data[index].stateCode,
//                       style: const TextStyle(color: Colors.white),
//                     ),
//                   );
//                 },
//                 dataLabelSettings: MapDataLabelSettings(
//                   textStyle: TextStyle(
//                     color: Colors.black26,
//                     fontWeight: FontWeight.w400,
//                     fontSize: Theme.of(context).textTheme.caption!.fontSize,
//                   ),
//                 ),
//               )