import 'package:flutter/material.dart';

import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:yatraa_admin/main.dart';
import 'package:yatraa_admin/screens/login_screen.dart';

import '../providers/bus_stop_location.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    initializeLocationAndSave();
  }

  void initializeLocationAndSave() async {
    Location location = Location();
    bool? serviceEnabled;
    PermissionStatus? permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
    }

    LocationData locationData = await location.getLocation();
    sharedPreferences.setDouble("latitude", locationData.latitude!);
    sharedPreferences.setDouble("longitude", locationData.longitude!);

    // ignore: use_build_context_synchronously
    Provider.of<BusStopLocation>(context, listen: false).addLocation();
    // ignore: use_build_context_synchronously
    Navigator.pushNamed(context, LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: const Color.fromARGB(255, 29, 141, 34),
        child: Center(
          child: Image.asset(
            "assets/images/logo_.png",
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
