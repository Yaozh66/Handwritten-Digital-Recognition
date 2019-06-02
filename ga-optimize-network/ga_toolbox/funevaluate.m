function [f,count, Cache] = funevaluate(FUN,Xin,X,cacheflag,Cache, cachetol,cachelimit, varargin)
%FUNEVALUATE Evaluate objective function FUN at X.
% 	This function takes a vector or matrix X and evaluate FUN at X.
% 	If X is a matrix then FUN must return a vector output. The caller
%   of this function should do the error checking and make sure
% 	that FUN will be able to handle X which is being passed to this function.
%
% 	cacheflag: A flag for using CACHE. If 'off', no cache is used.
%
%   Cache: A pointer to the C++ XCache object containing evaluated points.
%
% 	CACHETOL: Tolerance used in cache in order to determine whether two points
% 	are same or not.
%
% 	CACHELIMIT: Limit the cache size to 'cachelimit'.
%
% 	Example:
% 	If there are 4 points in 2 dimension space then
%    X is     [2  1  9 -2
%              0  1 -4  5]
%   The objective function will get a transpose of X to be evaluated.

%   Copyright 2003-2007 The MathWorks, Inc.

if nargin == 2 && strcmpi(FUN,'reset') % Want to compare FUN here not Cache since only one input.
    % Delete the cache, which is Xin here (the second variable).
    Xin.clear();
    return;
end

%Return here if X is empty
if isempty(X)
    f = [];
    count = 0;
    return;
end

if strcmpi(cacheflag,'off')  %No CACHE use
    count = size(X,2);
    f = feval(FUN,reshapeinput(Xin,X),varargin{:});
    Real = isreal(f) & ~isnan(f);
    f(~Real) = NaN;
    
elseif strcmpi(cacheflag, 'init') %Initializing the Cache
    cacheSize = 1024;
    if(nargin >= 7 && isnumeric(cachelimit) && ~isempty(cachelimit))
        cacheSize = cachelimit;
    end
    
    %Initialize the Cache
    Cache = globaloptim.internal.PointCache(cacheSize);
    
    count = size(X,2);
    f = feval(FUN,reshapeinput(Xin,X),varargin{:});
    Real = isreal(f) & ~isnan(f);
    f(~Real) = NaN;
    % Do not store evaluated values since this is 'init', to preserve
    % original functionality.
    
elseif strcmpi(cacheflag,'on')
    f = NaN(size(X,2),1);
    cacheSize = 1024;
    if(nargin >= 7 && isnumeric(cachelimit))
        cacheSize = cachelimit;
    end
    
    % Check if there was a Cache inputted, if so we do not need to "setup"
    if(nargin >= 5 && isempty(Cache))
        Cache = globaloptim.internal.PointCache(cacheSize);
    end
    
    InCache = Cache.lookup(X, cachetol);
    XtoEvaluateAndStore = X(:,~InCache);
    
    % Store and evaluate the new points in the cache
    Cache.store(XtoEvaluateAndStore);
    if(size(XtoEvaluateAndStore, 2) > 0)
        f(~InCache) = feval(FUN,reshapeinput(Xin, XtoEvaluateAndStore),varargin{:});
    end
    
    count = sum(~InCache);
    Real = isreal(f) & ~isnan(f);
    f(~Real) = NaN;
end

