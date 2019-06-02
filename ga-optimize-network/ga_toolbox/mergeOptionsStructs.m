function mergedOptions = mergeOptionsStructs(defaultOptions,options)
%

%mergeOptionsStructs Merge two structures of options without using
%optimset, avoiding checks for option names or values that it doesn't support.

% Copy any specified options into the options structure. We assume here
% that the values in the fields are valid and have been checked elsewhere.
% NOTE: we may not be able to use optimset to perform the following
% function since optimset may not support all of the option/value
% combinations. So, we essentially replicate the optimset(struct1,struct2)
% syntax here.
if isempty(options)
    mergedOptions = defaultOptions;
else
    mergedOptions = defaultOptions;
    optNames = fieldnames(options);
    for i = 1:length(optNames)
        mergedOptions.(optNames{i}) = options.(optNames{i});
    end
end