import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_bloc.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_event.dart';
import 'package:vive_good_app/presentation/blocs/notification/notification_state.dart';
import 'package:vive_good_app/presentation/pages/notifications/notification_settings_page.dart';
import 'package:vive_good_app/core/di/injection_container.dart' as di;

class NotificationIconButton extends StatefulWidget {
  final String userId;

  const NotificationIconButton({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton>
    with TickerProviderStateMixin {
  late NotificationBloc _notificationBloc;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _notificationBloc = di.sl<NotificationBloc>();
    _notificationBloc.add(LoadPendingNotifications());
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notificationBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _notificationBloc,
      child: BlocListener<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state.notificationSchedules.isNotEmpty) {
            _animationController.forward().then((_) {
              _animationController.reverse();
            });
          }
        },
        child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            return AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          state.hasPermissions
                              ? Icons.notifications
                              : Icons.notifications_off,
                          color: state.hasPermissions
                              ? (state.notificationSchedules.isNotEmpty
                                  ? Colors.orange
                                  : Colors.grey)
                              : Colors.red,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NotificationSettingsPage(
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                        tooltip: 'Configuración de Notificaciones',
                      ),
                      if (state.notificationSchedules.isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${state.notificationSchedules.length > 99 ? '99+' : state.notificationSchedules.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}