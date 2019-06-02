function solverData = sanewpoint(solverData,problem,options)
%SANEWPOINT is used to generate the next point in the algorithm.  It
%   calls the GenFcn in a loop and then plugs the best point it finds into
%   the AcceptFcn to determine whether or not to move forward with the new
%   point.

%   This function is private to SIMULANNEAL.

%   Copyright 2006-2010 The MathWorks, Inc.

% Prepare data to be sent over to annealing and acceptance function
optimvalues = saoptimStruct(solverData,problem);
% Generate one point; call AnnealingFcn
newx = problem.x0; % newx will get the original shape of x0
try 
    % newx will retain its shape irrespective of the shape returned by AnnealingFcn
     newx(:) = options.AnnealingFcn(optimvalues,problem); 
catch userFcn_ME
    gads_ME = MException('globaloptim:callAnnealingFunction:invalidAnnealingFcn', ...
        'Failure in AnnealingFcn evaluation.');
    userFcn_ME = addCause(userFcn_ME,gads_ME);
    rethrow(userFcn_ME)
end
newfval = problem.objective(newx);
solverData.funccount = solverData.funccount+1;

% Call the acceptance function to determine whether or not the new point
% should be accepted
try
    if options.AcceptanceFcn(optimvalues,newx,newfval)
       solverData.currentx(:) = newx;
       solverData.currentfval = newfval;
       solverData.acceptanceCounter = solverData.acceptanceCounter + 1;
    end
catch userFcn_ME
    gads_ME = MException('globaloptim:sanewpoint:invalidAcceptanceFcn', ...
        'Failure in AnnealingFcn evaluation.');
    userFcn_ME = addCause(userFcn_ME,gads_ME);
    rethrow(userFcn_ME)
end


