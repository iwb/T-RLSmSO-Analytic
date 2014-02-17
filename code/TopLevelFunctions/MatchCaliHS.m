function [ doubleEllipHS ] = MatchCaliHS( calibrationObj, doubleEllipHS )
%MatchCaliHS Setzt die kalibrierten WQ an die richtige Position für die
%abschließende Simulation der Oscillations-Trajektorie
%   Detailed explanation goes here

% Überführen in lokale Variablen
numCaliHS = calibrationObj.ReducedModel.NumTFields;
numDiskretOsci = doubleEllipHS.TrajectoryInfo.Config.Oscillation.Discretization;
numHSOsci = length(doubleEllipHS.HeatSourceField);

mult = fix(numHSOsci/numDiskretOsci);
check = mod(numHSOsci, numDiskretOsci);

%watt = calibrationObj.WQoutput;
calibrationObj.WQoutput = zeros(numHSOsci, 1);

for i = 1:length(numCaliHS)
    if numCaliHS(i) > check
        change = numCaliHS(i):numDiskretOsci:mult*numDiskretOsci;
    else
        change = numCaliHS(i):numDiskretOsci:mult*numDiskretOsci+numCaliHS(i);
    end
    
    for j = 1:length(change)
        doubleEllipHS.HeatSourceField{change(j), 1}.HeatEmission = calibrationObj.CalibratedHS{i}(1);
        doubleEllipHS.HeatSourceField{change(j), 1}.GeoDescription.Cxf = calibrationObj.CalibratedHS{i}(2);
        doubleEllipHS.HeatSourceField{change(j), 1}.GeoDescription.Cxb = calibrationObj.CalibratedHS{i}(3);
        doubleEllipHS.HeatSourceField{change(j), 1}.GeoDescription.Cy = calibrationObj.CalibratedHS{i}(4);
        doubleEllipHS.HeatSourceField{change(j), 1}.GeoDescription.Cz = calibrationObj.CalibratedHS{i}(5);
        
        %calibrationObj.WQoutput(change(j), 1) = watt(i);
    end
end

end

