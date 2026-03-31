import { Router } from 'express';
import type { Request, Response } from 'express';
import { supabase } from '../config/supabase.js';
import { asyncHandler, createError } from '../middleware/errorHandler.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import type { AuthRequest } from '../middleware/auth.js';

const router = Router();

// GET /insignias — catálogo completo (público)
router.get(
  '/',
  asyncHandler(async (_req: Request, res: Response) => {
    const { data, error } = await supabase
      .from('insignias')
      .select('*')
      .order('visitas_requeridas');

    if (error) throw createError(error.message, 500, 'DB_ERROR');
    res.json(data);
  })
);

// GET /insignias/usuario/:userId — insignias desbloqueadas de un usuario
router.get(
  '/usuario/:userId',
  asyncHandler(async (req: Request, res: Response) => {
    const { data, error } = await supabase
      .from('usuario_insignias')
      .select('*, insignias(*)')
      .eq('usuario_id', req.params.userId)
      .order('desbloqueada_at', { ascending: false });

    if (error) throw createError(error.message, 500, 'DB_ERROR');
    res.json(data);
  })
);

// POST /insignias/check — evaluar y desbloquear insignias para el usuario autenticado
router.post(
  '/check',
  requireAuth,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    // Get user's total verified visits
    const { data: perfil, error: perfilErr } = await supabase
      .from('perfiles')
      .select('visitas_totales')
      .eq('usuario_id', req.userId!)
      .single();

    if (perfilErr) throw createError(perfilErr.message, 404, 'NOT_FOUND');

    // Get all insignias not yet unlocked by this user
    const { data: yaDesbloqueadas } = await supabase
      .from('usuario_insignias')
      .select('insignia_id')
      .eq('usuario_id', req.userId!);

    const desbloqueadasIds = (yaDesbloqueadas ?? []).map((u) => u.insignia_id);

    const { data: insigniasPendientes, error: insigniasErr } = await supabase
      .from('insignias')
      .select('*')
      .lte('visitas_requeridas', perfil.visitas_totales)
      .not('id', 'in', `(${desbloqueadasIds.length > 0 ? desbloqueadasIds.join(',') : 'null'})`);

    if (insigniasErr) throw createError(insigniasErr.message, 500, 'DB_ERROR');

    if (!insigniasPendientes?.length) {
      return res.json({ nuevas: [] });
    }

    const nuevasRows = insigniasPendientes.map((i) => ({
      usuario_id: req.userId!,
      insignia_id: i.id,
    }));

    const { data: nuevas, error: insertErr } = await supabase
      .from('usuario_insignias')
      .insert(nuevasRows)
      .select('*, insignias(*)');

    if (insertErr) throw createError(insertErr.message, 500, 'INSERT_ERROR');
    res.json({ nuevas });
  })
);

// POST /insignias — admin: crear insignia
router.post(
  '/',
  requireAuth,
  requireRole('admin'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { data, error } = await supabase
      .from('insignias')
      .insert(req.body as { nombre: string; descripcion: string; icono: string; nivel: string; visitas_requeridas: number })
      .select()
      .single();

    if (error) throw createError(error.message, 400, 'INSERT_ERROR');
    res.status(201).json(data);
  })
);

export default router;
