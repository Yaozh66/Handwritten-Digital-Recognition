function options  = savalidate(options,problem)
% SAVALIDATE is used to ensure that the options structure for a SIMULANNEAL
%   problem is valid and each field in it has an acceptable type.
%
%   This function is private to SIMULANNEAL.

%   Copyright 2006-2012 The MathWorks, Inc.

% Sanity check for the options structure
options = saoptimset(options);

% Determine the verbosity
switch  options.Display
    case {'off','none'}
        options.Verbosity = 0;
    case 'final'
        options.Verbosity = 1;
    case 'iter'
        options.Verbosity = 2;
    case 'diagnose'
        options.Verbosity = 3;
    otherwise
        options.Verbosity = 1;
end

% MaxFunEvals default value is string
if strcmpi(options.MaxFunEvals,'3000*numberofvariables')
    options.MaxFunEvals = 3000*problem.nvar;
end
% StallIterLimit default value is string
if strcmpi(options.StallIterLimit,'500*numberofvariables')
    options.StallIterLimit = 500*problem.nvar;
end

if strcmpi(options.HybridInterval, 'end')
    options.HybridInterval = [];
elseif strcmpi(options.HybridInterval, 'never')
    options.HybridFcn = [];
elseif ~isempty(options.HybridInterval)
    nonNegInteger('HybridInterval', options.HybridInterval)
end

positiveInteger('MaxIter', options.MaxIter)
positiveInteger('MaxFunEvals', options.MaxFunEvals);
positiveInteger('StallIterLimit', options.StallIterLimit)
positiveScalarArray('InitialTemperature',options.InitialTemperature);

positiveScalar('TimeLimit', options.TimeLimit)
realScalar('ObjectiveLimit', options.ObjectiveLimit)

nonNegInteger('DisplayInterval', options.DisplayInterval)
nonNegInteger('ReannealInterval', options.ReannealInterval)
nonNegInteger('PlotInterval', options.PlotInterval)

nonNegScalar('TolFun',options.TolFun);

% These functions not only savalidate, they separate fcns from args for
% speed.
[options.AnnealingFcn,options.AnnealingFcnArgs] = functionHandleOrCell('AnnealingFcn',options.AnnealingFcn);
[options.TemperatureFcn,options.TemperatureFcnArgs] = functionHandleOrCell('TemperatureFcn',options.TemperatureFcn);
[options.AcceptanceFcn,options.AcceptanceFcnArgs] = functionHandleOrCell('AcceptanceFcn',options.AcceptanceFcn);

if ~isempty(options.HybridFcn)
    [options.HybridFcn,options.HybridFcnArgs] = functionHandleOrCell('HybridFcn',options.HybridFcn);
    hybridFcnName = func2str(options.HybridFcn);
    
    unconstrainedHybridFcns = {'fminsearch','fminunc','patternsearch'};
    constrainedHybridFcns = {'fmincon','patternsearch'};
    allHybridFcns = union(unconstrainedHybridFcns,constrainedHybridFcns);
    % Check for a valid hybrid function
    % NOTE: that a hybrid function that is outside of the set above would
    % be caught by one of the checks below. However, the error message
    % would then be slightly misleading. With a dedicated check here, the
    % message is the most clear.
    if ~any(strcmpi(hybridFcnName, allHybridFcns))
        error(message('globaloptim:savalidate:InvalidHybridFcn', ...
            strjoin(upper(allHybridFcns), ', ') ));
    end
    
    % All HybridFcns only apply to double data types
    if ~strcmpi(options.DataType,'double')
        msg = getString(message('globaloptim:validate:NonDoubleHybridFcn', ...
            'DataType','double'));
        error('globaloptim:savalidate:InvalidHybrid',msg);
    end    
    
    % Check for a valid hybrid function for constrained problems
    if problem.bounded && ~any(strcmpi(hybridFcnName,constrainedHybridFcns))
        msg = getString(message('globaloptim:validate:NotConstrainedHybridFcn', ...
                upper(hybridFcnName),strjoin(upper(constrainedHybridFcns),', ')));
        error('globaloptim:savalidate:NotConstrainedHybridFcn',msg);
    elseif ~problem.bounded && ~any(strcmpi(hybridFcnName,unconstrainedHybridFcns))
        msg = getString(message('globaloptim:validate:NotUnconstrainedHybridFcn', ...
                upper(hybridFcnName),strjoin(upper(unconstrainedHybridFcns),', ')));
        error('globaloptim:savalidate:NotUnconstrainedHybridFcn',msg);
    end
    
    % If the user has set a hybrid function, they can specify options for the
    % hybrid function. If a user has passed a SolverOptions object for these
    % options, convert the options object to a structure. Note that we will not
    % warn here if a user specifies a solver with a different solver's options.
    if ~isempty(options.HybridFcnArgs) ...
            && isa(options.HybridFcnArgs{1}, 'optim.options.SolverOptions')
        % It is possible for a user to pass in a vector of options to the
        % solver. Silently use the first element in this array.
        options.HybridFcnArgs{1} = options.HybridFcnArgs{1}(1);
        
        % Extract the options structure
        options.HybridFcnArgs{1} = extractOptionsStructure(options.HybridFcnArgs{1});
    end
    
end

% this special case takes an array of function cells
[options.PlotFcns,options.PlotFcnsArgs] = functionHandleOrCellArray('PlotFcns',options.PlotFcns);
[options.OutputFcns,options.OutputFcnsArgs] = functionHandleOrCellArray('OutputFcns',options.OutputFcns);

% Make the length of the options.InitialTemperature to nvar
len_temp = length(options.InitialTemperature);
if len_temp > problem.nvar
    warning(message('globaloptim:savalidate:lengthOfInitialTemperature'));
    options.InitialTemperature(len_temp:end) = [];
elseif len_temp < problem.nvar
    temperature = zeros(problem.nvar,1);
    temperature(1:len_temp) = options.InitialTemperature;
    temperature(len_temp+1 : end)= options.InitialTemperature(end);
    options.InitialTemperature = temperature;
end
% We want initialtemperature to be a column vector
options.InitialTemperature = options.InitialTemperature(:);

