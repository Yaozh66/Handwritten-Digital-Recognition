function stop = callOutputAndPlotFcns(options, optimValues, state, fname)
%CALLOUTPUTANDPLOTFCNS Call output and plot functions
%
%   STOP = CALLOUTPUTANDPLOTFCNS(OPTIONS, OPTIMVALUES, STATE, FNAME) calls
%   the output and plot functions specified in the solver OPTIONS
%   structure.
%
%   Note that this function assumes that the output and plot functions are
%   in options.OutputFcns and options.PlotFcns. Furthermore, these fields
%   are assumed to be either empty or cell arrays.
%
%   See also GADSPLOT

%   Copyright 2010-2015 The MathWorks, Inc.

% Call all output functions
stop = false;
if ~isempty(options.OutputFcns)
    switch state
        case {'iter','init'}
            stop = i_callAllOutputFcns(options.OutputFcns, optimValues, state);
        case 'done'
            i_callAllOutputFcns(options.OutputFcns, optimValues, state);
        otherwise
            error(message('globaloptim:callOutputAndPlotFcns:UnknownStateInCALLOUTPUTANDPLOTFCNS'))
    end
end

% Call plot functions
if ~isempty(options.PlotFcns)
    switch state
        case {'iter','init'}
            stop = gadsplot(options, optimValues, state, fname) || stop;
        case 'done'
            gadsplot(options, optimValues, state, fname);
        otherwise
            error(message('globaloptim:callOutputAndPlotFcns:UnknownStateInCALLOUTPUTANDPLOTFCNS'))
    end
end

function stop = i_callAllOutputFcns(OutputFcn, optimValues, state)

% Call each output function
stop = false(length(OutputFcn),1);
for i = 1:length(OutputFcn)
    stop(i) = feval(OutputFcn{i},optimValues,state);
end

% If any stop(i) is true we set the stop to true
stop = any(stop);