function [pVec, intensity] = calcPoynting( point, param)
%POYNTING Summary of this function goes here
%   pvec = [r; z]

x = point(1,:);
y = point(2,:);
z = point(3,:);

r = sqrt(x.^2 + y.^2);

fokus = param.scaled.fokus;
Rl = param.scaled.Rl;
waveLength = param.scaled.waveLength;

sumz = z + fokus;

intensity = 1 ./ (1 + (sumz.^2 ./ Rl.^2)) .* exp(-2 * r.^2 ./ (1 + (sumz.^2 ./ Rl.^2)));

% Poyntingvektor - Komponenten
%Eigene Berechnung

% PoyntX = -(2*pi .* x .* sumz) ./ (Rl^2 * waveLength + sumz.^2 .* waveLength);
% PoyntY = -(2*pi .* y .* sumz) ./ (Rl^2 * waveLength + sumz.^2 .* waveLength);
% 
% PoyntZ = (pi*(-2*Rl^4 + sumz.^2 .* (x.^2 + y.^2 - 2*sumz.^2) - Rl^2 ...
%     .* (x.^2 + y.^2 + 4*sumz.^2)) + Rl*(Rl^2 + sumz.^2)*waveLength) ./ ...
%     ((Rl^2 + sumz.^2).^2 * waveLength);

%Jansen Berechnung

PoyntX = -(2 .* x .* sumz) ./ (Rl .* (1 + (sumz.^2 ./ Rl.^2)));
PoyntY = -(2 .* y .* sumz) ./ (Rl .* (1 + (sumz.^2 ./ Rl.^2)));

PoyntZ = (2 * (x.^2 + y.^2) .* sumz.^2) ./ (Rl^3 * (1 + (sumz.^2 ./ Rl.^2)).^2) ...
    + (1) ./ (Rl .* (1 + (sumz.^2 ./ Rl.^2))) ...
    - (x.^2 + y.^2) ./ (Rl .* ((1 + (sumz.^2 ./ Rl.^2)))) ...
    - (2*pi) ./ (waveLength);

% Poyntingvektor - Gesamt + Normierung
pVec = [PoyntX; PoyntY; PoyntZ];
pVec = bsxfun(@rdivide, pVec, sqrt(sum(pVec.^2)));
end