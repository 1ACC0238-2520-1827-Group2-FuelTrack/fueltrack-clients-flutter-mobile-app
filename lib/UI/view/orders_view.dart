// dart
// `lib/UI/view/orders_view.dart`
import 'package:flutter/material.dart';
import 'package:fueltrack_clients/utils/db_helper.dart';
import 'package:fueltrack_clients/utils/http_helper.dart';
import 'package:fueltrack_clients/models/order.dart';
import '../../models/user.dart';
import 'order_create_view.dart';
import '../auth/login_view.dart';

class OrdersView extends StatefulWidget {
  @override
  _OrdersViewState createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  String _getFuelTypeName(int? type) {
    switch (type) {
      case 1:
        return 'Diesel';
      case 2:
        return 'Gasohol';
      case 3:
        return 'GNV';
      case 4:
        return 'GLP';
      default:
        return 'Desconocido';
    }
  }

  String _getStatusName(int? status) {
    switch (status) {
      case 1:
        return 'Solicitado';
      case 2:
        return 'Denegado';
      case 3:
        return 'Aprobado';
      case 4:
        return 'Despachado';
      case 5:
        return 'Cerrado';
      default:
        return 'Desconocido';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 1:
        return Colors.blueGrey;
      case 2:
        return Colors.redAccent;
      case 3:
        return Colors.green;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.grey;
      default:
        return Colors.black26;
    }
  }

  Future<void> _logoutAndNavigateToLogin() async {
    try {
      await DbHelper().openDb();
      await DbHelper().deleteMethod();
      await DbHelper().deleteUser();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginView()),
          (route) => false,
    );
  }

  Future<void> _loadOrders() async {
    try {
      await DbHelper().openDb();
      User? user = await DbHelper().getUser();
      String? token = user?.accessToken;
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Token no disponible';
          _loading = false;
        });
        return;
      }

      List<Order> list;
      try {
        list = await HttpHelper().getAllOrders(token);
      } catch (e) {
        if (e.toString().contains('401')) {
          if (user?.refreshToken != null) {
            try {
              User newUser = await HttpHelper().postAuthRefreshToken(user!);
              await DbHelper().updateUser(newUser);
              token = newUser.accessToken;
              list = await HttpHelper().getAllOrders(token!);
            } catch (_) {
              await _logoutAndNavigateToLogin();
              return;
            }
          } else {
            await _logoutAndNavigateToLogin();
            return;
          }
        } else {
          throw e;
        }
      }

      list.sort((a, b) {
        final aDate = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
      setState(() {
        _orders = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Espacio vacío superior sin divisor visual
  Widget _headerSpacer() {
    return const Padding(
      padding: EdgeInsets.only(top: 12.0),
      child: SizedBox(height: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2E7D32);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildBody(primaryGreen)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18, // aumentado
          fontWeight: FontWeight.w900, // más fuerte
          letterSpacing: 0.3,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildBody(Color primaryGreen) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_orders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _sectionTitle('Listado de órdenes'),
          const Expanded(child: Center(child: Text('No hay órdenes'))),
        ],
      );
    }

    final total = _orders.length;
    final approved = _orders.where((o) => o.status == 3).length;
    final dispatched = _orders.where((o) => o.status == 4).length;
    final closed = _orders.where((o) => o.status == 5).length;

    final Color borderColor = Colors.grey[300]!;
    final Color shadowColor = Colors.black.withOpacity(0.08);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerSpacer(),
          _sectionTitle('Resumen de órdenes'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _infoChip('Total', total, Colors.blueGrey),
              _infoChip('Aprob.', approved, Colors.green),
              _infoChip('Desp.', dispatched, Colors.orange),
              _infoChip('Cerr.', closed, Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderCreateView()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'Generar orden de abastecimiento',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BBEC0), // color sólido solicitado
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sectionTitle('Listado de órdenes'),
          Expanded(
            child: ListView.separated(
              itemCount: _orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final o = _orders[index];
                DateTime? createdAt;
                String fecha = '', hora = '';
                if (o.createdAt != null) {
                  createdAt = DateTime.tryParse(o.createdAt!);
                  if (createdAt != null) {
                    fecha = "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}";
                    hora = "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";
                  }
                }

                return Card(
                  elevation: 2, // más sutil
                  shadowColor: shadowColor,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: borderColor, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fila: número de orden + estado a la derecha
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                o.orderNumber ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16.5,
                                  color: Colors.black87,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _statusTag(o.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Fila compacta: litros y tipo a la izquierda, precio a la derecha
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${o.quantity?.toStringAsFixed(2) ?? '--'} litros · ${_getFuelTypeName(o.fuelType)}",
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              "S/ ${o.totalAmount != null ? o.totalAmount!.toStringAsFixed(2) : '0.00'}",
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Dirección en una línea más compacta
                        if ((o.deliveryAddress ?? '').isNotEmpty)
                          Text(
                            o.deliveryAddress!,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 6),
                        // Fecha y hora sutil
                        Text(
                          "$fecha · $hora",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Actualiza solo el método `_statusTag`
  Widget _statusTag(int? status) {
    final Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _getStatusName(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // Resumen compacto tipo chip
  Widget _infoChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}