-- Esquema de "Mis Proyectos" (gestion-contratista.html), en el mismo proyecto Supabase
-- (aocbetucqvgxxjopjbjm, "planilla maestra") pero en tablas propias, sin relación
-- ni join con public.proyectos / la app de Gestión de Proyectos.
-- Estado real ya aplicado en el proyecto — documentación, no re-ejecutar tal cual.

create table public.contratista_proyectos (
  id bigint generated always as identity primary key,
  contratista text not null, -- identificación simple (nombre/empresa que ingresó, sin login real)
  nombre text not null,
  cliente text,
  direccion text,
  comuna text,
  region text,
  obs text,

  -- notificaciones automáticas: por ahora solo se guarda la configuración;
  -- el envío real se define más adelante (p.ej. Edge Function + proveedor de correo)
  notif_activa boolean not null default false,
  notif_email text,

  -- hitos recomendados del proceso, en orden
  f_visita timestamptz,          -- Visita técnica / levantamiento en terreno
  f_cotizacion timestamptz,      -- Cotización enviada
  f_adjudicado timestamptz,      -- Trabajo adjudicado (OC o contrato recibido)
  f_materiales timestamptz,      -- Compra de materiales
  f_inicio_montaje timestamptz,
  f_fin_montaje timestamptz,
  f_pruebas timestamptz,         -- Pruebas de hermeticidad
  f_certificacion timestamptz,   -- Certificación SEC
  f_entrega timestamptz,         -- Entrega y cierre (acta de recepción / pago)

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_contratista_proyectos_contratista on public.contratista_proyectos (contratista);

-- reutiliza la función public.set_updated_at() ya creada para public.proyectos
create trigger trg_contratista_proyectos_updated_at
before update on public.contratista_proyectos
for each row execute function public.set_updated_at();

alter table public.contratista_proyectos enable row level security;
create policy "anon_select_contratista_proyectos" on public.contratista_proyectos for select using (true);
create policy "anon_insert_contratista_proyectos" on public.contratista_proyectos for insert with check (true);
create policy "anon_update_contratista_proyectos" on public.contratista_proyectos for update using (true) with check (true);
create policy "anon_delete_contratista_proyectos" on public.contratista_proyectos for delete using (true);
-- a diferencia de "proyectos", aquí SÍ hay policy de delete: son proyectos propios
-- del contratista (bajo riesgo), y la app pide confirmación antes de borrar.

alter publication supabase_realtime add table public.contratista_proyectos;

-- Cola de notificaciones: se llena al marcar un hito con notificación activada.
-- El envío real (SMTP/proveedor) se conecta después, procesando estado='pendiente'.
create table public.contratista_notif_cola (
  id bigint generated always as identity primary key,
  proyecto_id bigint not null references public.contratista_proyectos(id) on delete cascade,
  hito text not null,
  destinatario text,
  asunto text,
  mensaje text,
  estado text not null default 'pendiente',
  created_at timestamptz not null default now()
);

alter table public.contratista_notif_cola enable row level security;
create policy "anon_select_contratista_notif_cola" on public.contratista_notif_cola for select using (true);
create policy "anon_insert_contratista_notif_cola" on public.contratista_notif_cola for insert with check (true);
