// dart
// File: 'lib/UI/navigation/home.dart'
import 'package:flutter/material.dart';
import '../view/notifications_view.dart';
import '../view/orders_view.dart';
import '../view/payments_view.dart';
import '../view/profile_view.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 1; // 0: Notificaciones, 1: Órdenes, 2: Pagos

  static final List<Widget> _views = [
    NotificationsView(embedded: true),
    OrdersView(),
    PaymentsView(),
  ];

  static const List<String> _titles = [
    'Panel de notificaciones',
    'Gestión de órdenes',
    'Pagos y métodos',
  ];

  static const List<String> _subtitles = [
    'Revisa avisos y actualizaciones recientes.',
    'Crea y controla tus órdenes de combustible.',
    'Administra pagos y métodos de forma segura.',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2E7D32);
    final Color unselectedColor = Colors.grey[600]!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        // Aumenta la altura del AppBar
        toolbarHeight: 80,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                fontSize: 22, // más grande
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitles[_selectedIndex],
              style: const TextStyle(
                fontSize: 15, // más grande
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          // Centra verticalmente y aumenta tamaño del logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Tooltip(
                message: 'Perfil',
                child: GestureDetector(
                  onTap: _goToProfile,
                  child: Image.asset(
                    'assets/images/logo_white.png',
                    width: 36, // más grande
                    height: 36, // más grande
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: _views[_selectedIndex],
      ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey[300]!,
                width: 1, // línea fina
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                offset: const Offset(0, 2),
                blurRadius: 6, // sombra bajo la barra
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, // usa el color del Container
            elevation: 0,
            selectedItemColor: primaryGreen,
            unselectedItemColor: unselectedColor,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
            selectedIconTheme: const IconThemeData(size: 26),
            unselectedIconTheme: const IconThemeData(size: 24),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(Icons.notifications),
                label: 'Notificaciones',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt),
                label: 'Órdenes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payment_outlined),
                activeIcon: Icon(Icons.payment),
                label: 'Pagos',
              ),
            ],
          ),
        )
    );
  }
}