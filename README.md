# Abastible · Gestión de Proyectos

Sistema interno de Abastible para gestionar y hacer seguimiento de proyectos de instalación de GLP (Gas Licuado de Petróleo): desde el ingreso del proyecto hasta el cierre, pasando por hitos de asignación, revisión, ejecución, normalización SEC y pagos.

Producción: https://abastible-gestion-proyectos.vercel.app/

## Arquitectura

**No hay build ni framework.** Es HTML + JavaScript vanilla, servido tal cual por Vercel como archivos estáticos (`vercel.json` solo define un `rewrite` de `/` hacia `Abastible_Gestion_v8.html` y una cabecera de caché). `package.json` solo existe para fijar Playwright como dependencia de desarrollo — no participa del producto.

**No hay backend propio.** El navegador habla directo con [Supabase](https://supabase.com) (Postgres + PostgREST + Realtime) usando la `anon key` pública embebida en `compartido/supabase-config.js`. No hay Edge Functions, ni Serverless Functions, ni ningún servidor intermedio. La única lógica de negocio que vive del lado servidor es la función SQL `rpc_listar_proyectos` (ver `schema.sql`), usada para paginar/filtrar la tabla principal.

```
Navegador
   │
   ├─ Abastible_Gestion_v8.html  (motor principal: tabla, dashboard, alertas, exportaciones)
   │     └─ habla directo con Supabase (supabase-js)
   │
   ├─ páginas satélite (se abren desde el motor principal, vía enlace o window.open):
   │     planilla-datos.html, panel-wp-ep.html, solicitud-envio-oc.html,
   │     solicitud-retiro-materiales.html, solicitud-retiro-tq.html,
   │     solicitud-liberar-grafo.html, anexos-d.html (+ anexo1/anexo2)
   │
   └─ compartido/  (CSS y JS reusado entre páginas: supabase-config, utils-cl, contratistas)

Supabase (proyecto "planilla maestra")
   ├─ tabla proyectos (fuente de verdad)
   ├─ tabla certificadores_por_region (catálogo)
   └─ rpc_listar_proyectos (paginado/filtrado del lado servidor)
```

Ver `manual.html` para la guía de uso de cada pantalla, pensada para el equipo que usa la app día a día (no para desarrolladores).

## Estructura del repositorio

| Archivo/carpeta | Qué es |
|---|---|
| `Abastible_Gestion_v8.html` | Motor principal: Gestión de Proyectos, Dashboard, Resumen/Alertas, Despacho de Tanques, creación/edición/cierre de proyectos, exportaciones. |
| `planilla-datos.html` | Formulario de antecedentes del cliente, con lectura automática de PDF (OCR vía Tesseract). |
| `panel-wp-ep.html` | Genera el correo de Welcome Pack / End Pack. |
| `solicitud-envio-oc.html` | Genera el correo de envío de la Orden de Compra, con lectura de PDF (pdf.js). |
| `solicitud-retiro-materiales.html` | Solicitud de Retiro de Materiales, con lectura de Detalle Comercial (PDF). |
| `solicitud-retiro-tq.html` | Solicitud de Retiro de Tanques (con flujos especiales por región). |
| `solicitud-liberar-grafo.html` | Correo de liberación de grafo. |
| `anexos-d.html`, `anexo1-suministro-provisorio.html`, `anexo2-prorroga-suministro-provisorio.html` | Documentos imprimibles de Suministro Provisorio, independientes de la base de datos. |
| `manual.html` | Manual de uso para el equipo. |
| `compartido/` | CSS y JS reusado: `supabase-config.js` (cliente Supabase), `utils-cl.js` (formato/validación de RUT y teléfono chileno, normalización de texto), `contratistas.js` (listado de contratistas), `solicitud-base.css`, `valor-sugerido.css`. |
| `schema.sql` | Documentación histórica del esquema de Supabase — registra cada cambio de tabla/policy/función a medida que se aplicó. **No pensado para re-ejecutar de punta a punta.** |
| `anexos/` | Plantillas `.dotx` y PDF de los Anexos de Suministro Provisorio. |

## Cómo correr esto localmente

No hay build. Cualquier servidor estático sirve:

```bash
python3 -m http.server 8000
# o
npx serve .
```

Y abrir `http://localhost:8000/Abastible_Gestion_v8.html`. Como no hay backend propio, se conecta directo a la base de Supabase de producción — no existe un ambiente de desarrollo/staging separado hoy.

## Base de datos

Proyecto Supabase: `aocbetucqvgxxjopjbjm` ("planilla maestra"). `schema.sql` documenta el estado real aplicado, en orden cronológico (cada sección `-- ── Stage: ... ──` es un cambio real que se aplicó en su momento). Para ver el estado actual exacto de una tabla o función, usar el MCP de Supabase o el dashboard — `schema.sql` es documentación, puede quedar levemente desactualizado respecto al último cambio si no se lo actualiza a la par.

## Seguridad — estado actual (decisión consciente, no un descuido)

Hoy la tabla `proyectos` acepta lectura y escritura desde el cliente sin autenticación (con la `anon key` pública). Es una decisión temporal mientras la app la use un grupo chico y conocido: está documentada en detalle en `schema.sql` (sección "reversión temporal y deliberada de la restricción de escritura"). Antes de sumar más usuarios sin supervisión directa, hay que implementar autenticación real (Supabase Auth, pensado para cuentas Microsoft/Azure AD @abastible.cl) y volver a acotar las policies de RLS a un rol autenticado.

## Testing

No hay tests automatizados hoy. `playwright` está como dependencia de desarrollo (se usó para grabar un video demostrativo, no para testing). Si se agrega testing a futuro, lo más valioso para esta app sería: (1) E2E con Playwright cubriendo crear/editar/cerrar un proyecto y exportar Excel/JSON, y (2) tests unitarios simples sobre las funciones puras más críticas (`hitoActual()`, `diasDesde()`, `dvRut()`/`validarRut()` en `Abastible_Gestion_v8.html`).
