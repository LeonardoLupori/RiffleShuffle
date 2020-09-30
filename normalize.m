function J = normalize(I)
% Normalize all the values in a multidimensional array in the range [0 1]
% 
% Syntax:  J = normalize(I)
%
% Inputs:
%    I - N-D Array 

%
% Outputs:
%    J - N-D Array with values in the range [0 1]
%
    J = I;
    minJ = min(J(:));
    maxJ = max(J(:));
    
    if maxJ > minJ
        J = (J-minJ)/(maxJ-minJ);
    end
end