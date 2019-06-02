function [X,FVAL,optimState] = isconverged(optimState,options,MeshSize,nextIterate,X)
%ISCONVERGED Checks several conditions of convergence.
%
% 	STOP: A flag passed by user to stop the iteration (Used from OutPutFcn)
%
% 	VERBOSITY: Level of display
%
% 	ITER, MAXITER: Current Iteration and maximum iteration allowed respectively
%
% 	FUNEVAL,MAXFUN: Number of function evaluation and maximum iteration
% 	allowed respectively
%
% 	MESHSIZE,MINMESH; Current mesh size used and minimum mesh size
% 	allowed respectively
%
% 	NEXTITERATE: Next iterate is stored in this structure nextIterate.x
%   and nextIterate.f

%   Copyright 2003-2016 The MathWorks, Inc.

verbosity = options.Verbosity;
Iter = optimState.Iter;
maxIter = options.MaxIter;
FunEval = optimState.FunEval;
pollmethod = options.PollMethod;
minMesh = options.TolMesh;
how = optimState.how;
deltaX = optimState.deltaX;
deltaF = optimState.deltaF;
TolFun = options.TolFun;
TolX = options.TolX;
StartTime = optimState.StartTime;

X(:) = nextIterate.x;
FVAL = nextIterate.f;
optimState.msg = '';
if verbosity > 1
    fprintf('%5.0f    %8.0f   %12.6g  %12.4g     %s\n',Iter, FunEval, nextIterate.f, MeshSize, how);
end

% User interruption
if optimState.stopOutput || optimState.stopPlot
    optimState.msg = sprintf('%s','Stop requested.');
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    optimState.exitflag = -1;
    optimState.run = false;
    return;
end
if ~isempty(optimState.infMessage)
    optimState.msg = sprintf('%s','Optimization terminated: ');
    optimState.msg = [optimState.msg, sprintf('%s','objective function has reached -Inf value (objective function is unbounded below).')];
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    optimState.exitflag = 1;
    optimState.run = false;
    return;
end

% Convergence check is different for adaptive mesh and fixed mesh
% algorithms
AdaptiveMesh = any(strcmpi(pollmethod,{'madspositivebasisnp1','madspositivebasis2n'}));

% Check mesh size parameter for fixed mesh direct search
if MeshSize < minMesh && (deltaF < TolFun || deltaX < TolX) && ...
        ~AdaptiveMesh
    optimState.exitflag = 1;
    optimState.run  = false;
    optimState.msg = sprintf('%s','Optimization terminated: ');
    optimState.msg = [optimState.msg,sprintf('%s', 'mesh size less than options.MeshTolerance.')];
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end

% X and Fun tolerances will be used only when iteration is successful and
% Meshsize is of the order of TolX so the progress is very slow (stall)
if ~strcmpi(how,'Refine Mesh') && ~AdaptiveMesh && ...
        ( MeshSize < TolX && (deltaF < TolFun || deltaX < TolX))
    optimState.run  = false;
    optimState.msg = sprintf('%s','Optimization terminated: ');
    if deltaX < TolX && MeshSize < TolX
        optimState.msg = [optimState.msg, sprintf('%s', 'change in X less than options.StepTolerance.')];
        optimState.exitflag = 2;
    else
        optimState.msg = [optimState.msg, sprintf('%s', 'change in the function value less than options.FunctionTolerance.')];
        optimState.exitflag = 3;
    end
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end
% Check poll size parameter for mesh adaptive direct search
if AdaptiveMesh
    if strcmpi(pollmethod,'madspositivebasisnp1')
        framesize = numel(X)*sqrt(MeshSize);
    else
        framesize = sqrt(MeshSize);
    end
    if framesize < minMesh && (deltaF < TolFun || deltaX < TolX)
        optimState.exitflag = 1;
        optimState.run  = false;
        optimState.msg = sprintf('%s','Optimization terminated: ');
        if strcmpi(pollmethod,'madspositivebasisnp1')
            optimState.msg = [optimState.msg,sprintf('%s', 'mesh size less than ''numberOfVariables*sqrt(MeshTolerance)''.')];
        else
            optimState.msg = [optimState.msg,sprintf('%s', 'mesh size less than ''sqrt(MeshTolerance)''.')];
        end
        if verbosity > 0
            fprintf('%s\n',optimState.msg);
        end
        return;
    end

    % X and Fun tolerances will be used only when iteration is successful and
    % Meshsize is of the order of TolX  so the progress is very slow (stall)
    if ~strcmpi(how,'Refine Mesh') && ... 
            (framesize < TolX && (deltaF < TolFun || deltaX < TolX))
        optimState.run  = false;
        optimState.msg = sprintf('%s','Optimization terminated: ');
        if deltaX < TolX && framesize < TolX
            optimState.msg = [optimState.msg, sprintf('%s', 'change in X less than options.StepTolerance.')];
            optimState.exitflag = 2;
        else
            optimState.msg = [optimState.msg, sprintf('%s', 'change in the function value less than options.FunctionTolerance.')];
            optimState.exitflag = 3;
        end
        if verbosity > 0
            fprintf('%s\n',optimState.msg);
        end
        return;
    end

end
% Maximum iteration limit
if Iter > maxIter
    optimState.exitflag = 0;
    optimState.run  = false;
    optimState.msg = sprintf('%s', 'Maximum number of iterations exceeded: ');
    optimState.msg = [optimState.msg,sprintf('%s', 'increase options.MaxIterations.')];
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end
% Maximum function evaluation limit
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
% Maximum time limit
if toc(StartTime) > options.TimeLimit
    optimState.exitflag = 0;
    optimState.run  = false;
    optimState.msg = sprintf('%s', 'Time limit reached: ');
    optimState.msg = [optimState.msg, sprintf('%s', 'increase options.MaxTime.')];
    if verbosity > 0
        fprintf('%s\n',optimState.msg);
    end
    return;
end

% Setup display header every thirty iterations
if verbosity > 1 && rem(Iter,30)== 0 && Iter >0 && Iter < maxIter
    fprintf('\nIter     Func-count        f(x)       MeshSize      Method\n');
end
