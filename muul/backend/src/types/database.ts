// ─── Entity interfaces ────────────────────────────────────────────────────────
// These mirror the public schema in Supabase (MuulTests project).
// Use these for typing query results in route handlers.

export type Json = string | number | boolean | null | { [key: string]: Json } | Json[];

export interface Amenidad {
  id: string;
  nombre: string;
  icono: string;
}

export interface Coleccion {
  id: string;
  usuario_id: string;
  poi_id: string;
  created_at: string;
}

export interface Insignia {
  id: string;
  nombre: string;
  descripcion: string;
  icono: string;
  nivel: 'bronce' | 'plata' | 'oro' | 'platino';
  visitas_requeridas: number;
}

export interface NegocioAmenidad {
  negocio_id: string;
  amenidad_id: string;
}

export interface NegocioStats {
  id: string;
  negocio_id: string;
  vistas: number;
  visitas_verificadas: number;
  presencia_rutas: number;
  fecha: string;
}

export interface Negocio {
  id: string;
  propietario_id: string;
  nombre: string;
  descripcion: string | null;
  categoria: string;
  direccion: string;
  lat: number;
  lng: number;
  telefono: string | null;
  email: string | null;
  sitio_web: string | null;
  horario: Json | null;
  imagen_url: string | null;
  verificado: boolean;
  activo: boolean;
  created_at: string;
}

export interface Perfil {
  id: string;
  usuario_id: string;
  nombre: string;
  avatar_url: string | null;
  rol: 'turista' | 'empresa' | 'admin';
  idioma: 'es' | 'en' | 'zh' | 'pt';
  pasos_totales: number;
  calorias_totales: number;
  visitas_totales: number;
  created_at: string;
}

export interface Poi {
  id: string;
  nombre: string;
  descripcion: string | null;
  categoria: string;
  lat: number;
  lng: number;
  imagen_url: string | null;
  fuente: 'supabase' | 'mapbox';
  mapbox_id: string | null;
  activo: boolean;
  created_at: string;
}

export interface Producto {
  id: string;
  negocio_id: string;
  nombre: string;
  descripcion: string | null;
  precio: number | null;
  imagen_url: string | null;
  disponible: boolean;
  created_at: string;
}

export interface RecorridoNodo {
  id: string;
  recorrido_id: string;
  poi_id: string;
  orden: number;
  tiempo_estimado_min: number | null;
}

export interface Recorrido {
  id: string;
  usuario_id: string;
  nombre: string | null;
  distancia_km: number | null;
  duracion_min: number | null;
  pasos: number | null;
  calorias: number | null;
  completado: boolean;
  created_at: string;
}

export interface Resena {
  id: string;
  usuario_id: string;
  poi_id: string | null;
  negocio_id: string | null;
  calificacion: number;
  comentario: string | null;
  created_at: string;
}

export interface UsuarioInsignia {
  id: string;
  usuario_id: string;
  insignia_id: string;
  desbloqueada_at: string;
}

export interface Visita {
  id: string;
  usuario_id: string;
  poi_id: string | null;
  negocio_id: string | null;
  lat: number | null;
  lng: number | null;
  verificada: boolean;
  created_at: string;
}
