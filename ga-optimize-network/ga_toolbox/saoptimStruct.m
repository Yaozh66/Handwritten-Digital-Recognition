function optimvalues = saoptimStruct(solverData,problem)
%saoptimStruct create a structure to be passed to user functions
%   OPTIMVALUES = saoptimStruct(solverData,problem) creates a structure
%   OPTIMVALUES with the following fields:
%              x: current point 
%           fval: function value at x
%          bestx: best point found so far
%       bestfval: function value at bestx
%    temperature: current temperature
%      iteration: current iteration
%      funccount: number of function evaluations
%             t0: start time
%              k: annealing parameter
%
%   PROBLEM is a structure with the following fields:
%      objective: function handle to the objective function
%             x0: the start point
%           nvar: number of decision variables
%             lb: lower bound on decision variables
%             ub: upper bound on decision variables
%
%   solverData is a structure used by the solvers SIMULANNEALBND. The
%   fields of this structure may change in future.  

%   This function is private to SIMULANNEAL.

%   Copyright 2006-2010 The MathWorks, Inc.

% Prepare data to be sent over to temperature function
optimvalues.x = reshapeinput(problem.x0,solverData.currentx);
optimvalues.fval = solverData.currentfval;
optimvalues.bestx = reshapeinput(problem.x0,solverData.bestx);
optimvalues.bestfval = solverData.bestfval;
optimvalues.temperature = solverData.temp;
optimvalues.iteration = solverData.iteration;
optimvalues.funccount = solverData.funccount;
optimvalues.t0 = solverData.t0;
optimvalues.k = solverData.k;
