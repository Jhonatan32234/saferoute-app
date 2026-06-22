import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notificacion_provider.dart';
import '../../domain/entities/notificacion.dart';

class NotificacionesPanel extends StatelessWidget {
  final Function(double lat, double lon)? onNotificacionTap;

  const NotificacionesPanel({super.key, this.onNotificacionTap});

  void _mostrarDetalles(BuildContext context, Notificacion n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Fondo blanco para máxima claridad
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _getTipoColor(n.tipo)),
            const SizedBox(width: 10),
            const Text(
              'Detalle de Alerta',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n.mensaje, 
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 17, 
                color: Colors.black87
              )
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.category, 'Tipo: ${n.tipo.toUpperCase()}'),
            _infoRow(Icons.access_time, 'Hora: ${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')}'),
            if (n.notaVoz.isNotEmpty)
              _infoRow(Icons.description, 'Descripción: ${n.notaVoz}'),
            const SizedBox(height: 20),
            const Text(
              'El marcador aparecerá resaltado en el mapa para tu referencia.', 
              style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Cierra dialogo
              Navigator.pop(context); // Cierra panel
              if (onNotificacionTap != null) {
                onNotificacionTap!(n.latitud, n.longitud);
              }
            },
            icon: const Icon(Icons.location_searching),
            label: const Text('Localizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey[400]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text, 
              style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)
            )
          ),
        ],
      ),
    );
  }

  Color _getTipoColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'accidente': return Colors.red;
      case 'bloqueo': return Colors.orange;
      default: return Colors.amber[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notiProvider = context.watch<NotificacionProvider>();
    final notifications = notiProvider.notificaciones;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA), // Gris ultra claro para fondo del panel
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alertas de Seguridad', 
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
                    ),
                    Text(
                      '${notiProvider.sinLeer} alertas por revisar', 
                      style: TextStyle(color: Colors.blueGrey[600], fontSize: 13)
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (notifications.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay alertas en tu zona', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return Opacity(
                    opacity: n.leida ? 0.7 : 1.0,
                    child: Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: n.leida ? 0 : 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: n.leida ? BorderSide(color: Colors.grey[200]!) : BorderSide.none,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 4, bottom: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getTipoColor(n.tipo).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTipoColor(n.tipo) == Colors.red ? Icons.error_outline : Icons.warning_amber_rounded, 
                            color: _getTipoColor(n.tipo), 
                            size: 24
                          ),
                        ),
                        title: Text(
                          n.mensaje, 
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: n.leida ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          )
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Hora de reporte • ${n.timestamp.hour}:${n.timestamp.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ),
                        onTap: () => _mostrarDetalles(context, n),
                        trailing: n.leida 
                          ? const IconButton(
                              icon: Icon(Icons.check_circle, color: Colors.green, size: 24),
                              onPressed: null,
                            )
                          : IconButton(
                              icon: const Icon(Icons.radio_button_unchecked, color: Colors.blue),
                              tooltip: 'Marcar como leída',
                              onPressed: () => notiProvider.marcarLeida(n.id),
                            ),
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
}
