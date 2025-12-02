// dart
// File: 'lib/UI/view/order_create_view.dart'
import 'package:flutter/material.dart';
import '../../utils/db_helper.dart';
import '../../utils/http_helper.dart';
import '../../models/user.dart';
import '../navigation/home.dart';
import '../auth/login_view.dart';

class OrderCreateView extends StatefulWidget {
  @override
  _OrderCreateViewState createState() => _OrderCreateViewState();
}

class _OrderCreateViewState extends State<OrderCreateView> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  int _fuelType = 1;
  bool _loading = false;
  String? _error;

  Color get primaryGreen => const Color(0xFF2E7D32);
  Color get accentGreen => const Color(0xFF43A047);

  // Nuevos colores para los botones solicitados
  Color get dangerRed => const Color(0xFFD32F2F);
  Color get primaryBlue => const Color(0xFF1565C0);

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lonController.dispose();
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

  Future<void> _submitOrder() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _error = null;
      _loading = true;
    });

    final qtyText = _quantityController.text.trim();
    final address = _addressController.text.trim();
    final latText = _latController.text.trim();
    final lonText = _lonController.text.trim();

    final quantity = double.tryParse(qtyText.replaceAll(',', '.'));
    final lat = double.tryParse(latText.replaceAll(',', '.'));
    final lon = double.tryParse(lonText.replaceAll(',', '.'));

    if (quantity == null || quantity <= 0) {
      setState(() {
        _error = 'Cantidad inválida.';
        _loading = false;
      });
      return;
    }
    if (lat == null || lat < -90 || lat > 90) {
      setState(() {
        _error = 'Latitud inválida.';
        _loading = false;
      });
      return;
    }
    if (lon == null || lon < -180 || lon > 180) {
      setState(() {
        _error = 'Longitud inválida.';
        _loading = false;
      });
      return;
    }

    try {
      await DbHelper().openDb();
      User? user = await DbHelper().getUser();
      String? token = user?.accessToken;
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Token no disponible.';
          _loading = false;
        });
        return;
      }

      Future<void> doPost(String tk) async {
        try {
          await HttpHelper().postOrder(
            tk,
            _fuelType,
            quantity,
            address,
            lat,
            lon,
          );
        } catch (e) {
          setState(() {
            _error = 'Error al crear pedido: ${e.toString()}';
          });
          rethrow;
        }
      }

      try {
        await doPost(token);
      } catch (e) {
        if (e.toString().contains('401')) {
          if (user?.refreshToken != null) {
            try {
              User newUser = await HttpHelper().postAuthRefreshToken(user!);
              await DbHelper().updateUser(newUser);
              token = newUser.accessToken;
              await doPost(token!);
            } catch (_) {
              await _logoutAndNavigateToLogin();
              return;
            }
          } else {
            await _logoutAndNavigateToLogin();
            return;
          }
        }
      }

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
            (Route<dynamic> route) => false,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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

  Widget _fuelDropdown() {
    return DropdownButtonFormField<int>(
      value: _fuelType,
      decoration: _inputDecoration('Tipo de combustible'),
      items: const [
        DropdownMenuItem(value: 1, child: Text('1 \\- Diesel')),
        DropdownMenuItem(value: 2, child: Text('2 \\- Gasohol')),
        DropdownMenuItem(value: 3, child: Text('3 \\- GNV')),
        DropdownMenuItem(value: 4, child: Text('4 \\- GLP')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _fuelType = v);
      },
      validator: (v) => v == null ? 'Selecciona un tipo' : null,
    );
  }

  // Botón Cancelar \- tonos rojos
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
    overlayColor: WidgetStateProperty.resolveWith(
          (states) => dangerRed.withOpacity(0.10),
    ),
    shadowColor: WidgetStateProperty.all(dangerRed.withOpacity(0.35)),
    elevation: WidgetStateProperty.all(2),
  );

  // Botón Ordenar \- tonos azules
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

  @override
  Widget build(BuildContext context) {
    final shadowColor = Colors.black.withOpacity(0.08);

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
              'Registrar pedido',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                height: 1.25,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Completa los datos del despacho',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Image.asset(
                'assets/images/logo_black.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Card(
              elevation: 3,
              shadowColor: shadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[300]!, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Center(
                        child: Image.asset(
                          'assets/images/logo_black.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _fuelDropdown(),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration('Cantidad (litros)'),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          final n = double.tryParse(t.replaceAll(',', '.'));
                          if (t.isEmpty) return 'La cantidad es requerida';
                          if (n == null || n <= 0) return 'Cantidad inválida';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        decoration: _inputDecoration('Dirección de entrega'),
                        keyboardType: TextInputType.multiline,
                        minLines: 3,
                        maxLines: 6,
                        validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'La dirección es requerida'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                              decoration: _inputDecoration('Latitud'),
                              validator: (v) {
                                final t = (v ?? '').trim();
                                final n =
                                double.tryParse(t.replaceAll(',', '.'));
                                if (t.isEmpty) return 'Latitud requerida';
                                if (n == null || n < -90 || n > 90) {
                                  return 'Latitud inválida';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lonController,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                              decoration: _inputDecoration('Longitud'),
                              validator: (v) {
                                final t = (v ?? '').trim();
                                final n =
                                double.tryParse(t.replaceAll(',', '.'));
                                if (t.isEmpty) return 'Longitud requerida';
                                if (n == null || n < -180 || n > 180) {
                                  return 'Longitud inválida';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                              _loading ? null : () => Navigator.of(context).pop(),
                              style: _outlinedStrong,
                              icon: const Icon(Icons.close),
                              label: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loading ? null : _submitOrder,
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
                                  : const Icon(Icons.check_circle),
                              // Cambia el texto a "ORDENAR"
                              label: _loading
                                  ? const Text('Procesando...')
                                  : const Text('ORDENAR'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Transacción segura',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}