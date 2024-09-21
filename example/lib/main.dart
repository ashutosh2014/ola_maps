import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ola_maps/ola_maps.dart';

void main() {
  Olamaps.instance.initialize('YUCBZ4cDDpdTEwov513rxxxxxxxxxxxx');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ola Maps Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'GeoEncoder API',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  var result = await Olamaps.instance.geoencoder.fetchLocation(
                    'Ola Electric, 2, Hosur Rd, Koramangala Industrial Layout, Koramangala, Bengaluru, 560095, Karnataka',
                  );
                  for (var address in result) {
                    log("Addresses:: ${address.toJson()}");
                  }
                } catch (ex, st) {
                  log("Error Occurred $ex $st");
                }
              },
              child: const Text('Test Geoencode'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  var result = await Olamaps.instance.geoencoder.fetchAddresses(
                    Location(lng: 77.5526110768168, lat: 12.923946516889448),
                  );
                  for (var address in result) {
                    log("Addresses:: ${address.toJson()}");
                  }
                } catch (ex, st) {
                  log("Error Occurred $ex $st");
                }
              },
              child: const Text('Test Reverse Geoencode'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Places API',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  var result =
                      await Olamaps.instance.places.getAutocompleteSuggestions(
                    input: 'kempe',
                    // location: Location(
                    //     lng: 77.5526110768168, lat: 12.923946516889448),
                  );
                  for (var address in result) {
                    log("AutoComplete Results:: ${address.toJson()}");
                  }
                } catch (ex, st) {
                  log("Error Occurred $ex $st");
                }
              },
              child: const Text('Test AutoComplete Results'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  var result = await Olamaps.instance.places.getTextPredictions(
                    location: Location(
                        lng: 77.5526110768168, lat: 12.923946516889448),
                    types: ['Cafes'],
                    input: 'Cafes in Koramangala',
                  );
                  for (var address in result) {
                    log("Cafe:: ${address.toJson()}");
                  }
                } catch (ex, st) {
                  log("Error Occurred $ex $st");
                }
              },
              child: const Text('Test Text Seach'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  var result = await Olamaps.instance.places.getPlaceDetails(
                      placeId: 'ola-platform:a79ed32419962a11a588ea92b83ca78e');
                  log("RESULT>>>> $result");
                } catch (ex, st) {
                  log("Error Occurred $ex $st");
                }
              },
              child: const Text('Test Place Details'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  var result =
                      await Olamaps.instance.places.getNearBySearchPlaces(
                    location: Location(
                        lng: 77.5526110768168, lat: 12.923946516889448),
                    layers: ['venue'],
                    types: ['restaurant'],
                  );
                  for (var address in result) {
                    log("Near By Place:: ${address.toJson()}");
                  }
                } catch (ex, st) {
                  log("Error Occurred $ex $st");
                }
              },
              child: const Text('Test Near By Places'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'AutoComplete SeachField',
                style: TextStyle(
                  fontSize: 24,
                ),
              ),
            ),
            SizedBox(
              height: 54,
              width: 356,
              child: OlaMapsAutocomplete(
                hintText: 'Search for location',
                decoration: const CustomDropdownDecoration(
                    closedFillColor: Colors.transparent,
                    hintStyle: TextStyle(fontSize: 12, color: Colors.black)),
                onChanged: (value) {
                  log((value?.toJson()).toString());
                },
              ),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
