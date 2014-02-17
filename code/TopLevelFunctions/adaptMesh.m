function [newCompMesh, meshDisk] = adaptMesh( PosWQ, L, B, T )
%adaptMesh passt die Diskretisierung an --> um die Position der aktuellen
%WQ feinere Schritte
%   PosWQ: <1x3> double [x, y, z] Position der WQ
%   Cxb: <1x1> double Größe der aktuellen WQ
%   L,B,T: <1xn> double aus componentMesh

% Zur Verfügung stehende Elemente
nx = length(L);
ny = length(B);

% Berechnung der gesamt Steigung in x und y
sx = (max(L) - min(L)) ./ nx;
sy = (max(B) - min(B)) ./ ny;

% Umrechnung von PosWQ in nWQ
nWQx = (PosWQ(1) ./ max(L)).*(nx+1);
nWQy = (PosWQ(2) ./ max(B)).*(ny+1);

ccX = [0, 0, 0, 0, 1; ...
       nx^4, nx^3, nx^2, nx, 1; ...
       4*nWQx^3, 3*nWQx^2, 2*nWQx, 1, 0; ...
       nWQx^4, nWQx^3, nWQx^2, nWQx, 1; ...
       12*nWQx^2, 6*nWQx, 2, 0, 0] \ [min(L); max(L); sx*0.15; PosWQ(1); 0];
   
ccY = [0, 0, 0, 0, 1; ...
       ny^4, ny^3, ny^2, ny, 1; ...
       4*nWQy^3, 3*nWQy^2, 2*nWQy, 1, 0; ...
       nWQy^4, nWQy^3, nWQy^2, nWQy, 1; ...
       12*nWQy^2, 6*nWQy, 2, 0, 0] \ [min(B); max(B); sy*0.15; PosWQ(2); 0];

xgridFinal = polyval(ccX, 0:1:nx);
ygridFinal = polyval(ccY, 0:1:ny);

% Diskretisierung in z-Richtung
zgridFinal = T;

[x, y, z] = meshgrid(xgridFinal, ygridFinal, zgridFinal);

newCompMesh = horzcat(reshape(x, numel(x) ,1), ...
                      reshape(y, numel(y), 1), ...
                      reshape(z, numel(z), 1));


meshDisk = {xgridFinal, ygridFinal, zgridFinal};

end

