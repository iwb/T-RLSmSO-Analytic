close all
% Gegebenenfalls pool schließen
poolobj = gcp('nocreate');
if ~isempty(poolobj)
    poolobj.delete
end

% Pfade hinzufügen
addpath('.\Klassen');
addpath('.\TopLevelFunctions');

% Auswahl des Clusters
%myProfile = 'Amazon_Trail';
myProfile = 'local';
myCluster = parcluster(myProfile);

% Auslesen der verfügbaren worker
numWorkers = myCluster.NumWorkers;

switch myProfile
    case 'local'
        parpool(myCluster, numWorkers);
    otherwise
        % Pfade angeben für Cloud Computing
        classes = dir('.\Klassen');
        funcs = dir('.\TopLevelFunctions');
        
        classNames = {classes.name};
        classNames = classNames(3:end);
        
        for i = 1:length(classNames)
            classNames{i} = ['.\Klassen\' classNames{i}];
        end
        
        funcNames = {funcs.name};
        funcNames = funcNames(3:end);
        
        for i = 1:length(funcNames)
            funcNames{i} = ['.\TopLevelFunctions\' funcNames{i}];
        end
        
        allFiles = [classNames, funcNames];
        
        parpool(myCluster, numWorkers, 'AttachedFiles', allFiles);
end

% Initialisieren eines neuen Taksmanagers
% Begin der Simulation
try
    assignment = TaskManager('..\Einstellungen\EinstellungenSimple.xlsx', '..\storage\logfile.txt');
    assignment.RunTask([1,6]);
    
    save('..\storage\MeshTest', 'assignment');
catch err
    tweet('Achtung Simulation ist abgebrochen!');
    rethrow(err)
end

matlabpool close

% appointment = TaskManager('..\Einstellungen\EinstellungenSimple.xlsx', '..\storage\logfile.txt');
% appointment.Findfmin(3, [200 2000]);

