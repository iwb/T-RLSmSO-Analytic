classdef ScaledConfig < handle
    %SCALEDCONFIG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Config@Config;
        
        PecletNumber = NaN;         %Skalierter Vorschub
        RayleighLength = NaN;       %Skalierte Rayleighlänge
        Gamma = NaN;                %Skalierung für Intensität
        FusionEnthalpy = NaN;       %Skalierte Schmelzenthalpie
        Fokus = NaN;                %Skalierter Fokus
        WaveLength = NaN;           %Skalierte Wellenlänge
    end
    
    methods
        function this = ScaledConfig(config)
            this.Config = config;
        end
        
        function Scale(this)
            this.PecletNumber = this.Config.WeldingParameter.WaistSize ./ ...
                this.Config.Material.ThermalDiffusivity .* this.Config.WeldingParameter.TrueVelocityNorm;
            
            this.RayleighLength = this.Config.WeldingParameter.RayleighLength / ...
                this.Config.WeldingParameter.WaistSize;
            
            this.Gamma = this.Config.WeldingParameter.WaistSize * this.Config.WeldingParameter.MaxIntensity / ...
                (this.Config.Material.ThermalConductivity * (this.Config.Material.VaporTemperature - this.Config.Material.AmbientTemperature));
            
            this.FusionEnthalpy = this.Config.Material.FusionEnthalpy / ... 
                (this.Config.Material.HeatCapacity*(this.Config.Material.VaporTemperature - this.Config.Material.AmbientTemperature));
            
            this.Fokus = this.Config.WeldingParameter.Fokus / this.Config.WeldingParameter.WaistSize;
            
            this.WaveLength = this.Config.WeldingParameter.WaveLength / this.Config.WeldingParameter.WaistSize;
        end
    end
    
end

