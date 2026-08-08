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
