function postprocessor
    
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
    
        % Dibujar barra original (negro)
        plot(x_original, y_original, 'w--', 'LineWidth', 1.0);
    
        % Dibujar barra deformada con color
        plot(x_deformado, y_deformado, 'Color', color, 'LineWidth', 2.0);
    end
    
    % Configuración del gráfico
    cmap = colormap("jet");
    colorbar; % Mostrar barra de color
    clim([min_tension, max_tension]); % Escalar colores según el rango de tensiones
    title('Distribución de Tensiones en la Estructura');
    xlabel('X (m)');
    ylabel('Y (m) * 0.01');
    legend('Original', 'Deformada (colores por tensión)');
    axis equal;
    grid on;
    hold off;
	saveas(gcf, 'figuras/deformada.png');

end

