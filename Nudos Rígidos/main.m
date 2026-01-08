clc;
clear all;

% Abrir archivo para guardar resultados
output_file = 'output_resultados.txt';
fid = fopen(output_file, 'w');

fprintf(fid, '==========================================================\n');
fprintf(fid, '   ANÁLISIS ESTRUCTURAL - NUDOS RÍGIDOS\n');
fprintf(fid, '   Fecha: %s\n', datestr(now, 'dd/mm/yyyy HH:MM:SS'));
fprintf(fid, '==========================================================\n\n');

disp('==========================================================');
disp('   ANÁLISIS ESTRUCTURAL - NUDOS RÍGIDOS');
disp('==========================================================');
disp(' ');

%% Paso 1: Lectura de input
disp('Paso 1: Lectura de input...');
fprintf(fid, 'Paso 1: Lectura de input\n');
fprintf(fid, '   Estado: Completado\n\n');

%% Paso 2: Preprocesamiento
disp('Paso 2: Preprocesamiento...');
fprintf(fid, 'Paso 2: Preprocesamiento\n');
preprocessor("estructura.txt", fid);
fprintf(fid, '   Estado: Completado\n\n');

%% Paso 3: Procesamiento
disp('Paso 3: Procesamiento...');
fprintf(fid, 'Paso 3: Procesamiento\n');
processor(fid);
fprintf(fid, '   Estado: Completado\n\n');

%% Paso 4: Postprocesamiento
disp('Paso 4: Postprocesamiento...');
fprintf(fid, 'Paso 4: Postprocesamiento\n');
postprocessor(fid);
fprintf(fid, '   Estado: Completado\n\n');

fprintf(fid, '==========================================================\n');
fprintf(fid, '   SIMULACIÓN COMPLETADA CORRECTAMENTE\n');
fprintf(fid, '==========================================================\n');

fclose(fid);

disp(' ');
disp('==========================================================');
disp('   SIMULACIÓN COMPLETADA CORRECTAMENTE');
disp('==========================================================');
disp(['Resultados guardados en: ', output_file]);
