// dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/http_helper.dart';
import '../../utils/db_helper.dart';
import '../../models/user.dart';
import '../../models/method.dart';
import '../auth/login_view.dart';

class CardAddView extends StatefulWidget {
  @override
  State<CardAddView> createState() => _CardAddViewState();
}

class _CardAddViewState extends State<CardAddView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _holderController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  bool _loading = false;
  bool _isDefault = false;
  String? _error;

  // Colores coherentes con OrderCreateView
  Color get primaryGreen => const Color(0xFF2E7D32);
  Color get dangerRed => const Color(0xFFD32F2F);
  Color get primaryBlue => const Color(0xFF1565C0);

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _cvvController.dispose();
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

  // Estilo unificado de inputs
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

  // Botón Cancelar
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

  // Botón Agregar
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

  // Formatters y validaciones
  bool _luhnCheck(String digits) {
    int sum = 0;
    bool alt = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alt) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alt = !alt;
    }
    return sum % 10 == 0;
  }

  String? _validateNotEmpty(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo requerido';
    return null;
  }

  String? _validateCardNumber(String? v) {
    final s = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (s.isEmpty) return 'Número requerido';
    if (s.length < 13 || s.length > 19) return 'Número inválido';
    if (!_luhnCheck(s)) return 'Número inválido';
    return null;
  }

  String? _validateMonth(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Mes requerido';
    final m = int.tryParse(s);
    if (m == null || m < 1 || m > 12) return 'Mes inválido';
    final y = int.tryParse(_yearController.text.trim());
    if (y != null) {
      final now = DateTime.now();
      if (y == now.year && m < now.month) return 'Tarjeta vencida';
    }
    return null;
  }

  String? _validateYear(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Año requerido';
    final y = int.tryParse(s);
    final nowY = DateTime.now().year;
    if (y == null || y < nowY) return 'Año inválido';
    if (y > nowY + 30) return 'Año inválido';
    final m = int.tryParse(_monthController.text.trim());
    if (m != null) {
      final now = DateTime.now();
      if (y == now.year && m < now.month) return 'Tarjeta vencida';
    }
    return null;
  }

  // 1) Validador de CVV: aceptar letras o números, 3–4 chars
  String? _validateCvv(String? v) {
    final s = (v?.trim() ?? '');
    if (s.isEmpty) return 'CVV requerido';
    if (!RegExp(r'^[A-Za-z0-9]{3,4}$').hasMatch(s)) {
      return 'CVV inválido (3-4 letras o números)';
    }
    return null;
  }

  Future<Method> _postMethod(
      String token,
      String holder,
      String number,
      int month,
      int year,
      String cvv,
      bool setDefault,
      ) async {
    return await HttpHelper().postPaymentMethod(
      token,
      holder,
      number,
      month,
      year,
      cvv,
      setDefault,
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _error = 'Revisa los campos del formulario.');
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });

    final holder = _holderController.text.trim();
    final number = _numberController.text.replaceAll(RegExp(r'\D'), '');
    final month = int.parse(_monthController.text.trim());
    final year = int.parse(_yearController.text.trim());
    // 2) Normaliza CVV a mayúsculas (sigue siendo String)
    final cvv = _cvvController.text.trim().toUpperCase();

    try {
      await DbHelper().openDb();
      User? user = await DbHelper().getUser();
      String? token = user?.accessToken;
      if (token == null || token.isEmpty) {
        throw Exception('Token no disponible');
      }

      Future<Method> doPost(String tk) =>
          _postMethod(tk, holder, number, month, year, cvv, _isDefault);

      Method created;
      try {
        created = await doPost(token);
      } catch (e) {
        if (e.toString().contains('401')) {
          if (user?.refreshToken != null) {
            try {
              final newUser = await HttpHelper().postAuthRefreshToken(user!);
              await DbHelper().updateUser(newUser);
              token = newUser.accessToken;
              created = await doPost(token!);
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

      if (_isDefault) {
        try {
          await DbHelper().updateMethod(created);
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarjeta agregada correctamente')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar tarjeta: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Formatea número de tarjeta en grupos de 4
  static final _cardNumberFormatter = _CardNumberInputFormatter();

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
              'Agregar tarjeta',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                height: 1.25,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Registra un método de pago',
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      TextFormField(
                        controller: _holderController,
                        decoration: _inputDecoration(
                          'Nombre del titular',
                          suffix: const Icon(Icons.person),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: _validateNotEmpty,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _numberController,
                        decoration: _inputDecoration(
                          'Número de tarjeta',
                          suffix: const Icon(Icons.credit_card),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _cardNumberFormatter,
                        ],
                        validator: _validateCardNumber,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _monthController,
                              decoration: _inputDecoration(
                                'Mes (MM)',
                                suffix: const Icon(Icons.calendar_today),
                              ),
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: false, signed: false),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(2),
                              ],
                              validator: _validateMonth,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _yearController,
                              decoration: _inputDecoration(
                                'Año (YYYY)',
                                suffix: const Icon(Icons.event),
                              ),
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: false, signed: false),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              validator: _validateYear,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 3) Campo de texto de CVV: permitir letras y números, máx. 4
                      TextFormField(
                        controller: _cvvController,
                        decoration: _inputDecoration(
                          'CVV (3-4 letras o números)',
                          suffix: const Icon(Icons.lock),
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization:
                        TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9]')),
                          LengthLimitingTextInputFormatter(4),
                        ],
                        obscureText: true,
                        validator: _validateCvv,
                      ),
                      const SizedBox(height: 8),

                      CheckboxListTile(
                        value: _isDefault,
                        onChanged: (v) =>
                            setState(() => _isDefault = v ?? false),
                        title: const Text(
                          'Establecer como predeterminado',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 8),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.redAccent),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pop(false),
                              style: _outlinedStrong,
                              icon: const Icon(Icons.close),
                              label: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _submit,
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
                              label: _loading
                                  ? const Text('Procesando...')
                                  : const Text('Agregar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security,
                              color: Colors.grey[600], size: 16),
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

// InputFormatter que agrupa en bloques de 4 dígitos (máx. 19 dígitos)
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.substring(0, math.min(digits.length, 19));

    final buf = StringBuffer();
    for (int i = 0; i < limited.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(limited[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}