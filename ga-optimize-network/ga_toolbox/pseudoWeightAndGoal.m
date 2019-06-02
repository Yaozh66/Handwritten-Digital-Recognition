function [pweight, pgoal] = pseudoWeightAndGoal(fval,scores)
%pseudoWeightAndGoal Calculate pseudo weight and goal.
%
%   This function is private to GAMULTIOBJ

%   Copyright 2007 The MathWorks, Inc.

fmin = min(scores,[],1);
fmax = max(scores,[],1);
pgoal = fmin;

totalwt = sum((fmax - fval)./(1 + fmax - fmin));
pweight = (fmax - fval)./((1 + fmax - fmin)*totalwt);
