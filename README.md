# Muul Monorepo

Repositorio del proyecto Muul siguiendo la arquitectura definida en el SRS:

- Una aplicacion movil en Flutter.
- Una aplicacion web en Flutter.
- Paquetes compartidos para mantener separacion de responsabilidades.

## Estructura

```text
muul/
	apps/
		mobile_app/
		web_app/
	packages/
		core/
		ui/
		services/
		data/
	docs/
	assets/
	.github/
```

## Estado actual

Implementado en este cambio:

- Componente 1 (Autenticacion, sesion y perfil de usuario): completo.
- Estructura base de monorepo: creada.
- Paquetes compartidos: inicializados.

No implementado en este cambio:

- Componentes 2, 3, 4 y 5 (solo se dejaron puntos TODO de integracion desde el modulo de autenticacion).

## Ejecutar aplicaciones

Movil:

1. Ir a `apps/mobile_app`
2. Ejecutar `flutter pub get`
3. Ejecutar `flutter run`

Web:

1. Ir a `apps/web_app`
2. Ejecutar `flutter pub get`
3. Ejecutar `flutter run -d chrome`

## Documentacion de responsabilidades

La asignacion de responsabilidades por persona y entregables se encuentra en:

- `docs/team_responsibilities.md`

## Responsabilidades del equipo

## Persona 1 - Autenticacion, sesion y perfil de usuario

Incluye:

- Splash y carga inicial
- Login y registro
- Cierre y persistencia de sesion
- Perfil y edicion basica de perfil
- Preferencias basicas (idioma)

Pantallas:

- SplashScreen
- LoginScreen
- RegisterScreen
- ProfileScreen
- EditProfileScreen

Entregables esperados:

- Flujo completo de autenticacion funcionando
- Modelo User
- Servicio AuthService
- Guardas o validaciones para rutas protegidas

Dependencias:

- Usa core, services y data
- Es base para todos los modulos

## Persona 2 - Exploracion, busqueda y detalle de lugares/negocios

Incluye:

- Home principal
- Catalogo/listado
- Busqueda y filtros
- Detalle de lugar y negocio

Pantallas:

- HomeScreen
- ExploreScreen
- SearchScreen
- PlaceDetailScreen
- BusinessDetailScreen

Entregables esperados:

- Modelo Place
- Modelo Business
- Widgets de cards/listas/filtros
- Flujo funcional de exploracion y busqueda

Dependencias:

- Consume datos de data
- Reutiliza UI compartida

## Persona 3 - Mapa, geolocalizacion y rutas

Incluye:

- Mapa principal y ubicacion actual
- Marcadores y rutas sugeridas
- Vista de recorrido e itinerario

Pantallas:

- MapScreen
- RoutePlannerScreen
- RouteDetailScreen

Entregables esperados:

- Servicio de geolocalizacion
- Integracion de mapa
- Widget de mapa reutilizable
- Modelos Route e ItineraryStop

Dependencias:

- Se integra con exploracion
- Usa datos de lugares/negocios
- Puede iniciar con mocks

## Persona 4 - Modulo de negocios y gestion web

Incluye:

- Registro/edicion de negocio
- Perfil de negocio
- Panel de negocio en web
- Administracion basica de datos

Pantallas:

- BusinessRegisterScreen
- BusinessDashboardScreen
- BusinessEditScreen
- MyBusinessProfileScreen

Entregables esperados:

- Modelo BusinessProfile
- Formularios validados
- Flujo CRUD basico del perfil de negocio
- Vistas responsive para web

Dependencias:

- Requiere autenticacion
- Comparte modelos con exploracion
- Coordina con data

## Persona 5 - Gamificacion, multilenguaje e integracion transversal

Incluye:

- Sistema de insignias/logros
- Soporte multilenguaje
- Tema global
- Navegacion global
- Integracion de modulos
- Pruebas de integracion minimas

Pantallas y secciones:

- AchievementsScreen
- Configuracion de idioma
- Componentes globales de navegacion

Entregables esperados:

- AppRouter global
- ThemeConfig
- Localization setup
- Modelo Achievement
- Base de arquitectura compartida
- Checklist de integracion general

Dependencias:

- Trabaja con todos los componentes
- Recomendada como persona integradora tecnica
