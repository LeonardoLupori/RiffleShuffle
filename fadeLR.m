function F = fadeLR(I,f)
% Fades the left and right portion of the 2D matrix to 0.
% The amount of area for the fading is equivalent to a percentage of the
% width of the input matrix I determined by f in the range [0 1]
% 
% Syntax:  F = fadeLR(I,f)
%
% Inputs:
%    I - 2D matrix
%    f - amount of area to fade
%
% Outputs:
%    P - left and right-faded 2D matrix


c0 = round(f*size(I,2));
c1 = round((1-f)*size(I,2));
F = I;
% Left side fading
for c = 1:c0
    fadingAmount = (c-1)/c0;
    F(:,c) = fadingAmount*F(:,c);
end
% Right side fading
for c = c1:size(F,2)
    fadingAmount = 1-(c-c1)/(size(F,2)-c1);
    F(:,c) = fadingAmount*F(:,c);
end

end