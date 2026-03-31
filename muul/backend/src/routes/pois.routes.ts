import { Router } from 'express';
import type { Request, Response } from 'express';
import { supabase } from '../config/supabase.js';
import { asyncHandler, createError } from '../middleware/errorHandler.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import type { AuthRequest } from '../middleware/auth.js';

const router = Router();

// GET /pois — list with optional category filter
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const { categoria, search, limit = '50', offset = '0' } = req.query as Record<string, string>;

    let query = supabase
      .from('pois')
      .select('*')
      .eq('activo', true)
      .order('nombre')
      .range(Number(offset), Number(offset) + Number(limit) - 1);

    if (categoria) query = query.eq('categoria', categoria);
    if (search) query = query.ilike('nombre', `%${search}%`);

    const { data, error, count } = await query;
    if (error) throw createError(error.message, 500, 'DB_ERROR');

    res.json({ data, count });
  })
);

// GET /pois/categorias — distinct categories
router.get(
  '/categorias',
  asyncHandler(async (_req: Request, res: Response) => {
    const { data, error } = await supabase
      .from('pois')
      .select('categoria')
      .eq('activo', true);

    if (error) throw createError(error.message, 500, 'DB_ERROR');

    const unique = [...new Set(data?.map((p) => p.categoria))];
    res.json(unique);
  })
);

// GET /pois/:id
router.get(
  '/:id',
  asyncHandler(async (req: Request, res: Response) => {
    const { data, error } = await supabase
      .from('pois')
      .select('*')
      .eq('id', req.params.id)
      .eq('activo', true)
      .single();

    if (error) throw createError('POI no encontrado', 404, 'NOT_FOUND');
    res.json(data);
  })
);

// POST /pois — admin only
router.post(
  '/',
  requireAuth,
  requireRole('admin'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { data, error } = await supabase
      .from('pois')
      .insert(req.body)
      .select()
      .single();

    if (error) throw createError(error.message, 400, 'INSERT_ERROR');
    res.status(201).json(data);
  })
);

// PATCH /pois/:id — admin only
router.patch(
  '/:id',
  requireAuth,
  requireRole('admin'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { data, error } = await supabase
      .from('pois')
      .update(req.body as Record<string, unknown>)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw createError(error.message, 400, 'UPDATE_ERROR');
    res.json(data);
  })
);

// DELETE /pois/:id — soft delete
router.delete(
  '/:id',
  requireAuth,
  requireRole('admin'),
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { error } = await supabase
      .from('pois')
      .update({ activo: false })
      .eq('id', req.params.id);

    if (error) throw createError(error.message, 400, 'DELETE_ERROR');
    res.status(204).send();
  })
);

export default router;
