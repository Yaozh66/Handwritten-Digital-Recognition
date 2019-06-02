function [nextScore,nextPopulation,state] = stepGASA(thisScore,thisPopulation,options,state,GenomeLength,FitnessFcn,ann_data,ann_label,layer)
%STEPGA Moves the genetic algorithm forward by one generation
%   This function is private to GA.

%   Copyright 2003-2007 The MathWorks, Inc.

% how many crossover offspring will there be from each source?
nEliteKids = options.EliteCount;
nXoverKids = round(options.CrossoverFraction * (size(thisPopulation,1) - nEliteKids));
nMutateKids = size(thisPopulation,1) - nEliteKids - nXoverKids;
% how many parents will we need to complete the population?
nParents = 2 * nXoverKids + nMutateKids;

% decide who will contribute to the next generation

% fitness scaling
state.Expectation = feval(options.FitnessScalingFcn,thisScore,nParents,options.FitnessScalingFcnArgs{:});

% selection. parents are indices into thispopulation
parents = feval(options.SelectionFcn,state.Expectation,nParents,options,options.SelectionFcnArgs{:});

% shuffle to prevent locality effects. It is not the responsibility
% if the selection function to return parents in a "good" order so
% we make sure there is a random order here.
parents = parents(randperm(length(parents)));

[unused,k] = sort(thisScore);

% Everyones parents are stored here for genealogy display
state.Selection = [k(1:options.EliteCount);parents'];

% here we make all of the members of the next generation
eliteKids  = thisPopulation(k(1:options.EliteCount),:);
xoverKids  = feval(options.CrossoverFcn, parents(1:(2 * nXoverKids)),options,GenomeLength,FitnessFcn,thisScore,thisPopulation,options.CrossoverFcnArgs{:});
mutateKids = feval(options.MutationFcn,  parents((1 + 2 * nXoverKids):end), options,GenomeLength,FitnessFcn,state,thisScore,thisPopulation,options.MutationFcnArgs{:});

% group them into the next generation
nextPopulation = [ eliteKids ; xoverKids ; mutateKids ];
% score the population
%We want to add the vectorizer if fitness function is NOT vectorized

%% 添加模拟退火算法
%模拟退火算法的配置，优化10代，绘出适应度的收敛曲线
sa_options = saoptimset('PlotFcn',@saplotbestf,'MaxIter',10);
lb=repmat(-3,length(nextPopulation),1);
ub=repmat(3,length(nextPopulation),1);
inputnum=size(ann_data,1);
outputnum=size(ann_label,1);
obj=@(x) fun3(x,inputnum,layer,outputnum,ann_data,ann_label);
for i=1:size(nextPopulation,1)
    nextPopulation(i,:)=simulannealbnd(obj,nextPopulation(i,:),lb,ub,sa_options);%对每一个个体执行退火算法，适应度函数直接取为遗传算法计算
end

%% 结束模拟退火算法算法，并重新计算score
if strcmpi(options.Vectorized, 'off') 
    nextScore = fcnvectorizer(nextPopulation,FitnessFcn,1,options.SerialUserFcn);
else
    nextScore = FitnessFcn(nextPopulation);
end 
% Make sure score is a column vector
nextScore = nextScore(:);
state.FunEval = state.FunEval + size(nextScore,1);