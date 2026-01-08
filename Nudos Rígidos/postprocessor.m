function postprocessor(fid)
    load('processing_rigidos_data.mat', 'd', 'tensiones', 'barras_fallidas', 'r', 'p');
    load('preprocessing_rigidos_data.mat', 'PROB');
    
    % Número de elementos y nodos
    n_elementos = size(PROB.miembros, 1);
    n_nodos = size(PROB.nodos, 1);
    
    % Escala para visualizar la deformación
    escala = 500; 
    
    % Extraer solo desplazamientos x, y (ignorar rotaciones para visualización)
    d_xy = zeros(2 * n_nodos, 1);
    for i = 1:n_nodos
        d_xy(2*i-1) = d(3*i-2); % dx
        d_xy(2*i) = d(3*i-1);   % dy
    end
    
    % Calcular posiciones deformadas
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
        x_original = [PROB.nodos(nodo1, 1), PROB.nodos(nodo2, 1)];
        y_original = [PROB.nodos(nodo1, 2), PROB.nodos(nodo2, 2)];
    
        % Coordenadas deformadas
        x_deformado = [nodos_deformados(nodo1, 1), nodos_deformados(nodo2, 1)];
        y_deformado = [nodos_deformados(nodo1, 2), nodos_deformados(nodo2, 2)];
    
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
    
        % Estructura deformada
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