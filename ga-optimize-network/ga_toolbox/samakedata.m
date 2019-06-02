function solverData = samakedata(solverData,problem,options)
%SAMAKEDATA is used to initialize the data structure that is used by
%   SIMULANNEAL throughout their runs.  It also makes sure that
%   options.InitialTemperature is the right length.
%

%    This function is private to SIMULANNEAL.

%   Copyright 2006-2010 The MathWorks, Inc.

solverData.running = true;
solverData.stopPlot = false;
solverData.stopOutput = false;
solverData.message = '';
solverData.iteration = 0;
solverData.acceptanceCounter = 1;


try
    solverData.currentfval = problem.objective(reshapeinput(problem.x0,solverData.currentx));
    solverData.funccount = 1;
catch userFcn_ME
    gads_ME = MException('globaloptim:samakedata:objfunCheck', ...
        'Failure in initial user-supplied objective function evaluation.');
    userFcn_ME = addCause(userFcn_ME,gads_ME);
    rethrow(userFcn_ME)
end
if numel(solverData.currentfval) ~=1
    error(message('globaloptim:samakedata:objfunCheck', 'Your objective function must return a scalar value.'));
end

solverData.bestfval = solverData.currentfval;
solverData.bestx = solverData.currentx;
% Initialize a list to keep a record of best fval found so far
solverData.bestfvals(1) = solverData.bestfval;

solverData.temp = options.InitialTemperature;
solverData.k = ones(problem.nvar,1);
