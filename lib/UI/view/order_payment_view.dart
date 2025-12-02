// dart
// File: 'lib/UI/view/order_payment_view.dart'
import 'package:flutter/material.dart';
import '../../utils/db_helper.dart';
import '../../utils/http_helper.dart';
import '../../models/order.dart';
import '../../models/method.dart';
import '../../models/user.dart';
import '../../models/payment.dart';
import '../auth/login_view.dart';

class OrderPaymentView extends StatefulWidget {
  @override
  State<OrderPaymentView> createState() => _OrderPaymentViewState();
}

class _OrderPaymentViewState extends State<OrderPaymentView> {
  final TextEditingController _orderNumberController = TextEditingController();
  Order? _order;
  String? _orderError;
  Method? _defaultMethod;
  bool _loading = false;
  List<Payment> _payments = [];
  bool _paymentsLoading = true;

  // Paleta y estilos unificados (basado en OrderCreateView)
  Color get primaryGreen => const Color(0xFF2E7D32);
  Color get primaryBlue => const Color(0xFF1565C0);
  Color get dangerRed => const Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
    _loadDefaultMethod();
    _loadPayments();
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    super.dispose();
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

  Future<void> _loadDefaultMethod() async {
    await DbHelper().openDb();
    final method = await DbHelper().getMethod();
    setState(() {
      _defaultMethod = method;
    });
  }

  // Cargar y ordenar pagos por fecha descendente
  Future<void> _loadPayments() async {
    await DbHelper().openDb();
    User? user = await DbHelper().getUser();
    String? token = user?.accessToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _payments = [];
        _paymentsLoading = false;
      });
      return;
    }
    try {
      final payments = await HttpHelper().getAllPayments(token);
      payments.sort((a, b) {
        final aDate = DateTime.tryParse(a.processedAt ?? '') ?? DateTime(1970);
        final bDate = DateTime.tryParse(b.processedAt ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
      setState(() {
        _payments = payments;
        _paymentsLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('401')) {
        if (user?.refreshToken != null) {
          try {
            final newUser = await HttpHelper().postAuthRefreshToken(user!);
            await DbHelper().updateUser(newUser);
            final payments =
            await HttpHelper().getAllPayments(newUser.accessToken!);
            payments.sort((a, b) {
              final aDate =
                  DateTime.tryParse(a.processedAt ?? '') ?? DateTime(1970);
              final bDate =
                  DateTime.tryParse(b.processedAt ?? '') ?? DateTime(1970);
              return bDate.compareTo(aDate);
            });
            setState(() {
              _payments = payments;
              _paymentsLoading = false;
            });
            return;
          } catch (_) {
            await _logoutAndNavigateToLogin();
            return;
          }
        } else {
          await _logoutAndNavigateToLogin();
          return;
        }
      }
      setState(() {
        _payments = [];
        _paymentsLoading = false;
      });
    }
  }

  // Helpers de UI/formatos (consistentes con otras vistas)
  InputDecoration _inputDecoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryGreen, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      suffixIcon: suffix,
    );
  }

  ButtonStyle get _outlinedStrong => OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    side: BorderSide(color: dangerRed, width: 2),
    foregroundColor: dangerRed,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.3,
    ),
  ).copyWith(
    overlayColor:
    WidgetStateProperty.resolveWith((_) => dangerRed.withOpacity(0.10)),
    shadowColor: WidgetStateProperty.all(dangerRed.withOpacity(0.35)),
    elevation: WidgetStateProperty.all(2),
  );

  ButtonStyle get _elevatedStrong => ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: Colors.white,
    elevation: 10,
    shadowColor: primaryBlue.withOpacity(0.55),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.3,
    ),
  );

  // Mostrar solo últimos dígitos con un * al inicio
  String _maskedCardNumber(String? last4) {
    final l4 = (last4 ?? '').padLeft(4, '•');
    return '*$l4';
  }

  String _formatCurrency(num? v) {
    if (v == null) return 'S/ 0.00';
    return 'S/ ${v.toStringAsFixed(2)}';
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '--/--/---- · --:--';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--/--/---- · --:--';
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy · $hh:$mi';
  }

  String _formatExpiryDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '--/--';
    try {
      final d = DateTime.tryParse(raw);
      if (d != null) {
        return '${d.month.toString().padLeft(2, '0')}/${d.year}';
      }
      if (RegExp(r'^\d{2}/\d{4}$').hasMatch(raw)) return raw;
    } catch (_) {}
    return '--/--';
  }

  Color _typeColor(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('visa')) return const Color(0xFF1A73E8);
    if (t.contains('master')) return const Color(0xFFFF6F00);
    if (t.contains('amex')) return const Color(0xFF2E7D32);
    return Colors.blueGrey;
  }

  LinearGradient _defaultGradient() {
    return const LinearGradient(
      colors: [
        Color(0xFF5F48E3),
        Color(0xFF826CF6),
        Color(0xFFB3A8FA),
      ],
      stops: [0.0, 0.55, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _statusChip({required String label, required Color color, bool filled = false}) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: filled ? Colors.white : color,
          fontWeight: FontWeight.w800,
        ),
      ),
      backgroundColor: filled ? color : color.withOpacity(0.10),
      side: BorderSide(color: color, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // Búsqueda de orden con validaciones y manejo de 401
  Future<void> _searchOrder() async {
    setState(() {
      _loading = true;
      _order = null;
      _orderError = null;
    });

    await DbHelper().openDb();
    User? user = await DbHelper().getUser();
    String? token = user?.accessToken;

    if (token == null || token.isEmpty) {
      setState(() {
        _orderError = 'Token no disponible';
        _loading = false;
      });
      return;
    }

    final orderNumber = _orderNumberController.text.trim();
    if (orderNumber.isEmpty) {
      setState(() {
        _orderError = 'Ingresa un código de pedido';
        _loading = false;
      });
      return;
    }

    try {
      // 1) Verificar si ya fue pagada
      try {
        final payments = await HttpHelper().getAllPayments(token);
        final paid =
        payments.where((p) => p.orderNumber == orderNumber).toList();
        if (paid.isNotEmpty) {
          setState(() {
            _orderError = 'Esta orden ya fue cancelada';
            _loading = false;
          });
          return;
        }
      } catch (e) {
        if (e.toString().contains('401')) {
          if (user?.refreshToken != null) {
            try {
              final newUser = await HttpHelper().postAuthRefreshToken(user!);
              await DbHelper().updateUser(newUser);
              token = newUser.accessToken;
              final payments = await HttpHelper().getAllPayments(token!);
              final paid =
              payments.where((p) => p.orderNumber == orderNumber).toList();
              if (paid.isNotEmpty) {
                setState(() {
                  _orderError = 'Esta orden ya fue cancelada';
                  _loading = false;
                });
                return;
              }
            } catch (_) {
              await _logoutAndNavigateToLogin();
              return;
            }
          } else {
            await _logoutAndNavigateToLogin();
            return;
          }
        } else {
          rethrow;
        }
      }

      // 2) Buscar la orden
      try {
        final orders = await HttpHelper().getAllOrders(token);
        final found =
        orders.where((o) => o.orderNumber == orderNumber).toList();
        if (found.isEmpty) {
          setState(() {
            _orderError = 'Ningún pedido tiene este código';
            _loading = false;
          });
        } else {
          setState(() {
            _order = found.first;
            _orderError = null;
            _loading = false;
          });
        }
      } catch (e) {
        if (e.toString().contains('401')) {
          if (user?.refreshToken != null) {
            try {
              final newUser = await HttpHelper().postAuthRefreshToken(user!);
              await DbHelper().updateUser(newUser);
              token = newUser.accessToken;
              final orders = await HttpHelper().getAllOrders(token!);
              final found =
              orders.where((o) => o.orderNumber == orderNumber).toList();
              if (found.isEmpty) {
                setState(() {
                  _orderError = 'Ningún pedido tiene este código';
                  _loading = false;
                });
              } else {
                setState(() {
                  _order = found.first;
                  _orderError = null;
                  _loading = false;
                });
              }
            } catch (_) {
              await _logoutAndNavigateToLogin();
              return;
            }
          } else {
            await _logoutAndNavigateToLogin();
            return;
          }
        } else {
          setState(() {
            _orderError = 'Error al buscar pedido';
            _loading = false;
          });
        }
      }
    } catch (_) {
      setState(() {
        _orderError = 'Error al buscar pedido';
        _loading = false;
      });
    }
  }

  // UI: Sección de búsqueda
  Widget _buildOrderInput() {
    final borderColor = Colors.grey[300]!;
    final shadowColor = Colors.black.withOpacity(0.08);

    return Card(
      elevation: 3,
      shadowColor: shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa el código de tu pedido',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _orderNumberController,
              decoration:
              _inputDecoration('Código de pedido', suffix: const Icon(Icons.tag)),
            ),
            const SizedBox(height: 12),
            if (_order == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _searchOrder,
                  style: _elevatedStrong,
                  icon: _loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.search),
                  label: Text(_loading ? 'Buscando...' : 'Buscar'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Borrar'),
                      style: _outlinedStrong,
                      onPressed: () {
                        setState(() {
                          _orderNumberController.clear();
                          _order = null;
                          _orderError = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text('Pagar ahora'),
                      style: _elevatedStrong,
                      onPressed: () async {
                        if (_defaultMethod == null || _order == null) return;
                        await DbHelper().openDb();
                        User? user = await DbHelper().getUser();
                        String? token = user?.accessToken;
                        if (token == null || token.isEmpty) return;
                        try {
                          await HttpHelper().postPayment(
                            token,
                            _order!.id!,
                            _defaultMethod!.id!,
                          );
                          await _loadPayments();
                          setState(() {
                            _orderNumberController.clear();
                            _order = null;
                            _orderError = null;
                          });
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Pago realizado correctamente')),
                          );
                        } catch (e) {
                          if (e.toString().contains('401')) {
                            if (user?.refreshToken != null) {
                              try {
                                final newUser =
                                await HttpHelper().postAuthRefreshToken(
                                  user!,
                                );
                                await DbHelper().updateUser(newUser);
                                await HttpHelper().postPayment(
                                  newUser.accessToken!,
                                  _order!.id!,
                                  _defaultMethod!.id!,
                                );
                                await _loadPayments();
                                setState(() {
                                  _orderNumberController.clear();
                                  _order = null;
                                  _orderError = null;
                                });
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                      Text('Pago realizado correctamente')),
                                );
                              } catch (_) {
                                await _logoutAndNavigateToLogin();
                                return;
                              }
                            } else {
                              await _logoutAndNavigateToLogin();
                              return;
                            }
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al pagar: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            if (_orderError != null) ...[
              const SizedBox(height: 8),
              Text(_orderError!,
                  style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
    );
  }

  // UI: Tarjeta de la orden
  Widget _buildOrderCard() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orderError != null) {
      return Card(
        color: Colors.red[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sentiment_dissatisfied,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _orderError!,
                style: const TextStyle(fontSize: 16, color: Colors.redAccent),
              ),
            ],
          ),
        ),
      );
    }
    if (_order == null) {
      return Card(
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.receipt_long, color: Colors.grey, size: 48),
              SizedBox(height: 12),
              Text(
                'Ingresa el código de tu pedido para ver detalles',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    String getFuelType(int? type) {
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
          return '-';
      }
    }

    final borderColor = Colors.grey[300]!;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.local_gas_station, color: Colors.indigo[700], size: 32),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    getFuelType(_order!.fuelType),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Text(
                  _formatCurrency(_order!.totalAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_order!.quantity?.toStringAsFixed(2) ?? '--'} litros',
              style: const TextStyle(
                fontSize: 14.5,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            if ((_order!.deliveryAddress ?? '').isNotEmpty)
              Text(
                _order!.deliveryAddress!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              _formatDateTime(_order!.createdAt),
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
  }


  // dart
  Widget _buildMethodCard() {
    Widget _emptyCard() {
      return Card(
        color: Colors.grey[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Center(
            child: Text(
              'No tienes tarjeta predeterminada',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_defaultMethod == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.credit_card_off, color: Colors.grey, size: 48),
          const SizedBox(height: 12),
          _emptyCard(),
        ],
      );
    }

    final m = _defaultMethod!;
    final Color typeColor = _typeColor(m.cardType);
    final Color baseText = Colors.white;
    final Color subtleText = Colors.white70;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.transparent),
                ),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: _defaultGradient(),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: SingleChildScrollView(
                    physics: constraints.maxHeight >= 240
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ícono arriba y luego el nombre (más compacto)
                        Icon(Icons.credit_card, color: Colors.white, size: 22),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Text(
                            m.cardHolderName ?? 'Sin nombre',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: baseText,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _statusChip(
                              label: m.cardType ?? 'Tarjeta',
                              color: typeColor,
                              filled: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _maskedCardNumber(m.lastFourDigits),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: baseText,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month, color: subtleText, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Vence: ${_formatExpiryDate(m.expiryDate)}',
                              style: TextStyle(
                                color: subtleText,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  // Lista de pagos con formato de moneda y fecha
  Widget _buildPaymentsList() {
    if (_paymentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_payments.isEmpty) {
      return const Center(child: Text('No tienes historial de pagos.'));
    }
    return ListView.builder(
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final p = _payments[index];
        final date = _formatDateTime(p.processedAt ?? p.createdAt);
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Color(0xFF1A73E8)),
            title: Text(
              'Pedido: ${p.orderNumber ?? '-'}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            subtitle: Text(
              '${_formatCurrency(p.amount)} · $date',
              style: TextStyle(color: Colors.grey[700]),
            ),
            // Mostrar *1234 a la derecha
            trailing: Text(
              _maskedCardNumber(p.lastFourDigits),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 2,
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        toolbarHeight: 80,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Pago de pedido',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                height: 1.25,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Busca tu orden y paga con tu tarjeta',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              children: [
                _buildOrderInput(),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: screenHeight * 0.28,
                        child: _buildOrderCard(),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SizedBox(
                        height: screenHeight * 0.28,
                        child: _buildMethodCard(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Historial de pagos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: screenHeight * 0.33,
                  child: _buildPaymentsList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}