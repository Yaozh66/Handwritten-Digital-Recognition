function [optimState,nextIterate,MeshSize] = getinitial(optimState,Iterate,lb,ub,options)
%GETINITIAL is private to pfminlcon, pfminbnd and pfminunc.

%   Copyright 2003-2017 The MathWorks, Inc.

numberOfVariables = optimState.numberOfVariables;
neqcstr = optimState.neqcstr;
% Initialization
optimState.run = true;
nextIterate = Iterate;
optimState.Iter = 0;
optimState.FunEval = 1;
optimState.infMessage  = '';
optimState.stopPlot = false;
optimState.stopOutput = false;
optimState.deltaF = NaN;
optimState.deltaX = NaN;
optimState.Successdir = [];
optimState.how = ' ';
optimState.MeshCont = options.MeshContraction;
optimState.scale = ones(numberOfVariables,1);
optimState.exitflag = -1;
MeshSize = options.InitialMeshSize;

% Calculate scale
if ~strcmpi(options.ScaleMesh,'off') && ~neqcstr
    meanX = mean([Iterate.x],2);
    optimState.scale = logscale(lb,ub,meanX);
end

optimState.StartTime = tic;



