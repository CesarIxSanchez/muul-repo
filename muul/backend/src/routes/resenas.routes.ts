import { Router } from 'express';
import type { Request, Response } from 'express';
import { supabase } from '../config/supabase.js';
import { asyncHandler, createError } from '../middleware/errorHandler.js';
import { requireAuth } from '../middleware/auth.js';
import type { AuthRequest } from '../middleware/auth.js';

const router = Router();

// GET /resenas?poi_id=&negocio_id=
router.get(
  '/',
  asyncHandler(async (req: Request, res: Response) => {
    const { poi_id, negocio_id, limit = '20', offset = '0' } = req.query as Record<string, string>;

    let query = supabase
      .from('resenas')
      .select('*, perfiles(nombre, avatar_url)')
      .order('created_at', { ascending: false })
      .range(Number(offset), Number(offset) + Number(limit) - 1);

    if (poi_id) query = query.eq('poi_id', poi_id);
    if (negocio_id) query = query.eq('negocio_id', negocio_id);

    const { data, error } = await query;
    if (error) throw createError(error.message, 500, 'DB_ERROR');
    res.json(data);
  })
);

// POST /resenas
router.post(
  '/',
  requireAuth,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { calificacion, comentario, poi_id, negocio_id } = req.body as {
      calificacion: number;
      comentario?: string;
      poi_id?: string;
      negocio_id?: string;
    };

    if (!poi_id && !negocio_id) {
      throw createError('Debe especificar poi_id o negocio_id', 400, 'VALIDATION_ERROR');
    }
    if (!calificacion || calificacion < 1 || calificacion > 5) {
      throw createError('Calificacion debe ser entre 1 y 5', 400, 'VALIDATION_ERROR');
    }

    const { data, error } = await supabase
      .from('resenas')
      .insert({ calificacion, comentario, poi_id, negocio_id, usuario_id: req.userId! })
      .select()
      .single();

    if (error) throw createError(error.message, 400, 'INSERT_ERROR');
    res.status(201).json(data);
  })
);

// DELETE /resenas/:id — only owner
router.delete(
  '/:id',
  requireAuth,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { data: resena } = await supabase
      .from('resenas')
      .select('usuario_id')
      .eq('id', req.params.id)
      .single();

    if (!resena) throw createError('Reseña no encontrada', 404, 'NOT_FOUND');
    if (resena.usuario_id !== req.userId && req.userRole !== 'admin') {
      throw createError('No tienes permiso', 403, 'FORBIDDEN');
    }

    const { error } = await supabase.from('resenas').delete().eq('id', req.params.id);
    if (error) throw createError(error.message, 400, 'DELETE_ERROR');
    res.status(204).send();
  })
);

export default router;
