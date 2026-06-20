import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notificacion_provider.dart';

class NotificacionesPanel extends StatelessWidget {
  final Function(double lat, double lon)? onNotificacionTap;

  const NotificacionesPanel({super.key, this.onNotificacionTap});

  @override
  Widget build(BuildContext context) {
    final notiProvider = context.watch<NotificacionProvider>();
    final notifications = notiProvider.notificaciones;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Centro de Alertas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          if (notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay alertas en tu ruta', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: n.leida ? Colors.grey[300] : Colors.orange.withOpacity(0.2),
                      child: Icon(
                        Icons.warning_amber_rounded, 
                        color: n.leida ? Colors.grey : Colors.orange[800], 
                        size: 20
                      ),
                    ),
                    title: Text(
                      n.mensaje, 
                      style: TextStyle(
                        fontWeight: n.leida ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14
                      )
                    ),
                    subtitle: Text(
                      '${n.tipo} • ${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () {
                      notiProvider.marcarLeida(n.id);
                      if (onNotificacionTap != null) {
                        onNotificacionTap!(n.latitud, n.longitud);
                        Navigator.pop(context);
                      }
                    },
                    trailing: !n.leida 
                      ? const Icon(Icons.circle, color: Colors.blue, size: 10) 
                      : const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
