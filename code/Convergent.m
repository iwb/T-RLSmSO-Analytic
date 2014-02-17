% Laden der Versuche
inputData = load('../Einstellungen/KonvergenzTestWQ.mat');

isequalRel = @(x,y,tol) ( abs(x-y) <= ( tol*max(abs(x),abs(y)) + eps) );
isequalAbs = @(x,y,tol) ( abs(x-y) <= tol );

% Erstellen der nötigen Config Objekte
convWQ = zeros(1,size(inputData.VariParam,1));
convSP = zeros(1,size(inputData.VariParam,1));
converWQ = cell(1,size(inputData.VariParam,1));
for i = 1:size(inputData.VariParam,1)
    configObject = Config();
    
    % Anpassen der Config-Objekte
    configObject.Oscillation.Velocity = inputData.VariParam(i, 1);
    
    configObject.WeldingParameter.LaserPower = inputData.VariParam(i, 2);
    
    configObject.WeldingParameter.Fokus = 0;
    
    configObject.Oscillation.SeamLength = inputData.Osci(1, 1);
    
    configObject.Material.ThermalConductivity = inputData.Mat(1, 1);
    configObject.Material.Density = inputData.Mat(1, 2);
    configObject.Material.HeatCapacity = inputData.Mat(1, 3);
    configObject.Material.FresnelEpsilon = inputData.Mat(1, 4);
    configObject.Material.FusionEnthalpy = inputData.Mat(1, 5);
    configObject.Material.MeltingTemperature = inputData.Mat(1, 6);
    configObject.Material.VaporTemperature = inputData.Mat(1, 7);
    configObject.Material.AmbientTemperature = inputData.Mat(1, 8);
    
    configObject.ComponentGeo.L = inputData.Comp(1, 1);
    configObject.ComponentGeo.B = inputData.Comp(1, 2);
    configObject.ComponentGeo.D = inputData.Comp(1, 3);
    configObject.ComponentGeo.Dx = inputData.Comp(1, 4);
    configObject.ComponentGeo.Dy = inputData.Comp(1, 5);
    configObject.ComponentGeo.Dz = inputData.Comp(1, 6);
    
    configObject.WeldingParameter.WaveLength = inputData.Weld(1, 1);
    configObject.WeldingParameter.WaistSize = inputData.Weld(1, 2);
    
    % Erstellen der Trajektorien Objekte
    trajObject = CalcTrajectory(configObject);
    
    trajObject.ComponentMesh = configObject.ComponentGeo.FieldGrid.Mesh;
    
    anzWQ = 2;
    anzSP = 0;
    compareTField = zeros(size(trajObject.ComponentMesh,1), 2);
    count = 1;
    while true
        configObject.WeldingParameter.TrueVelocityNorm = repmat(inputData.VariParam(i, 1), [anzWQ, 1]);
        
        trajObject.WeldingTrajectory.X = linspace(1e-3, 2e-3, anzWQ)';
        trajObject.WeldingTrajectory.Y = repmat(inputData.Comp(1, 2)/2, [length(trajObject.WeldingTrajectory.X), 1]);
        trajObject.WeldingTrajectory.Z = zeros(length(trajObject.WeldingTrajectory.X) ,1);
        
        trajObject.WeldingTrajectory.TrueVeloX = configObject.WeldingParameter.TrueVelocityNorm;
        trajObject.WeldingTrajectory.TrueVeloY = zeros(length(trajObject.WeldingTrajectory.X), 1);
        trajObject.WeldingTrajectory.TrueVeloNorm = trajObject.WeldingTrajectory.TrueVeloX;
        
        trip = 1e-3;
        
        trajObject.DiscreteTimeStep = (trip/inputData.VariParam(i, 1))/anzWQ;
        trajObject.DiscreteTimeVector = (trajObject.DiscreteTimeStep:trajObject.DiscreteTimeStep:trip/inputData.VariParam(i, 1))';
        
        if anzWQ == 2
            scaledConfigObj = ScaledConfig(configObject);
            scaledConfigObj.Scale();
            
            reducedModelObj = ReducedModel(scaledConfigObj, 1);
            reducedModelObj.CalcEntireTFields();
            
            caliHScell = PrepCalibration(reducedModelObj);
            
            calibrationObj = Calibration(reducedModelObj, caliHScell);
            calibrationObj.Calibrating();
            
            doubleEllipHSObj = DoubleEllipHeatSource(trajObject);
            
            for k = 1:anzWQ
                doubleEllipHSObj.HeatSourceField{k, 1}.HeatEmission = calibrationObj.CalibratedHS{1}(1);
                doubleEllipHSObj.HeatSourceField{k, 1}.GeoDescription.Cxf = calibrationObj.CalibratedHS{1}(2);
                doubleEllipHSObj.HeatSourceField{k, 1}.GeoDescription.Cxb = calibrationObj.CalibratedHS{1}(3);
                doubleEllipHSObj.HeatSourceField{k, 1}.GeoDescription.Cy = calibrationObj.CalibratedHS{1}(4);
                doubleEllipHSObj.HeatSourceField{k, 1}.GeoDescription.Cz = calibrationObj.CalibratedHS{1}(5);
            end
        else
            doubleEllipHSObj = DoubleEllipHeatSource(trajObject);
            
            for k = 1:anzWQ
                doubleEllipHSObj.HeatSourceField{k, 1}.HeatEmission = calibrationObj.CalibratedHS{1}(1);
                doubleEllipHSObj.HeatSourceField{k, 1}.GeoDescription.Cxf = calibrationObj.CalibratedHS{1}(2);
                doubleEllipHSObj.HeatSourceField{k, 1}.GeoDescription.Cxb = calibrationObj.CalibratedHS{1}(3);
                doubleEllipHSObj.HeatSourceField{k, 1}.GeoDescription.Cy = calibrationObj.CalibratedHS{1}(4);
                doubleEllipHSObj.HeatSourceField{k, 1}.GeoDescription.Cz = calibrationObj.CalibratedHS{1}(5);
            end
        end
        
        doubleEllipHSObj.HeatSourceReflection([0 0 anzSP]);
        
        doubleEllipSolverObj = DoubleEllipSolver(doubleEllipHSObj);
        doubleEllipSolverObj.RunSolver();
        
        compareTField(:,2) = compareTField(:,1);
        compareTField(:,1) = doubleEllipSolverObj.TemperatureField;
        
        testAbs = isequalAbs(compareTField(:,2), compareTField(:,1), 5);
        testAbs = sum(testAbs);
        
        rsquared = 1 - ((sum((compareTField(:,2) - compareTField(:,1)).^2))/(sum((compareTField(:,2) - mean(compareTField(:,2))).^2)));
        
        converWQ{i}(count,2) = rsquared;
        converWQ{i}(count,1) = anzWQ;
        
        fprintf('Absolut: %d/%d\n', testAbs, size(trajObject.ComponentMesh,1));
        
        if testAbs == size(trajObject.ComponentMesh,1)
            convWQ(i) = anzWQ;
            convSP(i) = anzSP;
            break
        end
        
        anzWQ = anzWQ + 1;
        count = count + 1;
    end
end