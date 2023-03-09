import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/bus_stop_location.dart';

// ignore: must_be_immutable
class Home extends StatefulWidget {
  static const routeName = "/home-screen";

  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late MapboxMapController controller;
  String baseUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places';
  String accessToken = MAPBOX_ACCESS_TOKEN;
  LatLng currentLocation = LatLng(sharedPreferences.getDouble("latitude")!,
      sharedPreferences.getDouble("longitude")!);
  // ignore: prefer_typing_uninitialized_variables

  Dio dio = Dio();

  late List<CameraPosition> busStopLocationCoordinates;
  Future<Map> getParsedReverseGeocoding(LatLng latLng) async {
    Map<String, dynamic> response =
        await getReverseGeocodingGivenLatLngUsingMapbox(latLng);
    Map feature = response['features'][1];
    Map revGeocode = {
      'name': feature['text'],
      'address': feature['place_name'].split('${feature['text']}, ')[1],
      'place': feature['place_name'].split(',').sublist(0, 3).join(","),
      'location': latLng
    };
    return revGeocode;
  }

  Future getReverseGeocodingGivenLatLngUsingMapbox(LatLng latLng) async {
    String query = '${latLng.longitude},${latLng.latitude}';
    String url = '$baseUrl/$query.json?access_token=$accessToken';

    url = Uri.parse(url).toString();

    try {
      dio.options.contentType = Headers.jsonContentType;
      final responseData = await dio.get(url);

      return responseData.data;
      // ignore: empty_catches
    } catch (e) {}
  }

  _onMapCreated(MapboxMapController controller) async {
    this.controller = controller;
  }

  _onStyleLoadedCallBack() async {
    for (CameraPosition coordinates in busStopLocationCoordinates) {
      await controller.addSymbol(
        SymbolOptions(
          geometry: coordinates.target,
          iconSize: 1.5,
          iconImage: "assets/images/bus-stop.png",
        ),
      );
    }
    await controller.addSymbol(
      SymbolOptions(
        geometry: currentLocation,
        iconSize: 1.5,
        draggable: true,
        iconImage: "assets/images/selector.png",
      ),
    );

    controller.onSymbolTapped.add((Symbol symbol) {
      symbol.options.geometry!;
      double lat = symbol.options.geometry!.latitude;
      double lon = symbol.options.geometry!.longitude;

      if (symbol.options.draggable == true) {
        showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () async {
                  String currentAddress = (await getParsedReverseGeocoding(
                      LatLng(lat, lon)))['name'];

                  // ignore: use_build_context_synchronously
                  showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Are you sure?'),
                      content: Text(
                          "Do you want to add \"$currentAddress\" as a bus-stop?"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'Cancel'),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            dio.post(
                              Uri.parse("$serverUrl/location/busroutes/")
                                  .toString(),
                              data:
                                  "{\"lon\":\"$lon\",\"lat\":\"$lat\",\"location\":\"$currentAddress\"}",
                              options: Options(
                                headers: {
                                  'Cookie':
                                      'jwt=${sharedPreferences.getString("jwt-token")}'
                                },
                              ),
                            );
                            Provider.of<BusStopLocation>(context, listen: false)
                                .addLocation();
                            Navigator.popAndPushNamed(context, Home.routeName);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text("Create Bus-stop"),
              );
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final busStopLocation = Provider.of<BusStopLocation>(context).locations;

    busStopLocationCoordinates = List<CameraPosition>.generate(
      busStopLocation.length,
      (index) => CameraPosition(
        target: LatLng(
            busStopLocation[index]['lat'], busStopLocation[index]['lon']),
        zoom: 15,
      ),
    );
    // print(busStopLocationCoordinates);
    return Scaffold(
      body: Stack(
        children: [
          MapboxMap(
            initialCameraPosition: CameraPosition(
              target: currentLocation,
              zoom: 14,
            ),
            accessToken: MAPBOX_ACCESS_TOKEN,
            compassEnabled: true,
            myLocationEnabled: true,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoadedCallBack,
          ),
          Positioned(
            right: 5,
            bottom: 200,
            child: SizedBox(
              height: 35,
              child: FloatingActionButton(
                heroTag: null,
                onPressed: () {
                  controller.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: currentLocation,
                        zoom: 14,
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.my_location),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
