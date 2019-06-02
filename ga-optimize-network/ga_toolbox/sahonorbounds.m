function newx = sahonorbounds(newx,optimValues,problem)
%SAHONORBOUNDS ensures that the points that SIMULANNEAL  move forward with
%   are always feasible.  It does so by checking to see if the given point
%   is outside of the bounds, and then if it is, creating a point called
%   which is on the bound that was being violated and then generating a new
%   point on the line between the previous point and the projnewx. It is
%   assumed that optimValues.x is within bounds.

%   Copyright 2006-2010 The MathWorks, Inc.

% Return if the problem is unbounded
if ~problem.bounded
    return
end

xin = newx; % Get the shape of input
newx = newx(:); % make a column vector
lb = problem.lb;
ub = problem.ub;
lbound = newx < lb;
ubound = newx > ub;
alpha = rand;
% Project newx to the feasible region; get a random point as a convex
% combination of proj(newx) and currentx (already feasible)
if any(lbound) || any(ubound)
    projnewx = newx;
    projnewx(lbound) = lb(lbound);
    projnewx(ubound) = ub(ubound);
    newx = alpha*projnewx + (1-alpha)*optimValues.x(:);
    % Reshape back to xin
    newx = reshapeinput(xin,newx);
else
    newx = xin;
end
