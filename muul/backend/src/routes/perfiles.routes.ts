import { Router } from 'express';
import type { Response } from 'express';
import { supabase } from '../config/supabase.js';
import { asyncHandler, createError } from '../middleware/errorHandler.js';
import { requireAuth } from '../middleware/auth.js';
import type { AuthRequest } from '../middleware/auth.js';

const router = Router();

// All perfil routes require auth
router.use(requireAuth);

// GET /perfiles/me
router.get(
  '/me',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { data, error } = await supabase
      .from('perfiles')
      .select('*')
      .eq('usuario_id', req.userId!)
      .single();

    if (error) throw createError('Perfil no encontrado', 404, 'NOT_FOUND');
    res.json(data);
  })
);

// PATCH /perfiles/me
router.patch(
  '/me',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const allowed = ['nombre', 'avatar_url', 'idioma'] as const;
    type AllowedKey = (typeof allowed)[number];
    const updates = Object.fromEntries(
      Object.entries(req.body as Record<string, unknown>).filter(([k]) =>
        (allowed as readonly string[]).includes(k)
      )
    ) as Partial<Record<AllowedKey, unknown>>;

    if (Object.keys(updates).length === 0) {
      throw createError('No hay campos válidos para actualizar', 400, 'VALIDATION_ERROR');
    }

    const { data, error } = await supabase
      .from('perfiles')
      .update(updates)
      .eq('usuario_id', req.userId!)
      .select()
      .single();

    if (error) throw createError(error.message, 400, 'UPDATE_ERROR');
    res.json(data);
  })
);

// GET /perfiles/me/stats — pasos, calorías, visitas, insignias
router.get(
  '/me/stats',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const [{ data: perfil, error: perfilErr }, { data: insignias, error: insigniasErr }] =
      await Promise.all([
        supabase
          .from('perfiles')
          .select('pasos_totales, calorias_totales, visitas_totales')
          .eq('usuario_id', req.userId!)
          .single(),
        supabase
          .from('usuario_insignias')
          .select('*, insignias(*)')
          .eq('usuario_id', req.userId!),
      ]);

    if (perfilErr) throw createError(perfilErr.message, 404, 'NOT_FOUND');
    if (insigniasErr) throw createError(insigniasErr.message, 500, 'DB_ERROR');

    res.json({ ...perfil, insignias });
  })
);

// GET /perfiles/:id — público (para vista de perfil empresa)
router.get(
  '/:id',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { data, error } = await supabase
      .from('perfiles')
      .select('id, nombre, avatar_url, rol, visitas_totales, pasos_totales, created_at')
      .eq('id', req.params.id)
      .single();

    if (error) throw createError('Perfil no encontrado', 404, 'NOT_FOUND');
    res.json(data);
  })
);

export default router;
