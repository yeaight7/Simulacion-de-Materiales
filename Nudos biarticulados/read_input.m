function PROB = read_input(file)
    M = readmatrix(file, 'NumHeaderLines', 0);
    PROB = struct;

    section_names = {'nodos', 'soportes', 'material', 'seccion', 'miembros', 'cargas'};
    num_sections = numel(section_names);

    current_row = 1;

    for i = 1:num_sections
        num = M(current_row, 1);
        current_row = current_row + 1;

        if i == 1
            PROB.(section_names{i}) = M(current_row:current_row+num-1, 1:2);
        elseif i == 2
            PROB.(section_names{i}) = M(current_row:current_row+num-1, 1:3);
        elseif i == 3 || i == 4
            PROB.(section_names{i}) = M(current_row:current_row+num-1, 1:2);
        elseif i == 5
            PROB.(section_names{i}) = M(current_row:current_row+num-1, 1:4);
        elseif i == 6
            PROB.(section_names{i}) = M(current_row:current_row+num-1, 1:3);
        end

        current_row = current_row + num;
    end
end