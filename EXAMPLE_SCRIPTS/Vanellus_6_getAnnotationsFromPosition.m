% COLLECT ALL ANNOTATION DATA FROM POSITION:

%% SETTINGS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
posFolder      = ['/Users/kivietda/CloudStation/WORK/RESEARCH/VANELLUS/2017-01-06 Clicking Analysis for AleM/pos1/'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% prepare data structure
data = struct.empty;

% load position
pos = VPosition( posFolder );

% loop over regions
for i = 1:length( pos.regionList )
    
    % load region
    reg = VRegion([posFolder filesep pos.regionList{i}]);
    
    % loop over cellNrs
    for j = 1:length( reg.annotations.cellNrs )
        
        disp([  VTools.getFoldername( pos.filename ) ' ' ...
                VTools.getFoldername( reg.filename ) ' ' ...
                num2str( reg.annotations.cellNrs(j) ) ]);

        datasetNr = size(data,2) + 1;
        data(datasetNr).posName = VTools.getFoldername( pos.filename );
        data(datasetNr).regName = VTools.getFoldername( reg.filename );
        data(datasetNr).cellNr  = reg.annotations.cellNrs(j);
        data(datasetNr).annotations = reg.annotations.getData( data(datasetNr).cellNr );
    end
end

