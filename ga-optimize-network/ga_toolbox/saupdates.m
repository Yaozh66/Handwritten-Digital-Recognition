function solverData = saupdates(solverData,problem,options)
%SAUPDATES is used to update values during runs of SIMULANNEAL. It updates
%   the counters, as well as the temperature and the recentargs/recentvals
%   (used with TolX/TolFun) and the global best values.

%   This function is private to SIMULANNEAL.

%   Copyright 2006-2010 The MathWorks, Inc.

% Increment the data.k's and the data.iter counter
solverData.iteration = solverData.iteration+1;
solverData.k = solverData.k+1;

% If it is time to do so, reanneal
if solverData.acceptanceCounter == options.ReannealInterval && solverData.iteration ~=0
    solverData = reanneal(solverData,problem,options);
end

optimvalues = saoptimStruct(solverData,problem);
% Create a new temperature vector
try
    solverData.temp = max(eps,options.TemperatureFcn(optimvalues,options));
catch userFcn_ME
    gads_ME = MException('globaloptim:saupdate:invalidTemperatureFcn', ...
        'Failure in TemperatureFcn evaluation.');
    userFcn_ME = addCause(userFcn_ME,gads_ME);
    rethrow(userFcn_ME)
end

% Update the global best point and value if appropriate
if solverData.currentfval < solverData.bestfval
    solverData.bestx = solverData.currentx;
    solverData.bestfval = solverData.currentfval;
end
solverData.bestfvals(end+1) = solverData.bestfval;
% Restrict the length of solverData.bestfvals to StallIterLimit
if solverData.iteration > options.StallIterLimit
    solverData.bestfvals(1) = [];
end
