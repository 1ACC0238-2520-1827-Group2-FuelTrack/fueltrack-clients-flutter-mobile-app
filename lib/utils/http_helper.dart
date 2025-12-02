
import 'package:fueltrack_clients/models/notification.dart';
import 'package:fueltrack_clients/models/order.dart';
import 'package:fueltrack_clients/models/payment.dart';
import 'package:fueltrack_clients/models/profile.dart';

import 'package:fueltrack_clients/models/user.dart';
import 'package:fueltrack_clients/models/method.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class HttpHelper {
  final String urlBase = 'https://fueltrack-api.onrender.com';
  final String urlUpcoming = '/api';


  // Autenticación - Login/Register
  Future<User> postAuthLogin(String email, String password) async {
    final String loginPath = '$urlBase$urlUpcoming/Auth/login';
    final uri = Uri.parse(loginPath);

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'email': email,
      'password': password,
    });

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }

  Future<User> postAuthRegister(String firstName,
      String lastName,
      String email,
      String password,
      String phone) async
  {
    final String registerPath = '$urlBase$urlUpcoming/Auth/register';
    final uri = Uri.parse(registerPath);
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phone': phone,
      'role': 2 // usuario normal
    });
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }

  Future<User> postAuthRefreshToken(User user) async {
    final String refreshPath = '$urlBase$urlUpcoming/Auth/refresh';
    final uri = Uri.parse(refreshPath);

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = jsonEncode(user.toJson());

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
        return User.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }


  // Notificaciones - Get Notifications

  Future<List<Notification>> getAllNotifications(String token) async {
    final String notificationsPath = '$urlBase$urlUpcoming/Notifications';
    final uri = Uri.parse(notificationsPath);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map<Notification>((i) =>
            Notification.fromJson(i as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }

  // Orders - Get Orders/Post Order

  Future<List<Order>> getAllOrders(String token) async {
    final String ordersPath = '$urlBase$urlUpcoming/Orders';
    final uri = Uri.parse(ordersPath);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map<Order>((i) => Order.fromJson(i as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }


  Future<Order> postOrder(String token,
      int fuelType,
      double quantity,
      String deliveryAddress,
      double deliveryLatitude,
      double deliveryLongitude,) async
  {
    final String orderPath = '$urlBase$urlUpcoming/Orders';
    final uri = Uri.parse(orderPath);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> payload = {
      'fuelType': fuelType,
      'quantity': quantity,
      'deliveryAddress': deliveryAddress,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
    };

    final body = jsonEncode(payload);

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
        return Order.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }

  ////// Payments - Aqui todos los endpoints de pagos menos patment/id

  // Endpoints de las formas de pago
  Future<List<Method>> getAllPaymentMethods(String token) async {
    final String methodsPath = '$urlBase$urlUpcoming/Payments/methods';
    final uri = Uri.parse(methodsPath);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map<Method>((i) => Method.fromJson(i as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }

  Future<Method> postPaymentMethod(String token,
      String cardHolderName,
      String cardNumber,
      int expiryMonth,
      int expiryYear,
      String cvv,
      bool isDefault) async
  {
    final String methodPath = '$urlBase$urlUpcoming/Payments/methods';
    final uri = Uri.parse(methodPath);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> payload = {
      'cardHolderName': cardHolderName,
      'cardNumber': cardNumber,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvv': cvv,
      'isDefault': isDefault,
    };



    final body = jsonEncode(payload);

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
        return Method.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }


  Future deletePaymentMethod(String token, int methodId) async {
    final String methodPath = '$urlBase$urlUpcoming/Payments/methods/$methodId';
    final uri = Uri.parse(methodPath);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }

  //Endpoints de los pagos

  Future<List<Payment>> getAllPayments(String token) async {
    final String paymentsPath = '$urlBase$urlUpcoming/Payments';
    final uri = Uri.parse(paymentsPath);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map<Payment>((i) => Payment.fromJson(i as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }

  Future<Payment> postPayment(
      String token,
      int orderId,
      int paymentMethodId) async
  {
    final String paymentPath = '$urlBase$urlUpcoming/Payments/process';
    final uri = Uri.parse(paymentPath);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> payload = {
      'orderId': orderId,
      'paymentMethodId': paymentMethodId,
    };

    final body = jsonEncode(payload);

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
        return Payment.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }


  // Users/Profile - Get Profile/Update Profile

  Future<Profile> getUserProfile(String token) async {
    final String profilePath = '$urlBase$urlUpcoming/Users/profile';
    final uri = Uri.parse(profilePath);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
        return Profile.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }

  Future<Profile> updateUserProfile(
      String token,
      Profile profile) async
  {
    final String profilePath = '$urlBase$urlUpcoming/Users/profile';
    final uri = Uri.parse(profilePath);

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> payload = profile.toJson();

    final body = jsonEncode(payload);

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
        return Profile.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión de red');
    } catch (e) {
      rethrow;
    }
  }
}