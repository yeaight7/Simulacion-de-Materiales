function processor
    load('preprocessing_rigidos_data.mat', 'S', 'PROB');
    
    % nodos y elementos
    n_nodos = size(PROB.nodos, 1);
    n_elementos = size(PROB.miembros, 1);
    
    % Inicializar vectores y matrices
    d = zeros(3 * n_nodos, 1); % desplazamientos (ahora hay 3 gdl por nodo)
    p = zeros(3 * n_nodos, 1); % fuerzas nodales
    tensiones = zeros(1, n_elementos);
    barras_fallidas = [];
    
    % Ensamblar
    for i = 1:size(PROB.cargas, 1)
        nodo = PROB.cargas(i, 1);
        gdl_x = 3 * nodo - 2;
        gdl_y = 3 * nodo - 1;
        % gdl_theta = 3 * nodo; % Grado de libertad rotacional (momento)
        
        p(gdl_x) = PROB.cargas(i, 2); % Fuerza en X
        p(gdl_y) = PROB.cargas(i, 3); % Fuerza en Y
        % p(gdl_theta) = 0; % Sin momentos externos aplicados
    end
    
    % Identificar los grados de libertad con desplazamientos prescritos
    % Para nudos rígidos: restringir x, y, y θ en cada soporte
    ind_p = [];
    for i = 1:size(PROB.soportes, 1)
        nodo = PROB.soportes(i, 1);
        % Agregar los 3 GDL del nodo restringido
        ind_p = [ind_p; 3*nodo-2; 3*nodo-1; 3*nodo];
    end
    ind_p = unique(ind_p);
    dp = zeros(length(ind_p), 1); % Desplazamientos prescritos (cero en los apoyos)
    
    % Identificar los grados de libertad libres
    ind_d = setdiff(1:3 * n_nodos, ind_p); % Grados de libertad libres
    
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
        E = PROB.material(tipo_material, 1);  % Módulo de Young
        Sy = PROB.material(tipo_material, 2); % Tensión de fluencia
        A = PROB.seccion(tipo_seccion, 1);    % Área
        I = PROB.seccion(tipo_seccion, 2);    % Momento de inercia
    
        % Coordenadas de los nodos
        x1 = PROB.nodos(nodo1, 1);
        y1 = PROB.nodos(nodo1, 2);
        x2 = PROB.nodos(nodo2, 1);
        y2 = PROB.nodos(nodo2, 2);
    
        % Longitud original del elemento
        L_original = sqrt((x2 - x1)^2 + (y2 - y1)^2);
    
        % Desplazamientos de los nodos (ahora con rotación)
        d1 = [d(3*nodo1-2); d(3*nodo1-1); d(3*nodo1)];     % [dx1, dy1, θ1]
        d2 = [d(3*nodo2-2); d(3*nodo2-1); d(3*nodo2)];     % [dx2, dy2, θ2]
    
        % Longitud deformada (solo traslaciones)
        L_deformada = sqrt((x2 - x1 + d2(1) - d1(1))^2 + (y2 - y1 + d2(2) - d1(2))^2);
    
        % Cálculo de la tensión axial
        delta_L = L_deformada - L_original;
        tension_axial = E * delta_L / L_original;
    
        % Cálculo de la tensión por flexión (aproximada)
        % Momento máximo en viga simplemente apoyada con deflexión
        % Usamos una aproximación basada en las rotaciones
        theta_avg = abs(d1(3) - d2(3)) / 2;  % Rotación promedio
        momento_max = E * I * theta_avg / L_original;  % Aproximación
        
        % Tensión máxima por flexión: σ = M*c/I, donde c ≈ sqrt(I/A) para secciones típicas
        c = sqrt(I / A);  % Distancia al eje neutro (aproximada)
        tension_flexion = momento_max * c / I;
    
        % Tensión total (combinación de axial y flexión)
        tensiones(ele) = tension_axial + tension_flexion;
    
        % Verificar si la barra falla
        if tensiones(ele) > Sy
            barras_fallidas = [barras_fallidas, ele];
        end
    end
    
    % Calcular reacciones en los apoyos
    r = S * d - p;
    
    % Verificar equilibrio de fuerzas
    sum_Fx = 0;
    sum_Fy = 0;
    sum_M = 0;
    
    % Suma de fuerzas externas
    for i = 1:size(PROB.cargas, 1)
        sum_Fx = sum_Fx + PROB.cargas(i, 2);
        sum_Fy = sum_Fy + PROB.cargas(i, 3);
    end
    
    % Suma de reacciones en los apoyos
    for i = 1:length(ind_p)
        gdl = ind_p(i);
        resto = mod(gdl - 1, 3) + 1; % Determina si es 1 (X), 2 (Y) o 3 (θ)
        if resto == 1 % GDL en X (3*n-2: 1, 4, 7, ...)
            sum_Fx = sum_Fx + r(gdl);
        elseif resto == 2 % GDL en Y (3*n-1: 2, 5, 8, ...)
            sum_Fy = sum_Fy + r(gdl);
        else % GDL rotacional (3*n: 3, 6, 9, ...)
            sum_M = sum_M + r(gdl);
        end
    end
    
    % Mostrar resultados
    disp('========================================');
    disp('    RESULTADOS - NUDOS RÍGIDOS');
    disp('========================================');
    
    disp(' ');
    disp('--- Desplazamientos nodales (d) ---');
    disp('Formato: [dx, dy, θ] por nodo');
    disp(reshape(d, 3, []).');
    
    disp(' ');
    disp('--- Tensiones en los elementos ---');
    disp(tensiones');
    
    % Encontrar tensión máxima
    [max_tension, max_bar] = max(abs(tensiones));
    disp(' ');
    disp(['Barra ', num2str(max_bar), ' tiene la máxima tensión: ', num2str(tensiones(max_bar)), ' Pa']);
    disp(['  (Valor absoluto: ', num2str(max_tension), ' Pa)']);
    
    disp(' ');
    disp('--- Barras fallidas ---');
    if isempty(barras_fallidas)
        disp('✓ Ninguna barra falló.');
    else
        disp(['✗ Las siguientes barras fallaron: ', num2str(barras_fallidas)]);
    end
    
    disp(' ');
    disp('--- Comprobación de equilibrio ---');
    disp(['Suma de fuerzas en X: ', num2str(sum_Fx, '%.6e'), ' N']);
    disp(['Suma de fuerzas en Y: ', num2str(sum_Fy, '%.6e'), ' N']);
    disp(['Suma de momentos:     ', num2str(sum_M, '%.6e'), ' N·m']);
    
    disp(' ');
    disp('--- Reacciones en los Apoyos ---');
    for i = 1:size(PROB.soportes, 1)
        nodo = PROB.soportes(i, 1);
        rx = r(3*nodo-2);
        ry = r(3*nodo-1);
        rm = r(3*nodo);
        disp(['Nodo ', num2str(nodo), ': Rx = ', num2str(rx, '%.3e'), ' N, Ry = ', num2str(ry, '%.3e'), ' N, M = ', num2str(rm, '%.3e'), ' N·m']);
    end
    
    disp('========================================');
    
    % Guardar resultados para el postprocesamiento
    save('processing_rigidos_data.mat', 'd', 'tensiones', 'barras_fallidas', 'r', 'p');
end