import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeMap extends StatefulWidget {
  HomeMap({Key key}) : super(key: key);

  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  Set<Marker> _mapMarkers = Set();
  Set<Polygon> _mapPolygons = Set();
  GoogleMapController _mapController;
  TextEditingController _textController = TextEditingController();
  Position _currentPosition;
  Position _defaultPosition = Position(
    longitude: 20.608148,
    latitude: -103.417576,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getCurrentPosition(),
      builder: (context, result) {
        if (result.error == null) {
          if (_currentPosition == null) _currentPosition = _defaultPosition;
          return Scaffold(
            appBar: AppBar(
              title: Text("Maps"),
              actions: <Widget>[
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text("Posición actual"),
                      value: 1,
                    ),
                    PopupMenuItem(
                      child: Text("Buscar dirección"),
                      value: 2,
                    ),
                    PopupMenuItem(
                      child: Text("Trazar polígono"),
                      value: 3,
                    )
                  ],
                  onSelected: (value) {
                    if(value == 1) {
                      _getCurrentPosition();
                    } else if (value == 2) {
                      _search();
                    } else if (value == 3) {
                      _polygons();
                    }
                  },
                )
              ],
            ),
            body: Stack(
              children: <Widget>[
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  markers: _mapMarkers,
                  polygons: _mapPolygons,
                  onLongPress: _setMarker,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition.latitude,
                      _currentPosition.longitude,
                    ),
                  ),
                )
              ],
            ),
          );
        } else {
          Scaffold(
            body: Center(child: Text("Error!")),
          );
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  void _onMapCreated(controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void _setMarker(LatLng coord) async {
    // add marker
    setState(() {
      _mapMarkers.add(
        Marker(
          markerId: MarkerId(coord.toString()),
          position: coord,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          onTap: () async {
            var places = await Geolocator().placemarkFromCoordinates(coord.latitude, coord.longitude);
            _showBottomSheet(places.first);
          }
        ),
      );
    });
  }

  Future<void> _getCurrentPosition() async {
    // get current position
    _currentPosition = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    

    // add marker
    _mapMarkers.add(
      Marker(
        markerId: MarkerId(_currentPosition.toString()),
        position: LatLng(
          _currentPosition.latitude,
          _currentPosition.longitude,
        ),
        onTap: () async {
          var places = await Geolocator().placemarkFromCoordinates(_currentPosition.latitude, _currentPosition.longitude);
            _showBottomSheet(places.first);
        }
      ),
    );

    // move camera
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition.latitude,
            _currentPosition.longitude,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }

  Future<String> _getGeolocationAddress(Position position) async {
    var places = await Geolocator().placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (places != null && places.isNotEmpty) {
      final Placemark place = places.first;
      return "${place.thoroughfare}, ${place.locality}";
    }
    return "No address availabe";
  }

  void _search() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Buscar lugar"),
          content: TextField(
            controller: _textController,
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              }, 
              child: Text("Cancelar")
            ),
            FlatButton(
              onPressed: () async {
                List<Placemark> placemark = await Geolocator().placemarkFromAddress(_textController.text);
                _mapController.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(
                        placemark.first.position.latitude,
                        placemark.first.position.longitude,
                      ),
                      zoom: 15.0,
                    ),
                  ),
                );
                _textController.clear();
                Navigator.of(context).pop();
              }, 
              child: Text("Buscar")
            ),
          ],
        );
      }
    );
  }

  void _polygons() {
    setState(() {
      if(_mapPolygons.isEmpty) {
        List<LatLng> list = new List();
        _mapMarkers.forEach( (marker) {
          if(marker.position.latitude != _currentPosition.latitude || marker.position.longitude != marker.position.longitude) {
            list.add(marker.position);
          }
        });
        _mapPolygons.add(
          Polygon(
            polygonId: PolygonId("value"),
            points: list,
            strokeColor: Colors.red,
            fillColor: Colors.red
          )
        );
      } else {
        _mapPolygons = Set();
      }
    });
  }

  void _showBottomSheet(Placemark p) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
          return Container (
            child: new Wrap (
              children: <Widget> [
                new ListTile(
                  title: new Text('País'),
                  subtitle: Text(p.country),
                  onTap: () => {}          
                ),
                new ListTile(
                  title: new Text('Localidad'),
                  subtitle: Text(p.locality),
                  onTap: () => {},          
                ),
                new ListTile(
                  title: new Text('CP'),
                  subtitle: Text(p.postalCode),
                  onTap: () => {},          
                ),
                new ListTile(
                  title: new Text('Coordenadas'),
                  subtitle: Text("${p.position.latitude.toString()}, ${p.position.longitude.toString()}"),
                  onTap: () => {},          
                ),
                new ListTile(
                  title: new Text('Área administrativa'),
                  subtitle: Text(p.administrativeArea),
                  onTap: () => {},          
                ),
              ],
            ),
          );
      }
    );
  }
}
