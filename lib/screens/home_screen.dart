import 'dart:math';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Geolocator location = Geolocator();

  // Position initialPosition = Geolocator.getCurrentPosition();
  // static const LatLng center = LatLng(initialPosition.latitude, initialPosition.lo);

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Geoflutterfire geo = Geoflutterfire();

  GoogleMapController? mapController;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId? selectedMarker;
  int _markerIdCounter = 1;
  LatLng? markerPosition;

  BehaviorSubject<double> radius = BehaviorSubject.seeded(100.0);

  Stream<dynamic>? query;

  StreamSubscription? subscription;

  void _onMapCreated(GoogleMapController controller) {
    _startQuery();
    setState(() {
      mapController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIS App'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-33.852, 151.211),
              zoom: 10,
            ),
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.hybrid,
            compassEnabled: true,
            markers: Set<Marker>.of(markers.values),
            // trafficEnabled: true,
          ),
          Positioned(
            bottom: 80,
            right: 15,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                30.0,
              ),
              child: Container(
                width: 40.h,
                height: 40.h,
                color: Colors.greenAccent,
                child: IconButton(
                  padding: const EdgeInsets.all(
                    3.0,
                  ),
                  onPressed: _addGeoPoint,
                  icon: const Icon(
                    Icons.pin_drop,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 70.0,
            left: 15.0,
            child: Slider(
              inactiveColor: Colors.grey,
              activeColor: Colors.greenAccent,
              thumbColor: Colors.greenAccent,
              min: 100.0,
              max: 500.0,
              divisions: 4,
              value: radius.value,
              label: 'Radius ${radius.value}km',
              onChanged: _updateQuery,
            ),
          ),
        ],
      ),
    );
  }

  Future<DocumentReference> _addGeoPoint() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    GeoFirePoint point = geo.point(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    var store = firestore.collection('location').add({
      'position': point.data,
      'name': 'Ade',
    });
    return store;
  }

  // void _addMarker() {
  //   final int markerCount = markers.length;
  //   if (markerCount == 12) {
  //     return;
  //   }
  //   final String markerIdVal = 'marker_id_$_markerIdCounter';
  //   _markerIdCounter++;
  //   final MarkerId markerId = MarkerId(markerIdVal);

  //   final Marker marker = Marker(
  //     markerId: markerId,
  //     position: mapController.animateCamera(cameraUpdate),
  //     infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
  //     onTap: () => _onMarkerTapped(markerId),
  //   );

  //   setState(() {
  //     markers[markerId] = marker;
  //   });
  // }

  void _updateMarkers(List<DocumentSnapshot> documentList) async {
    Position loc = await Geolocator.getCurrentPosition();
    // print(documentList);
    mapController?.dispose();
    documentList.forEach((DocumentSnapshot document) {
      GeoPoint pos = document.get('position')['geopoint'];
      double distance = document.get('distance');

      GeoFirePoint center = geo.point(latitude: loc.latitude, longitude: loc.longitude);

      final String markerIdVal = 'marker_id_$_markerIdCounter';
      _markerIdCounter++;
      final MarkerId markerId = MarkerId(markerIdVal);
      var marker = Marker(
        markerId: markerId,
        position: LatLng(
          center.latitude + sin(_markerIdCounter * pi / 6.0) / 20.0,
          center.longitude + cos(_markerIdCounter * pi / 6.0) / 20.0,
        ),
        infoWindow: InfoWindow(title: markerIdVal, snippet: '*'),
        onTap: () => _onMarkerTapped(markerId),
      );

      setState(() {
        markers[markerId] = marker;
      });
    });
  }

  void _onMarkerTapped(MarkerId markerId) {
    final Marker? tappedMarker = markers[markerId];
    if (tappedMarker != null) {
      setState(() {
        final MarkerId? previousMarkerId = selectedMarker;
        if (previousMarkerId != null && markers.containsKey(previousMarkerId)) {
          final Marker resetOld = markers[previousMarkerId]!
              .copyWith(iconParam: BitmapDescriptor.defaultMarker);
          markers[previousMarkerId] = resetOld;
        }
        selectedMarker = markerId;
        final Marker newMarker = tappedMarker.copyWith(
          iconParam: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        );
        markers[markerId] = newMarker;

        markerPosition = null;
      });
    }
  }

  void _animateToUser() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            position.latitude,
            position.longitude,
          ),
          zoom: 10,
        ),
      ),
    );
  }

  _startQuery() async {
    // Get users location
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
    double lat = pos.latitude;
    double lng = pos.longitude;

    // Make a referece to firestore
    var ref = firestore.collection('locations');
    GeoFirePoint center = geo.point(latitude: lat, longitude: lng);

    // subscribe to query
    subscription = radius.switchMap((rad) {
      return geo.collection(collectionRef: ref).within(
          center: center, radius: rad, field: 'position', strictMode: true);
    }).listen(_updateMarkers);
  }

  _updateQuery(value) {
    final zoomMap = {
      100.0: 12.0,
      200.0: 10.0,
      300.0: 7.0,
      400.0: 6.0,
      500.0: 5.0
    };
    final zoom = zoomMap[value];
    mapController?.moveCamera(CameraUpdate.zoomTo(zoom!));

    setState(() {
      radius.add(value);
    });
  }

  @override
  dispose() {
    subscription?.cancel();
    super.dispose();
  }
}
