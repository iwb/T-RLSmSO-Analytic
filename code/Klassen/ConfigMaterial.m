classdef ConfigMaterial < handle
    %ConfigMaterial beinhaltet alle n�tigen Materialkennwerte
    %   Detailed explanation goes here
    
    properties
        ThermalConductivity  = 33.63;   %W�rmeleitf�higkeit [W/(mK)]
        Density = 7033;                 %Dichte [kg/m�]
        HeatCapacity = 711.4;           %spezifische W�rmekapazit�t [J/(kgK)]
        
        FresnelEpsilon = 0.25;          %Materialparameter f�r Fresnel Absorption [-]
        
        FusionEnthalpy = 2.75e5;        %Schmelzenthalpie [J/kg]
        
        MeltingTemperature = 1796;      %Schmelztemperatur [K]
        VaporTemperature = 3133;        %Verdampfungstemperatur [K]
        AmbientTemperature = 300;       %Umgebungstemperatur [K]
    end
    
    properties (Dependent = true)
        ThermalDiffusivity              %Temperaturleitf�higkeit [m�/s]
    end
    
    methods
        function this = ConfigMaterial()
            this.ThermalConductivity = this.ThermalConductivity;
            this.Density = this.Density;
            this.HeatCapacity = this.HeatCapacity;
        end
        
        function thermalDiff = get.ThermalDiffusivity(this)
            thermalDiff = this.ThermalConductivity/(this.Density * this.HeatCapacity);
        end
    end
    
end

