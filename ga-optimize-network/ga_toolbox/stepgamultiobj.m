function state = stepgamultiobj(subpopIndex,thisPopulation,options,state, ...
    GenomeLength,FitnessFcn,ConstrFcn)
%STEPGAMULTIOBJ perform one step using a variant of NSGA-II algorithm
%   This function is private to GAMULTIOBJ.

%   Copyright 2007-2014 The MathWorks, Inc.

popSize     = size(state.Population(thisPopulation,:),1);
population  = state.Population(thisPopulation,:);
C           = state.C(thisPopulation,:);
Ceq         = state.Ceq(thisPopulation,:);
isFeas      = state.isFeas(thisPopulation,:);
maxLinInfeas = state.maxLinInfeas(thisPopulation,:);
score       = state.Score(thisPopulation,:); 
rank        = state.Rank(thisPopulation,:);
Distance    = state.Distance(thisPopulation,:);
score_old   = score;
numObj = size(score,2);

% How many crossover offspring will there be from each source?
nXoverKids = round(options.CrossoverFraction * popSize);
nMutateKids = popSize - nXoverKids;
% how many parents will we need to complete the population?
nParents = 2 * nXoverKids + nMutateKids;


% Selection.
parents = feval(options.SelectionFcn,[-rank,Distance],nParents,options,options.SelectionFcnArgs{:});
% Shuffle to prevent locality effects. 
parents = parents(randperm(length(parents)));

% Everyones parents are stored here for genealogy display
state.Selection = [parents'];

% Here we make all of the members of the next generation
xoverKids  = feval(options.CrossoverFcn,parents(1:(2 * nXoverKids)),options,GenomeLength, ...
    FitnessFcn,score,population,options.CrossoverFcnArgs{:});
mutateKids = feval(options.MutationFcn,parents((1 + 2 * nXoverKids):end),options,GenomeLength, ...
    FitnessFcn,state,score,population,options.MutationFcnArgs{:});

% Group them into the next generation
nextPopulation = [xoverKids ; mutateKids ];

% Evaluate the population
if isfield(options,'LinearConstr') && options.LinearConstr.linconCheck
    [nextIsFeas,nextMaxLinInfeas] = isTrialFeasible(nextPopulation,options.LinearConstr.Aineq, ...
        options.LinearConstr.bineq,options.LinearConstr.Aeq,options.LinearConstr.beq, ...
        options.LinearConstr.lb,options.LinearConstr.ub,options.TolCon);
else
    nextIsFeas = true(size(nextPopulation,1),1);
    nextMaxLinInfeas = zeros(size(nextPopulation,1),1);
end

if strcmpi(options.Vectorized, 'off')
    % Score remaining members of the population
    [nextScore,nextC,nextCeq,nextIsFeas] = objAndConVectorizer(nextPopulation, ...
        FitnessFcn,ConstrFcn,numObj,state.mIneq,state.mEq,options.SerialUserFcn, ...
        nextIsFeas,options.TolCon);
else
    if state.mAll > 0
        [nextC,nextCeq] = ConstrFcn(nextPopulation);
        % Make sure sizes of empties are correct
        if state.mEq == 0
            nextCeq = reshape(nextCeq,size(nextC,1),0);
        elseif state.mIneq == 0
            nextC = reshape(nextC,size(nextCeq,1),0);
        end        
        nextIsFeas = nextIsFeas & isNonlinearFeasible(nextC,nextCeq,options.TolCon);
    else
        nextC = zeros(size(nextPopulation,1),0);
        nextCeq = zeros(size(nextPopulation,1),0);
    end
    
    % Only evaluate feasible points
    nextScore = Inf(size(nextPopulation,1),numObj);
    nextScore(nextIsFeas,:) = FitnessFcn(nextPopulation(nextIsFeas,:));
end

% Update function evaluation counter
state.FunEval = state.FunEval + size(nextScore,1);

%--Prepare for next generation--

% Combine new and old population
population   = [population;   nextPopulation];
score        = [score;        nextScore];
C            = [C;            nextC];
Ceq          = [Ceq;          nextCeq];
isFeas       = [isFeas;       nextIsFeas];
maxLinInfeas = [maxLinInfeas; nextMaxLinInfeas];

% Sort combined population and pick best 'popSize' individuals for next
% generation
[state.Population(thisPopulation,:),state.Score(thisPopulation,:), ...
    state.Rank(thisPopulation,:),state.Distance(thisPopulation,:), ...
    state.C(thisPopulation,:),state.Ceq(thisPopulation,:), ...
    state.isFeas(thisPopulation,:),state.maxLinInfeas(thisPopulation,:),...
    state.complexWarningThrown] = ...
        rankAndDistance(population,score,C,Ceq,isFeas,maxLinInfeas,...
        options,popSize, state.complexWarningThrown);

% Calculate average distance and spread for the Pareto front
[state.AverageDistance(subpopIndex), state.Spread(state.Generation+1,subpopIndex)] = ...
    distanceAndSpread(state.Distance(thisPopulation,:),state.Rank(thisPopulation,:), ...
    state.Score(thisPopulation,:),score_old);

