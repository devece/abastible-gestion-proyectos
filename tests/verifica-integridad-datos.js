#!/usr/bin/env node
// Detección automática de inconsistencias de datos (Fase 6 de la auditoría 2026).
//
// Automatiza los mismos chequeos que se hicieron a mano durante la auditoría
// (ver DAT-001/DAT-002 en el informe): fechas de hitos fuera de orden y RUT sin
// dígito verificador válido. Antes había que acordarse de correr estas consultas
// SQL a mano; ahora se puede correr en cualquier momento con `npm run
// verificar-datos`, y es lo que usa la Rutina semanal de alertas por correo.
//
// No modifica nada — es 100% de solo lectura (select).
//
// Uso:
//   npm run verificar-datos
// Sale con código 0 si no encuentra nada, código 1 si encuentra inconsistencias
// (y las imprime), código 2 si hubo un error de conexión/consulta.

const { createClient } = require('@supabase/supabase-js');
const { validarRutCL } = require('../compartido/utils-cl.js');

const SUPABASE_URL = 'https://aocbetucqvgxxjopjbjm.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvY2JldHVjcXZneHhqb3BqYmptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxMzI1ODEsImV4cCI6MjEwMTcwODU4MX0.QfsInd_7iyeUHInGEMMSzLUh_FILaG4QPVn9pC8RByI';

// Pares [hito anterior, hito posterior] que deben respetar ese orden cronológico.
// Mismos 3 pares verificados a mano en la auditoría (DAT-001).
const PARES_ORDEN = [
  ['f_v_coord', 'f_liberado', 'Asignación', 'Liberado'],
  ['f_oc', 'f_trabajos', 'Envío O.C.', 'Inicio Trabajos'],
  ['f_trabajos', 'f_termino_ejecucion', 'Inicio Trabajos', 'Término Ejecución'],
];

// Campos de RUT a validar (dígito verificador), y de qué sección de Planilla de
// Datos vienen — para armar un mensaje que le sirva a quien lo lea sin tener que
// adivinar dónde corregir.
const CAMPOS_RUT = [
  ['rut_cliente', 'RUT Cliente (ficha del proyecto)'],
  ['hab_rut', 'RUT (Habitacional)'],
  ['const_rut_empresa', 'RUT Empresa (Constructora)'],
  ['const_rep_legal_rut', 'RUT Representante Legal (Constructora)'],
  ['com_rut_empresa', 'RUT Empresa (Comercial)'],
  ['com_rep_legal_rut', 'RUT Representante (Comercial)'],
];

async function verificar() {
  const sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  const { data: proyectos, error } = await sb.from('proyectos').select('*');
  if (error) { console.error('Error trayendo proyectos:', error); process.exit(2); }

  const fechasFueraDeOrden = [];
  for (const p of proyectos) {
    for (const [antes, despues, labelAntes, labelDespues] of PARES_ORDEN) {
      if (p[antes] && p[despues] && new Date(p[despues]) < new Date(p[antes])) {
        fechasFueraDeOrden.push({
          item: p.item, codigo: p.codigo, cliente: p.cliente,
          problema: `${labelDespues} (${p[despues]}) es anterior a ${labelAntes} (${p[antes]})`,
        });
      }
    }
  }

  const rutInvalidos = [];
  for (const p of proyectos) {
    for (const [campo, label] of CAMPOS_RUT) {
      const val = p[campo];
      if (val && !validarRutCL(val)) {
        rutInvalidos.push({ item: p.item, codigo: p.codigo, cliente: p.cliente, campo: label, valor: val });
      }
    }
  }

  const sinNombre = proyectos.filter((p) => !p.nombre_proyecto || !String(p.nombre_proyecto).trim());

  return { total: proyectos.length, fechasFueraDeOrden, rutInvalidos, sinNombre };
}

function imprimirReporte(r) {
  console.log(`Proyectos verificados: ${r.total}`);
  console.log(`- Fechas de hitos fuera de orden: ${r.fechasFueraDeOrden.length}`);
  r.fechasFueraDeOrden.forEach((d) => console.log(`  · Ítem ${d.item} (${d.codigo}, ${d.cliente}): ${d.problema}`));
  console.log(`- RUT sin dígito verificador válido: ${r.rutInvalidos.length}`);
  r.rutInvalidos.forEach((d) => console.log(`  · Ítem ${d.item} (${d.codigo}, ${d.cliente}): ${d.campo} = "${d.valor}"`));
  console.log(`- Proyectos sin nombre (informativo, no bloqueante): ${r.sinNombre.length}`);
}

if (require.main === module) {
  verificar().then((r) => {
    imprimirReporte(r);
    const hayProblemas = r.fechasFueraDeOrden.length > 0 || r.rutInvalidos.length > 0;
    process.exit(hayProblemas ? 1 : 0);
  }).catch((e) => { console.error('Error inesperado:', e); process.exit(2); });
}

module.exports = { verificar, PARES_ORDEN, CAMPOS_RUT };
