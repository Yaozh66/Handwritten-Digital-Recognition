function solverData = sahybrid(solverData,problem,options)
%SAHYBRID is used to call the hybrid function (if there is one) every
%   options.HybridInterval iterations.  It also makes sure that
%   constrained or unconstrained problems do not get passed to solvers
%   that cannot handle them.

%   This function is private to SIMULANNEAL.

%   Copyright 2006-2010 The MathWorks, Inc.

% If there is a hybrid function and it has been an appropriate number of
% iterations (or the algorithm is done) then call the hybrid function
if isempty(options.HybridFcn)
    return
end

if isempty(options.HybridInterval) || ...
        ~(mod(solverData.iteration,options.HybridInterval)==0)
    return;
end

if isequal(options.HybridFcn,@patternsearch) && isempty(options.HybridFcnArgs)
    args = psoptimset;
elseif isequal(options.HybridFcn,@fmincon) && isempty(options.HybridFcnArgs)
    args = optimset('Algorithm','active-set');
elseif isequal(options.HybridFcn,@fminunc) && isempty(options.HybridFcnArgs)
    args = optimset('LargeScale','off');
elseif  isempty(options.HybridFcnArgs)
    args = optimset;
else
    args = options.HybridFcnArgs{:};
end

% Who is the hybrid function
hybridFcn = fcnchk(options.HybridFcn);
hfunc = func2str(hybridFcn);

% Inform about hybrid scheme
if  options.Verbosity > 1
    fprintf('%s%s%s\n','Switching to the hybrid optimization algorithm (',upper(hfunc),').');
end
fun = problem.objective;
x0 = reshapeinput(problem.x0,solverData.bestx);
lb = problem.lb;
ub = problem.ub;
% Determine which syntax to call
switch hfunc
    case 'fminsearch'
        [xx,ff,~,o] = hybridFcn(fun,x0,args);
        hybridPointFeasible = true;
    case 'patternsearch'
        [xx,ff,~,o] = hybridFcn(fun,x0,[],[],[],[],lb,ub,[],args);
        % Copy funccount (all lower) to funcCount (camelCase) to make the
        % common solverData update below work.
        o.funcCount = o.funccount;
        % Since we are always calling bound-constrained patternsearch
        % solver, the output structure will always have 'maxconstraint'
        % field. 
        conviol = o.maxconstraint;
        hybridPointFeasible = isHybridPointFeasible(conviol, 'patternsearch', args);
    case 'fminunc'
        [xx,ff,~,o] = hybridFcn(fun,x0,args);
        hybridPointFeasible = true;
    case 'fmincon'
        [xx,ff,~,o] = hybridFcn(fun,x0,[],[],[],[],lb,ub,[],args);
        hybridPointFeasible = isHybridPointFeasible(o.constrviolation, 'fmincon', args);
end

solverData.funccount = solverData.funccount + o.funcCount;
solverData.message   = [solverData.message sprintf('\n%s: \n%s',upper(hfunc),o.message)];
% Determine feasibility of point returned from simulated annealing. The
% point should always be feasible if the built in operators are used, but
% could be infeasible if a user specifies their own.
saPointFeasible = isTrialFeasible(solverData.bestx(:), [], [], [], [], lb, ub, 0);

% Test whether hybrid point should be used
if hybridPointFeasible && (~saPointFeasible || ff < solverData.bestfval)
    solverData.bestfval = ff;
    solverData.bestx = xx;
end
% Inform about hybrid scheme termination
if  options.Verbosity > 0 && strcmpi(args.Display,'off')
    fprintf('%s%s\n',upper(hfunc), ' terminated.');
end