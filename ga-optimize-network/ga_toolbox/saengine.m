function solverData = saengine(solverData,problem,options)
% SAENGINE does the following
%    - check to see if the algorithm is done
%    - generate a next point
%    - call the hybrid search
%    - update solver data
%    - call output and plot functions
%  Until solverData.running is set to false

%    This function is private to SIMULANNEAL.

%   Copyright 2006-2015 The MathWorks, Inc.

fname = 'Simulated Annealing';

% Setup output and plot functions
callOutputPlotFunctions('init');
% Setup display header
if  options.Verbosity > 1
    fprintf('\n                           Best        Current           Mean');
    fprintf('\nIteration   f-count         f(x)         f(x)         temperature\n');
end

while solverData.running
    % Check termination criteria and print iterative display
    solverData = sacheckexit(solverData,problem,options);
    if ~solverData.running, break; end
    % Generate new point 
    solverData = sanewpoint(solverData,problem,options);
    % Call hybrid functions if any
    solverData = sahybrid(solverData,problem,options);
    % Update solverData e.g., iteration, temperature, bestx, bestfval;
    % reannealing may also be done
    solverData = saupdates(solverData,problem,options);
    % Call output/plot functions with 'iter' state
    callOutputPlotFunctions('iter');
end
% Call hybrid functions at the end if any
if isempty(options.HybridInterval)
    options.HybridInterval = solverData.iteration;
    solverData = sahybrid(solverData,problem,options);
end

% Call output/plot functions with 'done' state
callOutputPlotFunctions('done');

% If verbosity > 0 then print termination message
if options.Verbosity > 0
    fprintf('%s\n',solverData.message)
end

%-----------------------------------------------------------------
% Nested function to call output/plot functions
    function callOutputPlotFunctions(state)
        % Prepare data to be sent over to plot/output functions
        optimvalues = saoptimStruct(solverData,problem);
        switch state
            case {'init', 'iter'}
                [solverData.stopOutput,options] = saoutput(options.OutputFcns,options.OutputFcnsArgs, ...
                    optimvalues,options.OutputPlotFcnOptions,state,options,problem);
                % Update options if user has changed them
                solverData.stopPlot = gadsplot(options,optimvalues,state,fname);
            case 'done'
                saoutput(options.OutputFcns,options.OutputFcnsArgs,optimvalues,options.OutputPlotFcnOptions,state);
                gadsplot(options,optimvalues,state,fname);
        end
    end
end
