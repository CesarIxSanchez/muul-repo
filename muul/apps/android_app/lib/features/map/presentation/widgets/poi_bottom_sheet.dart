import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/poi_model.dart';
import '../providers/map_provider.dart';

class PoiBottomSheet extends ConsumerWidget {
  final PoiModel poi;
  const PoiBottomSheet({super.key, required this.poi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(mapProvider).value;
    final enItinerario = s?.poisParaItinerario.any((p) => p.id == poi.id) ?? false;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  poi.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (poi.verificado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.secondary),
                  ),
                  child: Text(
                    '✓ Muul',
                    style: TextStyle(color: AppColors.secondary, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            poi.categoria.toUpperCase(),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Text(
            poi.descripcion,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          if (poi.horario != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.textSecondary, size: 14),
                const SizedBox(width: 4),
                Text(poi.horario!, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              // Botón Ir (ruta directa)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.directions_walk, size: 18),
                  label: const Text('Ir aquí'),
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(mapProvider.notifier).calcularRutaAPoi(poi);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Botón agregar a itinerario
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: enItinerario ? AppColors.accent : AppColors.secondary,
                  side: BorderSide(
                    color: enItinerario ? AppColors.accent : AppColors.secondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(enItinerario ? Icons.remove : Icons.add, size: 18),
                label: Text(enItinerario ? 'Quitar' : 'Itinerario'),
                onPressed: () {
                  ref.read(mapProvider.notifier).togglePoiItinerario(poi);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}