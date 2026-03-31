import { Router } from 'express';
import type { Response } from 'express';
import { supabase } from '../config/supabase.js';
import { asyncHandler, createError } from '../middleware/errorHandler.js';
import { requireAuth } from '../middleware/auth.js';
import type { AuthRequest } from '../middleware/auth.js';

// Radius in meters to consider a visit as verified GPS-proximity
const VERIFICACION_RADIO_M = 100;

function haversineMetros(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

const router = Router();
router.use(requireAuth);

// GET /visitas — historial del usuario
router.get(
  '/',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { data, error } = await supabase
      .from('visitas')
      .select('*, pois(nombre, lat, lng), negocios(nombre, lat, lng)')
      .eq('usuario_id', req.userId!)
      .order('created_at', { ascending: false });

    if (error) throw createError(error.message, 500, 'DB_ERROR');
    res.json(data);
  })
);

// POST /visitas — registrar visita con validación GPS
router.post(
  '/',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { poi_id, negocio_id, lat, lng } = req.body as {
      poi_id?: string;
      negocio_id?: string;
      lat?: number;
      lng?: number;
    };

    if (!poi_id && !negocio_id) {
      throw createError('Debe especificar poi_id o negocio_id', 400, 'VALIDATION_ERROR');
    }

    let verificada = false;

    // GPS proximity check
    if (lat !== undefined && lng !== undefined) {
      if (poi_id) {
        const { data: poi } = await supabase
          .from('pois')
          .select('lat, lng')
          .eq('id', poi_id)
          .single();

        if (poi) {
          verificada = haversineMetros(lat, lng, poi.lat, poi.lng) <= VERIFICACION_RADIO_M;
        }
      } else if (negocio_id) {
        const { data: negocio } = await supabase
          .from('negocios')
          .select('lat, lng')
          .eq('id', negocio_id)
          .single();

        if (negocio) {
          verificada = haversineMetros(lat, lng, negocio.lat, negocio.lng) <= VERIFICACION_RADIO_M;
        }
      }
    }

    const { data: visita, error } = await supabase
      .from('visitas')
      .insert({ poi_id, negocio_id, lat, lng, verificada, usuario_id: req.userId! })
      .select()
      .single();

    if (error) throw createError(error.message, 400, 'INSERT_ERROR');

    // If verified, increment user's visit count
    if (verificada) {
      // Increment user's visit count via RPC (define this function in Supabase SQL editor)
      await supabase.rpc('increment_visitas', { p_usuario_id: req.userId! });

      // Also update business stats if applicable
      if (negocio_id) {
        const today = new Date().toISOString().slice(0, 10);
        await supabase.from('negocio_stats').upsert(
          {
            negocio_id,
            fecha: today,
            vistas: 0,
            visitas_verificadas: 1,
            presencia_rutas: 0,
          },
          { onConflict: 'negocio_id,fecha' }
        );
      }
    }

    res.status(201).json({ ...(visita as object), verificada });
  })
);

export default router;
