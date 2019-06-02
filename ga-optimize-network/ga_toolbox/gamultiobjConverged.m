function [state,exitFlag,reasonToStop] = gamultiobjConverged(options,state)
%gamultiobjConverged Check to see if any of the stopping criteria have been met.


%   Copyright 2007-2015 The MathWorks, Inc.


Gen = state.Generation;

if options.Verbosity > 1
    fprintf('%5.0f      %8.0f      %12.6g      %12.6g\n',Gen,state.FunEval,mean(state.AverageDistance),mean(state.Spread(end,:)));
end

% Window used to get best fval
 Window = options.StallGenLimit + 1;
 spreadChange = Inf;
 % Compute change in fval and individuals in last 'Window' generations
 if Gen > Window
     if size(state.Spread,2) > 1
        Spread =  mean(state.Spread((Gen - Window):end,:),2);
     else
         Spread = state.Spread((Gen - Window):end);
     end
     meanSpread = mean(Spread);
     spreadChange = 0;
     Weight = 0.5;
     for i = 1:Window-1
        spreadChange = spreadChange + (Weight)^(Window- i)*abs(Spread(i+1) - Spread(i))/(1+Spread(i));
     end
     % Take an average of function value change
     spreadChange = spreadChange/Window;
 end

reasonToStop = '';
exitFlag = [];
if(state.Generation >= options.Generations)
    reasonToStop = sprintf('Optimization terminated: maximum number of generations exceeded.');
    exitFlag = 0;
elseif toc(state.StartTime) > options.TimeLimit
    reasonToStop = sprintf('Optimization terminated: time limit exceeded.');
    exitFlag = -5;
elseif(~isempty(state.StopFlag))
    reasonToStop = sprintf('Optimization terminated: %s',state.StopFlag);
    exitFlag = -1;
 elseif spreadChange <= options.TolFun && meanSpread >= Spread(end)
     reasonToStop = sprintf('Optimization terminated: average change in the spread of Pareto solutions less than options.FunctionTolerance.');
     exitFlag = 1;
end

% If it is a constrained problem and we want to check constraints (only
% when GAMULIOBJ is terminating)
if ~isempty(reasonToStop) 
    if ~all(state.isFeas(state.Rank == 1))
        if options.Verbosity > 0
            fprintf('%s\n','Infeasible individuals are present in the final population.');
        end
        reasonToStop = [reasonToStop,...
            sprintf('\n%s','Constraints are not satisfied within constraint tolerance.')];
        exitFlag = -2;
    end
end

if ~isempty(reasonToStop) && options.Verbosity > 0
    fprintf('%s\n',reasonToStop);
    return;
end
% Print header again
if options.Verbosity > 1 && rem(Gen,30)==0 && Gen > 0
    fprintf('\n                              Average            Average\n');
    fprintf('Generation   Func-count    Pareto distance    Pareto spread\n');
end
