function preprocessor(file, fid)

    PROB = read_input(file);

    n_ele = size(PROB.miembros, 1);
    n_nod = size(PROB.nodos, 1);

    S = zeros(n_nod * 2);

    matrices_k = crea_k(PROB, n_ele);
    matrices_T = crea_T(PROB, n_ele);
    matrices_K = crea_K(matrices_k, matrices_T, n_ele);

    for ele = 1:n_ele
        nodo1 = PROB.miembros(ele, 1);
        nodo2 = PROB.miembros(ele, 2);
        gdl = [2*nodo1-1, 2*nodo1, 2*nodo2-1, 2*nodo2];
        S(gdl, gdl) = S(gdl, gdl) + matrices_K(:, :, ele);
    end

    fprintf(fid, '   Número de nodos: %d\n', n_nod);
    fprintf(fid, '   Número de elementos: %d\n', n_ele);
    fprintf(fid, '   Grados de libertad totales: %d\n', n_nod * 2);
    fprintf(fid, '   Tamaño matriz de rigidez: %dx%d\n', size(S, 1), size(S, 2));

    disp(['   Nodos: ', num2str(n_nod), ' | Elementos: ', num2str(n_ele)]);
    disp(['   Grados de libertad: ', num2str(n_nod * 2)]);

    nodes = PROB.nodos;          
    ele = PROB.miembros;   

    figure;
    hold on;

    scatter(nodes(:, 1), nodes(:, 2), 50, 'filled', 'b'); 
    for i = 1:size(nodes, 1)
        text(nodes(i, 1), nodes(i, 2), ['  ', num2str(i)], 'FontSize', 10); 
    end

    for i = 1:size(ele, 1)
        node1 = ele(i, 1);
        node2 = ele(i, 2);
        x = [nodes(node1, 1), nodes(node2, 1)];
        y = [nodes(node1, 2), nodes(node2, 2)];
        sec = ele(i, 4); 

        if sec == 1
            plot(x, y, 'r-', 'LineWidth', 1.5); 
        elseif sec == 2
            plot(x, y, 'g-', 'LineWidth', 1.5); 
        elseif sec == 3
            plot(x, y, 'b-', 'LineWidth', 1.5); 
        end

        mid_x = mean(x);
        mid_y = mean(y);
        text(mid_x, mid_y, sprintf('E%d', i), 'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', 'r');
    end

    xlabel('x (m)');
    ylabel('y (m)');
    title('Estructura con Nudos Biarticulados');
    axis equal;
    grid on;
    hold off;
    saveas(gcf, 'figuras/estructura.png');

    save('preprocessing_data.mat', 'S', 'matrices_k', 'matrices_T', 'matrices_K', 'PROB');
end

%% Funciones auxiliares

function matrices_k = crea_k(PROB, n_ele)
    matrices_k = zeros(4, 4, n_ele);

    for ele = 1:n_ele
        i_mat = PROB.miembros(ele, 3);
        E = PROB.material(i_mat);
        i_sec = PROB.miembros(ele, 4);
        A = PROB.seccion(i_sec);
        nodo1 = PROB.miembros(ele, 1);
        nodo2 = PROB.miembros(ele, 2);
        delta = PROB.nodos(nodo2,:) - PROB.nodos(nodo1,:);
        L = norm(delta);

        matrices_k(:, :, ele) = [ E*A/L,  0,  -E*A/L,  0;
                                  0,      0,   0,      0;
                                 -E*A/L,  0,   E*A/L,  0;
                                  0,      0,   0,      0];
    end
end

function matrices_T = crea_T(PROB, n_ele)
    matrices_T = zeros(4, 4, n_ele);
    th = zeros(1, n_ele);

    for ele = 1:n_ele
        nodo1 = PROB.miembros(ele, 1);
        nodo2 = PROB.miembros(ele, 2);
        x21 = PROB.nodos(nodo2, 1) - PROB.nodos(nodo1, 1);
        y21 = PROB.nodos(nodo2, 2) - PROB.nodos(nodo1, 2);
        th(ele) = rad2deg(atan2(y21, x21));

        matrices_T(:, :, ele) = [ cosd(th(ele)),   sind(th(ele)),   0,               0;
                                 -sind(th(ele)),   cosd(th(ele)),   0,               0;
                                  0,               0,               cosd(th(ele)),   sind(th(ele));
                                  0,               0,              -sind(th(ele)),   cosd(th(ele))];
    end
end

function matrices_K = crea_K(matrices_k, matrices_T, n_ele)
    matrices_K = zeros(4, 4, n_ele);
    for ele = 1:n_ele
        matrices_K(:, :, ele) = matrices_T(:, :, ele)' * matrices_k(:, :, ele) * matrices_T(:, :, ele);
    end
end
