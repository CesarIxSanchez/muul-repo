import { Router } from 'express';
import type { Request, Response } from 'express';
import { supabase } from '../config/supabase.js';
import { asyncHandler, createError } from '../middleware/errorHandler.js';
import { requireAuth } from '../middleware/auth.js';
import type { AuthRequest } from '../middleware/auth.js';

const router = Router();

// POST /auth/register
router.post(
  '/register',
  asyncHandler(async (req: Request, res: Response) => {
    const { email, password, nombre, rol = 'turista', idioma = 'es' } = req.body as {
      email: string;
      password: string;
      nombre: string;
      rol?: string;
      idioma?: string;
    };

    if (!email || !password || !nombre) {
      throw createError('email, password y nombre son requeridos', 400, 'VALIDATION_ERROR');
    }

    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { nombre, rol, idioma },
    });

    if (authError) {
      throw createError(authError.message, 400, authError.code ?? 'AUTH_ERROR');
    }

    // Create profile row
    const { error: profileError } = await supabase.from('perfiles').insert({
      usuario_id: authData.user.id,
      nombre,
      rol: rol as 'turista' | 'empresa' | 'admin',
      idioma: idioma as 'es' | 'en' | 'zh' | 'pt',
      pasos_totales: 0,
      calorias_totales: 0,
      visitas_totales: 0,
    });

    if (profileError) {
      // Rollback user if profile creation fails
      await supabase.auth.admin.deleteUser(authData.user.id);
      throw createError(profileError.message, 500, 'PROFILE_CREATE_ERROR');
    }

    res.status(201).json({ message: 'Usuario registrado exitosamente', userId: authData.user.id });
  })
);

// POST /auth/login
router.post(
  '/login',
  asyncHandler(async (req: Request, res: Response) => {
    const { email, password } = req.body as { email: string; password: string };

    if (!email || !password) {
      throw createError('email y password son requeridos', 400, 'VALIDATION_ERROR');
    }

    const { data, error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      const statusCode = error.message.includes('Invalid') ? 401 : 400;
      throw createError(error.message, statusCode, error.code ?? 'AUTH_ERROR');
    }

    res.json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_in: data.session.expires_in,
      user: {
        id: data.user.id,
        email: data.user.email,
        rol: data.user.user_metadata.rol,
        idioma: data.user.user_metadata.idioma,
      },
    });
  })
);

// POST /auth/refresh
router.post(
  '/refresh',
  asyncHandler(async (req: Request, res: Response) => {
    const { refresh_token } = req.body as { refresh_token: string };

    if (!refresh_token) {
      throw createError('refresh_token es requerido', 400, 'VALIDATION_ERROR');
    }

    const { data, error } = await supabase.auth.refreshSession({ refresh_token });

    if (error || !data.session) {
      throw createError('Refresh token inválido o expirado', 401, 'UNAUTHORIZED');
    }

    res.json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      expires_in: data.session.expires_in,
    });
  })
);

// POST /auth/logout
router.post(
  '/logout',
  requireAuth,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const token = req.headers.authorization!.slice(7);
    await supabase.auth.admin.signOut(token);
    res.json({ message: 'Sesión cerrada' });
  })
);

// GET /auth/me
router.get(
  '/me',
  requireAuth,
  asyncHandler(async (req: AuthRequest, res: Response) => {
    const { data, error } = await supabase
      .from('perfiles')
      .select('*')
      .eq('usuario_id', req.userId!)
      .single();

    if (error) throw createError(error.message, 404, 'NOT_FOUND');
    res.json(data);
  })
);

export default router;
