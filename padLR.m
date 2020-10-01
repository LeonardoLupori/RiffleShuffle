function [P,offset] = padLR(I,f)
% Increase the width of a 2D matrix by a factor of f by padding the matrix
% to the left and to the right with zeros
% 
% Syntax:  [P,offset] = padLR(I,f)
%
% Inputs:
%    I - 2D matrix
%    f - padding factor
%
% Outputs:
%    P - Zero-padded 2D matrix
%    offset - index in the second dimension (columns) where the data from
%    the original image starts in the padded version
%
% see also: padTB

if f<1
    error('Padding factor must be > 1.\nGot %.3f instead',f)
end

% Preallocate a matrix with a width expanded by a factor f
P = zeros(size(I,1),round(f*size(I,2)));

offset = floor((size(P,2)-size(I,2))/2);
% Insert the original image in the center of P
P(:,offset+1:offset+size(I,2)) = I;
offset = offset+1;
end