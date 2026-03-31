import { Router } from 'express';
import type { Response } from 'express';
import { supabase } from '../config/supabase.js';
import { asyncHandler, createError } from '../middleware/errorHandler.js';
import { requireAuth } from '../middleware/auth.js';
import type { AuthRequest } from '../middleware/auth.js';

const router = Router();
router.use(requireAuth);

// GET /colecciones — POIs guardados por el usuario
router.get(
  '/',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { data, error } = await supabase
      .from('colecciones')
      .select('*, pois(*)')
      .eq('usuario_id', req.userId!)
      .order('created_at', { ascending: false });

    if (error) throw createError(error.message, 500, 'DB_ERROR');
    res.json(data);
  })
);

// POST /colecciones — guardar un POI
router.post(
  '/',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { poi_id } = req.body as { poi_id: string };
    if (!poi_id) throw createError('poi_id es requerido', 400, 'VALIDATION_ERROR');

    // Upsert to prevent duplicates
    const { data, error } = await supabase
      .from('colecciones')
      .upsert({ usuario_id: req.userId!, poi_id }, { onConflict: 'usuario_id,poi_id' })
      .select()
      .single();

    if (error) throw createError(error.message, 400, 'INSERT_ERROR');
    res.status(201).json(data);
  })
);

// DELETE /colecciones/:poiId — quitar de colección
router.delete(
  '/:poiId',
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { error } = await supabase
      .from('colecciones')
      .delete()
      .eq('usuario_id', req.userId!)
      .eq('poi_id', req.params.poiId);

    if (error) throw createError(error.message, 400, 'DELETE_ERROR');
    res.status(204).send();
  })
);

export default router;
