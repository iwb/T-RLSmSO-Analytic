function cellHeatSources = PrepCalibration( reducedModel )
%PREPCALIBRATION Erzeugt für jedes Temperaturfeld in ReducedModel ein
%HeatSource Objekt, das eine lineare Trajektorie enthält, die zur
%Kalibrierung genutzt wird
%   Detailed explanation goes here

% Übertragen in lokale Variablen
num = reducedModel.NumTFields;
config = reducedModel.Scaled.Config;
VeloArray = config.WeldingParameter.TrueVelocityNorm(num);

settings = struct();

% Erstellen von NumTFields Trajektorien Objekten
trajObj = cell(length(num), 1);
for i = 1:length(num)
    posMaxT = zeros(size(reducedModel.EntireFields{i,1},3), 1);
    for j = 1:size(reducedModel.EntireFields{i,1},3)
        planeTField = reducedModel.EntireFields{i,1}(:,:,j);
        posMaxT(j) = find(planeTField(1,:) == max(planeTField(1,:)), 1, 'last');
    end
    
    posKeyhole = max(posMaxT);
    
    currentVelo = VeloArray(i);
    settings.X = reducedModel.DiskreteCaliField{i}{1};
    settings.Y = reducedModel.DiskreteCaliField{i}{2};
    settings.Z = reducedModel.DiskreteCaliField{i}{3};
    
    trajObj{i} = CalcTrajectory(config);
    trajObj{i}.CalibrationTraj(settings, currentVelo, posKeyhole);
end

% Erstellen von NumTFields HeatSource Objekte mit den errechneten
% Trajektorien
cellHeatSources = cell(length(num), 1);
for i = 1:length(num)
    cellHeatSources{i} = DoubleEllipHeatSource(trajObj{i});
    cellHeatSources{i}.HeatSourceReflection([0 0 2], 'cali');
    
    emptycells = cellfun(@isempty, cellHeatSources{i}.HeatSourceField);
    cellHeatSources{i}.HeatSourceField(emptycells) = [];
end


end