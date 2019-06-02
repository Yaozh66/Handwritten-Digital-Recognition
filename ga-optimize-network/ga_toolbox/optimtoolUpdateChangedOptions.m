function optnewobject = optimtoolUpdateChangedOptions(...
    optnewstruct, optlastobject, solver, extradefault, validatefcn)
%OPTIMTOOLUPDATECHANGEDOPTIONS Update options that have changed when 
%                              optimtool is paused
%
%   OPTNEWOBJECT = OPTIMTOOLUPDATECHANGEDOPTIONS(OPTNEWSTRUCT,
%   OPTLASTOBJECT, SOLVER) encapsulates common update tasks when updating
%   options in OPTNEW that have changed on resuming an OPTIMTOOL run. This
%   calling syntax is designed for the cases when SOLVER is equal to
%   'patternsearch' or 'simulannealbnd'.
%
%   OPTNEWOBJECT = OPTIMTOOLUPDATECHANGEDOPTIONS(OPTNEWSTRUCT,
%   OPTLASTOBJECT, SOLVER, EXTRADEFAULT, VALIDATEFCN) allows extra default
%   information and a validation function to be passed for the case where
%   SOLVER is equal to 'ga' or 'gamultiobj'.
%
%   See also GATOOLOUTPUT, GAMULTIOBJTOOLOUTPUT, PSEARCHTOOLOUTPUT,
%   SATOOLOUTPUT

%   Copyright 2015 The MathWorks, Inc.

if nargin < 5
    validatefcn = [];
end

if nargin < 4
    extradefault = {};
end

switch solver
    case 'simulannealbnd'
        optionsfcn = @saoptimset;
    case {'ga', 'gamultiobj'}        
        optionsfcn = @gaoptimset;
    case 'patternsearch'
        optionsfcn = @psoptimset;
end

% 1) Add output function to the list
optnewstruct = addOptimguiOutputFcn(optnewstruct, solver);

% 2) Create a full options structure for the solver containing the new
% option settings.
optdefaultstore = getOptionsStore(optimoptions(solver));
optdefault = optdefaultstore.Defaults;
optdefault.TolFun = optdefault.TolFunValue;
optdefault.Display = 'off';
for i = 1:2:length(extradefault)
   optdefault.(extradefault{i}) =  extradefault{i+1};
end
optnewstructwithdefault = optionsfcn(optdefault, optnewstruct);

% 3) Validate new options if a validation function has been supplied. 
%
% We do the validate first because this ensures that any options that are
% taking their runtime default value are initialized correctly.
%
% Create a full options structure for the solver containing the new option
% settings. The call to validate requires all the options to be present,
% hence the call to the old options setting function (either gaoptimset,
% saoptimset or psoptimset). A note on the "new" options structures here:
%
% optnew: Options structure containing non-empty values for options that
% have been changed and empty values otherwise
%
% optnew2: Options structure containing new option values and default
% values. The call to validate ensure that optnew2 contains the correct
% runtime values.
%
% Note further that the call to validate needs a full structure, optnew2.
% It also needs optnew (with its empty values indicating default) to
% determine the correct runtime default option values.
if ~isempty(validatefcn)
    optnewstructwithdefault = validatefcn(optnewstructwithdefault, optnewstruct);
end

% 4) Merge new and default options structures

% We need to return an options object, not a structure.
optnewobject = optlastobject;

% Ideally we would use the copyForOutputAndPlotFcn method
% to copy the updated options into the output function
% options object. This method does not mark any options as
% "Set by user".
%
% However, the driver function which controls all ga-based
% output functions, gaoutput, calls prepareOptionsForSolver
% to extract the options for the next iteration of the
% solver. prepareOptionsForSolver ignores any options which
% are not marked as "Set by user". As such, any changes to
% the options are ignored.
%
% Any options that have been updated by the user must be
% marked as "Set by user". To do this we will loop through
% all the options and set those whose value has changed
% from the previous iteration.
propNames = fieldnames(optnewstructwithdefault);
for i = 1:length(propNames)
    % The options structure from optimtool (optnewstructwithdefault) only
    % supports old names of the options, whereas the new options objects
    % support both. As such, we have to cycle through the larger structure
    % (rather than the smaller object) to check the options that have been
    % updated by the user. 
    %
    % The larger structure contains options for all the solvers. Hence we
    % perform the test below in a try-catch to allow the loop to proceed
    % when we check an option which isn't in the current solver.
    try
        if ~isequal(optnewstructwithdefault.(propNames{i}), optnewobject.(propNames{i}))
            optnewobject.(propNames{i}) = optnewstructwithdefault.(propNames{i});
        end
    catch
        % Nothing to do options that do not belong to this
        % solver.
    end
end