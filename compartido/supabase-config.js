// Inicialización del cliente de Supabase — compartida por Abastible_Gestion_v8.html
// y planilla-datos.html (las únicas 2 páginas que hablan directo con Supabase).
// Requiere que el <script> del SDK de supabase-js (pineado a una versión exacta,
// ver PR #72) ya se haya cargado ANTES de este archivo.
var SUPABASE_URL='https://aocbetucqvgxxjopjbjm.supabase.co';
var SUPABASE_ANON_KEY='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvY2JldHVjcXZneHhqb3BqYmptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYxMzI1ODEsImV4cCI6MjEwMTcwODU4MX0.QfsInd_7iyeUHInGEMMSzLUh_FILaG4QPVn9pC8RByI';
var sb=supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
