// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:place_tracker_demo/place_bean.dart';
import 'package:place_tracker_demo/stub_data.dart';
import 'package:provider/provider.dart';

import 'place_list.dart';
import 'place_map.dart';

enum PlaceTrackerViewType {
  map,
  list,
}

class PlaceTrackerDemo extends StatelessWidget {
  const PlaceTrackerDemo({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _PlaceTrackerStateFul(),
    );
  }
}

class _PlaceTrackerStateFul extends StatefulWidget {

  @override
  State<_PlaceTrackerStateFul> createState() => _PlaceTrackerStateFulState();
}

class _PlaceTrackerStateFulState extends State<_PlaceTrackerStateFul> {
  late Position _position;

  double _lat = 0.0, _lng = 0.0;

  @override
  void initState() {
    _checkPermission();
    super.initState();
  }

  _checkPermission() async {
    Permission permission = Permission.location; // 添加要访问的权限是什么
    PermissionStatus status = await permission.status; // 获取当前权限的状态
    // 判断当前状态处于什么类型
    if( status.isDenied ){
      permission.request();
      // 第一次申请被拒绝 再次重试
    } else if( status.isPermanentlyDenied ){
      permission.request();
      // 第二次申请被拒绝 去设置中心
    } else if( status.isLimited ){
      permission.request();
    } else if( status.isRestricted ){
      permission.request();
    } else if(status.isGranted || await permission.request().isGranted){
      _statusGranted();
    }
  }

  _statusGranted() async{
    _position = await Geolocator.getCurrentPosition();
    setState(() {
      _lat = _position.latitude;
      _lng = _position.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Padding(
              padding: EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
              child: Icon(Icons.pin_drop, size: 24.0),
            ),
            Text('Place Tracker Demo'),
          ],
        ),
        backgroundColor: Colors.green[700],
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
            child: IconButton(
              icon: Icon(
                state.viewType == PlaceTrackerViewType.map
                    ? Icons.list
                    : Icons.map,
                size: 32.0,
              ),
              onPressed: () {
                state.setViewType(
                  state.viewType == PlaceTrackerViewType.map
                      ? PlaceTrackerViewType.list
                      : PlaceTrackerViewType.map,
                );
              },
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: state.viewType == PlaceTrackerViewType.map ? 0 : 1,
        children: [
          PlaceMap(center: LatLng(_lat, _lng)),
          const PlaceList()
        ],
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  AppState({
    this.places = StubData.places,
    this.selectedCategory = PlaceCategory.favorite,
    this.viewType = PlaceTrackerViewType.map,
  });

  List<PlaceBean> places;
  PlaceCategory selectedCategory;
  PlaceTrackerViewType viewType;

  void setViewType(PlaceTrackerViewType viewType) {
    this.viewType = viewType;
    notifyListeners();
  }

  void setSelectedCategory(PlaceCategory newCategory) {
    selectedCategory = newCategory;
    notifyListeners();
  }

  void setPlaces(List<PlaceBean> newPlaces) {
    places = newPlaces;
    notifyListeners();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppState &&
        other.places == places &&
        other.selectedCategory == selectedCategory &&
        other.viewType == viewType;
  }

  @override
  int get hashCode => Object.hash(places, selectedCategory, viewType);
}