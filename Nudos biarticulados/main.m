clc;
clear all;

%% Paso 1 y 2: Lectura de input y Preprocesamiento
disp('--- Paso 1: Lectura de input ---');
disp('Lectura de input completada');
disp(' ');

disp('--- Paso 2: Preprocesamiento ---');
preprocessor("estructura.txt");
disp('Preprocesamiento completado');
disp(' ');

%% Paso 3: Procesamiento
disp('--- Paso 3: Procesamiento ---');
processor;
disp('Procesamiento completado');
disp(' ');

%% Paso 4: Postprocesamiento
disp('--- Paso 4: Postprocesamiento ---');
postprocessor;
disp('Postprocesamiento completado');
disp(' ');

disp('--- Simulación completada correctamente ---');
