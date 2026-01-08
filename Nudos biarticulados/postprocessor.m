function postprocessor(fid)
    
    % Cargar datos del procesamiento
    load('processing_data.mat', 'd', 'tensiones', 'barras_fallidas', 'reacciones', 'p', 'r');
    load('preprocessing_data.mat', 'PROB');
    
    % Número de elementos y nodos
    n_elementos = size(PROB.miembros, 1);
    n_nodos = size(PROB.nodos, 1);
    
    % Escala para visualizar la deformación
    escala = 100; % Ajustar según la magnitud de los desplazamientos
    
    % Calcular posiciones deformadas
    nodos_deformados = PROB.nodos + escala * reshape(d, 2, [])';
    
    % Obtener el rango de tensiones para la escala de colores
    min_tension = min(tensiones);
    max_tension = max(tensiones);
    
    % Crear un mapa de colores (escala de azul a rojo)
    cmap = colormap(jet);
    n_colors = size(cmap, 1);
    
    % Dibujar la estructura
    figure;
    hold on;
    
    % Dibujar barras coloreadas según la tensión
    for ele = 1:n_elementos
        % Nodos de cada elemento
        nodo1 = PROB.miembros(ele, 1);
        nodo2 = PROB.miembros(ele, 2);
    
        % Coordenadas originales
        x_original = [PROB.nodos(nodo1, 1), PROB.nodos(nodo2, 1)];
        y_original = [PROB.nodos(nodo1, 2), PROB.nodos(nodo2, 2)];
    
        % Coordenadas deformadas
        x_deformado = [nodos_deformados(nodo1, 1), nodos_deformados(nodo2, 1)];
        y_deformado = [nodos_deformados(nodo1, 2), nodos_deformados(nodo2, 2)];
    
        % Color según la tensión
        if max_tension == min_tension
            tension_norm = zeros(size(tensiones)); % Normalizar tensiones
        else
            tension_norm = (tensiones(ele) - min_tension) / (max_tension - min_tension); % Normalizar tensión
        end
        color_index = round(tension_norm * (size(cmap, 1) - 1)) + 1;
        color = cmap(color_index,:);
    
        % Dibujar barra original (línea discontinua)
        plot(x_original, y_original, 'w--', 'LineWidth', 1.0);
    
        % Dibujar barra deformada con color
        plot(x_deformado, y_deformado, 'Color', color, 'LineWidth', 2.0);
    end
    
    % Configuración del gráfico
    cmap = colormap("jet");
    colorbar; % Mostrar barra de color
    clim([min_tension, max_tension]); % Escalar colores según el rango de tensiones
    title(sprintf('Estructura Deformada - Nudos Biarticulados (escala ×%d)', escala));
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

