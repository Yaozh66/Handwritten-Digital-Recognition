function [Pop,Score,Rank,Distance,C,Ceq,isFeas,maxLinInfeas, warningThrown] = rankAndDistance( ...
                        Pop,Score,C,Ceq,isFeas,maxLinInfeas,options,nParents, warningThrownEarlier)
%rankAndDistance Assign rank and distance measure to each individual

%   Copyright 2007-2014 The MathWorks, Inc.

popSize = size(Pop,1);
Rank = Inf(popSize,1);
nScore = size(Score,2);

if isempty(nParents)
    nParents = popSize;
end

warningThrown = warningThrownEarlier;
if(~warningThrownEarlier && ~isreal(Score(isFeas,:)))
    warningThrown = true;
%NOTE: this warning is in rankAndDistanceComplex instead of rankAndDistance
%due to some perforce misbehavior. This should be fixed, if possible.
    msg = getString(message('globaloptim:rankAndDistanceComplex:complexScore', 'gamultiobj'));
    warning('globaloptim:rankAndDistance:complexScore',msg);
end

% In problems with nonlinear constraints, we use the concept of
% "constraint-domination" to determine rank:
% - Feasible points dominate any infeasible points (regardless of objective values)
% - Within the infeasible set, points with lowest constraint violation
%   measure dominate 
% - Within the feasible set, we use the unconstrained multi-objective
%   domination measure.
%
% To do this efficiently, we partition the data into feasible and
% infeasible sets, and then do the domination tests separately within those
% sets. This avoids unnecessary comparisons between the two. Also, we only
% need to compute a scalar constraint violation and a simple sorting to
% determine the rank within the infeasible set.

% Get ranks for the feasible set
if nScore > 1
    feasRank = globaloptim.internal.mexfiles.mx_nonDominatedRank(Score(isFeas,:));
else
    % Problems with single objectives don't need the domination test. A
    % simple sort is all that is needed.
    feasRank = sortedRank(Score(isFeas,:)); 
end
Rank(isFeas) = feasRank;

% Now, rank the infeasible set ONLY if the population has infeasible members. 
if any(~isFeas)
    constrViol = maxLinInfeas(~isFeas);
    if(size(C,2) + size(Ceq,2) > 0)
        % Compute L1 constraint violation for the population members that have
        % been marked infeasible. (NOTE: Population are the rows, constraints
        % are the columns. Sum along rows.)
        constrViol = constrViol + sum([C(~isFeas,:), abs(Ceq(~isFeas,:))],2);
    end
    % Get rank from the sort and offset by the number of feasible points so
    % that no infeasible point will be ranked above a feasible point.
    infeasRank = sortedRank(constrViol);
    if ~isempty(feasRank)
        Rank(~isFeas) = max(feasRank) + infeasRank; % Note: offset by numFeas
    else
        Rank = infeasRank;
    end
end

if nScore == 1
    % In the case of a single objective, there are no pareto fronts.
    % Rather, each population member is its own "front" on the real line.
    % The distance calculation and trimming are then irrelevant. All
    % distances will come out as Inf. Re-size other arrays accordingly.
    index = Rank > nParents;
    Rank(index,:) = [];
    Pop(index,:) = [];
    Score(index,:) = [];
    C(index,:) = [];
    Ceq(index,:) = [];
    isFeas(index,:) = [];
    maxLinInfeas(index,:) = [];
    Distance = Inf(nParents,1);
    return
end

% Reset popSize to nParents for the rest of the function so that all
% array dimensions agree
popSize = size(Pop,1);
Distance = zeros(popSize,1);
numRank = unique(Rank); % numRank will be sorted

% Compute crowding distance for individuals in each front
for i = numRank'
   % Get individual from each front
   index = (Rank == i);
   Distance(index) = options.DistanceMeasureFcn(Pop(index,:), ...
       Score(index,:),options,options.DistanceMeasureFcnArgs{:}); 
end

% If populations were not combined then no need to trim
if nParents == popSize
    % do nothing
else
    [Pop,Score,Rank,Distance,C,Ceq,isFeas,maxLinInfeas] = trimPopulation( ...
        Pop,Score,Rank,Distance,C,Ceq,isFeas,maxLinInfeas,popSize,nScore, ...
        nParents,options.ParetoFraction);
end


%--------------------------------------------------------------------------
function rank = sortedRank(values)
% Sort values in ascending order and return the rank of each element of
% values
nValues = size(values,1);
[~,sortIdx] = sort(values);
rank = zeros(nValues,1);
rank(sortIdx) = 1:nValues;



