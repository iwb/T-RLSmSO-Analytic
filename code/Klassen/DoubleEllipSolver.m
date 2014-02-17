classdef DoubleEllipSolver < AbstractSolver
	%DoubleEllipSolver beinhaltet die Lösung der Wärmeleitungsgleichung für
	%eine doppelt elliptische Wärmequelle
	%   Detailed explanation goes here
	
	properties
		HeatSourceDefinition@DoubleEllipHeatSource;
	end
	
	methods
		function this = DoubleEllipSolver(heatSourceDefinition)
			this.HeatSourceDefinition = heatSourceDefinition;
		end
		
		function heatSourceTField = HeatSourceIntegration(this, transMesh, index)
			% Funktion zur numerischen Integration der doppelt ellipsoiden WQ um das T-Feld zu Berechnen
			%Temperaturleitfähigkeit in lokale Variable speichern
			a = this.HeatSourceDefinition.TrajectoryInfo.Config.Material.ThermalDiffusivity;
			rho = this.HeatSourceDefinition.TrajectoryInfo.Config.Material.Density;
			c = this.HeatSourceDefinition.TrajectoryInfo.Config.Material.HeatCapacity;
			
			%Berechnung der Hilfsgrößen rf und rb
			rf = 2 * this.HeatSourceDefinition.HeatSourceField{index,1}.GeoDescription.Cxf/(this.HeatSourceDefinition.HeatSourceField{index,1}.GeoDescription.Cxf + this.HeatSourceDefinition.HeatSourceField{index,1}.GeoDescription.Cxb);
			rb = 2 * this.HeatSourceDefinition.HeatSourceField{index,1}.GeoDescription.Cxb/(this.HeatSourceDefinition.HeatSourceField{index,1}.GeoDescription.Cxf + this.HeatSourceDefinition.HeatSourceField{index,1}.GeoDescription.Cxb);
			
			%Berechnung des T-Feldes durch numerische Integration
			heatSourceTField = integral(@integrationFunction, 0, this.HeatSourceDefinition.HeatSourceField{index,1}.ActivationTime, 'ArrayValued', true, 'AbsTol', 0.01, 'RelTol', 0.1);
			
			function result = integrationFunction(time)
				cxf2=this.HeatSourceDefinition.HeatSourceField{index,1}.GeoDescription.Cxf^2;
				cxb2=this.HeatSourceDefinition.HeatSourceField{index,1}.GeoDescription.Cxb^2;
				cy2=this.HeatSourceDefinition.HeatSourceField{index,1}.GeoDescription.Cy^2;
				cz2=this.HeatSourceDefinition.HeatSourceField{index,1}.GeoDescription.Cz^2;
                
                q = this.HeatSourceDefinition.HeatSourceField{index,1}.HeatEmission;
				
				AAA = transMesh(:,1).^2;
				AA = (AAA ./ (12 .* a .* time + cxf2));
				AB = (AAA ./ (12 .* a .* time + cxb2));
				
				BB = (transMesh(:,2).^2 ./ (12 .* a .* time + cy2));
				CC = (transMesh(:,3).^2 ./ (12 .* a .* time + cz2));				
				DD = exp(-3 * (BB + CC));
				
				N=zeros(length(AA), 2);
				N(:, 1) = rf .* exp( -3*AA ) .* DD;
				N(:, 2) = rb .* exp( -3*AB ) .* DD;
				
				J(1, 1) = 1/(sqrt(12 .* a .* time + cxf2));
				J(2, 1) = 1/(sqrt(12 .* a .* time + cxb2));

				M = N * J; % Matrix Multiplikation ftw!
				
				
				result = (3 .* sqrt(3) .* q) ./ (4 .* rho .* c .* sqrt(pi)) .* (1 ./ (sqrt((12 .* a .* time + cy2) .* (12 .* a .* time + cz2)))) ...
					.* M;
			end
		end
    end
	
    
end