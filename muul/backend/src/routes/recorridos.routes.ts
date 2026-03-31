import { Router } from 'express';
import type { Response } from 'express';
import { supabase } from '../config/supabase.js';
import { asyncHandler, createError } from '../middleware/errorHandler.js';
import { requireAuth } from '../middleware/auth.js';
import type { AuthRequest } from '../middleware/auth.js';

const router = Router();

router.use(requireAuth);

// GET /recorridos — historial del usuario
router.get(
  '/',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { data, error } = await supabase
      .from('recorridos')
      .select('*, recorrido_nodos(*, pois(id, nombre, lat, lng))')
      .eq('usuario_id', req.userId!)
      .order('created_at', { ascending: false });

    if (error) throw createError(error.message, 500, 'DB_ERROR');
    res.json(data);
  })
);

// GET /recorridos/:id
router.get(
  '/:id',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { data, error } = await supabase
      .from('recorridos')
      .select('*, recorrido_nodos(*, pois(*))')
      .eq('id', req.params.id)
      .eq('usuario_id', req.userId!)
      .single();

    if (error) throw createError('Recorrido no encontrado', 404, 'NOT_FOUND');
    res.json(data);
  })
);

// POST /recorridos — crear nuevo recorrido con sus nodos
router.post(
  '/',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { nodos, ...recorridoBody } = req.body as {
      nodos?: Array<{ poi_id: string; orden: number; tiempo_estimado_min?: number }>;
      [key: string]: unknown;
    };

    const { data: recorrido, error } = await supabase
      .from('recorridos')
      .insert({ ...recorridoBody, usuario_id: req.userId!, completado: false })
      .select()
      .single();

    if (error) throw createError(error.message, 400, 'INSERT_ERROR');

    if (nodos?.length) {
      const nodoRows = nodos.map((n) => ({ ...n, recorrido_id: recorrido.id }));
      const { error: nodosErr } = await supabase.from('recorrido_nodos').insert(nodoRows);
      if (nodosErr) throw createError(nodosErr.message, 400, 'INSERT_ERROR');
    }

    res.status(201).json(recorrido);
  })
);

// PATCH /recorridos/:id — actualizar progreso (pasos, calorías, completado)
router.patch(
  '/:id',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const allowed = ['pasos', 'calorias', 'distancia_km', 'duracion_min', 'completado'] as const;
    type AllowedKey = (typeof allowed)[number];
    const updates = Object.fromEntries(
      Object.entries(req.body as Record<string, unknown>).filter(([k]) =>
        (allowed as readonly string[]).includes(k)
      )
    ) as Partial<Record<AllowedKey, unknown>>;

    const { data, error } = await supabase
      .from('recorridos')
      .update(updates)
      .eq('id', req.params.id)
      .eq('usuario_id', req.userId!)
      .select()
      .single();

    if (error) throw createError(error.message, 400, 'UPDATE_ERROR');

    // If completed, update user totals via RPC (define in Supabase SQL editor)
    if (updates.completado) {
      await supabase.rpc('increment_perfil_stats', {
        p_usuario_id: req.userId!,
        p_pasos: (data as { pasos: number | null }).pasos ?? 0,
        p_calorias: (data as { calorias: number | null }).calorias ?? 0,
      });
    }

    res.json(data);
  })
);

// DELETE /recorridos/:id
router.delete(
  '/:id',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { error } = await supabase
      .from('recorridos')
      .delete()
      .eq('id', req.params.id)
      .eq('usuario_id', req.userId!);

    if (error) throw createError(error.message, 400, 'DELETE_ERROR');
    res.status(204).send();
  })
);

export default router;
