function stop = timestorefcn(x,optimValues,state,timeStore)
%TIMESTOREFCN Output function to stop local solver if time limit exceeded.
%
%   STOP = TIMESTOREFCN(X,OPTIMVALUES,STATE,TIMESTORE) is an output
%   function which stops a local solver call if the overall time limit on
%   the global solver has been exceeded. TIMESTORE must be a structure with
%   two fields:
%   
%   TIMESTORE.startTime : time the global solver was started, stored as a 
%                         six element date vector.   
%   TIMESTORE.maxTime   : maximum time the global solver is allowed to run
%                         for in seconds.
%                         
%   See also GLOBALSEARCHNLP, FMULTISTART

%   Copyright 2009 The MathWorks, Inc.

stop = false;
if etime(clock,timeStore.startTime) >= timeStore.maxTime
    stop = true;
end