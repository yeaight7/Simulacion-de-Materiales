function processor(fid)    
    load('preprocessing_data.mat', 'S', 'PROB');
    
    % Número de nodos y elementos
    n_nodos = size(PROB.nodos, 1);
    n_elementos = size(PROB.miembros, 1);
    
    % Inicialización de vectores y matrices
    d = zeros(2 * n_nodos, 1); % Vector de desplazamientos
    p = zeros(2 * n_nodos, 1); % Vector de fuerzas nodales
    tensiones = zeros(1, n_elementos); % Tensiones en los elementos
    barras_fallidas = []; % Barras que fallan
    
    % Ensamblar vector de fuerzas nodales (p)
    for i = 1:size(PROB.cargas, 1)
        nodo = PROB.cargas(i, 1);
        gdl_x = 2 * nodo - 1; % Grado de libertad en X
        gdl_y = 2 * nodo;     % Grado de libertad en Y
        p(gdl_x) = PROB.cargas(i, 2);
        p(gdl_y) = PROB.cargas(i, 3);
    end
    
    % Identificar los grados de libertad con desplazamientos prescritos
    ind_p = unique([2 * PROB.soportes(:, 1) - 1; 2 * PROB.soportes(:, 1)]); % Grados de libertad restringidos
    dp = zeros(length(ind_p), 1); % Desplazamientos prescritos (cero en los apoyos)
    
    % Identificar los grados de libertad libres
    ind_d = setdiff(1:2 * n_nodos, ind_p); % Grados de libertad libres
    
    % Submatrices del sistema de ecuaciones
    Spp = S(ind_p, ind_p);
    Spd = S(ind_p, ind_d);
    Sdp = S(ind_d, ind_p);
    Sdd = S(ind_d, ind_d);
    
    pp = p(ind_p); % Fuerzas en grados de libertad restringidos
    pd = p(ind_d); % Fuerzas en grados de libertad libres
    
    % Resolver sistema de ecuaciones para desplazamientos libres
    dd = Sdd \ (pd - Sdp * dp);
    
    % Actualizar vector de desplazamientos
    d(ind_p) = dp; % Desplazamientos prescritos
    d(ind_d) = dd; % Desplazamientos libres calculados
    
    % Calcular tensiones y verificar fallas
    for ele = 1:n_elementos
        nodo1 = PROB.miembros(ele, 1);
        nodo2 = PROB.miembros(ele, 2);
        tipo_material = PROB.miembros(ele, 3);
        tipo_seccion = PROB.miembros(ele, 4);
    
        % Propiedades del material y la sección
        E = PROB.material(tipo_material);  % Módulo de Young
        A = PROB.seccion(tipo_seccion);    % Área
    
        % Coordenadas de los nodos
        x1 = PROB.nodos(nodo1, 1);
        y1 = PROB.nodos(nodo1, 2);
        x2 = PROB.nodos(nodo2, 1);
        y2 = PROB.nodos(nodo2, 2);
    
        % Longitud original del elemento
        L_original = sqrt((x2 - x1)^2 + (y2 - y1)^2);
    
        % Desplazamientos de los nodos
        d1 = [d(2 * nodo1 - 1); d(2 * nodo1)];
        d2 = [d(2 * nodo2 - 1); d(2 * nodo2)];
    
        % Longitud deformada
        L_deformada = sqrt((x2 - x1 + d2(1) - d1(1))^2 + (y2 - y1 + d2(2) - d1(2))^2);
    
        % Cálculo de la tensión
        delta_L = L_deformada - L_original; % Cambio de longitud
        tensiones(ele) = E * delta_L / L_original; % Tensión
    
        % Verificar si la barra falla
        if tipo_seccion == 1
            Sy = 250e6; % Límite elástico para tipo 1
        elseif tipo_seccion == 2
            Sy = 250e6; % Límite elástico para tipo 2
        elseif tipo_seccion == 3
            Sy = 210e6; % Límite elástico para tipo 3
        else
            error('Tipo de sección desconocido para el elemento %d.', ele);
        end
        if abs(tensiones(ele)) > Sy
            barras_fallidas = [barras_fallidas, ele];
        end
    end
    
    % Verificar equilibrio de fuerzas
    sum_Fx = 0;
    sum_Fy = 0;
    
    % Suma de fuerzas externas
    for i = 1:size(PROB.cargas, 1)
        sum_Fx = sum_Fx + PROB.cargas(i, 2); % Fuerza en X
        sum_Fy = sum_Fy + PROB.cargas(i, 3); % Fuerza en Y
    end
    
    % Suma de reacciones en los apoyos
    reacciones = S * d - p;
    for i = 1:length(ind_p)
        if mod(ind_p(i), 2) == 1 % Grado de libertad en X
            sum_Fx = sum_Fx + reacciones(ind_p(i));
        else % Grado de libertad en Y
            sum_Fy = sum_Fy + reacciones(ind_p(i));
        end
    end
    
    % Mostrar resultados principales
    disp(' ');
    disp('========================================');
    disp('    RESULTADOS - NUDOS BIARTICULADOS');
    disp('========================================');
    
    fprintf(fid, '\n========================================\n');
    fprintf(fid, '    RESULTADOS - NUDOS BIARTICULADOS\n');
    fprintf(fid, '========================================\n');
    
    disp(' ');
    disp('--- Desplazamientos nodales (d) ---');
    disp('Formato: [dx, dy] por nodo');
    disp(reshape(d, 2, []).');
    
    fprintf(fid, '\n--- Desplazamientos nodales (d) ---\n');
    fprintf(fid, 'Formato: [dx, dy] por nodo\n');
    d_reshaped = reshape(d, 2, []).';
    for i = 1:n_nodos
        fprintf(fid, 'Nodo %2d: dx = %12.6e m, dy = %12.6e m\n', i, d_reshaped(i,1), d_reshaped(i,2));
    end
    
    disp(' ');
    disp('--- Tensiones en los elementos ---');
    disp(tensiones');
    
    fprintf(fid, '\n--- Tensiones en los elementos ---\n');
    for i = 1:n_elementos
        fprintf(fid, 'Elemento %2d: σ = %12.6e Pa\n', i, tensiones(i));
    end
    
    % Cálculo de las reacciones en los apoyos
    r = S * d - p;
    
    % Mostrar reacciones en los apoyos
    disp(' ');
    disp('--- Reacciones en los Apoyos ---');
    disp(r);
    
    fprintf(fid, '\n--- Reacciones en los Apoyos ---\n');
    for i = 1:size(PROB.soportes, 1)
        nodo = PROB.soportes(i, 1);
        rx = r(2*nodo-1);
        ry = r(2*nodo);
        fprintf(fid, 'Nodo %d: Rx = %.3e N, Ry = %.3e N\n', nodo, rx, ry);
    end

    % Mostrar resultados de equilibrio
    disp(' ');
    disp('--- Comprobación de equilibrio ---');
    fprintf(fid, '\n--- Comprobación de equilibrio ---\n');
    % Redondear valores muy pequeños a cero para mostrar (tolerancia numérica)
    tol = 1e-6;
    sum_Fx_mostrar = sum_Fx;
    sum_Fy_mostrar = sum_Fy;
    if abs(sum_Fx) < tol 
        sum_Fx_mostrar = 0; 
    end
    if abs(sum_Fy) < tol 
        sum_Fy_mostrar = 0; 
    end
    disp(['Suma de fuerzas en X: ', num2str(sum_Fx_mostrar, '%.4f'), ' N']);
    disp(['Suma de fuerzas en Y: ', num2str(sum_Fy_mostrar, '%.4f'), ' N']);
    
    fprintf(fid, 'Suma de fuerzas en X: %.4f N\n', sum_Fx_mostrar);
    fprintf(fid, 'Suma de fuerzas en Y: %.4f N\n', sum_Fy_mostrar);
    
    % Identificar barra con mayor tensión y comprobar barras fallidas
    maximo = 0;
    for i = 1:size(tensiones,2)
        if (abs(tensiones(1,i)) > maximo)
            maximo = abs(tensiones(1,i));
            tension_maxima = tensiones(1,i);
            max_bar = i; 
        end
    end
    
    disp(' ');
    disp('--- Máxima tensión y comprobación ---')
    max_tension = tension_maxima;
    disp(['Barra ', num2str(max_bar), ' tiene la máxima tensión de ', num2str(max_tension), ' Pa']);
    
    fprintf(fid, '\n--- Máxima tensión y comprobación ---\n');
    fprintf(fid, 'Barra %d tiene la máxima tensión de %.6e Pa\n', max_bar, max_tension);

    disp('Barras fallidas:');
    fprintf(fid, 'Barras fallidas: ');
    if isempty(barras_fallidas)
        disp('Ninguna barra falló.');
        fprintf(fid, 'Ninguna barra falló.\n');
    else
        disp(barras_fallidas);
        fprintf(fid, '%s\n', num2str(barras_fallidas));
    end
    
    disp('========================================');
    fprintf(fid, '========================================\n');

    % Guardar resultados para el postprocesamiento
    save('processing_data.mat', 'd', 'tensiones', 'barras_fallidas', 'reacciones', 'p', 'r');
end