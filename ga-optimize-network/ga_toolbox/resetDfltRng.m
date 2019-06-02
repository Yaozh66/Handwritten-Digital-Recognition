function resetDfltRng(rngstate)
%RESETDFLTRNG Reset the random number generator to a saved state.
%
%   This function is private to the GADS solvers

%   Copyright 2008-2016 The MathWorks, Inc.

if ~isempty(rngstate)
    if isfield(rngstate,'Type') && isfield(rngstate,'Seed')
        rng(rngstate)
    elseif isfield(rngstate,'state') && isfield(rngstate,'type')
        dflt = RandStream.getGlobalStream;
        if isempty(rngstate.type) || isequal(rngstate.type,dflt.Type)
            try
                dflt.State = rngstate.state;
            catch ME
                error(message('globaloptim:resetDfltRng:InvalidRNGState'));
            end
        else
            error(message('globaloptim:resetDfltRng:RNGType', rngstate.type, dflt.Type));
        end
    else
        error(message('globaloptim:resetDfltRng:InvalidRNGField'));
    end
end
