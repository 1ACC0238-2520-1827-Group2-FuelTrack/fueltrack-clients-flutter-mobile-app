// dart
// lib/UI/view/payments_view.dart
import 'package:flutter/material.dart';
import '../../utils/db_helper.dart';
import '../../utils/http_helper.dart';
import '../../models/user.dart';
import '../../models/method.dart';
import 'order_payment_view.dart';
import 'card_add_view.dart';
import '../auth/login_view.dart';

class PaymentsView extends StatefulWidget {
  @override
  State<PaymentsView> createState() => _PaymentsViewState();
}

class _PaymentsViewState extends State<PaymentsView> {
  late Future<List<Method>> _methodsFuture = Future.value(<Method>[]);
  Method? _defaultMethod;

  @override
  void initState() {
    super.initState();
    _loadAll();
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

  Future<void> _loadAll() async {
    await DbHelper().openDb();
    _defaultMethod = await DbHelper().getMethod();
    setState(() {
      _methodsFuture = _loadMethods();
    });
  }

  Future<List<Method>> _loadMethods() async {
    await DbHelper().openDb();
    User? user = await DbHelper().getUser();
    String? token = user?.accessToken;
    if (token == null || token.isEmpty) throw Exception('Token no disponible');
    try {
      final all = await HttpHelper().getAllPaymentMethods(token);
      if (_defaultMethod != null) {
        return all.where((m) => m.id != _defaultMethod!.id).toList();
      }
      return all;
    } catch (e) {
      if (e.toString().contains('401')) {
        if (user?.refreshToken != null) {
          try {
            User newUser = await HttpHelper().postAuthRefreshToken(user!);
            await DbHelper().updateUser(newUser);
            token = newUser.accessToken;
            final all = await HttpHelper().getAllPaymentMethods(token!);
            if (_defaultMethod != null) {
              return all.where((m) => m.id != _defaultMethod!.id).toList();
            }
            return all;
          } catch (_) {
            await _logoutAndNavigateToLogin();
            throw Exception('Sesión inválida. Redirigiendo al login.');
          }
        } else {
          await _logoutAndNavigateToLogin();
          throw Exception('Sesión inválida. Redirigiendo al login.');
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> _deleteMethod(Method method) async {
    await DbHelper().openDb();
    User? user = await DbHelper().getUser();
    String? token = user?.accessToken;
    if (token == null || token.isEmpty) return;
    try {
      await HttpHelper().deletePaymentMethod(token, method.id!);
    } catch (e) {
      if (e.toString().contains('401')) {
        if (user?.refreshToken != null) {
          try {
            User newUser = await HttpHelper().postAuthRefreshToken(user!);
            await DbHelper().updateUser(newUser);
            token = newUser.accessToken;
            await HttpHelper().deletePaymentMethod(token!, method.id!);
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
    if (_defaultMethod != null && method.id == _defaultMethod!.id) {
      await DbHelper().deleteMethod();
      _defaultMethod = null;
    }
    await _loadAll();
  }

  Future<void> _setDefaultMethod(Method method) async {
    await DbHelper().openDb();
    await DbHelper().updateMethod(method);
    _defaultMethod = method;
    await _loadAll();
  }

  Future<void> _unsetDefaultMethod(Method method) async {
    await DbHelper().openDb();
    await DbHelper().deleteMethod();
    _defaultMethod = null;
    await _loadAll();
  }

  // Helpers de UI y formato

  String _maskedCardNumber(String? last4) {
    final l4 = (last4 ?? '').padLeft(4, '•');
    return '•••• •••• •••• $l4';
  }

  String _formatExpiry(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '--/----';
    final value = raw.trim();

    final reMMYY = RegExp(r'^\d{2}[\/\-]?\d{2}$');    // MMYY o MM/YY
    final reMMYYYY = RegExp(r'^\d{2}[\/\-]?\d{4}$');  // MMYYYY o MM/YYYY
    final reYYYYMM = RegExp(r'^\d{4}[\/\-]?\d{2}$');  // YYYYMM o YYYY/MM

    if (reMMYY.hasMatch(value)) {
      final d = value.replaceAll(RegExp(r'\D'), '');
      final mm = d.substring(0, 2);
      final yy = d.substring(2, 4);
      return '$mm/20$yy';
    }
    if (reMMYYYY.hasMatch(value)) {
      final d = value.replaceAll(RegExp(r'\D'), '');
      final mm = d.substring(0, 2);
      final yyyy = d.substring(2, 6);
      return '$mm/$yyyy';
    }
    if (reYYYYMM.hasMatch(value)) {
      final d = value.replaceAll(RegExp(r'\D'), '');
      final yyyy = d.substring(0, 4);
      final mm = d.substring(4, 6);
      return '$mm/$yyyy';
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 6) {
      final mm = digits.substring(0, 2);
      final yyyy = digits.substring(2, 6);
      return '$mm/$yyyy';
    }
    if (digits.length == 4) {
      final mm = digits.substring(0, 2);
      final yy = digits.substring(2, 4);
      return '$mm/20$yy';
    }
    return value; // fallback
  }

  Color _typeColor(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('visa')) return const Color(0xFF1A73E8);
    if (t.contains('master')) return const Color(0xFFFF6F00);
    if (t.contains('amex')) return const Color(0xFF2E7D32);
    return Colors.blueGrey;
  }

  // dart
  LinearGradient _defaultGradient() {
    return const LinearGradient(
      colors: [
        Color(0xFF5F48E3), // oscuro (derivado de #826CF6)
        Color(0xFF826CF6), // base (#826CF6)
        Color(0xFFB3A8FA), // claro
      ],
      stops: [0.0, 0.55, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }


  Widget _statusChip({required String label, required Color color, bool filled = false}) {
    return Chip(
      label: Text(label, style: TextStyle(color: filled ? Colors.white : color, fontWeight: FontWeight.w800)),
      backgroundColor: filled ? color : color.withOpacity(0.10),
      side: BorderSide(color: color, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _paymentCard(Method method, {required bool isDefault}) {
    final Color typeColor = _typeColor(method.cardType);
    final Color baseText = isDefault ? Colors.white : Colors.black87;
    final Color subtleText = isDefault ? Colors.white70 : Colors.black54;
    final Color borderColor = Colors.grey[300]!;
    final Color surface = const Color(0xFFF9FAFB);
    final Color iconColor = isDefault ? Colors.white : Colors.grey[800]!;

    return Card(
      elevation: isDefault ? 4 : 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDefault ? Colors.transparent : borderColor),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isDefault ? _defaultGradient() : null,
          color: isDefault ? null : surface,
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Columna izquierda: info de la tarjeta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado: ícono + titular
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, color: isDefault ? Colors.white : typeColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          method.cardHolderName ?? 'Sin nombre',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: baseText,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Chips: Predeterminado y tipo de tarjeta
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (isDefault)
                        _statusChip(
                          label: 'Predeterminado',
                          color: const Color(0xFFFFC107),
                          filled: true,
                        ),
                      _statusChip(
                        label: method.cardType ?? 'Tarjeta',
                        color: typeColor,
                        filled: isDefault,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Número enmascarado
                  Text(
                    _maskedCardNumber(method.lastFourDigits),
                    style: TextStyle(
                      color: baseText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Vencimiento
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: subtleText, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Vence: ${_formatExpiry(method.expiryDate)}',
                        style: TextStyle(color: subtleText, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Columna derecha: acciones (estrella y eliminar)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDefault)
                  IconButton(
                    icon: Icon(Icons.star_rounded, color: iconColor),
                    tooltip: 'Quitar como predeterminado',
                    onPressed: () => _unsetDefaultMethod(method),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.star_border_rounded, color: iconColor),
                    tooltip: 'Seleccionar como predeterminado',
                    onPressed: () => _setDefaultMethod(method),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: isDefault ? Colors.white : Colors.red,
                  ),
                  tooltip: 'Eliminar método',
                  onPressed: () => _deleteMethod(method),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultSection() {
    if (_defaultMethod == null) {
      return Column(
        children: const [
          Icon(Icons.sentiment_dissatisfied, color: Colors.grey, size: 48),
          SizedBox(height: 8),
          Text('Agrega una tarjeta predeterminada', style: TextStyle(fontSize: 16, color: Colors.grey)),
          SizedBox(height: 16),
        ],
      );
    }
    return _paymentCard(_defaultMethod!, isDefault: true);
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _actionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Botón de pago: Elevado, morado e ícono de pagos
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payments_rounded),
              label: const Text('Pagar pedido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A), // morado
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              // Deshabilitar si no hay método predeterminado (\_defaultMethod == null)
              onPressed: _defaultMethod != null
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderPaymentView()),
                );
              }
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          // Botón agregar tarjeta: Delineado, azul e ícono específico de tarjeta
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_card_rounded),
              label: const Text('Agregar tarjeta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A73E8),
                side: const BorderSide(color: Color(0xFF1A73E8), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CardAddView()),
                );
                if (result == true) {
                  await _loadAll();
                }
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _sectionTitle('Método de pago predeterminado'),
            _buildDefaultSection(),
            _actionButtons(),
            Expanded(
              child: FutureBuilder<List<Method>>(
                future: _methodsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final methods = snapshot.data ?? [];
                  if (methods.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(height: 4),
                        Text(
                          'Lista de métodos guardados',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                        ),
                        Expanded(
                          child: Center(child: Text('No tienes métodos de pago registrados.')),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    itemCount: methods.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                          child: const Text(
                            'Lista de métodos guardados',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                          ),
                        );
                      }
                      final method = methods[index - 1];
                      return _paymentCard(method, isDefault: false);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}