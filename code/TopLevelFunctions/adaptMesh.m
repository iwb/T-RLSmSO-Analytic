function [newCompMesh, meshDisk] = adaptMesh( PosWQ, L, B, T )
%adaptMesh passt die Diskretisierung an --> um die Position der aktuellen
%WQ feinere Schritte
%   PosWQ: <1x3> double [x, y, z] Position der WQ
%   Cxb: <1x1> double Größe der aktuellen WQ
%   L,B,T: <1xn> double aus componentMesh

% Zur Verfügung stehende Elemente
nx = length(L);
ny = length(B);

% Länge des linearen zwischen Abschnittes
nlinX = floor(nx/10);
nlinY = floor(ny/10);

% Berechnung der gesamt Steigung in x und y
sx = (L(end) - L(1)) ./ nx;
sy = (B(end) - B(1)) ./ ny;

% Berechnung der linearen Steigung
slinX = 0.15*sx;
slinY = 0.15*sy;

% Umrechnung von PosWQ in nWQ
nWQx = (PosWQ(1) ./ L(end)).*(nx+1);
nWQy = (PosWQ(2) ./ B(end)).*(ny+1);

% Berechnung der Hilfspunkte (Endpunkte des linearen Abschnittes)
%Elementzahl
nlinPosX(1) = ceil(nWQx - nlinX/2);
nlinPosX(2) = floor(nWQx + nlinX/2);

nlinPosY(1) = ceil(nWQy - nlinY/2);
nlinPosY(2) = floor(nWQy + nlinY/2);

%Hilfspunkte dürfen nicht zu nahe am Rand liegen
if nlinPosX(1) < 4
    nlinPosX(1) = 4;
end
if nlinPosX(2) > (length(L) - 4)
    nlinPosX(2) = length(L) - 4;
end

if nlinPosY(1) < 4
    nlinPosY(1) = 4;
end
if nlinPosY(2) > (length(B) - 4)
    nlinPosY(2) = length(B) - 4;
end

%Hilfspunkte müssen richtige Reihenfolge besitzen
if nlinPosX(1) > nlinPosX(2)
    nlinPosX(1) = nlinPosX(2);  %Es existiert kein geradliniges Teilstück
end
if nlinPosY(1) > nlinPosY(2)
    nlinPosY(1) = nlinPosY(2);  %Es existiert kein geradliniges Teilstück
end

%Metrische Einheit
linPosX(1) = (nlinPosX(1) / (nx+1)) * L(end); %PosWQ(1) - (nlinX/2 * slinX);
linPosX(2) = (nlinPosX(2) / (nx+1)) * L(end); %PosWQ(1) + (nlinX/2 * slinX);

linPosY(1) = (nlinPosY(1) / (ny+1)) * B(end); %PosWQ(2) - (nlinY/2 * slinY);
linPosY(2) = (nlinPosY(2) / (ny+1)) * B(end); %PosWQ(2) + (nlinY/2 * slinY);

% X-Koordinate
%Quadratischen Spline anpassen an Hilfspunkt 1
ccX1 = [0,              0,              1;
        nlinPosX(1)^2,  nlinPosX(1),    1;
        2*nlinPosX(1),  1,              0] \ [L(1); linPosX(1); slinX];

xgrid_start = polyval(ccX1, 0:1:nlinPosX(1));
xgrid_middle = (linPosX(1) + slinX):slinX:(linPosX(2) - slinX);

%Quadratischen Spline anpassen an Hilfspunkt 2
ccX2 = [nx^2,           nx,             1;
        nlinPosX(2)^2,  nlinPosX(2),    1;
        2*nlinPosX(2),  1,              0] \ [L(end); linPosX(2); slinX];

xgrid_end = polyval(ccX2, nlinPosX(2):1:nx);

%Zusammensetzen der drei Abschnitte
if isempty(xgrid_start) || isempty(xgrid_middle) || isempty(xgrid_end)
    xgridFinal = L;
else
    xgridFinal = [xgrid_start, xgrid_middle, xgrid_end];
end


% Y-Koordinate
%Quadratischen Spline anpassen an Hilfspunkt 1
ccY1 = [0,              0,              1;
        nlinPosY(1)^2,  nlinPosY(1),    1;
        2*nlinPosY(1),  1,              0] \ [B(1); linPosY(1); slinY];

ygrid_start = polyval(ccY1, 0:1:nlinPosY(1));
ygrid_middle = (linPosY(1) + slinY):slinY:(linPosY(2) - slinY);

%Quadratischen Spline anpassen an Hilfspunkt 2
ccY2 = [ny^2,           ny,             1;
        nlinPosY(2)^2,  nlinPosY(2),    1;
        2*nlinPosY(2),  1,              0] \ [B(end); linPosY(2); slinY];

ygrid_end = polyval(ccY2, nlinPosY(2):1:ny);

%Zusammensetzen der drei Abschnitte
if isempty(ygrid_start) || isempty(ygrid_middle) || isempty(ygrid_end)
    ygridFinal = B;
else
    ygridFinal = [ygrid_start, ygrid_middle, ygrid_end];
end


% Diskretisierung in z-Richtung
zgridFinal = T;

[x, y, z] = meshgrid(xgridFinal, ygridFinal, zgridFinal);

newCompMesh = horzcat(reshape(x, numel(x) ,1), ...
                      reshape(y, numel(y), 1), ...
                      reshape(z, numel(z), 1));


meshDisk = {xgridFinal, ygridFinal, zgridFinal};

end

