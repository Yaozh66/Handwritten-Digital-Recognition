function [X,FVAL,maxConstr,optimState] = psAugConverged(Iterate,X,optimState,psAugParam,options)
%PSAUGCONVERGED Augmented Lagrangian barrier convergence test.
% Private to PATTERNSEARCH

%   Copyright 2005-2017 The MathWorks, Inc.

verbosity = options.Verbosity;
Iter = optimState.Iter;
FunEval = optimState.FunEval;
how = optimState.how;
deltaX = optimState.deltaX;
TolX = options.TolX;
currentTolMesh = psAugParam.currentTolMesh;
minMesh = options.TolMesh;
infMessage = optimState.infMessage;
TolCon = options.TolCon;

X(:) = Iterate.x;
FVAL = Iterate.f;
comp_slack = 0;
maxConstr = 0;
optimState.msg = '';
if optimState.numNonlinIneqcstr
    comp_slack = norm(Iterate.cineq.*psAugParam.lambdabar(1:optimState.numNonlinIneqcstr));
    maxConstr = max([maxConstr;Iterate.cineq(:)]);
end
if optimState.numNonlinCstr > optimState.numNonlinIneqcstr
    maxConstr = max([maxConstr;abs(Iterate.ceq(:))]);
end
% Print some iterative information
if verbosity > 1
    fprintf('%5.0f %9.0f %12.6g %12.4g %12.4g   %s', ...
        Iter,FunEval,FVAL,maxConstr,currentTolMesh,how);
    fprintf('\n');
end
stallTol = min(minMesh,eps);

% Check mesh size tolerance and complementary slackness
if currentTolMesh <= minMesh && comp_slack <= sqrt(TolCon) && maxConstr <= TolCon
    optimState.exitflag = 1;
    optimState.run  = false;
    optimState.msg = sprintf('%s','Optimization terminated: ');
    optimState.msg = [optimState.msg,sprintf('%s', 'mesh size less than options.MeshTolerance')];
    optimState.msg = [optimState.msg,sprintf('\n%s', ' and constraint violation is less than options.ConstraintTolerance.')];
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end

% Constraints are satisfied, deltaX is small, and mesh size is small enough
if deltaX <= TolX && currentTolMesh <= TolX && maxConstr <= TolCon
    optimState.exitflag = 2;
    optimState.run  = false;
    optimState.msg = sprintf('%s','Optimization terminated: Change in X less than options.StepTolerance');
    optimState.msg = [optimState.msg, sprintf('\n%s', ' and constraints violation is less that options.ConstraintTolerance.')];
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end

% Constraints are satisfied but step is too small
if currentTolMesh <= stallTol && maxConstr <= TolCon
    optimState.exitflag = 4;
    optimState.run  = false;
    optimState.msg = sprintf('%s %g','Optimization terminated: norm of the step is less than ',stallTol);
    optimState.msg = [optimState.msg, sprintf('\n%s', ' and constraints violation is less that options.ConstraintTolerance.')];
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end

% Mesh size below tolerance and no improvement in X
if (deltaX <= eps && currentTolMesh <= minMesh)
    optimState.run  = false;
    optimState.msg = sprintf('%s %g','Optimization terminated: norm of the step is less than ',stallTol);
    % Check feasibility
    if  maxConstr <= TolCon
        optimState.exitflag = 4;
        optimState.msg = [optimState.msg, sprintf('\n%s', ' and constraints violation is less that options.ConstraintTolerance.')];
    else % Stall in infeasible region
        optimState.exitflag = -2;
        optimState.msg = sprintf('%s\n','Optimization terminated: no feasible point found.');
    end
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end

% fmincon enocntered NaN or Inf and could not continue; error here
if ~isempty(infMessage) && strmatch('optimlib:optimfcnchk',infMessage)
    error(message('globaloptim:psAugConverged:NaNFval'));
end
% No feasible solution or stall
if strcmpi(psAugParam.step,'Infeasible')
    % Check feasibility
    if  (maxConstr <= TolCon)
         return; % This will stop in later iteration due to TolX
    else % Stall in infeasible region
        optimState.run = false;
        optimState.exitflag = -2;
        optimState.msg = sprintf('%s\n','Optimization terminated: no feasible point found.');
    end
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end

% User interruption
if optimState.stopOutput || optimState.stopPlot
    optimState.exitflag = -1;
    optimState.run = false;
    optimState.msg = sprintf('%s','Stop requested.');
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end

% Maxiter test
if Iter > options.MaxIter
    optimState.exitflag = 0;
    optimState.run  = false;
    optimState.msg = sprintf('%s', 'Maximum number of iterations exceeded: ');
    optimState.msg = [optimState.msg,sprintf('%s', 'increase options.MaxIterations.')];
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end
% max Fun Evaluation test
if FunEval >=  options.MaxFunEvals
    optimState.exitflag = 0;
    optimState.run  = false;
    optimState.msg = sprintf('%s', 'Maximum number of function evaluations exceeded: ');
    optimState.msg = [optimState.msg, sprintf('%s', 'increase options.MaxFunctionEvaluations.')];
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end

% Max time limit test
if toc(optimState.StartTime) > options.TimeLimit
    optimState.exitflag = 0;
    optimState.run  = false;
    optimState.msg = sprintf('%s', 'Time limit reached: ');
    optimState.msg = [optimState.msg, sprintf('%s', 'increase options.MaxTime.')];
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end
% Setup display header every twenty iterations
if verbosity > 1 && rem(Iter,20)== 0 && Iter > 0
    fprintf('\n                                      Max\n');
    fprintf('  Iter   Func-count       f(x)      Constraint   MeshSize      Method\n');
end
