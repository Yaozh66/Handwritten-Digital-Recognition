function sadiagnose(options,problem)
% SADIAGNOSE prints some diagnostic information about the problem

% Copyright 2006-2010 The MathWorks, Inc.

%   This function is private to SIMULANNEAL.

properties =  optionsList('sa');
Output_String = sprintf('\nDiagnostic information.');

Output_String = [Output_String sprintf('\n\tobjective function = %s',value2RHS(problem.objective))];

Output_String = [Output_String sprintf('\n\tX0 = %s',value2RHS(problem.x0))];

Output_String = [Output_String sprintf('\n%s','Modified options:')];
for i = 1:length(properties)
    prop = properties{i};
    if(~isempty(prop)) % the property list has blank lines, ignore them
        value = options.(prop);
        if ~isempty(value)  % don't generate Output_String for defaults.
            Output_String = [Output_String sprintf('\n\toptions.%s = %s',prop,value2RHS(value))];
        end
    end
end
Output_String = [Output_String sprintf('\nEnd of diagnostic information.\n\n')];
fprintf('%s',Output_String)
