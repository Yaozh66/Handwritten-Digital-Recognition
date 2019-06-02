function [lowerbounds,upperbounds] = checkconstraints(x,A,LB,UB,ToL)
%CHECKCONSTRAINTS determines the active lower and upper constraints with
%   respect to A, LB and UB with a specified tolerance 'tol'
%   
%   LOWERBOUNDS, UPPERBOUNDS are indices of active constraints w.r.t. lower
%   and upper bounds (LB and UB)

%   Copyright 2003-2007 The MathWorks, Inc.


% Setup the constraint A*x; we already have LB and UB.
Ax = A*x;
% Check the tolerance with respect to each constraint;
lowerbounds = (abs(LB-Ax)<=ToL);
upperbounds = (abs(Ax-UB)<=ToL);

