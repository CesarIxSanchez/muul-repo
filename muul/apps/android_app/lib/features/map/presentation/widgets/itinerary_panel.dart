import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/tema_provider.dart';
import '../../data/route_service.dart';

class ItineraryPanel extends StatelessWidget {
  final ItinerarioResult itinerario;
  final VoidCallback onClose;
  final TemaColors temaColors;

  const ItineraryPanel({
    super.key,
    required this.itinerario,
    required this.onClose,
    required this.temaColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: temaColors.secondary.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.map, color: temaColors.secondary),
              const SizedBox(width: 8),
              const Text(
                'Tu itinerario',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Totales
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _duracionTexto(itinerario.duracionTotal),
                    style: TextStyle(color: temaColors.secondary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _distanciaTexto(itinerario.distanciaTotal),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onClose,
              ),
            ],
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: itinerario.etapas.length,
              itemBuilder: (_, i) {
                final etapa = itinerario.etapas[i];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: temaColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(etapa.hasta,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Desde: ${etapa.desde}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(etapa.duracionTexto,
                            style: TextStyle(color: temaColors.secondary, fontSize: 12),
                          ),
                          Text(
                            _distanciaTexto(etapa.distanciaMetros),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _duracionTexto(double segundos) {
    final m = (segundos / 60).round();
    return m < 60 ? '$m min' : '${m ~/ 60}h ${m % 60}min';
  }

  String _distanciaTexto(double metros) {
    if (metros < 1000) return '${metros.round()} m';
    return '${(metros / 1000).toStringAsFixed(1)} km';
  }
}