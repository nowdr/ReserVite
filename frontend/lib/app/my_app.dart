import 'package:flutter/material.dart';
import 'package:prbd_2526_f01/views/pages/client_reservation_details_page.dart';
import 'package:prbd_2526_f01/views/pages/client_reservation_list_page.dart';
import 'package:prbd_2526_f01/views/pages/client_restaurant_details_page.dart';
import 'package:prbd_2526_f01/views/pages/client_restaurant_search_page.dart';
import 'package:prbd_2526_f01/views/pages/manager_assign_tables_page.dart';
import 'package:prbd_2526_f01/views/pages/manager_reservation_details_page.dart';
import 'package:prbd_2526_f01/views/pages/manager_reservation_list_page.dart';
import 'package:prbd_2526_f01/views/pages/manager_restaurant_list_page.dart';
import 'package:prbd_2526_f01/views/pages/signup_page.dart';

import '../views/pages/login_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReserVite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/client/reservations': (context) => ClientReservationListPage(),
        '/client/reservations/details': (context) =>
            ClientReservationDetailsPage(),
        '/client/restaurants/search': (context) => ClientRestaurantSearchPage(),
        '/client/restaurants/details': (context) =>
            ClientRestaurantDetailsPage(),
        '/manager/restaurants': (context) => ManagerRestaurantListPage(),
        '/manager/reservations': (context) => ManagerReservationListPage(),
        '/manager/reservations/details': (context) =>
            ManagerReservationDetailsPage(),
        '/manager/reservations/assign-tables': (context) =>
            ManagerAssignTables(),
      },
    );
  }
}
