import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _eta;
  GoogleMapController? _mapController;
  LatLng? _destination;
  LocationData? _currentLocation;
  Location location = Location();
  Timer? _etaTimer;
  FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _alertTriggered = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _etaTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(initSettings);
  }

  Future<void> _showNotification(String t) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'wake_up_channel',
      'Wake Up Notifications',
      channelDescription: 'Notification to alert arrival at destination',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      0,
      'Wake Up Alert',
      'You will arrive in $t minutes',
      platformChannelSpecifics,
    );
  }

  Future<void> _getUserLocation() async {
    _currentLocation = await location.getLocation();
    setState(() {}); // To update the UI with the current location
  }

  Duration _calculateWakeUpInterval() {
    if (_eta == null) return Duration(minutes: 10);

    final etaParts = _eta!.split(' ');
    int minutes = 0;

    for (int i = 0; i < etaParts.length; i++) {
      if (etaParts[i].contains('hour')) {
        minutes += int.parse(etaParts[i - 1]) * 60;
      }
      if (etaParts[i].contains('min')) {
        minutes += int.parse(etaParts[i - 1]);
      }
    }

    if (minutes > 300) {
      return Duration(minutes: 60);
    } else if (minutes > 120) {
      return Duration(minutes: 40);
    } else if (minutes > 60) {
      return Duration(minutes: 20);
    } else if (minutes > 30) {
      return Duration(minutes: 10);
    } else if (minutes > 10) {
      return Duration(minutes: 5);
    } else if (minutes > 6) {
      return Duration(minutes: 2);
    }else {
      return Duration(minutes: 1);
    }
  }

  Future<void> _updateETA() async {
    if (_currentLocation == null || _destination == null) return;

    final origin = "${_currentLocation!.latitude},${_currentLocation!.longitude}";
    final destination = "${_destination!.latitude},${_destination!.longitude}";
    final apiKey = "AIzaSyA1OYTvahexlXIDPJbVzsxpPZ0B5TM6PlI";

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey');

    final response = await http.get(url);
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final duration = data['routes'][0]['legs'][0]['duration']['text'];
      setState(() {
        _eta = duration;
    });

    // Step 3: Add Debugging Logs Here
      print('Current ETA: $_eta');

    // Step 4: Check the Condition for Notification
      if (_eta != null) {
        final etaParts = _eta!.split(' '); 
        int totalMinutes = 0;

        for (int i = 0; i < etaParts.length; i++) {
          if (etaParts[i].contains('h')) {
            totalMinutes += int.parse(etaParts[i - 1]) * 60; // Convert hours to minutes
          } else if (etaParts[i].contains('m')) {
            totalMinutes += int.parse(etaParts[i - 1]); // Add remaining minutes
          }
        }

        print('Total Minutes Left: $totalMinutes');

        if (totalMinutes <= 10) {
          print('ETA is less than or equal to 10 minutes, triggering notification.');
          _showNotification("10");
        } else if(totalMinutes<=30){
          print('ETA is less than or equal to 30 minutes, triggering notification.');
          _showNotification("30");
        }else {
          print('ETA is more than 30 minutes, no notification.');
        }
      }

    } else {
      print('Error fetching ETA: ${data['status']}');
    }

  // Calculate next wake-up interval
    Duration nextInterval = _calculateWakeUpInterval();
    print('Next Wake-Up in: ${nextInterval.inMinutes} minutes');

  // Set timer for next update
    _etaTimer?.cancel();
    _etaTimer = Timer(nextInterval, _updateETA);
  }


  void _setDestination(LatLng latLng) async {
    setState(() {
      _destination = latLng;
      _alertTriggered = false;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble('destination_lat', latLng.latitude);
    prefs.setDouble('destination_lng', latLng.longitude);
    await _updateETA();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wake Me There')),
      body: _currentLocation == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  onTap: _setDestination,
                  markers: _destination != null
                      ? {
                          Marker(
                            markerId: MarkerId('destination'),
                            position: _destination!,
                          ),
                        }
                      : {},
                ),
                Positioned(
                  bottom: 50,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.white,
                    child: Text(
                      _eta != null ? 'ETA: $_eta' : 'select destination',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
              ],
            ),
    );
  }
}
