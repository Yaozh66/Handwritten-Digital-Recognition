function options = checkPopulationInitRange(lb,ub,options)
%checkPopulationInitRange performs check on bounds and PopInitRange and
%   make sure that they are consistent 

%   Copyright 2006-2013 The MathWorks, Inc.

% Range is a (2 x nvars) matrix
lowerRange = options.PopInitRange(1,:)';
upperRange = options.PopInitRange(2,:)';

% Get the length of each variable's range
rangeExtent = abs(upperRange - lowerRange);

% Find any non-existant limits in the range and bounds
finiteLB = isfinite(lb);
finiteUB = isfinite(ub);

if ~options.UserSpecPopInitRange
    % Because the user didn't specify PopInitRange, options.PopInitRange
    % has the default range for the given problem-type. 
    
    % Ranges given bound values where finite, and default range values
    % otherwise. 
    lowerRange(finiteLB) = lb(finiteLB);
    upperRange(finiteUB) = ub(finiteUB);
    
    % In the case of 1-sided bounds, set opposite range to the finite bound
    % offset by the span of default range. NOTE: this guarantees
    % consistency in the range.
    onlyLbFinite = finiteLB & (~finiteUB);
    onlyUbFinite = finiteUB & (~finiteLB);
    upperRange(onlyLbFinite) = lowerRange(onlyLbFinite) + rangeExtent(onlyLbFinite);
    lowerRange(onlyUbFinite) = upperRange(onlyUbFinite) - rangeExtent(onlyUbFinite);
else
    % If user has given an initial range (which must be finite). Check this
    % for consistency with the bounds, and correct where needed.
    % NOTE: at this point both the bounds and PopInitRange have been
    % checked for consistency separately.
    lowerRangeViolatesLB = lowerRange < lb;
    lowerRange(lowerRangeViolatesLB) = lb(lowerRangeViolatesLB);
    
    % If entire range is greater than the ub, attempt to shift range to end
    % at ub. If the lower range is then smaller than the lb, move the lower
    % range to lb.
    lowerRangeViolatesUB = lowerRange > ub;
    upperRange(lowerRangeViolatesUB) = ub(lowerRangeViolatesUB);
    lowerRange(lowerRangeViolatesUB) = max(lb(lowerRangeViolatesUB), ...
        ub(lowerRangeViolatesUB) - rangeExtent(lowerRangeViolatesUB));
    
    upperRangeViolatesUB = upperRange > ub;
    upperRange(upperRangeViolatesUB) = ub(upperRangeViolatesUB);
    % If entire range is less than the lb, attempt to shift range to start
    % at lb. If the upper range is then greater than the ub, move it back
    % to the ub.
    upperRangeViolatesLB = upperRange < lb;
    lowerRange(upperRangeViolatesLB) = lb(upperRangeViolatesLB);    
    upperRange(upperRangeViolatesLB) = min(ub(upperRangeViolatesLB), ...
        lb(upperRangeViolatesLB) + rangeExtent(upperRangeViolatesLB));
end

options.PopInitRange = [lowerRange';upperRange'];
