function realScalar(property,value)
%realScalar Test for real scalar

%   Copyright 2007-2009 The MathWorks, Inc.

valid = isreal(value) && isscalar(value);
if(~valid)
    error(message('globaloptim:realScalar:notScalar', property));
end
