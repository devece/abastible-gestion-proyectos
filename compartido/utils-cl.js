// ─── RUT chileno (puntos de miles + guión) ────────────────────────────────
// Compartido por: panel-wp-ep.html, anexo2-prorroga-suministro-provisorio.html.
// (No reemplaza el formatearRut()/validarRut()/dvRut() de Abastible_Gestion_v8.html,
// que además valida el dígito verificador — es una función distinta, no una copia
// de esta; planilla-datos.html tampoco usa esta versión: su formatearRUT() se
// auto-conecta a los inputs con clase .rut, un mecanismo distinto e intencional.)
function formatearRutCL(v){
  const limpio = String(v||'').replace(/[^0-9kK]/g,'').toUpperCase();
  if(limpio.length < 2) return limpio;
  const cuerpo = limpio.slice(0,-1).replace(/\B(?=(\d{3})+(?!\d))/g,'.');
  return cuerpo + '-' + limpio.slice(-1);
}
// Valida el dígito verificador (módulo 11) — mismo algoritmo que dvRut()/validarRut()
// de Abastible_Gestion_v8.html, centralizado acá para no reimplementarlo de nuevo
// en cada página que agregue una validación de RUT (auditoría UX-002).
function validarRutCL(v){
  const limpio = String(v||'').replace(/[^0-9kK]/g,'').toUpperCase();
  if(!/^\d{6,8}[0-9K]$/.test(limpio)) return false;
  const cuerpo = limpio.slice(0,-1);
  let suma = 0, multiplo = 2;
  for(let i=cuerpo.length-1;i>=0;i--){
    suma += parseInt(cuerpo.charAt(i),10)*multiplo;
    multiplo = multiplo===7?2:multiplo+1;
  }
  const resto = 11 - (suma % 11);
  const dv = resto===11?'0':resto===10?'K':String(resto);
  return dv === limpio.slice(-1);
}
// ─── Normalización de texto para comparar/buscar (sin tildes, minúsculas, solo alfanumérico) ──
// Compartido por: solicitud-envio-oc.html, solicitud-retiro-materiales.html,
// solicitud-retiro-tq.html, solicitud-liberar-grafo.html (auditoría DEU-001:
// antes esta misma función estaba duplicada en los 4 archivos).
function normaliza(s){
  return (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g,'').replace(/[^a-z0-9]/g,'');
}
// ─── Teléfono chileno (+56 9 1234 5678) ───────────────────────────────────
// Compartido por: panel-wp-ep.html, Abastible_Gestion_v8.html.
function formatearTelefonoCL(valor){
  let numeros = String(valor||'').replace(/\D/g,'');
  if(numeros.startsWith('56')) numeros = numeros.slice(2);
  numeros = numeros.slice(0,9);
  let resultado = '+56 ';
  if(numeros.length > 0) resultado += numeros[0] + ' ';
  if(numeros.length > 1) resultado += numeros.slice(1,5);
  if(numeros.length > 5) resultado += ' ' + numeros.slice(5,9);
  return resultado.trim();
}

// Este archivo se carga como <script> plano en el navegador (por eso las
// funciones de arriba son globales, no exports de módulo). Este bloque solo
// las expone también vía require() para los scripts de Node en tests/
// (verifica-integridad-datos.js) — "typeof module" es undefined en el
// navegador, así que ahí este bloque no hace nada.
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { formatearRutCL, validarRutCL, normaliza, formatearTelefonoCL };
}
