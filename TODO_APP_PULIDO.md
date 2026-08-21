# Todo de pulido para la app Abastible

## Estado actual
- La lógica de estado ya toma la última etapa con fecha válida.
- La etapa 2 incluye "Crear UT" después de "Proyecto Liberado".
- El campo `f_ut` está presente en la estructura de datos.
- La app ya no depende de un estado manual obsoleto.

## Archivos clave
- [Abastible_Gestion_v8.html](Abastible_Gestion_v8.html)
- [schema.sql](schema.sql)
- [vercel.json](vercel.json)

## Checklist de mejoras pendientes
1. Revisar caché y deploy final en Vercel.
2. Validar que los proyectos se actualicen al cambiar fechas en Supabase.
3. Revisión visual de badges y estados.
4. Mejorar textos de etapas y tooltips.
5. Validar que no se permita ingresar fechas inconsistentes.
6. Revisar exportación de datos y paneles complementarios.
7. Mejorar UX del detalle de proyecto.
8. Revisar campos opcionales y validación de formularios.
9. Probar flujo de Welcome Pack / End Pack.
10. Revisar compatibilidad móvil y responsividad.

## Regla actual de estado
La lógica actual prioriza la etapa más reciente con fecha válida en este orden:
- cierre forzado
- gestor documental
- cargas N°1 a N°10
- inicio trabajos
- envío O.C.
- proyecto liberado
- revisión antecedentes
- entregado a coordinador
- evaluación previa

## Ideas de pulido
- Crear validaciones por orden lógico de fechas.
- Mostrar un resumen más claro del estado actual del proyecto.
- Añadir indicadores de alerta cuando una etapa se pasa por mucho tiempo.
- Mejorar mensajes del detalle del proyecto.
- Añadir un modo de edición más claro para fechas y hitos.

## Siguiente paso recomendado
- Validar en navegador la versión desplegada.
- Hacer una ronda de pruebas con 3 o 4 proyectos reales.
- Luego ir priorizando mejoras por valor: estado, UX, validaciones, exportación.
