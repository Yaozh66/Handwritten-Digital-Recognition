function [x,fval,exitFlag,output,population,scores] = gamultiobjsolve(FitnessFcn,GenomeLength, ...
     Aineq,bineq,Aeq,beq,lb,ub,ConstrFcn,options,output,numOutputsRequested)
%GAMULTIOBJSOLVE Genetic algorithm multi-objective solver.

%   Copyright 2007-2016 The MathWorks, Inc.

% Create initial state: population, scores, status data
state = gamultiobjMakeState(GenomeLength,FitnessFcn,ConstrFcn,output.problemtype,options);

currentState = 'init';
% Give the plot/output Fcns a chance to do any initialization they need.
state = gadsplot(options,state,currentState,'Genetic Algorithm');
[state,options] = gaoutput(FitnessFcn,options,state,currentState);

% Setup display header 
if  options.Verbosity > 1
    fprintf('\n                              Average            Average\n');
    fprintf('Generation   Func-count    Pareto distance    Pareto spread\n');
end

currentState = 'iter';
% Run the main loop until some termination condition becomes true
exitFlag = [];
while true
       state.Generation = state.Generation + 1;
        % check to see if any stopping criteria have been met
       [state,exitFlag,reasonToStop] = gamultiobjConverged(options,state);
       if ~isempty(exitFlag)
           break;
       end
       
        % Repeat for each sub-population (element of the PopulationSize vector)
        offset = 0;
        totalPop = options.PopulationSize;
        % Each sub-population loop
        for pop = 1:length(totalPop)
            populationSize =  totalPop(pop);
            thisPopulation = 1 + (offset:(offset + populationSize - 1));
            % Empty population is also possible
            if isempty(thisPopulation)
                continue; 
            end
            state = stepgamultiobj(pop,thisPopulation,options,state, ...
                                   GenomeLength,FitnessFcn,ConstrFcn);
            offset = offset + populationSize;
        end 
        
        % Migration
        state = migrate(FitnessFcn,GenomeLength,options,state);

        % Output and plot functions
        state = gadsplot(options,state,currentState,'Genetic Algorithm');
        [state,options] = gaoutput(FitnessFcn,options,state,currentState);
end % End while loop
% Update output structure
output.generations = state.Generation;
output.message = reasonToStop;

% If sub-population model is used, merge all sub-population and perform
% another non-dominated sorting
if length(options.PopulationSize) > 1
    [state.Population,state.Score,state.Rank,state.Distance,state.C,state.Ceq, ...
     state.isFeas,state.maxLinInfeas, state.complexWarningThrown] = rankAndDistance(state.Population, ...
         state.Score,state.C,state.Ceq,state.isFeas,state.maxLinInfeas,options,[],state.complexWarningThrown);
    % Calculate average distance and spread
    [output.averagedistance,output.spread] = distanceAndSpread(state.Distance, ...
        state.Rank,state.Score,state.Score);
else
    % Calculate front statistics for output structure
    output.averagedistance = state.AverageDistance;
    output.spread = state.Spread(end);
end

% Make sure the scores requested by the user do not contain Infs
if numOutputsRequested > 1 
    state = fillInMissingScores(FitnessFcn,state,options);
end
% Find and return the solutions on Pareto front
topRankedIdx = state.Rank == 1;
fval = state.Score(topRankedIdx,:);
x = state.Population(topRankedIdx,:);
c = state.C(topRankedIdx,:);
ceq = state.Ceq(topRankedIdx,:);
isFeas = state.isFeas(topRankedIdx);
maxLinInfeas = state.maxLinInfeas(topRankedIdx);

% A hybrid scheme; try another minimization method
if ~isempty(options.HybridFcn)
    state = gamultiobjHybrid(FitnessFcn,x,fval,c,ceq,isFeas,maxLinInfeas, ...
        state,Aineq,bineq,Aeq,beq,lb,ub,ConstrFcn,options);

    % Find and return the solutions on Pareto front
    fval = state.Score(state.Rank == 1,:);
    x = state.Population((state.Rank == 1),:);
    c = state.C(topRankedIdx,:);
    ceq = state.Ceq(topRankedIdx,:);
    
    if numOutputsRequested > 3
        % Calculate front statistics for output structure, if needed
        [output.averagedistance,output.spread] = distanceAndSpread( ...
            state.Distance,state.Rank,state.Score,state.Score);
    end
end

% Update statistics in the output structure, if needed.
if numOutputsRequested > 3
    output.maxconstraint = computeMaxConstraint(x,c,ceq,options);
    output.funccount   = state.FunEval;
end
population = state.Population;
scores = state.Score;

currentState = 'done';
% Give the Output functions a chance to finish up
gadsplot(options,state,currentState,'Genetic Algorithm');
gaoutput(FitnessFcn,options,state,currentState);

%--------------------------------------------------------------------------
function maxConstrViol = computeMaxConstraint(x,c,ceq,options)

maxConstrViol = [];
haveLinCon = isfield(options,'LinearConstr') && ~strcmp(options.LinearConstr.type,'unconstrained');
haveNonlinCon = ~isempty(c) || ~isempty(ceq);

if haveLinCon
    % Get maximum linear constraint violation for each member of the
    % "top-ranked" pareto front. Take the largest of these.
    [~,maxLinConViol] = isTrialFeasible(x,options.LinearConstr.Aineq, ...
        options.LinearConstr.bineq,options.LinearConstr.Aeq,options.LinearConstr.beq, ...
        options.LinearConstr.lb,options.LinearConstr.ub,options.TolCon);
    maxConstrViol = max(maxLinConViol);
end

if haveNonlinCon
    % Get largest nonlinear constraint violation for the "top-ranked"
    % pareto front.
    maxNonlinconViol = max([c(:); abs(ceq(:))]);
    maxConstrViol = max(maxConstrViol,maxNonlinconViol);
end
% No negative constraint violations
maxConstrViol = max(maxConstrViol,0);

%--------------------------------------------------------------------------
function state = fillInMissingScores(FitnessFcn,state,options)
% Fill in scores when the solver stalled/stopped at an infeasible
% population -> eval the top ranked front

% If only "fval" is requested, only evaluate infeasible members of
% the top-ranked population.
% NOTE: this will happen when the solver didn't converge with a
% feasible population.
evalIdx = ~state.isFeas & (state.Rank == 1);

if any(evalIdx)
    if strcmpi(options.Vectorized, 'off')
        % Score remaining members of the population
        state.Score(evalIdx,:) = fcnvectorizer(state.Population(evalIdx,:),FitnessFcn, ...
            size(state.Score,2),options.SerialUserFcn);
    else
        % Only evaluate feasible points
        state.Score(evalIdx,:) = FitnessFcn(state.Population(evalIdx,:));
    end
end
state.FunEval = state.FunEval + sum(evalIdx);


