// dart
// File: 'lib/UI/view/notifications_view.dart'
import 'package:flutter/material.dart';
import 'package:fueltrack_clients/utils/db_helper.dart';
import 'package:fueltrack_clients/utils/http_helper.dart';
import 'package:fueltrack_clients/models/notification.dart' as model_notification;

import '../../models/user.dart';
import '../auth/login_view.dart';

class NotificationsView extends StatefulWidget {
  final bool embedded; // true cuando se usa dentro de Home

  NotificationsView({this.embedded = true});

  @override
  _NotificationsViewState createState() => _NotificationsViewState();
}

enum _Filter { semana, mes, todos }

class _NotificationsViewState extends State<NotificationsView> {
  List<model_notification.Notification> _notifications = [];
  bool _loading = true;
  String? _error;

  _Filter _selectedFilter = _Filter.todos;

  // Flag para usar separador invisible con espacio
  final bool _showSeparatorSpace = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
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

  Future<void> _loadNotifications() async {
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

      List<model_notification.Notification> list;
      try {
        list = await HttpHelper().getAllNotifications(token);
      } catch (e) {
        if (e.toString().contains('401')) {
          if (user?.refreshToken != null) {
            try {
              User newUser = await HttpHelper().postAuthRefreshToken(user!);
              await DbHelper().updateUser(newUser);
              token = newUser.accessToken;
              list = await HttpHelper().getAllNotifications(token!);
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
        return bDate.compareTo(aDate); // más reciente arriba
      });

      setState(() {
        _notifications = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Filtros: semana = últimos 7 días, mes = últimos 31 días, todos = sin filtro
  List<model_notification.Notification> get _filteredNotifications {
    if (_selectedFilter == _Filter.todos) return _notifications;

    final now = DateTime.now();
    final limitDays = _selectedFilter == _Filter.semana ? 7 : 31;
    final start = now.subtract(Duration(days: limitDays));

    return _notifications.where((n) {
      final d = DateTime.tryParse(n.createdAt ?? '');
      if (d == null) return false;
      return d.isAfter(start) || d.isAtSameMomentAs(start);
    }).toList();
  }

  // Espacio vacío superior sin divisor visual
  Widget _headerSpacer() {
    return const Padding(
      padding: EdgeInsets.only(top: 12.0),
      child: SizedBox(height: 4),
    );
  }

  ButtonStyle _filterButtonStyle(bool selected, Color primaryGreen) {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      foregroundColor: selected ? primaryGreen : Colors.black87,
      backgroundColor: selected ? primaryGreen.withOpacity(0.10) : Colors.white,
      side: BorderSide(
        color: selected ? primaryGreen : Colors.grey[400]!,
        width: selected ? 2 : 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildFilters() {
    final Color primaryGreen = const Color(0xFF2E7D32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerSpacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            'Filtros de notificaciones',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedFilter = _Filter.semana),
                  style: _filterButtonStyle(_selectedFilter == _Filter.semana, primaryGreen),
                  icon: Icon(
                    Icons.calendar_view_week,
                    color: _selectedFilter == _Filter.semana ? primaryGreen : Colors.black54,
                  ),
                  label: Text('Esta semana'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedFilter = _Filter.mes),
                  style: _filterButtonStyle(_selectedFilter == _Filter.mes, primaryGreen),
                  icon: Icon(
                    Icons.calendar_month,
                    color: _selectedFilter == _Filter.mes ? primaryGreen : Colors.black54,
                  ),
                  label: Text('Este mes'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _selectedFilter = _Filter.todos),
                  style: _filterButtonStyle(_selectedFilter == _Filter.todos, primaryGreen),
                  icon: Icon(
                    Icons.all_inbox,
                    color: _selectedFilter == _Filter.todos ? primaryGreen : Colors.black54,
                  ),
                  label: Text('Todos'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    final items = _filteredNotifications;
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilters(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Text(
              'Listado de notificaciones',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Center(child: Text('No hay notificaciones'))),
        ],
      );
    }

    final Color borderColor = Colors.grey[300]!;
    final Color shadowColor = Colors.black.withOpacity(0.08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilters(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Text(
            'Listado de notificaciones',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (context, index) {
              return _showSeparatorSpace ? const SizedBox(height: 6) : const SizedBox.shrink();
            },
            itemBuilder: (context, index) {
              final n = items[index];
              DateTime? createdAt;
              String fecha = '', hora = '';
              if (n.createdAt != null) {
                createdAt = DateTime.tryParse(n.createdAt!);
                if (createdAt != null) {
                  fecha =
                  "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}";
                  hora =
                  "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}";
                }
              }
              return Card(
                elevation: 3,
                shadowColor: shadowColor,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor, width: 1.2),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    leading: _getIcon(n.type),
                    title: Text(
                      n.title ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          n.message ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Fecha: $fecha   Hora: $hora',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    enabled: false,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Icon _getIcon(int? type) {
    switch (type) {
      case 1:
        return const Icon(Icons.check_circle, color: Colors.green);
      case 2:
        return const Icon(Icons.warning, color: Colors.orange);
      case 3:
        return const Icon(Icons.info, color: Colors.blue);
      case 4:
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildBody();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: _buildBody(),
    );
  }
}