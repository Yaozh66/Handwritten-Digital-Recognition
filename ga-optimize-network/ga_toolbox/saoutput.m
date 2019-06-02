function [stop,varargout] = saoutput(OutputFcns,OutputFcnArgs,...
    optimvalues,optold,flag,varargin)
%SAOUTPUT Helper function that manages the output functions.
%
%   STATE = SAOUTPUT(OPTIMVAL,OPTOLD,FLAG) runs each of
%   the output functions in the options.OutputFcn cell array. This API is
%   used when FLAG is 'interrupt' or 'done'.
%
%   [STATE, OPTIONS] = SAOUTPUT(OPTIMVAL, OPTOLD, FLAG, OPTIONS,
%   DEFAULTOPT, PROBLEM) runs each of the output functions in the
%   options.OutputFcn cell array. This API is used when FLAG is 'init' or
%   'iter'.
%

%   Copyright 2006-2015 The MathWorks, Inc.


% Initialize
if any(strcmpi(flag, {'init', 'iter'}))
    options = varargin{1};
    problem = varargin{2};
end
stop   = false;
optchanged = false;

% Get the functions and return if there are none
if(isempty(OutputFcns))
    if any(strcmpi(flag, {'init', 'iter'}))
        varargout{1} = options;
    end
    return
end

% Call each output function
for i = 1:length(OutputFcns)
    [stop ,optnew , changed ] = feval(OutputFcns{i},optold,optimvalues, ...
        flag,OutputFcnArgs{i}{:});
    if changed  % If changes are not duplicates, we will get all the changes
        optold = optnew;
        optchanged = true;
    end
end

% Update options if user has changed them. We only have to check this in
% the 'iter' and 'init' cases.
if optchanged && any(strcmpi(flag, {'init', 'iter'}))
    optnew = prepareOptionsForSolver(optold, 'simulannealbnd');
    options = saoptimset(options, optnew);
    options = savalidate(options, problem);
    % Add TolFunValue back
    options.TolFunValue = options.TolFun;
    options.OutputPlotFcnOptions = optim.options.SimulannealbndOptions;
    options.OutputPlotFcnOptions = copyForOutputAndPlotFcn(...
        optim.options.SimulannealbndOptions, options);    
end

% If any stop(i) is true we set the stop to true
stop = any(stop);

% Return options if flag is 'init' or 'iter'
if any(strcmpi(flag, {'init', 'iter'}))
   varargout{1} = options; 
end
