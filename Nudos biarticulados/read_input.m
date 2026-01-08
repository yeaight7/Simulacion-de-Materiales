function PROB = read_input(file)
    M = readmatrix(file, 'NumHeaderLines', 0);
    PROB = struct;

    % Parametros
    section_names = {'nodos', 'soportes', 'material', 'seccion', 'miembros', 'cargas'};
    num_sections = numel(section_names);

    % Índice para M
    current_row = 1;

    for i = 1:num_sections
        num = M(current_row, 1);
        current_row = current_row + 1;

        % Almacenar los datos
        if i == 1
            % nodos
            PROB.(section_names{i}) = M(current_row:current_row+num-1, 1:2);
        elseif i == 2
            % soportes
            PROB.(section_names{i}) = M(current_row:current_row+num-1, 1:3);
        elseif i == 3 || i == 4
            % material y sección
            PROB.(section_names{i}) = M(current_row:current_row+num-1, 1:2);
        elseif i == 5
            % miembros
            PROB.(section_names{i}) = M(current_row:current_row+num-1, 1:4);
        elseif i == 6
            % cargas
            PROB.(section_names{i}) = M(current_row:current_row+num-1, 1:3);
        end

        % Actualizar el índice
        current_row = current_row + num;
    end
end