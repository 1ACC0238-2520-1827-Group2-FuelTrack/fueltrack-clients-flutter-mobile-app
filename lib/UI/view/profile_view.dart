// dart
// `lib/UI/view/profile_view.dart`
import 'package:flutter/material.dart';
import '../../utils/db_helper.dart';
import '../../utils/http_helper.dart';
import '../../models/user.dart';
import '../../models/profile.dart';
import '../auth/login_view.dart';

class ProfileView extends StatefulWidget {
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  Profile? _profile;
  String? _error;
  bool _loading = true;
  bool _editing = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  Color get primaryGreen => const Color(0xFF2E7D32);

  // Colores para los botones
  final Color dangerRed = const Color(0xFFD32F2F);
  final Color actionBlue = const Color(0xFF1565C0);
  final Color successGreen = const Color(0xFF2E7D32);
  final Color warnYellow = const Color(0xFFFFC107);

  // Estilos de botones
  ButtonStyle get _redButton => ElevatedButton.styleFrom(
    backgroundColor: dangerRed,
    foregroundColor: Colors.white,
    elevation: 3,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
  );

  ButtonStyle get _blueButton => ElevatedButton.styleFrom(
    backgroundColor: actionBlue,
    foregroundColor: Colors.white,
    elevation: 3,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
  );

  ButtonStyle get _greenButton => ElevatedButton.styleFrom(
    backgroundColor: successGreen,
    foregroundColor: Colors.white,
    elevation: 3,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
  );

  ButtonStyle get _yellowButton => ElevatedButton.styleFrom(
    backgroundColor: warnYellow,
    foregroundColor: Colors.black,
    elevation: 3,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.3),
  );

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await DbHelper().openDb();
      User? user = await DbHelper().getUser();
      String? token = user?.accessToken;
      if (token == null || token.isEmpty) throw Exception('Token no disponible');

      Profile profile;
      try {
        profile = await HttpHelper().getUserProfile(token);
      } catch (e) {
        if (e.toString().contains('401')) {
          if (user?.refreshToken != null) {
            try {
              User newUser = await HttpHelper().postAuthRefreshToken(user!);
              await DbHelper().updateUser(newUser);
              token = newUser.accessToken;
              profile = await HttpHelper().getUserProfile(token!);
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

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _firstNameController.text = profile.firstName ?? '';
        _lastNameController.text = profile.lastName ?? '';
        _phoneController.text = profile.phone ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow('Nombre', _profile?.firstName ?? ''),
        _infoRow('Apellido', _profile?.lastName ?? ''),
        _infoRow('Teléfono', _profile?.phone ?? ''),
      ],
    );
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

  Widget _buildEditFields() {
    return Column(
      children: [
        TextFormField(
          controller: _firstNameController,
          decoration: _inputDecoration('Nombre', suffix: const Icon(Icons.person)),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _lastNameController,
          decoration: _inputDecoration('Apellido', suffix: const Icon(Icons.person_outline)),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: _inputDecoration('Teléfono', suffix: const Icon(Icons.phone)),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

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
              'Perfil de usuario',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                height: 1.25,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Gestiona tu información personal',
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
                'assets/images/logo_white.png',
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
          : _error != null
          ? Center(child: Text(_error!))
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
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    Center(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _profile?.email ?? '-',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cliente',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionTitle(_editing ? 'Editar datos' : 'Información'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: _editing ? _buildEditFields() : _buildInfo(),
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _editing
                          ? [
                        ElevatedButton(
                          style: _yellowButton,
                          onPressed: () {
                            setState(() {
                              _editing = false;
                              _firstNameController.text = _profile?.firstName ?? '';
                              _lastNameController.text = _profile?.lastName ?? '';
                              _phoneController.text = _profile?.phone ?? '';
                            });
                          },
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: _greenButton,
                          onPressed: () async {
                            setState(() => _loading = true);
                            try {
                              await DbHelper().openDb();
                              User? user = await DbHelper().getUser();
                              String? token = user?.accessToken;
                              if (token == null || token.isEmpty) {
                                throw Exception('Token no disponible');
                              }

                              final updatedProfile = Profile(
                                id: _profile?.id,
                                firstName: _firstNameController.text,
                                lastName: _lastNameController.text,
                                email: _profile?.email,
                                phone: _phoneController.text,
                              );

                              Profile result;
                              try {
                                result = await HttpHelper()
                                    .updateUserProfile(token, updatedProfile);
                              } catch (e) {
                                if (e.toString().contains('401')) {
                                  if (user?.refreshToken != null) {
                                    try {
                                      User newUser = await HttpHelper()
                                          .postAuthRefreshToken(user!);
                                      await DbHelper().updateUser(newUser);
                                      final newToken = newUser.accessToken!;
                                      result = await HttpHelper().updateUserProfile(
                                          newToken, updatedProfile);
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

                              if (!mounted) return;
                              setState(() {
                                _profile = result;
                                _editing = false;
                                _firstNameController.text = result.firstName ?? '';
                                _lastNameController.text = result.lastName ?? '';
                                _phoneController.text = result.phone ?? '';
                                _loading = false;
                              });
                            } catch (e) {
                              if (!mounted) return;
                              setState(() {
                                _error = e.toString();
                                _loading = false;
                              });
                            }
                          },
                          child: const Text('Aceptar'),
                        ),
                      ]
                          : [
                        ElevatedButton(
                          style: _redButton,
                          onPressed: () async {
                            setState(() => _loading = true);
                            await DbHelper().openDb();
                            await DbHelper().deleteMethod();
                            await DbHelper().deleteUser();
                            setState(() => _loading = false);
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (context) => LoginView()),
                                  (route) => false,
                            );
                          },
                          child: const Text('Cerrar sesión'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: _blueButton,
                          onPressed: () {
                            setState(() {
                              _editing = true;
                              _firstNameController.text =
                                  _profile?.firstName ?? '';
                              _lastNameController.text =
                                  _profile?.lastName ?? '';
                              _phoneController.text =
                                  _profile?.phone ?? '';
                            });
                          },
                          child: const Text('Editar perfil'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}