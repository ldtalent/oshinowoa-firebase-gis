import 'dart:async';
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
  GoogleMapController? mapController;

  CameraPosition _kInitialPosition = const CameraPosition(
    target: LatLng(19.07, 72.87),
    zoom: 15,
  );

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Geoflutterfire geo = Geoflutterfire();

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId? selectedMarker;
  int _markerIdCounter = 1;
  LatLng? markerPosition;

  BehaviorSubject<double> radius = BehaviorSubject.seeded(100.0);
  Stream<dynamic>? query;

  StreamSubscription? subscription;

  Future<Position> getLocation() async {
    Position location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
    return location;
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
            initialCameraPosition: _kInitialPosition,
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.hybrid,
            compassEnabled: true,
            onCameraMove: _updateCameraPosition,
            markers: Set<Marker>.of(markers.values),
            // trafficEnabled: true,
            zoomControlsEnabled: false,
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
                  icon: const Icon(
                    Icons.pin_drop,
                    color: Colors.white,
                  ),
                  onPressed: _addGeoPoint,
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

  void _onMapCreated(GoogleMapController controller) {
    _startQuery();
    setState(() {
      mapController = controller;
    });
  }

  void _updateCameraPosition(CameraPosition position) {
    setState(() {
      _kInitialPosition = position;
    });
  }

  Future _animateToUser(double lat, double lng) async {
    return mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 15,
        ),
      ),
    );
  }

  Future<DocumentReference> _addGeoPoint() async {
    Position position = await getLocation();
    await _animateToUser(position.latitude, position.longitude);
    GeoFirePoint point = geo.point(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    return firestore.collection('locations').add({
      'position': point.data,
      'name': 'User',
    });
  }

  Future<Map<MarkerId, Marker>> _updateMarkers(
      List<DocumentSnapshot> documentList) async {
    mapController?.dispose();
    Position userCurrentLocation = await getLocation();
    GeoFirePoint point = geo.point(
      latitude: userCurrentLocation.latitude,
      longitude: userCurrentLocation.longitude,
    );
    for (var document in documentList) {
      GeoPoint position = document['position']['geopoint'];
      var distance =
          point.distance(lat: position.latitude, lng: position.longitude);
      final String markerIdVal = 'Marker-$_markerIdCounter';
      _markerIdCounter++;
      final MarkerId markerId = MarkerId(markerIdVal);
      final Marker marker = Marker(
        markerId: markerId,
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(
            title: markerIdVal,
            snippet: '$distance kilometers from present location'),
        onTap: () => _onMarkerTapped(markerId),
      );
      setState(() {
        markers[markerId] = marker;
      });
    }
    return markers;
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

  _startQuery() async {
    // Get users location
    Position pos = await getLocation();
    // Make a referece to firestore
    var ref = firestore.collection('locations');
    GeoFirePoint center =
        geo.point(latitude: pos.latitude, longitude: pos.longitude);
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
