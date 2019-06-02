function solverData = sacheckexit(solverData,problem,options)
%SACHECKEXIT is used to determine whether or not SIMULANNEAL should
%   terminate its run.  The function iterates through each stopping
%   criterion and if it has been met then the appropriate  exitflag and
%   message are set.

%   This function is private to SIMULANNEAL.

%   Copyright 2006-2016 The MathWorks, Inc.

% Iterate through the exit criteria and check to see if any of them have
% been met.
% If an exit criterion has been met then set the appropriate exit flag and
% exit message and set data.running to false.

% If the display is on iterative mode or higher and it is time to do so,
% display relevant data


reannealFlag = solverData.acceptanceCounter == options.ReannealInterval && solverData.iteration ~=0;
if reannealFlag
   % Reset the acceptancCounter to 0
   solverData.acceptanceCounter = 0;
end
if options.Verbosity > 1 
    if reannealFlag
        fprintf('%s%5.0f      %5.0f   %12.6g   %12.6g   %12.6g\n','*', ...
            solverData.iteration,solverData.funccount,solverData.bestfval, ...
            solverData.currentfval,mean(solverData.temp));
    elseif mod(solverData.iteration,options.DisplayInterval)==0 || ...
            solverData.iteration == options.MaxIter
        fprintf('%s%5.0f      %5.0f   %12.6g   %12.6g   %12.6g\n',' ', ...
            solverData.iteration,solverData.funccount,solverData.bestfval, ...
            solverData.currentfval,mean(solverData.temp));
    end
end


if solverData.stopPlot || solverData.stopOutput
    solverData.running = false;
    solverData.exitflag = -1;
    solverData.message = sprintf('Stop requested.');
    return;
end

% Compute change in bestfval and individuals in last options.StallIterLimit
% iterations
funChange = Inf;
if solverData.iteration >= options.StallIterLimit
    bestfvals =  solverData.bestfvals;
    funChange = sum(abs(diff(bestfvals)));
end
if funChange <= options.TolFun
    solverData.running = false;
    if isTrialFeasible(solverData.bestx(:), [], [], [], [], problem.lb(:), problem.ub(:),0)
        solverData.message = sprintf('Optimization terminated: change in best function value less than options.FunctionTolerance.');
        solverData.exitflag = 1;
    else
        % If a user specifies their own annealing and acceptance functions,
        % it is possible for the algorithm to terminate at a point outside
        % the bounds.
        solverData.message = sprintf('%s%s%s', 'Optimization terminated: ', ...
            'change in best function value less than options.FunctionTolerance, ', ...
            'but the bounds are not satisfied.');
        solverData.exitflag = -2;
    end
    return;
end

if solverData.iteration > options.MaxIter
    solverData.running = false;
    solverData.exitflag = 0;
    msg =  sprintf('%s', 'Maximum number of iterations exceeded: ');
    solverData.message = [msg,sprintf('%s', 'increase options.MaxIterations.')];
    return;
end

if solverData.funccount > options.MaxFunEvals
    solverData.running = false;
    solverData.exitflag = 0;
    msg = sprintf('%s', 'Maximum number of function evaluations exceeded: ');
    solverData.message = [msg, sprintf('%s', 'increase options.MaxFunctionEvaluations.')];
    return;
end

if toc(solverData.t0) > options.TimeLimit
    solverData.running = false;
    solverData.exitflag = -5;
    msg = sprintf('%s', 'Time limit exceeded: ');
    solverData.message = [msg, sprintf('%s', 'increase options.MaxTime.')];
    return;
end

if solverData.bestfval <= options.ObjectiveLimit
    solverData.running = false;
    if isTrialFeasible(solverData.bestx(:), [], [], [], [], problem.lb(:), problem.ub(:),0);
        solverData.exitflag = 5;
        solverData.message = sprintf(['Optimization terminated: ', 'best function value reached options.ObjectiveLimit.']);
    else
        % If a user specifies their own annealing and acceptance functions,
        % it is possible for the algorithm to terminate at a point outside
        % the bounds.        
        solverData.exitflag = -2;
        solverData.message = sprintf('%s%s%s', 'Optimization terminated: ', ...
            'best function value reached options.ObjectiveLimit, ',...
            'but the bounds are not satisfied.');        
    end
    return;
end

% Setup display header every thirty iterations
if options.Verbosity > 1 && mod(solverData.iteration,options.DisplayInterval*30)==0 && ...
        solverData.iteration >0 && solverData.iteration < options.MaxIter
    fprintf('\n                           Best        Current           Mean');
    fprintf('\nIteration   f-count         f(x)         f(x)         temperature\n');
end
