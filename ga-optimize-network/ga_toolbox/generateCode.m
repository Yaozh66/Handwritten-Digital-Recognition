function code = generateCode( obj )
%GENERATECODE Generate MATLAB code to recreate a GA options object
%   generateCode(gaoptimset ) is a string that can be evaluated to produce
%   the options structure passed in.

%   Copyright 2003-2015 The MathWorks, Inc.

if isa(obj, 'optim.options.SolverOptions')
    % make a default object. properties that match the values in the default
    % will not be generated.    
    default = optimoptions(obj.SolverName);
    % first line
    code = sprintf('options = optimoptions(''%s'');\n', obj.SolverName);
else % structure
    % make a default object. properties that match the values in the default
    % will not be generated.
    default = gaoptimset();
    
    % first line
    code = sprintf('options = gaoptimset;\n');
end
optNames =  properties(default);
% for each property
for i = 1:length(optNames)
    prop = optNames{i};
    if(~isempty(prop)) % the property list has blank lines, ignore them
        value = obj.(prop);
        if(~isequal(value,default.(prop))) % don't generate code for defaults.
            code = [code sprintf('options.%s = %s;\n',prop,value2RHS(value))];
        end
    end
end
