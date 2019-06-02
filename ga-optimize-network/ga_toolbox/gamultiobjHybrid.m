function state  = gamultiobjHybrid(FitnessFcn,x,fval,C,Ceq,isFeas,maxLinInfeas, ...
                            state,Aineq,bineq,Aeq,beq,lb,ub,ConstrFcn,options)
%gamultiobjHybrid setup arguments for the hybrid function and run it
%
%   This function is private to GAMULTIOBJ

%   Copyright 2007-2015 The MathWorks, Inc.

% Who is the hybrid function
if isa(options.HybridFcn,'function_handle')
    hfunc = func2str(options.HybridFcn);
else
    hfunc = options.HybridFcn;
end

% Create anonymous function to be passed to the hybrid function
FitnessHybridFcn = @(x) FitnessFcn(x,options.FitnessFcnArgs{:});
% Inform about hybrid scheme
if  options.Verbosity > 1
    fprintf('%s%s%s\n','Switching to the hybrid optimization solver (',upper(hfunc),').');
end

% Create room for new population from the hybrid solver
xHybrid = zeros(size(x));
fHybrid = zeros(size(fval));
cHybrid = zeros(size(C));
ceqHybrid = zeros(size(Ceq));
isFeasHybrid = false(size(isFeas));
maxLinInfeasHybrid = zeros(size(maxLinInfeas));
funccount = zeros(1,size(x,1));
% Local variable to use inside parfor loop
args = options.HybridFcnArgs;
% Get TolCon
TolCon = optimget(args,'TolCon',fgoalattain('defaults'),'fast');

% Use for if SerialUserFcn is 'true'; the if-and-else part should
% be exactly same other than parfor-for syntax difference.
if options.SerialUserFcn
    for i = 1:size(x,1)
        [xHybrid(i,:),fHybrid(i,:),cHybrid(i,:),ceqHybrid(i,:),isFeasHybrid(i), ...
         maxLinInfeasHybrid(i),funccount(i)] = callHybridSolver(hfunc, ...
                    FitnessHybridFcn,x(i,:),args,Aineq,bineq,Aeq,beq,lb,ub, ...
                    ConstrFcn,fval,fval(i,:),C(i,:),Ceq(i,:),isFeas(i),maxLinInfeas(i),TolCon);
    end
else % Run fgoalattain in parallel using parfor
    parfor (i = 1:size(x,1))
        [xHybrid(i,:),fHybrid(i,:),cHybrid(i,:),ceqHybrid(i,:),isFeasHybrid(i), ...
         maxLinInfeasHybrid(i),funccount(i)] = callHybridSolver(hfunc, ...
                    FitnessHybridFcn,x(i,:),args,Aineq,bineq,Aeq,beq,lb,ub, ...
                    ConstrFcn,fval,fval(i,:),C(i,:),Ceq(i,:),isFeas(i),maxLinInfeas(i),TolCon);
    end
end
state.FunEval = state.FunEval + sum(funccount);

% Merge xHybrid with current population and find a new non-dominated front
% of size(x,1)
[state.Population,state.Score,state.Rank,state.Distance,...
 state.C,state.Ceq,state.isFeas, state.complexWarningThrown]  = ...
    rankAndDistance([state.Population; xHybrid],[state.Score; fHybrid], ...
                    [state.C; cHybrid], [state.Ceq; ceqHybrid],[state.isFeas; isFeasHybrid], ...
                    [state.maxLinInfeas; maxLinInfeasHybrid],options,...
                    size(state.Score,1), state.complexWarningThrown);


% Inform about hybrid scheme termination
if  options.Verbosity > 1
    fprintf('%s %s\n',upper(hfunc), 'terminated.');
end

%--------------------------------------------------------------------------
function [xHybrid,fvalHybrid,cHybrid,ceqHybrid,isFeasHybrid,maxLinInfeasHybrid,numEvals] = ...
    callHybridSolver(hfunc,FitnessHybridFcn,x,args,Aineq,bineq,Aeq,beq,lb,ub,ConstrFcn, ...
                     allFvals,thisFval,c,ceq,isFeas,maxLinInfeas,TolCon)

% Do not call hybrid function if fval(i,:) have Inf or NaN
numEvals = 0;
if any(~isfinite(thisFval))
    acceptHybridSolution = false;
else
    [pweight,pgoal] = pseudoWeightAndGoal(thisFval,allFvals);
    acceptHybridSolution = false;
    try
        [xHybrid,fvalHybrid,numEvals] = callHybrid(hfunc, ...
            FitnessHybridFcn,x,args,Aineq,bineq,Aeq,beq,lb,ub,ConstrFcn,pgoal,pweight);
        % For fgoalattain, we need to pass the final point and the
        % problem constraints to isHybridPointFeasible.
        hybridConInfo = {xHybrid(:),Aineq,bineq,Aeq,beq,lb,ub};
        [isFeasHybrid,maxLinInfeasHybrid] = isHybridPointFeasible(hybridConInfo, 'fgoalattain', args{:});
        
        if ~isempty(ConstrFcn)
            [cHybrid,ceqHybrid] = feval(ConstrFcn,xHybrid);
            cHybrid = reshape(cHybrid,size(c)); 
            ceqHybrid = reshape(ceqHybrid,size(ceq)); 
            
            if isFeasHybrid
                isFeasHybrid = isNonlinearFeasible(cHybrid,ceqHybrid,TolCon);
            end
        else
            cHybrid = zeros(1,0); ceqHybrid = zeros(1,0);
        end
        acceptHybridSolution = isFeasHybrid;
    catch optim_ME
        if ~isempty(strfind(optim_ME.identifier,'optimlib:optimfcnchk:checkfun'))
            % do nothing
        else
            rethrow(optim_ME);
        end
    end
end
if ~acceptHybridSolution
    xHybrid = x; % Do not change x
    fvalHybrid = thisFval;
    cHybrid = c;
    ceqHybrid = ceq;
    maxLinInfeasHybrid = maxLinInfeas;
    isFeasHybrid = isFeas;
end
