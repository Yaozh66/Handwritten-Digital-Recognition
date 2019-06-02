function [Fvals,C,Ceq,isFeas] = objAndConVectorizer(pop,objFcn,nonlconFcn, ...
                          numObj,mIneq,mEq,SerialUserFcn,isFeas,TolCon)
%objAndConVectorizer is a utility function used for "vectorizing" an
%objective and nonlinear constraint function.
%NOTE: this function evaluates the nonlinear constraints first and only
%evaluates the objective if the constraints are feasible.

%   Copyright 2014 The MathWorks, Inc.

try
    popSize = size(pop,1);
    hasNonlinCon = mIneq + mEq > 0;
    Fvals = Inf(popSize,numObj);
    C = zeros(popSize,mIneq);
    Ceq = zeros(popSize,mEq);
    
    % Use for if SerialUserFcn is 'true'; the if-and-else part should
    % be exactly same other than parfor-for syntax difference.
    if SerialUserFcn
        for i = 1:popSize
            if hasNonlinCon
                [thisc, thisceq] = feval(nonlconFcn,pop(i, :));
                if mIneq > 0
                    C(i,:) = thisc(:);
                    isFeas(i) = isFeas(i) && all(thisc(:) <= TolCon);
                end
                if mEq > 0
                    Ceq(i,:) = thisceq(:);
                    isFeas(i) = isFeas(i) && all(abs(thisceq(:)) <= TolCon);
                end
            end
            if isFeas(i)
                Fvals(i,:) = feval(objFcn,(pop(i,:)));
            end
        end
    else
        parfor (i = 1:popSize)
            if hasNonlinCon
                [thisc, thisceq] = feval(nonlconFcn,pop(i, :));
                if mIneq > 0
                    C(i,:) = thisc(:);
                    isFeas(i) = isFeas(i) && all(thisc(:) <= TolCon);
                end
                if mEq > 0
                    Ceq(i,:) = thisceq(:);
                    isFeas(i) = isFeas(i) && all(abs(thisceq(:)) <= TolCon);
                end
            end    
            if isFeas(i)
                Fvals(i,:) = feval(objFcn,(pop(i,:)));
            end            
        end
    end
catch userFcn_ME
    if iscell(pop) % if it is a custom PopulationType
        Fvals = objFcn(pop);
        if hasNonlinCon
            [C,Ceq] = nonlconFcn(pop);
            isFeas = isFeas & isNonlinearFeasible(C,Ceq,TolCon);
        end
    else
        gads_ME = MException('globaloptim:objAndConVectorizer:fitnessEvaluation', ...
            'Failure in user-supplied fitness function evaluation. Cannot continue.');
        userFcn_ME = addCause(userFcn_ME,gads_ME);
        rethrow(userFcn_ME)
    end
end
