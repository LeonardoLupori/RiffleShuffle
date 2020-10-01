function [P,offset] = padTB(I,f)
% Increase the height of a 2D matrix by a factor of f by padding the matrix
% to the top and to the bottom with zeros
% 
% Syntax:  [P,offset] = padTB(I,f)
%
% Inputs:
%    I - 2D matrix
%    f - padding factor
%
% Outputs:
%    P - Zero-padded 2D matrix
%    offset - index in the first dimension (rows) where the data from
%    the original image starts in the padded version
%
% see also: padLR

if f<1
    error('Padding factor must be > 1.\nGot %.3f instead',f)
end

% Preallocate a matrix with a height expanded by a factor f
P = zeros(round(f*size(I,1)),size(I,2));

offset = floor((size(P,1)-size(I,1))/2);
% Insert the original image in the center of P
P(offset+1:offset+size(I,1),:) = I;
offset = offset+1;

end