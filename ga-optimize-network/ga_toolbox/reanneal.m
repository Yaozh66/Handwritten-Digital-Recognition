function solverData = reanneal(solverData,problem,options)
% REANNEAL is used to turn our SIMULANNEALBND algorithm into an adaptive
%   simulated annealing algorithm.  It implements the equations:
%           s(i) = (UB(i)-LB(i))*partial(data.FUN)/partial(ith dimension)
%           k(i) = ((ln[(T0(i)/T(i))(max(s)/s(i))])
%   if the datatype is the normal double vector.  Otherwise it simply
%   resets the data.k values (which in turn resets the temperature
%   values).

% Copyright 2006-2011 The MathWorks, Inc.

%    This function is private to SIMULANNEAL.

nvar = problem.nvar;
lb = problem.lb;
ub = problem.ub;
FUN = problem.objective;

if strcmpi(options.DataType, 'double')
    % Create the boundsdiff vector which will be used later as a multiplier for
    % the finite differences
    % If any of the dimensions are unbounded then just use a vector of ones
    if ~problem.bounded
        BoundsDiff = ones(nvar,1);
    else
        BoundsDiff = ub - lb;
        BoundsDiff(isinf(BoundsDiff)) = 1;
    end

    % The rest of the code represents the following two equations:
    % s(i) = (UB(i)-LB(i))*partial(data.FUN)/partial(ith dimension)
    % k(i) = ((ln[(T0(i)/T(i))(max(s)/s(i))])^nvar
    
    % Set inputs to finitedifferences
    Diff = zeros(nvar,1); % pre-allocate vector containing derivatives
    sizes.xShape = size(problem.x0);
    finDiffOpts.DiffMinChange = 1e-4;
    finDiffOpts.DiffMaxChange = 1.0;
    finDiffOpts.TypicalX = ones(nvar,1);
    finDiffOpts.FinDiffType = 'forward';
    % Set the perturbation factor for forward finite difference
    finDiffOpts.FinDiffRelStep = sqrt(eps)*ones(nvar,1);
    % Create structure of flags for finitedifferences
    finDiffFlags.fwdFinDiff = true; % Always forward fin-diff
    finDiffFlags.scaleObjConstr = false; % No scaling
    finDiffFlags.chkFunEval = false; % Don't validate function values
    finDiffFlags.isGrad = true; % Compute gradient, not Jacobian
    finDiffFlags.hasLBs = false(nvar,1);
    finDiffFlags.hasUBs = false(nvar,1);
    if ~isempty(lb)
        finDiffFlags.hasLBs = isfinite(lb); % Check for lower bounds
    end
    if ~isempty(ub)
        finDiffFlags.hasUBs = isfinite(ub); % Check for upper bounds
    end
    
    [Diff,~,~,numEvals] = finitedifferences(solverData.currentx,FUN,[],lb,ub, ...
        solverData.currentfval,[],[],1:nvar,finDiffOpts,sizes,Diff,[],[], ...
        finDiffFlags,[]);
    solverData.funccount = solverData.funccount + numEvals;
    s = reshape(BoundsDiff,nvar,1).*Diff;
    for i = 1:nvar
        if solverData.temp(i) < eps
            solverData.temp(i) = eps;
        end
        TRatio = options.InitialTemperature(i)/solverData.temp(i);

        if abs(s(i)) < eps
            s(i) = eps;
        end
        sRatio = max(s)/s(i);
        % log(eps) used to prevent infinite k values
        if abs(TRatio*sRatio) < options.TolFun
            solverData.k(i) = abs(log(options.TolFun));
        else
            solverData.k(i) = abs(log(abs(TRatio*sRatio)));
        end
    end
else
    solverData.k(:) = 1;
end


