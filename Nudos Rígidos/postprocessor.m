function postprocessor(fid)
    load('processing_rigidos_data.mat', 'd', 'tensiones', 'barras_fallidas', 'r', 'p');
    load('preprocessing_rigidos_data.mat', 'PROB', 'matrices_T');
    
    % Número de elementos y nodos
    n_elementos = size(PROB.miembros, 1);
    n_nodos = size(PROB.nodos, 1);
    
    % Escala para visualizar la deformación
    escala = 500; 
    
    % Funciones de forma de Hermite para desplazamiento transversal
    N1 = @(x,L) 1 - 3*(x./L).^2 + 2*(x./L).^3;
    N2 = @(x,L) x.*(1 - x./L).^2;
    N3 = @(x,L) 3*(x./L).^2 - 2*(x./L).^3;
    N4 = @(x,L) (x.^2./L).*(x./L - 1);
    
    % Funciones de forma para desplazamiento axial
    Nax1 = @(x,L) 1 - x./L;
    Nax2 = @(x,L) x./L;
    
    % Número de puntos para interpolar cada barra
    n_puntos = 20;
    
    % Extraer solo desplazamientos x, y para los nodos deformados
    d_xy = zeros(2 * n_nodos, 1);
    for i = 1:n_nodos
        d_xy(2*i-1) = d(3*i-2); % dx
        d_xy(2*i) = d(3*i-1);   % dy
    end
    
    % Calcular posiciones deformadas de los nodos
    nodos_deformados = PROB.nodos + escala * reshape(d_xy, 2, [])';
    
    % Obtener el rango de tensiones para la barra de colores
    min_tension = min(tensiones);
    max_tension = max(tensiones);
    
    % Crear un mapa de colores
    cmap = colormap(jet);
    n_colors = size(cmap, 1);
    
    % Gráfica
    figure;
    hold on;
    
    % Colorear según la tensión
    for ele = 1:n_elementos
        % Nodos de cada elemento
        nodo1 = PROB.miembros(ele, 1);
        nodo2 = PROB.miembros(ele, 2);
    
        % Coordenadas indeformadas
        x1 = PROB.nodos(nodo1, 1);
        y1 = PROB.nodos(nodo1, 2);
        x2 = PROB.nodos(nodo2, 1);
        y2 = PROB.nodos(nodo2, 2);
        
        % Longitud del elemento
        L = sqrt((x2 - x1)^2 + (y2 - y1)^2);
        
        % Desplazamientos globales del elemento [u1, v1, θ1, u2, v2, θ2]
        d_global = [d(3*nodo1-2); d(3*nodo1-1); d(3*nodo1); ...
                    d(3*nodo2-2); d(3*nodo2-1); d(3*nodo2)];
        
        % Matriz de transformación del elemento
        T = matrices_T(:, :, ele);
        
        % Transformar desplazamientos a coordenadas locales
        d_local = T * d_global;
        % d_local = [ux1, uy1, θ1, ux2, uy2, θ2] en sistema local
        
        ux1 = d_local(1);
        uy1 = d_local(2);
        theta1 = d_local(3);
        ux2 = d_local(4);
        uy2 = d_local(5);
        theta2 = d_local(6);
        
        % Puntos de interpolación a lo largo del elemento (coordenadas locales)
        xi = linspace(0, L, n_puntos);
        
        % Interpolación de desplazamientos locales usando funciones de forma
        u_local = Nax1(xi, L) * ux1 + Nax2(xi, L) * ux2;
        v_local = N1(xi, L) * uy1 + N2(xi, L) * theta1 + N3(xi, L) * uy2 + N4(xi, L) * theta2;
        
        % Posiciones deformadas en sistema local (xi + u_local, v_local)
        x_local_def = xi + escala * u_local;
        y_local_def = escala * v_local;
        
        % Transformar de vuelta a coordenadas globales
        % Ángulo del elemento
        c = T(1, 1);  % cos(theta)
        s = T(1, 2);  % sin(theta)
        
        % Posiciones globales deformadas
        x_deformado = x1 + c * x_local_def - s * y_local_def;
        y_deformado = y1 + s * x_local_def + c * y_local_def;
        
        % Coordenadas indeformadas (línea recta)
        x_original = [x1, x2];
        y_original = [y1, y2];
    
        % Color según la tensión
        if max_tension == min_tension
            tension_norm = zeros(size(tensiones));
        else
            tension_norm = (tensiones(ele) - min_tension) / (max_tension - min_tension);
        end
        color_index = round(tension_norm * (size(cmap, 1) - 1)) + 1;
        color = cmap(color_index, :);
    
        % Estructura indeformada
        plot(x_original, y_original, 'w--', 'LineWidth', 1.0);
    
        % Estructura deformada (curva)
        plot(x_deformado, y_deformado, 'Color', color, 'LineWidth', 2.5);
        
        % Marcar barras fallidas
        if ismember(ele, barras_fallidas)
            mid_x = mean(x_deformado);
            mid_y = mean(y_deformado);
            text(mid_x, mid_y, '✗', 'FontSize', 12, 'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
        end
    end
    
    % Dibujar nodos deformados
    scatter(nodos_deformados(:, 1), nodos_deformados(:, 2), 40, 'k', 'filled');
    
    % Configuración del gráfico
    cmap = colormap("jet");
    colorbar;
    clim([min_tension, max_tension]);
    title(sprintf('Estructura Deformada - Nudos Rígidos (escala ×%d)', escala));
    xlabel('X (m)');
    ylabel('Y (m)');
    legend('Original', 'Deformada', 'Location', 'best');
    axis equal;
    grid on;
    hold off;
    saveas(gcf, 'figuras/deformada.png');
    
    % Resumen
    disp(' ');
    disp(repmat('=', 1, 40));
    disp('    RESUMEN POSTPROCESAMIENTO');
    disp(repmat('=', 1, 40));
    disp(['Escala de deformación: ×', num2str(escala)]);
    disp(['Tensión mínima: ', num2str(min_tension/1e6, '%.2f'), ' MPa']);
    disp(['Tensión máxima: ', num2str(max_tension/1e6, '%.2f'), ' MPa']);
    disp(['Número de barras fallidas: ', num2str(length(barras_fallidas))]);
    if ~isempty(barras_fallidas)
        disp(['Barras fallidas: ', num2str(barras_fallidas)]);
    end
    disp(repmat('=', 1, 40));
    
    % Escribir resumen en archivo
    fprintf(fid, '\n');
    fprintf(fid, '%s\n', repmat('=', 1, 40));
    fprintf(fid, '    RESUMEN POSTPROCESAMIENTO\n');
    fprintf(fid, '%s\n', repmat('=', 1, 40));
    fprintf(fid, 'Escala de deformación: ×%d\n', escala);
    fprintf(fid, 'Tensión mínima: %.2f MPa\n', min_tension/1e6);
    fprintf(fid, 'Tensión máxima: %.2f MPa\n', max_tension/1e6);
    fprintf(fid, 'Número de barras fallidas: %d\n', length(barras_fallidas));
    if ~isempty(barras_fallidas)
        fprintf(fid, 'Barras fallidas: %s\n', num2str(barras_fallidas));
    end
    fprintf(fid, '%s\n', repmat('=', 1, 40));
end