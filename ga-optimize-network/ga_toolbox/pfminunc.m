function [X,FVAL,EXITFLAG,OUTPUT] = pfminunc(FUN,initialX,optimState,Iterate,options,defaultopt,OUTPUT)
%PFMINUNC Finds unconstrained minimum of a function.
%   PFMINUNC solves problems of the form:
%      min F(X)
%       X
%
%   Private to PATTERNSEARCH

%   Copyright 2003-2017 The MathWorks, Inc.

objFcnArg = optimState.objFcnArg;
numberOfVariables = optimState.numberOfVariables;

lb = -Inf*ones(numberOfVariables,1);
ub = Inf*ones(numberOfVariables,1);

% Get some initial values
[optimState,nextIterate,MeshSize] = getinitial(optimState,Iterate,lb,ub,options);

X = initialX;
X(:) = Iterate.x;
FVAL = Iterate.f;

% Determine who is the caller
callStack = dbstack;
[~,caller] = fileparts(callStack(2).file);
% Set up output function plot
if options.OutputTrue || options.PlotTrue
    % Set state for plot and output functions (only pfmincon will have
    % 'interrupt' state)
    if ~strcmp(caller,'pfmincon')
        currentState = 'init';
    else
        currentState = 'interrupt';
    end
    callOutputPlotFunctions(currentState)
end

% Setup display header
if  options.Verbosity>1
    fprintf('\n\nIter     Func-count       f(x)      MeshSize     Method\n');
end
% Set state for plot and output functions (only pfmincon will have
% 'interrupt' state)
if ~strcmp(caller,'pfmincon')
    currentState = 'iter';
else
    currentState = 'interrupt';
end
while optimState.run
    % Check for convergence
    [X,FVAL,optimState] = isconverged(optimState,options,MeshSize,nextIterate,X);
    if ~optimState.run
        continue; 
    end
    % SEARCH
    [successSearch,nextIterate,optimState] = search(FUN,X,Iterate,MeshSize,[],[], ...
        [],[],[],[],OUTPUT.problemtype,objFcnArg,optimState,options);
    % POLL
    if ~successSearch  % Unsuccessful search
        [successPoll,nextIterate,optimState] = poll(FUN,X,Iterate,MeshSize,[],[], ...
            [],[],[],[],OUTPUT.problemtype,objFcnArg,optimState,options);
    else
        successPoll =0;
    end
    % Scale the variables in every iterations only if called from pfmincon with 
    % internal flag 'dynamic'. Scale is not updated if called from patternsearch (unconstrained solver) 
    if strcmpi(options.ScaleMesh,'dynamic')
        optimState.scale = logscale(lb,ub,mean(Iterate.x,2));
    end

    % Update
    [MeshSize,Iterate,X,optimState] = updateparam(successPoll,successSearch, ...
        MeshSize,nextIterate,Iterate,X,optimState,options);

    % Call output and plot functions
    if options.OutputTrue || options.PlotTrue
        callOutputPlotFunctions(currentState)
    end
end % End of while

% Call output and plot functions
if options.OutputTrue || options.PlotTrue
    % Set state for plot and output functions (only pfmincon will have
    % 'interrupt' state)
    if ~strcmp(caller,'pfmincon')
        currentState = 'done';
    else
        currentState = 'interrupt';
    end
    callOutputPlotFunctions(currentState)
end

EXITFLAG = optimState.exitflag;
% Update values of OUTPUT structure
OUTPUT.pollmethod = options.PollMethod; % This might change via output function
OUTPUT.searchmethod = options.SearchMethod; % This might change via output function
OUTPUT.iterations = optimState.Iter;
OUTPUT.funccount = optimState.FunEval;
OUTPUT.meshsize = MeshSize;
OUTPUT.message = optimState.msg;

%-----------------------------------------------------------------
% Nested function to call output/plot functions
    function callOutputPlotFunctions(state)
        optimvalues.x = X; 
        optimvalues.iteration = optimState.Iter;
        optimvalues.fval = Iterate.f;
        optimvalues.problemtype = OUTPUT.problemtype;
        optimvalues.meshsize = MeshSize;
        optimvalues.funccount = optimState.FunEval;
        optimvalues.method = optimState.how;
        optimvalues.TolFun = optimState.deltaF;
        optimvalues.TolX = optimState.deltaX;
        solverName = 'Pattern Search';
        switch state
            case {'init', 'iter'}
                if options.PlotTrue
                    optimState.stopPlot = gadsplot(options,optimvalues,state,solverName);
                end
                if options.OutputTrue
                    [optimState.stopOutput,options] = psoutput(...
                        options.OutputFcns, options.OutputFcnsArg, ...
                        optimvalues, options.OutputPlotFcnOptions, state, ...
                        options, defaultopt, numberOfVariables);
                end
            case 'interrupt'
                if options.PlotTrue
                    optimState.stopPlot = gadsplot(options,optimvalues,state,solverName);
                end                
                if options.OutputTrue
                    optimState.stopOutput = psoutput(options.OutputFcns,options.OutputFcnsArg, ...
                        optimvalues,options.OutputPlotFcnOptions,state);
                end
            case 'done'
                if options.PlotTrue
                    gadsplot(options,optimvalues,state,solverName);
                end                
                if options.OutputTrue
                    psoutput(options.OutputFcns,options.OutputFcnsArg,optimvalues,options.OutputPlotFcnOptions,state);
                end
            otherwise 
                return
        end
    end % End of callOutputPlotFunctions
%------------------------------------------------------------------
end  % End of pfminunc



