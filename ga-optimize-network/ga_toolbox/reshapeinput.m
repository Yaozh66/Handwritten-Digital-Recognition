function X = reshapeinput(Xin, X)
% RESHAPEINPUT reshape X to match the shape of Xin 

%   Copyright 2003-2012 The MathWorks, Inc.


[m,n] = size(Xin);
% Scalar input is row major
if m == n && m == 1 
    X = X(:); 
    return; 
end

% Single point evaluation
if isvector(X) % X is a vector so use shape information
    Xin(:) = X;
    X = Xin;
    return;
elseif isvector(Xin)
    if  m > n && n == 1  % col major input
        return;
    elseif n > m && m == 1 % row major input
        X = X';
    end
else % Xin is a matrix; not a documented feature
    p = size(Xin,2);
    if p > 1          % Matrix Xin with vectorized 'on' 
        X = reshape(X,m,n,p);
    else
        X = reshape(X,m,n);
    end
end
