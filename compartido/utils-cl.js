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
