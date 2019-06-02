function [options,gLength,fitness,nonlcon] = validate(options,type,gLength,fitness,nonlcon,user_options)
%VALIDATE validates the contents of the fitness function, genome length and
%   options struct. 
%   [OUT,nvars,fitness,constr] = VALIDATE(GenomeLength,FitnessFcn,Nonlcon,IN,type) 
%   validates the FitnessFcn, GenomeLength and the structure IN. OUT is a
%   structure which have all the fields in IN and it gets other fields
%   like FitnessFcn, GenomeLength, etc. The output 'nvars' is the number of
%   variables, 'fitness' is the function handle to the fitness function,
%   and 'nonlcon' is the function handle to the nonlinear constraint
%   function. 
%
%   This function is private to GA and GAMULTIOBJ.

%   Copyright 2003-2015 The MathWorks, Inc.

if nargin < 6
    user_options = options;
end
% Make sure user_options is consistent with gaoptimset
user_options = gaoptimset(user_options);

% range check each field
stringSet('PopulationType',options.PopulationType,{'doubleVector','custom','bitString'});
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
end

validNumberofVariables(gLength)
% PopulationSize validation
if ischar(options.PopulationSize)
    if strcmpi(options.PopulationSize,'15*numberofvariables')
        options.PopulationSize = 15*gLength;
        options.PopulationSize  = floor(options.PopulationSize);
    elseif strcmpi(options.PopulationSize,'50 when numberOfVariables <= 5, else 200')
        if gLength <= 5
            options.PopulationSize = 50;
        else
            options.PopulationSize = 200;
        end
    end
end
positiveIntegerArray('PopulationSize',options.PopulationSize);
% If population size is a matrix then we want to get the row vector expansion
options.PopulationSize = options.PopulationSize(:)';

% Generations validation
if ischar(options.Generations) 
    if strcmpi(options.Generations,'200*numberofvariables')
        options.Generations = 200*gLength;
        options.Generations = floor(options.Generations);
    elseif strcmpi(options.Generations,'100*numberofvariables')
        options.Generations = 100*gLength;
        options.Generations = floor(options.Generations);
    end
end
positiveInteger('Generations',options.Generations);

% These options does not apply to gamultiobj
if ~isempty(options.FitnessLimit) 
    realScalar('FitnessLimit',options.FitnessLimit);
end
if ~isempty(options.StallTimeLimit)
    positiveScalar('StallTimeLimit',options.StallTimeLimit);
end
if ~isempty(options.FitnessScalingFcn) 
    [options.FitnessScalingFcn,options.FitnessScalingFcnArgs] = functionHandleOrCell('FitnessScalingFcn',options.FitnessScalingFcn);
end
% Elite count validation
if ischar(options.EliteCount) && strcmpi(options.EliteCount,'0.05*PopulationSize')
    options.EliteCount = ceil(0.05*mean(options.PopulationSize));
elseif ~isempty(options.EliteCount)
    % Protect against EliteCount greater than PopulationSize.
    if options.EliteCount >= sum(options.PopulationSize)
        error(message('globaloptim:validate:EliteCountGTPop'));
    end
end

% These fields does not apply to GA
if ~isempty(options.ParetoFraction)
    realUnitScalar('ParetoFraction',options.ParetoFraction);
end
if ~isempty(options.DistanceMeasureFcn)
     [options.DistanceMeasureFcn,options.DistanceMeasureFcnArgs] = functionHandleOrCell('DistanceMeasureFcn',options.DistanceMeasureFcn);
end

stringSet('Vectorized',options.Vectorized,{'on','off'});
realUnitScalar('CrossoverFraction',options.CrossoverFraction);
positiveInteger('MigrationInterval',options.MigrationInterval);
realUnitScalar('MigrationFraction',options.MigrationFraction);
stringSet('MigrationDirection',options.MigrationDirection,{'both','forward'});
nonNegScalar('TolFun',options.TolFun);
nonNegScalar('TolCon',options.TolCon);
positiveScalar('TimeLimit',options.TimeLimit);
positiveInteger('StallGenLimit',options.StallGenLimit);

positiveInteger('PlotInterval',options.PlotInterval);

if ~isempty(options.UseParallel)
    options.SerialUserFcn = ~validateopts_UseParallel(options.UseParallel,true,true);
else
    options.SerialUserFcn = true;
end

% Creation function for constrained GA has different default
% Creation function for linearly constrained GA has different default

% Creation function for constrained GA has different default
options.CreationFcnArgs = {};
if isempty(user_options.CreationFcn) 
    if ~isempty(nonlcon) && strcmpi(options.NonlinConAlgorithm,'penalty')
        % Make gacreationnonlinearfeasible the default for nonlinearly
        % constrained problems using the penalty algorithm.
        options.CreationFcn = @gacreationnonlinearfeasible;
    elseif strcmp(type,'linearconstraints')
        options.CreationFcn = @gacreationlinearfeasible;
    end
else
    [options.CreationFcn,options.CreationFcnArgs] = functionHandleOrCell('CreationFcn',options.CreationFcn);
end

% Crossover function for linearly constrained GA has different default
if isempty(user_options.CrossoverFcn) && strcmp(type,'linearconstraints')
    options.CrossoverFcn = @crossoverintermediate;
    options.CrossoverFcnArgs = {};
else
    [options.CrossoverFcn,options.CrossoverFcnArgs] = functionHandleOrCell('CrossoverFcn',options.CrossoverFcn);
end

[options.SelectionFcn,options.SelectionFcnArgs] = functionHandleOrCell('SelectionFcn',options.SelectionFcn);
if options.MultiObjective && ~isempty(user_options.SelectionFcn)
    % Check that the selection function is tournament or custom
    selectionFcnName = func2str(options.SelectionFcn);
    if any(strcmpi(selectionFcnName,optim.options.GamultiobjOptions.InvalidSelectionFcns))
        error(message('globaloptim:validate:InvalidMultiObjSelectionFcn'));
    end
end


% Mutation function validation
if isempty(user_options.MutationFcn) && ~strcmp(type,'unconstrained')
    % Mutation function for constrained GA has different default
    options.MutationFcn = @mutationadaptfeasible;
    options.MutationFcnArgs = {};
else
    [options.MutationFcn,options.MutationFcnArgs] = functionHandleOrCell('MutationFcn',options.MutationFcn);
end

if ~isempty(options.HybridFcn)
    [options.HybridFcn,options.HybridFcnArgs] = functionHandleOrCell('HybridFcn',options.HybridFcn);
    hybridFcnName = func2str(options.HybridFcn);
    
    unconstrainedHybridFcns = {'fminsearch','fminunc','patternsearch'};
    constrainedHybridFcns = {'fmincon','patternsearch'};
    multiObjHybridFcns = {'fgoalattain'};
    allHybridFcns = [union(unconstrainedHybridFcns,constrainedHybridFcns) multiObjHybridFcns];
   
    % Check for a valid hybrid function
    % NOTE: that a hybrid function that is outside of the set above would
    % be caught by one of the checks below. However, the error message
    % would then be slightly misleading. With a dedicated check here, the
    % message is the most clear.
    stringSet('HybridFcn',hybridFcnName,allHybridFcns);
    
    % All HybridFcns only apply to double population types
    if ~strcmpi(options.PopulationType,'doubleVector')
        error(message('globaloptim:validate:NonDoubleHybridFcn', ...
            'PopulationType','doubleVector'));
    end    
    
    % Check for invalid combination of problem-type and Hybrid function
    % e.g. HybridFcn = fminunc, for a constrained problem
    if options.MultiObjective && ~any(strcmpi(hybridFcnName,multiObjHybridFcns))
        % gamultiobj hybrid function must be fgoalattain
        error(message('globaloptim:validate:NotMultiObjHybridFcn', ...
                      upper(hybridFcnName),upper(multiObjHybridFcns{:})));
    elseif ~options.MultiObjective % ga hybrid function
        % Check for a valid hybrid function for constrained problems
        % NOTE: we have to check for nonlinear constrained problems with
        % nonlcon since "type" is changed to "subtype" in gacommon before
        % calling here.
        hasNonlinearConstraints = ~isempty(nonlcon);
        if (hasNonlinearConstraints || any(strcmp(type,{'linearconstraints','boundconstraints'}))) && ...
            ~any(strcmpi(hybridFcnName,constrainedHybridFcns))
            error(message('globaloptim:validate:NotConstrainedHybridFcn', ...
                upper(hybridFcnName),strjoin(upper(constrainedHybridFcns),', ')));
        elseif ~hasNonlinearConstraints && strcmp(type,'unconstrained') && ...
               ~any(strcmpi(hybridFcnName,unconstrainedHybridFcns))
            error(message('globaloptim:validate:NotUnconstrainedHybridFcn', ...
                upper(hybridFcnName),strjoin(upper(unconstrainedHybridFcns),', ')));
        end
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

[options.PlotFcns,options.PlotFcnsArgs] = functionHandleOrCellArray('PlotFcns',options.PlotFcns);
[options.OutputFcns,options.OutputFcnsArgs] = functionHandleOrCellArray('OutputFcns',options.OutputFcns);

options.FitnessFcnArgs = {};
options.NonconFcnArgs = {};
if ~isempty(fitness)
    [fitness,FitnessFcnArgs] = functionHandleOrCell('FitnessFcn',fitness);
    fitness = createAnonymousFcn(fitness,FitnessFcnArgs);
else
    fitness = [];
end
if ~isempty(nonlcon)
    [nonlcon,NonconFcnArgs] = functionHandleOrCell('NonconFcn',nonlcon);
    nonlcon = createAnonymousFcn(nonlcon,NonconFcnArgs);
else
    nonlcon = [];
end

% gacreationnonlinearfeasible needs a handle to the nonlinear constraints
if strcmpi(func2str(options.CreationFcn),'gacreationnonlinearfeasible')
    options.CreationFcnArgs = [{nonlcon} options.CreationFcnArgs];
    
    % Extra validation for gacreationnonlinearfeasible
    % - This function only works with double data
    if ~strcmpi(options.PopulationType,'doubleVector')
        error(message('globaloptim:validate:CreateNonlinFeasBadPopType'));
    end
    % - This function is only used for nonlinearly constrained problems
    if isempty(nonlcon)
        if strcmp(type,'linearconstraints')
            options.CreationFcn = @gacreationlinearfeasible;
        else
            options.CreationFcn = @gacreationuniform;
        end
        options.CreationFcnArgs = {};
    end
end

% Adjust PopInitRange, if necessary
options = rangeCorrection(gLength,options);

% Additional checks for 'bitString' population type
if strcmpi(options.PopulationType,'bitString') 
    % Verify that if population type is 'bitString' then initial population is
    % not 'logical' data type (common mistake in input)    
    if islogical(options.InitialPopulation)
        options.InitialPopulation = double(options.InitialPopulation);
    end
    % Also make sure that the default CrossoverFcn is set to
    % constraint-preserving crossover function
    if isempty(user_options.CrossoverFcn)
       options.CrossoverFcn = @crossoverscattered;
       options.CrossoverFcnArgs = {};
    end
    % Warn if crossover function is known not to work with bitString and
    % what are supported ones for bitString.
    crossoverfcn = func2str(options.CrossoverFcn);
    if any(strcmpi(crossoverfcn, {'crossoverintermediate','crossoverarithmetic','crossoverheuristic'}))
       warning(message('globaloptim:validate:bitStringCrossoverFcn', crossoverfcn));
       options.CrossoverFcn = @crossoverscattered;
       options.CrossoverFcnArgs = {};       
    end
end

% Remaining tests do not apply to custom population
if strcmpi(options.PopulationType,'custom')
    return;
end

if ~isnumeric(gaoptimget(options,'InitialPopulation'))
    error(message('globaloptim:validate:invalidInitialPopulation'));
end
if ~isnumeric(gaoptimget(options,'InitialScores'))
    error(message('globaloptim:validate:invalidInitialScores'));
end

% Make sure that initial population is consistent with GenomeLength
if ~isempty(options.InitialPopulation) && size(options.InitialPopulation,2) ~= gLength
    error(message('globaloptim:validate:wrongSizeInitialPopulation'));
end


%-------------------------------------------------------------------------------

% Number of variables
function validNumberofVariables(GenomeLength)
valid =  isnumeric(GenomeLength) && isscalar(GenomeLength)&& (GenomeLength > 0) ...
         && (GenomeLength == floor(GenomeLength));
if ~valid
   error(message('globaloptim:validate:validNumberofVariables:notValidNvars'));
end

%------------------------------------------------------------------------------
function options = rangeCorrection(nvars,options)
%rangeCorrection Check the size and consistency of PopInitRange

Range = options.PopInitRange;

lb = Range(1,:);
lb = lb(:);
lenlb = length(lb);
ub = Range(2,:);
ub = ub(:);
lenub = length(ub);

% Check maximum length
if lenlb > nvars
   lb = lb(1:nvars);   
elseif lenlb < nvars
   lb = [lb; lb(end)*ones(nvars-lenlb,1)];
end

if lenub > nvars
   ub = ub(1:nvars);
elseif lenub < nvars
   ub = [ub; ub(end)*ones(nvars-lenub,1)];
end
   
if any( lb > ub )
    count = nnz(lb > ub);
    error(message('globaloptim:validate:infeasibleRange',count));
end

options.PopInitRange = [lb,ub]';
%------------------------------End of rangeCorrection --------------------------


