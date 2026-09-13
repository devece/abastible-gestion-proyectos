-- Esquema de Abastible · Gestión de Proyectos (Supabase)
-- Estado real aplicado en el proyecto (aocbetucqvgxxjopjbjm) — documentación, no re-ejecutar tal cual
-- si la tabla ya existe (ver notas de Stage 2/3 más abajo para los próximos ALTER).

create table public.proyectos (
  id bigint generated always as identity primary key,
  item int unique, -- único real en los datos; "codigo" se repite en 8 proyectos (mismo cliente, dos etapas de negocio distintas)
  codigo text, -- NO es único
  cliente text,
  status text,
  etapa text,
  supervisor text,
  ito text,
  jefe text,
  contratista text,
  cert text,
  construccion text,
  costo numeric,
  potencia numeric,
  tanque text,
  cant_tanque int,
  region text,
  comuna text,
  tipo text,
  vendedor text,

  -- Etapa 1
  f_v_coord timestamptz,
  f_rev_ant timestamptz,
  f_visita timestamptz,
  f_liberar timestamptz,

  -- Etapa 2
  f_liberado timestamptz,
  f_ut timestamptz,
  f_oc timestamptz,
  f_trabajos timestamptz,
  f_tc8 timestamptz,
  f_montaje timestamptz,
  f_ampliacion timestamptz, -- separado de f_montaje (requerimiento #4) — falta exponerlo en la UI (Stage 2)

  -- Etapa 3: solicitudes de carga al 20%
  f_c1 timestamptz, f_c2 timestamptz, f_c3 timestamptz, f_c4 timestamptz, f_c5 timestamptz,
  f_c6 timestamptz, f_c7 timestamptz, f_c8 timestamptz, f_c9 timestamptz, f_c10 timestamptz,

  -- Etapa 4: normalización SEC
  tc2 text, sello text, tc6 text, ir text, tc7 text,

  -- Etapa 5: pagos
  pago1 text, pago2 text, pago3 text, pago4 text,

  -- Etapa 6: cierre
  f_gestor timestamptz,
  dev_ito timestamptz,
  f_forzado timestamptz,

  -- requerimiento #12 (carga manual por ahora, pendiente de exponer en la UI — Stage 3)
  reguladores_cant int,
  medidores_cant int,
  toneladas_estimadas numeric,

  -- para prellenar Welcome Pack / End Pack (panel-wp-ep.html)
  nombre_proyecto text,
  direccion text,
  rut_cliente text,
  correo_cliente text,
  correo_ito text,
  telefono_ito text,
  trabajos text,
  plazo_dias int,
  apoyo_cliente text,

  obs text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_proyectos_status on public.proyectos (status);
create index idx_proyectos_region on public.proyectos (region);
create index idx_proyectos_supervisor on public.proyectos (supervisor);

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_proyectos_updated_at
before update on public.proyectos
for each row execute function public.set_updated_at();

create table public.certificadores_por_region (
  region text primary key,
  certificador text not null,
  modo text not null -- 'solo_sello_verde' | 'normalizacion_completa' | 'contratista'
);

insert into public.certificadores_por_region (region, certificador, modo) values
  ('IV Coquimbo', 'GASTEK', 'solo_sello_verde'),
  ('V Valparaíso', 'GASSI', 'solo_sello_verde'),
  ('RM Metropolitana', 'Patricio Sandoval', 'normalizacion_completa'),
  ('VI Ohiggins', 'Contratista', 'contratista'),
  ('VII Maule', 'Contratista', 'contratista'),
  ('XVI Ñuble', 'Contratista', 'contratista'),
  ('VIII Biobío', 'Contratista', 'contratista'),
  ('X Los Lagos', 'Contratista', 'contratista'),
  ('IX Araucanía', 'Soporte Ingeniería', 'solo_sello_verde'),
  ('XIV Los Ríos', 'Soporte Ingeniería', 'solo_sello_verde');

-- RLS: sin login por ahora, acceso compartido igual que la versión anterior.
-- A propósito NO hay policy de "delete" — borrar filas requiere entrar al dashboard de Supabase,
-- para que un click accidental en la app no pueda destruir datos reales sin posibilidad de deshacerlo.
alter table public.proyectos enable row level security;
alter table public.certificadores_por_region enable row level security;

create policy "anon_select_proyectos" on public.proyectos for select using (true);
create policy "anon_insert_proyectos" on public.proyectos for insert with check (true);
create policy "anon_update_proyectos" on public.proyectos for update using (true) with check (true);

create policy "anon_select_certificadores" on public.certificadores_por_region for select using (true);

-- ── Corrección aplicada tras el CREATE TABLE inicial (constraint estaba mal puesta en "codigo") ──
-- alter table public.proyectos drop constraint proyectos_codigo_key;
-- alter table public.proyectos add constraint proyectos_item_key unique (item);

-- ── Stage: Planilla de Datos (planilla-datos.html) — campos por tipo de cliente ──
-- Comunes (reutiliza nombre_proyecto, direccion, region, comuna, obs que ya existen)
alter table public.proyectos add column if not exists pd_fecha date;
alter table public.proyectos add column if not exists pd_tipo_instalacion text; -- 'habitacional' | 'constructora' | 'comercial'
alter table public.proyectos add column if not exists pd_firma_nombre text;

-- Habitacional
alter table public.proyectos add column if not exists hab_nombre_cliente text;
alter table public.proyectos add column if not exists hab_rut text;
alter table public.proyectos add column if not exists hab_correo text;
alter table public.proyectos add column if not exists hab_telefono text;
alter table public.proyectos add column if not exists hab_contacto_obra_nombre text;
alter table public.proyectos add column if not exists hab_contacto_obra_telefono text;

-- Constructora Inmobiliaria
alter table public.proyectos add column if not exists const_razon_social text;
alter table public.proyectos add column if not exists const_rut_empresa text;
alter table public.proyectos add column if not exists const_rep_legal_nombre text;
alter table public.proyectos add column if not exists const_rep_legal_rut text;
alter table public.proyectos add column if not exists const_rep_legal_telefono text;
alter table public.proyectos add column if not exists const_rep_legal_correo text;
alter table public.proyectos add column if not exists const_contacto_obra_nombre text;
alter table public.proyectos add column if not exists const_contacto_obra_telefono text;
alter table public.proyectos add column if not exists const_contacto_obra_correo text;
alter table public.proyectos add column if not exists const_correo_facturacion text;
alter table public.proyectos add column if not exists const_cant_edificios int;
alter table public.proyectos add column if not exists const_cant_pisos int;
alter table public.proyectos add column if not exists const_cant_instalaciones int;
alter table public.proyectos add column if not exists const_anio_construccion int;
alter table public.proyectos add column if not exists const_vivienda_social text;
alter table public.proyectos add column if not exists const_conductos_colectivos text;
alter table public.proyectos add column if not exists const_cant_conductos_individuales int;
alter table public.proyectos add column if not exists const_cant_calderas int;

-- Comercial / Industrial
alter table public.proyectos add column if not exists com_razon_social text;
alter table public.proyectos add column if not exists com_rut_empresa text;
alter table public.proyectos add column if not exists com_rubro_sii text;
alter table public.proyectos add column if not exists com_rep_legal_nombre text;
alter table public.proyectos add column if not exists com_rep_legal_rut text;
alter table public.proyectos add column if not exists com_rep_legal_correo text;
alter table public.proyectos add column if not exists com_correo_facturacion text;
alter table public.proyectos add column if not exists com_fecha_fundacion date;
alter table public.proyectos add column if not exists com_tamano_empresa text;
alter table public.proyectos add column if not exists com_estacionalidad text;
alter table public.proyectos add column if not exists com_contacto_nombre text;
alter table public.proyectos add column if not exists com_contacto_telefono text;
alter table public.proyectos add column if not exists com_contacto_correo text;

-- ── Stage: campos para prellenar Welcome Pack / End Pack (correr esto en la tabla ya existente) ──
alter table public.proyectos add column if not exists nombre_proyecto text;
alter table public.proyectos add column if not exists direccion text;
alter table public.proyectos add column if not exists rut_cliente text;
alter table public.proyectos add column if not exists correo_cliente text;
alter table public.proyectos add column if not exists correo_ito text;
alter table public.proyectos add column if not exists telefono_ito text;
alter table public.proyectos add column if not exists trabajos text;
alter table public.proyectos add column if not exists plazo_dias int;
alter table public.proyectos add column if not exists apoyo_cliente text;

-- ── Stage: sincronización en vivo entre navegadores (Supabase Realtime) ──
-- habilita que la tabla transmita cambios en vivo a todos los que tengan la app abierta
alter publication supabase_realtime add table public.proyectos;

-- ── Stage: Término de Ejecución (dispara el recordatorio de End Pack) ──
alter table public.proyectos add column if not exists f_termino_ejecucion timestamptz;
alter table public.proyectos add column if not exists f_ut timestamptz;

-- ── Stage: Despacho de Tanques — ya no se cuenta por TC8, sino por envío del correo ──
-- Un tanque suma en el panel "Despacho Tanques" apenas tiene f_despacho_tq cargado,
-- sin importar el estado que tome el proyecto después (igual que Despacho de Reguladores):
-- este conteo alimenta el informe mensual para pedir la reposición, así que debe contar
-- una sola vez, al momento del envío del correo, y no desaparecer cuando el proyecto cierra.
alter table public.proyectos add column if not exists f_despacho_tq timestamptz;

-- ── Stage: Despacho de Reguladores — suma también el hito de automatización de Retiro de Materiales ──
-- Se marca sola (sin intervención manual) al generar la Solicitud de Retiro de Materiales.
-- El panel "Despacho de Reguladores" cuenta un proyecto si tiene f_tc8 O f_retiro_materiales (una sola vez si tiene ambos).
alter table public.proyectos add column if not exists f_retiro_materiales timestamptz;

-- ── Stage: guardar el/los modelos de regulador enviados en la Solicitud de Retiro de Materiales ──
-- Se completa sola (vía postMessage) cuando se genera/copia el correo en solicitud-retiro-materiales.html;
-- también editable a mano en la ficha del proyecto. Antes de esto no había ningún registro de modelo.
alter table public.proyectos add column if not exists reguladores_modelo text;

-- ── Stage: fecha propia para "Cierre de Proyecto" (cierre normal) ──
-- Antes solo quedaba una nota de texto en Observaciones; f_forzado y dev_ito ya tenían su
-- propia columna, así que este cierre quedaba sin fecha estructurada para poder medir
-- tiempo real de cierre, tasa de cierre forzado, etc. Se completa en mkCierre().
alter table public.proyectos add column if not exists f_cierre timestamptz;

-- ── Stage: teléfono del cliente editable ──
-- rut_cliente y correo_cliente ya existían (prellenar Welcome/End Pack) pero no había
-- columna de teléfono genérica ni las tres se usaban como editables: la ficha solo
-- mostraba texto plano derivado de hab_*/const_*/com_* según pd_tipo_instalacion, sin
-- ningún campo al que escribir. datosClientePD() ahora prioriza estas 3 columnas
-- genéricas y usa lo derivado solo como respaldo si están vacías.
alter table public.proyectos add column if not exists telefono_cliente text;

-- ── Stage: coordenadas GPS del proyecto ──
-- Texto libre (ej. "-35.4264, -71.6554") en vez de dos numeric separados: se completa
-- a mano o pegando un enlace/coordenada de Google Maps, no viene de ningún PDF de
-- captura automática (Detalle Comercial / Planilla de Datos no traen esta info).
alter table public.proyectos add column if not exists coordenadas text;

-- ── Stage: filtrado/orden/paginación de la tabla principal en el servidor ──
-- Antes Abastible_Gestion_v8.html traía TODOS los proyectos (select('*') sin paginar) y
-- filtraba/ordenaba/paginaba en JS sobre ese arreglo completo. Este RPC traduce a SQL la
-- cadena de prioridad de HITOS_DEF/hitoActual() del front (recorre de más tardío a más
-- temprano y devuelve el primer hito con fecha/valor cargado) para poder filtrar por
-- Etapa/Hito en el servidor, además de región/supervisor/tipo/contratista/búsqueda libre
-- y orden por cualquiera de las columnas de la tabla. Devuelve además total_count (conteo
-- exacto ya filtrado) para la paginación real con .range()/offset-limit.
-- Verificado 1:1 contra hitoActual()/HITO_BY_ID del front con los 120 proyectos reales
-- (0 discrepancias) antes de conectarlo a la UI.
-- BD (dataset completo) se sigue trayendo igual que antes — lo siguen necesitando
-- Dashboard, Resumen/Alertas, Despacho Tanques y la edición de proyectos por _id — este
-- RPC solo reemplaza cómo se alimenta la tabla de Gestión de Proyectos.
create or replace function public.rpc_listar_proyectos(
  p_q text default null,
  p_region text default null,
  p_supervisor text default null,
  p_tipo text default null,
  p_contratista text default null,
  p_etapa int default null,
  p_hito text default null,
  p_orden_col text default 'item',
  p_orden_asc boolean default true,
  p_offset int default 0,
  p_limit int default 25
)
returns table (
  id bigint, item int, codigo text, cliente text, nombre_proyecto text, direccion text,
  region text, comuna text, status text, supervisor text, ito text, jefe text,
  contratista text, vendedor text, tipo text,
  f_v_validar timestamptz, f_v_respondido timestamptz, f_v_coord timestamptz, f_rev_ant timestamptz,
  f_visita timestamptz, f_liberar timestamptz, f_liberado timestamptz, f_ut timestamptz,
  f_pedir_grafo timestamptz, f_oc timestamptz, f_trabajos timestamptz, f_despacho_tq timestamptz,
  f_retiro_materiales timestamptz, f_tc8 timestamptz, f_montaje timestamptz, f_ampliacion timestamptz,
  f_c1 timestamptz, f_c2 timestamptz, f_c3 timestamptz, f_c4 timestamptz, f_c5 timestamptz,
  f_c6 timestamptz, f_c7 timestamptz, f_c8 timestamptz, f_c9 timestamptz, f_c10 timestamptz,
  tc2 text, sello text, tc6 text, ir text, tc7 text,
  pago1 text, pago2 text, pago3 text, pago4 text,
  f_termino_ejecucion timestamptz, f_gestor timestamptz, f_forzado timestamptz,
  hito_actual text, etapa_actual int,
  total_count bigint
)
language plpgsql
stable
as $$
declare
  v_q text;
  v_orden_col text;
  v_dir text;
  v_order_clause text;
  v_sql text;
begin
  v_q := case when p_q is null or p_q='' then null
    else replace(replace(replace(p_q,'\','\\'),'%','\%'),'_','\_') end;

  v_orden_col := case p_orden_col
    when 'item' then 'item'
    when 'codigo' then 'codigo'
    when 'cliente' then 'cliente'
    when 'nombre_proyecto' then 'nombre_proyecto'
    when 'region' then 'region'
    when 'status' then 'status'
    when 'supervisor' then 'supervisor'
    when 'contratista' then 'contratista'
    when '_d' then 'dias'
    else 'item'
  end;

  v_dir := case when p_orden_asc then 'asc' else 'desc' end;

  if v_orden_col in ('item','dias') then
    v_order_clause := format('f.%I %s nulls last', v_orden_col, v_dir);
  else
    v_order_clause := format('lower(coalesce(f.%I, %L)) %s', v_orden_col, '', v_dir);
  end if;

  v_sql := format($f$
    with base as (
      select p.*,
        case
          when p.f_forzado is not null or p.status = '8. Cierre Forzado' then 'cierre_forzado'
          when p.status = '7. Cierre Proyecto' then 'pasado_post_venta'
          when p.f_gestor is not null then 'envio_gestor_documental'
          when p.f_termino_ejecucion is not null then 'termino_trabajos'
          when p.pago4 = 'OK' then 'pago_4'
          when p.pago3 = 'OK' then 'pago_3'
          when p.pago2 = 'OK' then 'pago_2'
          when p.pago1 = 'OK' then 'pago_1'
          when p.tc7 = 'OK' then 'tc5_tc7_otros'
          when p.ir = 'OK' then 'ir'
          when p.tc6 = 'OK' then 'tc6'
          when p.sello = 'OK' then 'sello_verde'
          when p.tc2 = 'OK' then 'tc2'
          when p.f_c10 is not null then 'carga_10'
          when p.f_c9 is not null then 'carga_9'
          when p.f_c8 is not null then 'carga_8'
          when p.f_c7 is not null then 'carga_7'
          when p.f_c6 is not null then 'carga_6'
          when p.f_c5 is not null then 'carga_5'
          when p.f_c4 is not null then 'carga_4'
          when p.f_c3 is not null then 'carga_3'
          when p.f_c2 is not null then 'carga_2'
          when p.f_c1 is not null then 'carga_1'
          when p.f_ampliacion is not null then 'ampliar_cliente'
          when p.f_montaje is not null then 'montaje_tk'
          when p.f_retiro_materiales is not null then 'retiro_materiales'
          when p.f_tc8 is not null then 'envio_tc8'
          when p.f_despacho_tq is not null then 'despacho_tq_equipos'
          when p.f_trabajos is not null then 'inicio_trabajos'
          when p.f_oc is not null then 'envio_oc'
          when p.f_pedir_grafo is not null then 'pedir_liberar_grafo'
          when p.f_ut is not null then 'crear_ut'
          when p.f_liberado is not null then 'liberado'
          when p.f_liberar is not null then 'envio_a_liberar'
          when p.f_visita is not null then 'visita_previa'
          when p.f_rev_ant is not null then 'revision'
          when p.f_v_coord is not null then 'asignacion'
          when p.f_v_respondido is not null then 'validacion'
          else 'ingreso'
        end as hito_actual,
        (current_date - (coalesce(p.f_liberado, p.f_v_coord, p.f_v_validar))::date) as dias
      from public.proyectos p
    ), base2 as (
      select b.*,
        case
          when b.hito_actual in ('revision','visita_previa','envio_a_liberar') then 1
          when b.hito_actual in ('termino_trabajos','envio_gestor_documental','pasado_post_venta','cierre_forzado') then 3
          when b.hito_actual in ('ingreso','validacion','asignacion') then 0
          else 2
        end as etapa_actual
      from base b
    ), filtrado as (
      select *
      from base2 b
      where
        ($1::text is null or (
          b.codigo ilike '%%'||$1||'%%' escape '\' or
          b.cliente ilike '%%'||$1||'%%' escape '\' or
          b.nombre_proyecto ilike '%%'||$1||'%%' escape '\' or
          b.direccion ilike '%%'||$1||'%%' escape '\' or
          b.region ilike '%%'||$1||'%%' escape '\' or
          b.contratista ilike '%%'||$1||'%%' escape '\' or
          b.ito ilike '%%'||$1||'%%' escape '\' or
          b.supervisor ilike '%%'||$1||'%%' escape '\' or
          b.vendedor ilike '%%'||$1||'%%' escape '\' or
          b.comuna ilike '%%'||$1||'%%' escape '\' or
          b.tipo ilike '%%'||$1||'%%' escape '\' or
          b.jefe ilike '%%'||$1||'%%' escape '\' or
          b.item::text ilike '%%'||$1||'%%' escape '\'
        ))
        and ($2::text is null or $2='' or b.region = $2)
        and ($3::text is null or $3='' or b.supervisor = $3)
        and ($4::text is null or $4='' or b.tipo = $4)
        and ($5::text is null or $5='' or b.contratista = $5)
        and (
          ($6::text is not null and $6<>'' and b.hito_actual = $6)
          or (
            ($6::text is null or $6='') and
            ($7::int is null or b.etapa_actual = $7)
          )
        )
    )
    select
      f.id, f.item, f.codigo, f.cliente, f.nombre_proyecto, f.direccion,
      f.region, f.comuna, f.status, f.supervisor, f.ito, f.jefe,
      f.contratista, f.vendedor, f.tipo,
      f.f_v_validar, f.f_v_respondido, f.f_v_coord, f.f_rev_ant,
      f.f_visita, f.f_liberar, f.f_liberado, f.f_ut,
      f.f_pedir_grafo, f.f_oc, f.f_trabajos, f.f_despacho_tq,
      f.f_retiro_materiales, f.f_tc8, f.f_montaje, f.f_ampliacion,
      f.f_c1, f.f_c2, f.f_c3, f.f_c4, f.f_c5,
      f.f_c6, f.f_c7, f.f_c8, f.f_c9, f.f_c10,
      f.tc2, f.sello, f.tc6, f.ir, f.tc7,
      f.pago1, f.pago2, f.pago3, f.pago4,
      f.f_termino_ejecucion, f.f_gestor, f.f_forzado,
      f.hito_actual, f.etapa_actual,
      count(*) over() as total_count
    from filtrado f
    order by %s
    offset $8 limit $9
  $f$, v_order_clause);

  return query execute v_sql using v_q, p_region, p_supervisor, p_tipo, p_contratista, p_hito, p_etapa, p_offset, p_limit;
end;
$$;

grant execute on function public.rpc_listar_proyectos(text,text,text,text,text,int,text,text,boolean,int,int) to anon, authenticated;
