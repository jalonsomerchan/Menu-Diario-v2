# Menu Diario — contexto y estado del proyecto

## 1. Objetivo original

La aplicación existente está en `/Users/jorgealonso/Proyectos/menu-diario`.
El objetivo es copiar/migrar la aplicación a
`/Users/jorgealonso/Proyectos/menudiario_v2` y sustituir Firebase/Firestore
como base de datos por MySQL.

La nueva aplicación debe:

- Usar Firebase Authentication con Google para identificar al usuario.
- Reutilizar el login y la validación de tokens de
  `/Applications/MAMP/htdocs/OV2/api/auth.php`.
- Tener el backend en
  `/Applications/MAMP/htdocs/OV2/api/menudiario.php`.
- Guardar los datos de Menu Diario en una base MySQL nueva llamada
  `menudiario`.
- Mantener el frontend en `menudiario_v2`, aprovechando las dependencias Vue
  ya instaladas.

El primer objetivo funcional solicitado es asignar platos a desayuno, comida y
cena, configurar qué comidas se quieren usar siempre y mover platos entre
distintos días.

## 2. Estado actual

Está implementado el primer vertical funcional: autenticación, planificador
semanal, edición de días, preferencias de comidas, persistencia MySQL y
movimiento individual de platos.

Todavía no se ha hecho la migración completa del histórico y de todas las
funcionalidades de Firestore de la aplicación original.

## 3. Trabajo realizado

### Frontend Vue

Archivo principal: [src/App.vue](./src/App.vue)

Incluye:

- Pantalla de bienvenida y acceso mediante Google.
- Llamada explícita a `POST /auth/login` después del popup de Firebase.
- Carga de rangos de fechas inclusivos mediante `GET /menudiario/range`.
- El planificador comienza en el día actual y pide siete días por petición; el
  scroll infinito continúa con el siguiente bloque de siete días.
- Vista de siete tarjetas diarias.
- Tarjetas para desayuno, comida y cena.
- Edición de uno o varios platos por comida.
- Notas por comida y notas generales del día.
- Sugerencias de platos mediante `<datalist>`.
- Ajustes para activar/desactivar desayuno, comida y cena.
- Movimiento mediante arrastrar cada plato y soltarlo en otro día. Al soltarlo
  sobre una comida concreta puede cambiar de franja; al soltarlo sobre la
  tarjeta del día conserva su franja original.
- Mensajes de guardado, errores y estado de carga.
- Diseño responsive para escritorio y móvil.
- Los días de la página principal se muestran en un listado vertical.
- La primera carga comienza en el día actual; no muestra los días anteriores de
  la semana actual. Después continúa con los días siguientes mediante scroll
  infinito.
- La portada no muestra selector ni navegación manual de semanas.
- El scroll infinito carga automáticamente los rangos siguientes al acercarse
  al final de la página.
- Ajustes se muestra como una página propia (`/ajustes`), no como un modal, y
  permite volver al planificador con `/`.
- Vue Router define rutas reales para las páginas actuales: `/` (planificador)
  y `/ajustes` (configuración).
- El movimiento contempla también días de semanas ya cargadas.
- Gestión del grupo actual desde Ajustes: código y enlace de invitación,
  miembros, emails pendientes, unión por código y salida del grupo.
- Las invitaciones por email quedan pendientes y se aceptan automáticamente
  cuando ese email inicia sesión con Firebase.
- Opciones diarias de grupo: alta, edición, borrado, orden, color, icono y
  activación/desactivación.
- Selección de opciones diarias al editar un día y visualización como etiquetas
  en la lista vertical.
- Avisos globales reutilizables: el propietario puede crear varios avisos con
  nombre, hora, mensaje, ámbito (desayuno/comida/cena/todas) y activación por
  defecto. Cada comida puede activar/desactivar esos avisos y añadir avisos
  exclusivos desde “Más opciones”. La API guarda estos datos, pero todavía no
  ejecuta el envío de avisos.
- El ID token Firebase se renueva con `getIdToken(true)` antes de cada escritura
  para evitar falsos `AUTH_REQUIRED` con sesiones largas.

### Cliente API

Archivo: [src/lib/api.js](./src/lib/api.js)

- Base configurable con `VITE_API_BASE`.
- Usa `http://localhost/OV2/api` en local y
  `https://alon.one/api` por defecto en producción.
- Envía el Firebase ID token como `Authorization: Bearer ...`.
- Interpreta respuestas con formato `{ ok, data, message }`.

### Cliente Firebase

Archivo: [src/lib/firebase.js](./src/lib/firebase.js)

- Carga Firebase App y Auth desde el CDN oficial.
- Usa Firebase SDK `12.6.0`.
- Inicializa Google Sign-In con `signInWithPopup`.
- Expone observación de sesión, login y logout.
- Lee configuración desde variables `VITE_FIREBASE_*` o las equivalentes
  `PUBLIC_FIREBASE_*`.

Variables documentadas en [.env.example](./.env.example).

Para pruebas locales se ha creado `.env.local` con la configuración Firebase
web proporcionada y `VITE_API_BASE=http://localhost/OV2/api`. Este archivo está
excluido de Git.

### Fechas

Archivo: [src/lib/dates.js](./src/lib/dates.js)

Contiene cálculo de lunes de la semana, desplazamiento entre semanas,
generación de los siete días y formateo en español.

### Backend PHP

Archivo: [menudiario.php](/Applications/MAMP/htdocs/OV2/api/menudiario.php)

La clase `menudiario`:

- Hereda de `BaseControler`.
- Selecciona la base `menudiario`, configurable con
  `MENUDIARIO_DB_NAME`.
- Valida el nombre de base de datos antes de usarlo.
- Si la base no existe, intenta crearla automáticamente con
  `CREATE DATABASE IF NOT EXISTS`.
- Crea las tablas de la aplicación en el primer acceso mediante
  `CREATE TABLE IF NOT EXISTS`.
- Reutiliza la validación de Firebase de `auth.php`.
- No confía en el nombre o email enviado por el cliente.
- Filtra fechas, comidas, textos y platos recibidos.
- Usa consultas preparadas para las operaciones de datos.
- Actualiza el contador de uso de los platos al guardar un día.

### Integración con auth.php

Archivo modificado: [auth.php](/Applications/MAMP/htdocs/OV2/api/auth.php)

Se añadió `getAuthenticatedIdentity()`, un hook público que reutiliza la
misma validación de tokens Firebase que `/auth/me`, sin emitir una respuesta
HTTP. Devuelve los claims y el usuario sincronizado en
`alon_api_users`.

Firebase sigue siendo el emisor del token. La API no genera una sesión PHP ni
un token alternativo.

### Registro del controlador

Archivo modificado: [index.php](/Applications/MAMP/htdocs/OV2/api/index.php)

Se añadió `menudiario => menudiario.php` a la lista explícita de controladores.
`menudiario.php` requiere explícitamente `auth.php`; no se ha añadido ningún
`glob()` ni carga genérica de scripts legacy.

### Base de datos

Esquema: [database/menudiario.sql](./database/menudiario.sql)

La base nueva contiene inicialmente:

- `md_preferences`: comidas activas, preferencias del usuario, grupo actual y
  valores por defecto de los avisos y preferencias de notificación.
- `md_groups`: grupos, propietario, código de invitación y comidas activas.
- `md_group_members`: relación de usuarios y grupos.
- `md_group_invites`: invitaciones pendientes por email.
- `md_daily_options`: opciones/condiciones diarias pertenecientes al grupo.
- `md_global_alerts`: catálogo de avisos globales del grupo, con hora, icono y
  días de antelación (0 = mismo día; hasta 30 días antes).
- `md_dishes`: platos globales y platos creados por cada usuario; el catálogo
  visible incluye los platos de todas las personas del grupo actual.
- `md_week_menus`: una fila por usuario y semana.
- `md_menu_days`: siete días por semana y sus IDs de opciones diarias.
- `md_menu_meals`: desayuno, comida y cena por día, incluyendo los avisos
  globales sobrescritos y los avisos personalizados, ambos con su día del aviso.
- `md_notifications`, `md_notification_reads`: historial de actividad y estado
  de lectura independiente para cada usuario.

La migración base se ha ejecutado directamente en producción sobre la base
`menudiario`. Verificación realizada el 12/09/2026: existían las nueve tablas
`md_*`, las columnas `md_preferences.group_id` y
`md_menu_days.option_ids_json`, un grupo inicial y un miembro; no quedan
opciones ni invitaciones de prueba.

La API crea automáticamente `md_global_alerts` y añade `alerts_json` a
`md_menu_meals` cuando atiende una petición tras esta ampliación.

Los platos iniciales globales son:

- Lentejas con verduras.
- Tortilla de patatas.
- Pasta con tomate.
- Ensalada completa.

La documentación del esquema está en [database/README.md](./database/README.md).

## 4. Contrato de API actual

Todos los endpoints de Menu Diario requieren:

```http
Authorization: Bearer FIREBASE_ID_TOKEN
Content-Type: application/json
```

### `GET /menudiario/bootstrap?week_start=YYYY-MM-DD`

Obtiene o crea la semana del usuario y devuelve:

```json
{
  "ok": true,
  "data": {
    "preferences": {
      "enabled_meals": ["lunch"],
      "theme": "system",
      "default_reminder_enabled": false,
      "default_reminder_time": "09:00"
    },
    "dishes": [],
    "menu": {
      "id": 1,
      "title": "Semana del 14/09/2026",
      "week_start": "2026-09-14",
      "days": {}
    },
    "group": {
      "id": 1,
      "name": "Menu Diario",
      "owner_uid": "firebase-uid",
      "invite_code": "ABCDEFGH",
      "enabled_meals": ["lunch"],
      "members": [],
      "pending_emails": []
    },
    "daily_options": [],
    "global_alerts": [],
    "notifications": [],
    "notification_unread_count": 0,
    "user": {}
  }
}
```

### `GET /menudiario/range?from=YYYY-MM-DD&to=YYYY-MM-DD`

Obtiene el rango inclusivo solicitado. El backend sigue almacenando los datos
por semanas, pero esa estructura no se expone en esta respuesta:

```json
{
  "ok": true,
  "data": {
    "from": "2026-09-13",
    "to": "2026-10-10",
    "days": {
      "2026-09-13": {
        "week_start": "2026-09-07",
        "notes": "",
        "option_ids": [],
        "meals": {}
      }
    },
    "preferences": {},
    "dishes": [],
    "group": {},
    "daily_options": [],
    "global_alerts": [],
    "notifications": [],
    "notification_unread_count": 0,
    "user": {}
  }
}
```

`from` y `to` son inclusivos; también se aceptan `start_date` y `end_date`
como nombres alternativos. El rango máximo es de 366 días. Para las siguientes
peticiones de scroll se puede enviar `include_context=0` y la respuesta
contendrá únicamente `from`, `to` y `days`.

### `POST /menudiario/preferences`

Body:

```json
{
  "enabled_meals": ["breakfast", "lunch", "dinner"],
  "default_reminder_enabled": true,
  "default_reminder_time": "09:00",
  "notification_enabled": true,
  "notification_types": ["meal_added", "meal_updated", "meal_moved", "group"]
}
```

Si se envía una lista vacía o inválida, el backend conserva `lunch` como
opción mínima.

También acepta `breakfast_time`, `lunch_time` y `dinner_time` por usuario en
formato `HH:MM`. Un valor vacío o `null` indica que esa comida se exportará
como evento de día completo en el feed iCal privado de los próximos 12 meses.

### Grupos e invitaciones

- `POST /menudiario/group_options`: cambia las comidas visibles del grupo y
  guarda los valores por defecto de avisos del propietario; solo el
  propietario.
- `POST /menudiario/invite_email`: registra un email pendiente; solo el
  propietario.
- `POST /menudiario/join_group`: recibe `{ "invite_code": "ABCDEFGH" }`.
- `POST /menudiario/leave_group`: abandona el grupo y crea/usa un grupo propio;
  si el propietario sale, se transfiere la propiedad al miembro más antiguo.

### Opciones diarias

- `GET /menudiario/daily_options`
- `POST /menudiario/save_daily_option`: recibe `id` opcional, `name`,
  `description`, `active`, `color`, `icon` y `order`; solo el propietario.
- `POST /menudiario/delete_daily_option`: recibe `{ "id": 1 }`; solo el
  propietario.

Los días guardan las opciones seleccionadas en `option_ids` dentro de
`save_day`. El backend filtra esos IDs para aceptar únicamente opciones del
grupo actual.

### Avisos globales

- `POST /menudiario/save_global_alert`: recibe `id` opcional, `name`,
  `message`, `time`, `day_offset` (0 = mismo día, 1 = día anterior), `icon`,
  `default_enabled`, `scope`, `active` y `order`; solo el
  propietario.
- `POST /menudiario/delete_global_alert`: recibe `{ "id": 1 }`; solo el
  propietario.

El catálogo se devuelve como `global_alerts` en `bootstrap`. Cada comida puede
guardar sobrescrituras de esos avisos y avisos personalizados en `alerts`.

### Notificaciones

`bootstrap` devuelve `notifications` (las últimas 50 visibles para el usuario)
y `notification_unread_count`. Las notificaciones con `recipient_uid` nulo son
del grupo; las demás son individuales. La lectura se guarda en
`md_notification_reads`, por lo que cada usuario mantiene su propio estado.

- `POST /menudiario/mark_notification_read`: recibe `{ "id": 1 }`.
- `POST /menudiario/mark_all_notifications_read`: marca como leídas las
  notificaciones visibles del usuario.

Los tipos configurables son `meal_added`, `meal_updated`, `meal_moved` y
`group`. Estas preferencias solo preparan la futura entrega externa; el
historial de la campanita no se filtra.

### `POST /menudiario/save_day`

Body simplificado:

```json
{
  "week_start": "2026-09-14",
  "day_date": "2026-09-16",
  "day": {
    "skipped": false,
    "reason": "",
    "skip_note": "",
    "notes": "Preparar el domingo",
    "option_ids": [1, 2],
    "meals": {
      "breakfast": {
        "items": ["Tostada con tomate"],
        "skipped": false,
        "reason": "",
        "note": "",
        "reminder_enabled": true,
        "reminder_time": "08:30",
        "reminder_message": "Preparar el desayuno"
      },
      "lunch": {
        "items": ["Lentejas con verduras"],
        "skipped": false,
        "reason": "",
        "note": ""
      },
      "dinner": {
        "items": [],
        "skipped": false,
        "reason": "",
        "note": ""
      }
    }
  }
}
```

### `POST /menudiario/move_dish`

Mueve un único plato entre dos días. Solo cambia las listas de platos; las
notas, el estado omitido y la configuración de avisos de cada comida se
mantienen en su día original.

```json
{
  "week_start": "2026-09-14",
  "source": {
    "day_date": "2026-09-14",
    "meal": "lunch",
    "dish": "Ensalada de pasta"
  },
  "target": {
    "day_date": "2026-09-17",
    "meal": "lunch"
  }
}
```

La operación usa una transacción MySQL.

`source.week_start` y `target.week_start` permiten mover platos entre semanas
distintas. El endpoint rechaza movimientos dentro del mismo día.

## 5. Decisiones técnicas actuales

- Vue 3 + Vite, manteniendo las dependencias ya instaladas en `v2`.
- Firebase solo para identidad, no para persistencia de Menu Diario.
- MySQL separado de `alonsoftware` para evitar mezclar tablas de la aplicación.
- Identidad compartida en `alonsoftware.alon_api_users`.
- Datos del menú normalizados en tablas relacionales en vez de guardar una
  semana completa como JSON.
- `enabled_meals` se guarda como JSON serializado en una columna de texto para
  mantener compatibilidad con instalaciones MySQL variadas.
- Los menús compartidos usan como `owner_uid` el propietario del grupo; todos
  los miembros trabajan sobre el mismo menú semanal.
- Las comidas visibles son una opción del grupo y solo las cambia su
  propietario.
- El movimiento cambia solo el plato seleccionado, no el bloque completo.

## 6. Comprobaciones realizadas

Se ejecutaron correctamente:

```text
npm run build
npm run lint
php -l /Applications/MAMP/htdocs/OV2/api/menudiario.php
php -l /Applications/MAMP/htdocs/OV2/api/auth.php
```

También se levantó Vite temporalmente y se comprobó visualmente la pantalla
inicial en Chrome. La interfaz muestra correctamente el acceso con Google y
el aviso de configuración cuando faltan las variables públicas de Firebase.

Con `.env.local`, Firebase inicializa correctamente y detecta una sesión local
existente. Se corrigió el paso del header `Authorization` en Apache/MAMP
añadiendo `CGIPassAuth On` y una regla `SetEnvIf Authorization` en
`/Applications/MAMP/htdocs/OV2/api/.htaccess`. Con Apache activo se verificó el
flujo autenticado en el navegador, el `bootstrap` cargó correctamente y una
sesión larga pudo guardar después de renovar el token Firebase.

También se comprobó desde Chrome el flujo propietario de una opción diaria:
crear, seleccionar en un día, guardar, mostrar la etiqueta y borrar la opción.
Los datos creados para la prueba se eliminaron de producción.

## 7. Producción

La base se ha creado correctamente en el servidor MySQL de producción
`217.182.169.184` usando la conexión indicada en `BaseControler.php`.

Verificación realizada:

```text
DATABASE: menudiario
TABLES: md_daily_options, md_dishes, md_global_alerts, md_group_invites,
        md_group_members, md_groups, md_menu_days, md_menu_meals,
        md_notification_reads, md_notifications, md_preferences, md_week_menus
DISHES: 4
GROUPS: 1
GROUP_MEMBERS: 1
GROUP_INVITES: 0
DAILY_OPTIONS: 0
NOTIFICATIONS: historial de actividad con lectura por usuario
```

El backend conserva además el arranque automático con `CREATE DATABASE IF NOT
EXISTS` y `CREATE TABLE IF NOT EXISTS`, para que una instalación nueva pueda
inicializarse desde el primer acceso.

## 8. Pendiente prioritario

### Bloque 1 — Puesta en marcha

1. Copiar/configurar las variables Firebase en el entorno de build del
   frontend de producción.
2. Confirmar que el dominio final del frontend está en Firebase Authorized
   Domains.
3. Probar con dos usuarios Google distintos: invitación por email, autoaceptar
   invitación, unión por código, salida y transferencia de propietario.
4. Confirmar que Apache permite las rutas `/api/menudiario/...` y que CORS
   incluye el dominio final del frontend.

### Bloque 2 — Migración de Firestore

1. Definir el alcance de la migración: usuarios, perfiles, grupos, menús,
   platos, historial, opciones diarias, estadísticas y tuppers.
2. Crear un export seguro de Firestore.
3. Implementar un script de migración idempotente y con modo simulación.
4. Mapear documentos `weeklyMenus`, `users`, `groups` y `dishes` a las tablas
   MySQL definitivas.
5. Resolver los documentos legacy (`lunch`, `dinner`, `lunchItems`, etc.)
   usando la misma normalización que la aplicación original.
6. Validar conteos, propietarios, fechas y platos duplicados antes de cortar.
7. Mantener Firestore en solo lectura durante la transición y hacer un corte
   final controlado.

### Bloque 3 — Paridad con la aplicación original

1. Migrar los grupos, miembros, emails pendientes y opciones diarias
   existentes desde Firestore; la estructura MySQL ya está preparada.
2. Portar platos globales, favoritos, etiquetas, archivado e ingredientes.
3. Portar historial y estadísticas de uso.
4. Portar lista de la compra y generación por ingredientes.
5. Portar tuppers y caducidades.
6. Portar participantes e intolerancias.
7. Portar notificaciones y sincronización entre usuarios.
8. Añadir rutas Vue separadas para cada módulo.
9. Añadir tests de API y tests de interacción del planificador.

## 9. Riesgos y notas

- No conviene borrar Firestore hasta validar la migración y tener copia.
- La conexión de red a MySQL desde el equipo local no sirve como prueba de
  conectividad desde el servidor Apache.
- La creación automática de base de datos depende de permisos MySQL; el
  `CREATE TABLE` no puede funcionar si la selección de `menudiario` falla y la
  cuenta tampoco puede crear la base.
- El frontend usa imports Firebase desde CDN. Para producción convendría
  valorar instalar el paquete `firebase` en el proyecto y fijar la dependencia
  en `package.json`.
- La interfaz actual está centrada en el primer vertical; no pretende ser aún
  una copia completa de todas las páginas Astro de `/menu-diario`.

## 10. Próximo paso recomendado

El siguiente paso recomendado es probar el flujo de colaboración con dos
cuentas Google reales y, después, diseñar y ejecutar la migración idempotente
del histórico de Firestore antes de portar los módulos secundarios.
