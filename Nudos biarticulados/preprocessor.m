function preprocessor(file)

    % Cargar datos
    PROB = read_input(file);

    % Número de elementos y nodos
    n_ele = size(PROB.miembros, 1);
    n_nod = size(PROB.nodos, 1);

    % Inicialización de matrices (Reserva de memoria)
    % matrices_k = zeros(4, 4, n_ele);    % Matrices de rigidez locales
    % matrices_T = zeros(4, 4, n_ele);    % Matrices de giro
    % matrices_K = zeros(4, 4, n_ele);    % Matrices de rigidez globales
    S = zeros(n_nod * 2);                 % Matriz global ensamblada

    % Calcular matrices locales, giros y globales
    matrices_k = crea_k(PROB, n_ele);
    matrices_T = crea_T(PROB, n_ele);
    matrices_K = crea_K(matrices_k, matrices_T, n_ele);

    % Ensamblaje de la matriz global de rigidez (S)
    for ele = 1:n_ele
        nodo1 = PROB.miembros(ele, 1);
        nodo2 = PROB.miembros(ele, 2);
        gdl = [2*nodo1-1, 2*nodo1, 2*nodo2-1, 2*nodo2];
        S(gdl, gdl) = S(gdl, gdl) + matrices_K(:, :, ele);
    end

    disp(S);

    % ****************************** GRÁFICA ******************************
    % figure;
    % hold on;
    % 
    % for ele = 1:n_ele
    %     nodo1 = PROB.miembros(ele, 1);
    %     nodo2 = PROB.miembros(ele, 2);
    %     tipo_seccion = PROB.miembros(ele, 4);
    % 
    %     x = [PROB.nodos(nodo1, 1), PROB.nodos(nodo2, 1)];
    %     y = [PROB.nodos(nodo1, 2), PROB.nodos(nodo2, 2)];
    % 
    %     if tipo_seccion == 1
    %         plot(x, y, 'r-', 'LineWidth', 1.5);
    %     elseif tipo_seccion == 2
    %         plot(x, y, 'g-', 'LineWidth', 1.5);
    %     elseif tipo_seccion == 3
    %         plot(x, y, 'b-', 'LineWidth', 1.5);
    %     end
    % 
    %     mid_x = mean(x);
    %     mid_y = mean(y);
    %     text(mid_x, mid_y, ['E', num2str(ele)], 'FontSize', 8, 'Color', 'k');
    % end
    % 
    % scatter(PROB.nodos(:, 1), PROB.nodos(:, 2), 52, 'filled', 'k');
    % for nodo = 1:n_nod
    %     text(PROB.nodos(nodo, 1), PROB.nodos(nodo, 2), ['N', num2str(nodo)], 'FontSize', 10, 'Color', 'r');
    % end
    % 
    % xlabel('X (m)');
    % ylabel('Y (m)');
    % title('Representación Gráfica de la Estructura');
    % axis equal;
    % grid on;
    % hold off;

    % Extract data
    nodes = PROB.nodos;          % Node coordinates
    ele = PROB.miembros;   % Element connectivity

    % Initialize figure
    figure;
    hold on;

    % Plot nodes
    scatter(nodes(:, 1), nodes(:, 2), 50, 'filled', 'b'); % Nodes as blue dots
    % Label nodes
    for i = 1:size(nodes, 1)
        text(nodes(i, 1), nodes(i, 2), ['  ', num2str(i)], 'FontSize', 10); 
    end

    % Plot elements


    for i = 1:size(ele, 1)
        node1 = ele(i, 1);
        node2 = ele(i, 2);
        x = [nodes(node1, 1), nodes(node2, 1)];
        y = [nodes(node1, 2), nodes(node2, 2)];
        sec = ele(i, 4); % Material type % Label Elements at the midpoint of the line

        if sec == 1
            plot(x, y, 'r-', 'LineWidth', 1.5); % Red for section 1
        elseif sec == 2
            plot(x, y, 'g-', 'LineWidth', 1.5); % Green for section 2
        elseif sec == 3
            plot(x, y, 'b-', 'LineWidth', 1.5); % blue for section2
        end
        % Label Elements at the midpoint of the line
        mid_x = mean(x);
        mid_y = mean(y);
        text(mid_x, mid_y, sprintf('E%d', i),'VerticalAlignment', 'middle', 'HorizontalAlignment', 'center','FontSize', 8, 'Color', 'r');


    end

    % Annotate plot
    xlabel('x (units)');
    ylabel('y (units)');
    title('Graphical Representation of the Structure');
    axis equal;
    grid on;
    hold off;

    % Guardar resultados
    save('preprocessing_data.mat', 'S', 'matrices_k', 'matrices_T', 'matrices_K', 'PROB');
end

%% ----------------------------- FUNCIONES ----------------------------- %%
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

% -------------------------------------------------------------------------
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

% -------------------------------------------------------------------------
function matrices_K = crea_K(matrices_k, matrices_T, n_ele)
    matrices_K = zeros(4, 4, n_ele);
    for ele = 1:n_ele
        matrices_K(:, :, ele) = matrices_T(:, :, ele)' * matrices_k(:, :, ele) * matrices_T(:, :, ele);
    end
end
