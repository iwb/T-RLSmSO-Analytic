function [ y ] = khz_func2( alpha, A, arguments, param )
%KHZ_FUNC2 Summary of this function goes here
%   Detailed explanation goes here

% Berechnung des Normalenvektors
Avec = [arguments.prevApex; A];
AlphaVec = [arguments.prevRadius; alpha];

winkel = 1*pi/180;
tmp_x = Avec - AlphaVec .* (1-cos(winkel));
tmp_y = AlphaVec .* sin(winkel);

P1 = [arguments.prevApex; 0; arguments.prevZeta];
P2 = [A; 0; arguments.zeta];
P3 = [tmp_x(1); tmp_y(1); arguments.prevZeta];
P4 = [tmp_x(2); tmp_y(2); arguments.zeta];

%{
    figure;
    PMat = [P1, P2, P3, P3_dash, P4];
    scatter3(PMat(1, :), PMat(2,:), PMat(3, :), [], 1:5, 'fill');
    xlim([-1 1]);
    ylim([-1 1]);
    zlim([-1 1]);
    daspect([1 1 1]);
    hold all;    line([0 P1(1)], [0, P1(2)], [0 P1(3)]);
    hold all;    line([0 P2(1)], [0, P2(2)], [0 P2(3)]);
    hold all;    line([0 P3(1)], [0, P3(2)], [0 P3(3)]);
    hold all;    line([0 P3_dash(1)], [0, P3_dash(2)], [0 P3_dash(3)]);
    hold all;    line([0 P4(1)], [0, P4(2)], [0 P4(3)]);
%}

d1 = P1 - P2;
n1 = [-d1(3); 0; d1(1)]; % [x; y; z]
n1 = n1 ./ norm(n1);

Algo = 2;
switch(Algo)
	case 1 % Approximation der Tangente durch die Sekante
		tmp_x = A - alpha .* (1-cos(winkel * 2));
		tmp_y = alpha .* sin(winkel * 2);
		P4a = [tmp_x; tmp_y; arguments.zeta];
		
		d2 = P4a - P2; % aaa = d2./norm(d2)
		d3 = P3 - P4;
		n2 = cross(d3, d2);
		n2 = n2 ./ norm(n2);
	case 2 % Errechung der Tangete per Trigonometrie/Ableitung
		tmp_x = -sin(winkel);
		tmp_y = cos(winkel);
        
		P4_tangent = [tmp_x; tmp_y; 0];
		
		d3 = P3 - P4;
		n2 = cross(d3, P4_tangent);
		n2 = n2 ./ norm(n2);
		
	case 3 % Approximierung der Tangente durch spitzes Dreieck
		tmp_x = A - alpha .* (1-cos(winkel * 1.01));
		tmp_y = alpha .* sin(winkel * 1.01);
		P4a = [tmp_x; tmp_y; arguments.zeta];
		
		d2 = P4a - P4;
		d3 = P3 - P4;
		n2 = cross(d3, d2);
		n2 = n2 ./ norm(n2);
	otherwise
		error('Fehler 0xDEADB33F');
end

[poyntVec, intensity] = calcPoynting([P2, P4], param);

% Berechnung von qa0 und qa2
Az = calcFresnel(poyntVec, [n1, n2], param);

qa0 = intensity(1) * Az(1);
qa1 = intensity(2) * Az(2);
qa2 = 2*(qa1 - qa0)/winkel^2;    % Da qa0 minimal größer ist, wird qa2 negtiv.
qa2 = qa2 * param.scaled.gamma;

y = qa2 + (1 + param.scaled.hm) * param.scaled.Pe;
end




















