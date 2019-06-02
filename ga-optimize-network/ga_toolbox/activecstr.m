function active = activecstr(x,A,LB,UB,ToL)
%ACTIVECSTR determines the active constraints with
% 	respect to A, LB and UB with a specified tolerance 'tol'

%   Copyright 2003-2006 The MathWorks, Inc.


%setup the constraint status A*x; we already have LB and UB.
Ax = A*x;
%Check the tolerance with respect to each constraints;
lowerbounds = (abs(LB-Ax)<=ToL);
upperbounds = (abs(Ax-UB)<=ToL);

active = any(lowerbounds) || any(upperbounds);