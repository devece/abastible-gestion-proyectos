#!/usr/bin/env node
// Verificación de consistencia de rpc_listar_proyectos (NEG-001/DEU-003, auditoría 2026).
//
// La app tiene 3 formas de derivar "en qué hito/etapa está un proyecto":
//   1. autoStatus() en Abastible_Gestion_v8.html — el status grueso que se guarda en la BD.
//   2. HITOS_DEF/hitoActual() en el mismo archivo — espejo cliente del cálculo de hito_actual
//      del RPC, usado por Dashboard/Resumen/Tanques/Reguladores (que leen el dataset completo).
//   3. CADENA_HITOS/proximoHitoPos() — espejo cliente del cálculo de "Próximo Hito" del RPC.
//
// El servidor (rpc_listar_proyectos, ver schema.sql) ya unifica el cálculo de hito_actual,
// etapa_actual y próximo hito en una sola función. Se decidió NO fusionar las 3 formas del
// cliente con la del servidor (es lógica de negocio sensible, el refactor sería grande y
// riesgoso para una ganancia solo estética) — en su lugar, este script reimplementa la MISMA
// especificación documentada de forma independiente y la compara contra lo que el RPC
// devuelve realmente hoy, para detectar automáticamente cualquier desincronización futura
// (por ejemplo, si se agrega un hito nuevo y se actualiza un lado pero no el otro).
//
// Uso:
//   npm run verificar-hitos
// Sale con código 0 si todo coincide, código 1 (y el detalle de cada diferencia) si no.

const { createClient } = require('@supabase/supabase-js');

// Mismas credenciales públicas que usa la app (compartido/supabase-config.js) — son de
// solo lectura para este script (solo se hace .select(), nunca insert/update/delete).
const SUPABASE_URL = 'https://aocbetucqvgxxjopjbjm.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvY2JldHVjcXZneHhqb3BqYmptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxMzI1ODEsImV4cCI6MjEwMTcwODU4MX0.QfsInd_7iyeUHInGEMMSzLUh_FILaG4QPVn9pC8RByI';

// ── Especificación documentada de hito_actual (de más tardío a más temprano) ──
// Copiada de la prioridad real del CASE WHEN de rpc_listar_proyectos (schema.sql).
// Si el RPC cambia este orden sin que se actualice acá (o viceversa en HITOS_DEF del
// archivo principal), este script lo detecta.
function calcularHitoActual(p) {
  if (p.f_forzado || p.status === '8. Cierre Forzado') return 'cierre_forzado';
  if (p.status === '7. Cierre Proyecto') return 'pasado_post_venta';
  if (p.f_gestor) return 'envio_gestor_documental';
  if (p.f_termino_ejecucion) return 'termino_trabajos';
  if (p.pago4 != null) return 'pago_4';
  if (p.pago3 != null) return 'pago_3';
  if (p.pago2 != null) return 'pago_2';
  if (p.pago1 != null) return 'pago_1';
  if (p.tc7 === 'OK') return 'tc5_tc7_otros';
  if (p.ir === 'OK') return 'ir';
  if (p.tc6 === 'OK') return 'tc6';
  if (p.sello === 'OK') return 'sello_verde';
  if (p.tc2 === 'OK') return 'tc2';
  if (p.f_c10) return 'carga_10';
  if (p.f_c9) return 'carga_9';
  if (p.f_c8) return 'carga_8';
  if (p.f_c7) return 'carga_7';
  if (p.f_c6) return 'carga_6';
  if (p.f_c5) return 'carga_5';
  if (p.f_c4) return 'carga_4';
  if (p.f_c3) return 'carga_3';
  if (p.f_c2) return 'carga_2';
  if (p.f_c1) return 'carga_1';
  if (p.f_ampliacion) return 'ampliar_cliente';
  if (p.f_montaje) return 'montaje_tk';
  if (p.f_retiro_materiales) return 'retiro_materiales';
  if (p.f_tc8) return 'envio_tc8';
  if (p.f_despacho_tq) return 'despacho_tq_equipos';
  if (p.f_trabajos) return 'inicio_trabajos';
  if (p.f_oc) return 'envio_oc';
  if (p.f_pedir_grafo) return 'pedir_liberar_grafo';
  if (p.f_ut) return 'crear_ut';
  if (p.f_liberado) return 'liberado';
  if (p.f_liberar) return 'envio_a_liberar';
  if (p.f_visita) return 'visita_previa';
  if (p.f_v_coord) return 'asignacion';
  if (p.f_rev_ant) return 'revision';
  if (p.f_v_respondido) return 'validacion';
  if (p.f_v_prevalidacion) return 'primera_validacion';
  return 'ingreso';
}

// etapa_actual: agrupación VISUAL (reunión 2026-09 — Vende/Construye), no la cadena de
// secuencia (CADENA_HITOS, más abajo, a propósito sin cambios). 'asignacion' y 'liberado'
// pasan a la etapa 1 (Construye), 'primera_validacion' se agrega a la etapa 0 (Vende).
function calcularEtapaActual(hitoActual) {
  if (['revision', 'asignacion', 'visita_previa', 'envio_a_liberar', 'liberado'].includes(hitoActual)) return 1;
  if (['termino_trabajos', 'envio_gestor_documental', 'pasado_post_venta', 'cierre_forzado'].includes(hitoActual)) return 3;
  if (['ingreso', 'primera_validacion', 'validacion'].includes(hitoActual)) return 0;
  return 2;
}

// ── CADENA_HITOS: misma lista y orden documentados para "Próximo Hito" ──
const CADENA_HITOS = [
  'f_v_validar', 'f_v_respondido', 'f_rev_ant', 'f_v_coord', 'f_visita',
  'f_liberar', 'f_liberado', 'f_ut', 'f_pedir_grafo', 'f_oc',
  'f_trabajos', 'f_despacho_tq', 'f_tc8', 'f_montaje', 'f_ampliacion',
  'f_termino_ejecucion', 'f_gestor',
];

function calcularProximoHito(p) {
  const hitosNa = Array.isArray(p.hitos_na) ? p.hitos_na : [];
  let ultimoPos = -1;
  CADENA_HITOS.forEach((key, pos) => {
    if (p[key] != null) ultimoPos = Math.max(ultimoPos, pos);
  });
  for (let pos = ultimoPos + 1; pos < CADENA_HITOS.length; pos++) {
    const key = CADENA_HITOS[pos];
    if (!hitosNa.includes(key)) return { proximo_hito_key: key, proximo_hito_pos: pos };
  }
  return { proximo_hito_key: null, proximo_hito_pos: null };
}

async function main() {
  const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  console.log('Trayendo dataset crudo (select *) y salida del RPC...');
  const [{ data: crudos, error: errCrudos }, { data: viaRpc, error: errRpc }] = await Promise.all([
    sb.from('proyectos').select('*'),
    sb.rpc('rpc_listar_proyectos', { p_limit: 100000 }),
  ]);

  if (errCrudos) { console.error('Error trayendo proyectos:', errCrudos); process.exit(2); }
  if (errRpc) { console.error('Error llamando rpc_listar_proyectos:', errRpc); process.exit(2); }

  const rpcPorId = new Map(viaRpc.map((r) => [r.id, r]));
  let discrepancias = [];

  for (const p of crudos) {
    const esperadoHito = calcularHitoActual(p);
    const esperadoEtapa = calcularEtapaActual(esperadoHito);
    const { proximo_hito_key: esperadoProxKey, proximo_hito_pos: esperadoProxPos } = calcularProximoHito(p);

    const real = rpcPorId.get(p.id);
    if (!real) {
      discrepancias.push({ item: p.item, id: p.id, motivo: 'El proyecto no aparece en la salida del RPC (¿filtro por defecto cambió?)' });
      continue;
    }

    if (real.hito_actual !== esperadoHito) {
      discrepancias.push({ item: p.item, id: p.id, campo: 'hito_actual', rpc: real.hito_actual, esperado: esperadoHito });
    }
    if (real.etapa_actual !== esperadoEtapa) {
      discrepancias.push({ item: p.item, id: p.id, campo: 'etapa_actual', rpc: real.etapa_actual, esperado: esperadoEtapa });
    }
    if ((real.proximo_hito_key ?? null) !== esperadoProxKey) {
      discrepancias.push({ item: p.item, id: p.id, campo: 'proximo_hito_key', rpc: real.proximo_hito_key, esperado: esperadoProxKey });
    }
    if ((real.proximo_hito_pos ?? null) !== esperadoProxPos) {
      discrepancias.push({ item: p.item, id: p.id, campo: 'proximo_hito_pos', rpc: real.proximo_hito_pos, esperado: esperadoProxPos });
    }
  }

  console.log(`Proyectos verificados: ${crudos.length}`);
  if (discrepancias.length === 0) {
    console.log('✅ Sin discrepancias — el RPC coincide con la especificación documentada para los 4 campos derivados, en todos los proyectos reales.');
    process.exit(0);
  } else {
    console.error(`❌ ${discrepancias.length} discrepancia(s) encontrada(s):`);
    discrepancias.slice(0, 50).forEach((d) => console.error(JSON.stringify(d)));
    if (discrepancias.length > 50) console.error(`... y ${discrepancias.length - 50} más.`);
    process.exit(1);
  }
}

if (require.main === module) {
  main().catch((e) => { console.error('Error inesperado:', e); process.exit(2); });
}

module.exports = { calcularHitoActual, calcularEtapaActual, calcularProximoHito, CADENA_HITOS };
