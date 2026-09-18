# Base de datos de Menu Diario

`menudiario.sql` crea la base de datos y las tablas del primer vertical de la
aplicación. Debe ejecutarse una vez en la instancia MySQL de producción con un
usuario que pueda crear bases de datos y tablas. La migración del 12/09/2026
ya está aplicada en producción.

Las ampliaciones de avisos se aplican automáticamente desde la API mediante
`CREATE TABLE IF NOT EXISTS` y comprobación de columnas.

La identidad continúa viviendo en `alonsoftware.alon_api_users`; las tablas
`md_*` contienen únicamente los datos propios de Menu Diario.

Tablas actuales:

- `md_preferences`: preferencias de usuario, grupo actual, horarios opcionales
  de desayuno/comida/cena, token privado del feed iCal y valores por defecto de
  los avisos.
- `md_groups`, `md_group_members`, `md_group_invites`: colaboración e
  invitaciones.
- `md_daily_options`: condiciones diarias configurables por el propietario.
- `md_global_alerts`: avisos globales reutilizables, con hora, día del aviso, icono, ámbito y estado
  por defecto.
- `md_notifications`, `md_notification_reads`: actividad del grupo y lectura
  independiente por usuario.
- `md_tasks`, `md_task_reminder_deliveries`: tareas del grupo, asignación,
  estado, importancia, vencimiento y control de avisos enviados.
- `md_dishes`: catálogo de platos.
- `md_ingredients`: catálogo único de ingredientes, sin duplicados.
- `md_user_ingredients`: ingredientes disponibles en el catálogo personal de cada usuario y su preferencia de exclusión de la lista de la compra.
- `md_dish_ingredient_links`: relación de ingredientes con platos por usuario.
- `md_dish_ingredients`: formato JSON legado, migrado automáticamente a las dos tablas normalizadas anteriores.
- `md_dish_favorites`: favoritos de cada usuario, incluidos los platos iniciales compartidos.
- `md_week_menus`, `md_menu_days`, `md_menu_meals`: planificación semanal,
  comidas asignadas y configuración de avisos por comida, incluidos los avisos
  personalizados.
