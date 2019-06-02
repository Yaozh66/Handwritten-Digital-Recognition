function nonNegInteger(property,value)
%nonNegInteger any nonnegative integer
    
%   Copyright 2007-2009 The MathWorks, Inc.

valid =  isreal(value) && isscalar(value) && (value >= 0) && (value == floor(value));
if(~valid)
    error(message('globaloptim:nonNegInteger:negativeNum', property));
end
