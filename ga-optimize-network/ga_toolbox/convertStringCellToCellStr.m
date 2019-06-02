function cellOut = convertStringCellToCellStr(cellIn)
    % CONVERTSTRINGCELLTOCELLSTR Loops through a cell array and converts
    % all string objects to cell arrays
    
    cellOut = cellIn(:);
    
    if iscell(cellOut)
        % loop through all cell array inputs and convert any
        % string datatypes to character arrays
        isStringTypeInCell = cellfun(@isstring, cellOut);
        isScalarTypeInCell = cellfun(@isscalar, cellOut);

        stringAndScalar = isStringTypeInCell & isScalarTypeInCell;
        stringAndArray = isStringTypeInCell & ~isScalarTypeInCell;

        % convert scalar strings to character arrays
        cellOut(stringAndScalar) = cellstr(cellOut(stringAndScalar));

        % convert non-scalar strings to cell arrays of
        % character vectors
        if any(stringAndArray)
            for k = find(stringAndArray)
                cellOut{k} = cellstr(cellOut{k});
            end
        end
    end
    
    cellOut = reshape(cellOut, size(cellIn));
end