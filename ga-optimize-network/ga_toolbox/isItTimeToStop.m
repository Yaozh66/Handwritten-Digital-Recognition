function [exitFlag,reasonToStop] = isItTimeToStop(options,state)
%isItTimeToStop Check to see if any of the stopping criteria have been met.
%
%   This function is private to GA

%   Copyright 2003-2016 The MathWorks, Inc.



funChange = Inf;
Gen = state.Generation;
if options.Verbosity > 1
    FunEval  = state.FunEval;
    BestFval = state.Best(Gen);
    MeanFval = meanf(state.Score);
    StallGen = Gen  - state.LastImprovement;
    fprintf('%5.0f         %8.0f    %12.4g    %12.4g    %5.0f\n', ...
        Gen, FunEval, BestFval, MeanFval, StallGen);
end
% Window used to get best fval
Window = options.StallGenLimit;
Weight = 0.5;
% Compute change in fval and individuals in last 'Window' generations
if Gen > Window
    Bestfvals =  state.Best((Gen-Window):end);
    % Compute value for selected stall test
    % (NOTE: other values are not permitted by gaoptimset).
    if strcmpi(options.StallTest, 'averageChange')
        funChange = abs(Bestfvals(1) - Bestfvals(end))/ (Window*max(1,abs(Bestfvals(end))));
    elseif strcmpi(options.StallTest, 'geometricWeighted')
        funChange = sum( Weight.^((Window-1):-1:0) .* ( abs(diff(Bestfvals)) ./ (abs(Bestfvals(1:Window)) + 1) ) )/Window;
    end
end

reasonToStop = '';
exitFlag = [];
if(state.Generation >= options.Generations)
    reasonToStop = sprintf('Optimization terminated: maximum number of generations exceeded.');
    exitFlag = 0;
elseif toc(state.StartTime) > options.TimeLimit
    reasonToStop = sprintf('Optimization terminated: time limit exceeded.');
    exitFlag = -5;
elseif toc(state.LastImprovementTime) > options.StallTimeLimit
    reasonToStop = sprintf('Optimization terminated: stall time limit exceeded.');
    exitFlag = -4;
elseif((state.Generation  - state.LastImprovement) > options.StallGenLimit)
    reasonToStop = sprintf('Optimization terminated: stall generations limit exceeded.');
    exitFlag = 3;
elseif(state.Best(Gen) <= options.FitnessLimit )
    reasonToStop = sprintf('Optimization terminated: minimum fitness limit reached.');
    exitFlag = 5;
elseif(~isempty(state.StopFlag))
    reasonToStop = sprintf('Optimization terminated: %s',state.StopFlag);
    exitFlag = -1;
elseif funChange <= options.TolFun
    reasonToStop = sprintf('Optimization terminated: average change in the fitness value less than options.FunctionTolerance.');
    exitFlag = 1;
end

% If it is a constrained problem and we want to check linear
% constraints (when GA is terminating)
if ~isempty(reasonToStop) && isfield(options,'LinearConstr')
        linCon = options.LinearConstr;
        if linCon.linconCheck && ~feasibleLinearConstraints
          reasonToStop = [reasonToStop,...
              sprintf('\n%s','Linear constraints are not satisfied within constraint tolerance.')];
          exitFlag = -2;
        end
end

if ~isempty(reasonToStop) && options.Verbosity > 0
    fprintf('%s\n',reasonToStop);
    return;
end
% Print header again
if options.Verbosity > 1 && rem(Gen,30)==0 && Gen > 0
    fprintf('\n                                  Best           Mean      Stall\n');
    fprintf('Generation      Func-count        f(x)           f(x)    Generations\n');
end
%------------------------------------------------
    function feasible  = feasibleLinearConstraints
        % Function to check if linear constraints are satisfied at final point
        % If it is a constrained problem and we want to check linear constraints
        tol = max(sqrt(eps),options.TolCon);
        [~,best] = min(state.Score);
        X = state.Population(best,:);
        feasible = isTrialFeasible(X(:),linCon.Aineq,linCon.bineq,linCon.Aeq, ...
                                   linCon.beq,linCon.lb,linCon.ub,tol);
    end % End of feasibleLinearConstraints
    %------------------------------------------------
    function m = meanf(x)
        nans = isnan(x);
        x(nans) = 0;
        n = sum(~nans);
        n(n==0) = NaN; % prevent divideByZero warnings
        % Sum up non-NaNs, and divide by the number of non-NaNs.
        m = sum(x) ./ n;
    end
end
