function processor(fid)
    load('preprocessing_rigidos_data.mat', 'S', 'PROB');
    
    n_nodos = size(PROB.nodos, 1);
    n_elementos = size(PROB.miembros, 1);
    
    d = zeros(3 * n_nodos, 1);
    p = zeros(3 * n_nodos, 1);
    tensiones = zeros(1, n_elementos);
    barras_fallidas = [];
    
    for i = 1:size(PROB.cargas, 1)
        nodo = PROB.cargas(i, 1);
        gdl_x = 3 * nodo - 2;
        gdl_y = 3 * nodo - 1;
        p(gdl_x) = PROB.cargas(i, 2);
        p(gdl_y) = PROB.cargas(i, 3);
    end
    
    ind_p = [];
    for i = 1:size(PROB.soportes, 1)
        nodo = PROB.soportes(i, 1);
        ind_p = [ind_p; 3*nodo-2; 3*nodo-1; 3*nodo];
    end
    ind_p = unique(ind_p);
    dp = zeros(length(ind_p), 1);
    
    ind_d = setdiff(1:3 * n_nodos, ind_p);
    
    Spp = S(ind_p, ind_p);
    Spd = S(ind_p, ind_d);
    Sdp = S(ind_d, ind_p);
    Sdd = S(ind_d, ind_d);
    
    pp = p(ind_p);
    pd = p(ind_d);
    
    dd = Sdd \ (pd - Sdp * dp);
    
    d(ind_p) = dp;
    d(ind_d) = dd;
    
    for ele = 1:n_elementos
        nodo1 = PROB.miembros(ele, 1);
        nodo2 = PROB.miembros(ele, 2);
        tipo_material = PROB.miembros(ele, 3);
        tipo_seccion = PROB.miembros(ele, 4);
    
        E = PROB.material(tipo_material, 1);
        Sy = PROB.material(tipo_material, 2);
        A = PROB.seccion(tipo_seccion, 1);
        I = PROB.seccion(tipo_seccion, 2);
    
        x1 = PROB.nodos(nodo1, 1);
        y1 = PROB.nodos(nodo1, 2);
        x2 = PROB.nodos(nodo2, 1);
        y2 = PROB.nodos(nodo2, 2);
    
        L_original = sqrt((x2 - x1)^2 + (y2 - y1)^2);
    
        d1 = [d(3*nodo1-2); d(3*nodo1-1); d(3*nodo1)];
        d2 = [d(3*nodo2-2); d(3*nodo2-1); d(3*nodo2)];
    
        L_deformada = sqrt((x2 - x1 + d2(1) - d1(1))^2 + (y2 - y1 + d2(2) - d1(2))^2);
    
        delta_L = L_deformada - L_original;
        tension_axial = E * delta_L / L_original;
    
        theta_avg = abs(d1(3) - d2(3)) / 2;
        momento_max = E * I * theta_avg / L_original;
        
        c = sqrt(I / A);
        tension_flexion = momento_max * c / I;
    
        tensiones(ele) = tension_axial + tension_flexion;
    
        if tensiones(ele) > Sy
            barras_fallidas = [barras_fallidas, ele];
        end
    end
    
    r = S * d - p;
    
    sum_Fx = 0;
    sum_Fy = 0;
    sum_M = 0;
    
    for i = 1:size(PROB.cargas, 1)
        sum_Fx = sum_Fx + PROB.cargas(i, 2);
        sum_Fy = sum_Fy + PROB.cargas(i, 3);
    end
    
    for i = 1:length(ind_p)
        gdl = ind_p(i);
        resto = mod(gdl - 1, 3) + 1;
        if resto == 1
            sum_Fx = sum_Fx + r(gdl);
        elseif resto == 2
            sum_Fy = sum_Fy + r(gdl);
        else
            sum_M = sum_M + r(gdl);
        end
    end
    
    % Mostrar resultados en consola
    disp(' ');
    disp('----------------------------------------------------------');
    disp('                    RESULTADOS');
    disp('----------------------------------------------------------');
    
    % Escribir en archivo de texto
    fprintf(fid, '\n   DESPLAZAMIENTOS NODALES\n');
    fprintf(fid, '   %-8s %-15s %-15s %-15s\n', 'Nodo', 'dx (m)', 'dy (m)', 'theta (rad)');
    fprintf(fid, '   %s\n', repmat('-', 1, 55));
    
    d_reshaped = reshape(d, 3, []).';
    for i = 1:n_nodos
        fprintf(fid, '   %-8d %-15.6e %-15.6e %-15.6e\n', i, d_reshaped(i, 1), d_reshaped(i, 2), d_reshaped(i, 3));
    end
    
    % Encontrar desplazamiento máximo
    [max_dy, max_nodo] = max(abs(d_reshaped(:, 2)));
    disp(['   Desplazamiento vertical máximo: ', num2str(max_dy * 1000, '%.3f'), ' mm (Nodo ', num2str(max_nodo), ')']);
    fprintf(fid, '\n   Desplazamiento vertical máximo: %.3f mm (Nodo %d)\n', max_dy * 1000, max_nodo);
    
    % Tensiones
    fprintf(fid, '\n   TENSIONES EN ELEMENTOS\n');
    fprintf(fid, '   %-10s %-20s\n', 'Elemento', 'Tensión (Pa)');
    fprintf(fid, '   %s\n', repmat('-', 1, 32));
    for i = 1:n_elementos
        fprintf(fid, '   %-10d %-20.4e\n', i, tensiones(i));
    end
    
    [max_tension, max_bar] = max(abs(tensiones));
    disp(['   Tensión máxima: ', num2str(tensiones(max_bar)/1e6, '%.2f'), ' MPa (Barra ', num2str(max_bar), ')']);
    fprintf(fid, '\n   Tensión máxima: %.2f MPa (Barra %d)\n', tensiones(max_bar)/1e6, max_bar);
    
    % Barras fallidas
    fprintf(fid, '\n   VERIFICACIÓN DE FALLO\n');
    if isempty(barras_fallidas)
        disp('   Barras fallidas: Ninguna');
        fprintf(fid, '   Estado: Ninguna barra falló\n');
    else
        disp(['   Barras fallidas: ', num2str(barras_fallidas)]);
        fprintf(fid, '   Barras fallidas: %s\n', num2str(barras_fallidas));
    end
    
    % Equilibrio
    tol = 1e-6;
    sum_Fx_display = sum_Fx; if abs(sum_Fx) < tol, sum_Fx_display = 0; end
    sum_Fy_display = sum_Fy; if abs(sum_Fy) < tol, sum_Fy_display = 0; end
    sum_M_display = sum_M; if abs(sum_M) < tol, sum_M_display = 0; end
    
    fprintf(fid, '\n   VERIFICACIÓN DE EQUILIBRIO\n');
    fprintf(fid, '   Suma Fx: %.4f N\n', sum_Fx_display);
    fprintf(fid, '   Suma Fy: %.4f N\n', sum_Fy_display);
    fprintf(fid, '   Suma M:  %.4f N·m\n', sum_M_display);
    
    disp(['   Equilibrio: Fx = ', num2str(sum_Fx_display, '%.4f'), ' N, Fy = ', num2str(sum_Fy_display, '%.4f'), ' N']);
    
    % Reacciones en los apoyos
    fprintf(fid, '\n   REACCIONES EN APOYOS\n');
    fprintf(fid, '   %-8s %-18s %-18s %-18s\n', 'Nodo', 'Rx (N)', 'Ry (N)', 'M (N·m)');
    fprintf(fid, '   %s\n', repmat('-', 1, 65));
    for i = 1:size(PROB.soportes, 1)
        nodo = PROB.soportes(i, 1);
        rx = r(3*nodo-2);
        ry = r(3*nodo-1);
        rm = r(3*nodo);
        fprintf(fid, '   %-8d %-18.4e %-18.4e %-18.4e\n', nodo, rx, ry, rm);
    end
    
    disp('----------------------------------------------------------');
    
    save('processing_rigidos_data.mat', 'd', 'tensiones', 'barras_fallidas', 'r', 'p');
end