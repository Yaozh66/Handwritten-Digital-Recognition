function positiveScalar(property,value)
%positiveScalar any positive scalar

%   Copyright 2007-2009 The MathWorks, Inc.

valid =  isreal(value) && isscalar(value) && (value > 0);
if(~valid)
    error(message('globaloptim:positiveScalar:notPosScalar', property));
end
