classdef Config < handle
    %Config Klasse die alle Parameter für die Simulation beinhaltet
    %   Detailed explanation goes here
    
    properties
        Oscillation@ConfigOscillation;
        Material@ConfigMaterial;
        ComponentGeo@ConfigComponentGeo;
        WeldingParameter@ConfigWeldingParameter;
    end
    
    methods
        function this = Config()
            this.Oscillation = ConfigOscillation();
            this.Material = ConfigMaterial();
            this.ComponentGeo = ConfigComponentGeo();
            this.WeldingParameter = ConfigWeldingParameter();
        end
    end
end

