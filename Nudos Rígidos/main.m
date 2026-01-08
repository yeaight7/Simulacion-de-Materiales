clc;
clear all;

% Abrir archivo para guardar resultados
output_file = 'output_resultados.txt';
fid = fopen(output_file, 'w');

fprintf(fid, '==========================================================\n');
fprintf(fid, '   ANÁLISIS ESTRUCTURAL - NUDOS RÍGIDOS\n');
fprintf(fid, '   Fecha: %s\n', datestr(now, 'dd/mm/yyyy HH:MM:SS'));
fprintf(fid, '==========================================================\n\n');

%% Paso 1 y 2: Lectura de input y Preprocesamiento
disp('--- Paso 1: Lectura de input ---');
fprintf(fid, '--- Paso 1: Lectura de input ---\n');
disp('Lectura de input completada');
fprintf(fid, 'Lectura de input completada\n\n');

disp('--- Paso 2: Preprocesamiento ---');
fprintf(fid, '--- Paso 2: Preprocesamiento ---\n');
preprocessor("estructura.txt", fid);
disp('Preprocesamiento completado');
fprintf(fid, 'Preprocesamiento completado\n\n');

%% Paso 3: Procesamiento
disp('--- Paso 3: Procesamiento ---');
fprintf(fid, '--- Paso 3: Procesamiento ---\n');
processor(fid);
disp('Procesamiento completado');
fprintf(fid, 'Procesamiento completado\n\n');

%% Paso 4: Postprocesamiento
disp('--- Paso 4: Postprocesamiento ---');
fprintf(fid, '--- Paso 4: Postprocesamiento ---\n');
postprocessor(fid);
disp('Postprocesamiento completado');
fprintf(fid, 'Postprocesamiento completado\n\n');

fprintf(fid, '==========================================================\n');
fprintf(fid, '   SIMULACIÓN COMPLETADA CORRECTAMENTE\n');
fprintf(fid, '==========================================================\n');

fclose(fid);

disp('--- Simulación completada correctamente ---');
disp(['Resultados guardados en: ', output_file]);
