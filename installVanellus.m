% This script install Vanellus in 3 steps:
%
% 1. It removes all previous Vanellus folders from Matlab's search path and adds the required folders 
%    of the Vanellus version where this file is located. You can check Matlab's search path using the 
%    command "pathtool".
%
% 2. It checks whether you have the right Matlab version installed, whether any required Toolboxes are 
%    missing and whether this is the most current of Vanellus.
%
% 3. It creates a settings file and sets it as the default.

%% first remove all Vanellus folders from path
currentPath = strsplit(path,':')';
for i = 1:numel(currentPath)
    if exist([currentPath{i} filesep 'Vanellus'], 'file') == 2 || exist([currentPath{i} filesep 'Vanellus'], 'file') == 6
        rmpath( currentPath{i} ); disp(['installVanellus: removed from search path: ' currentPath{i}]);
        
        % in case folder name is "CORE", also remove parent folder, and GUI and SCRIPTS folders
        [parentFolder,name] = fileparts( currentPath{i} );
        if strcmp(name, 'CORE')
            rmpath( parentFolder ); disp(['installVanellus: removed from search path: ' parentFolder]);
            rmpath( [parentFolder filesep 'GUI'] ); disp(['installVanellus: removed from search path: ' [parentFolder filesep 'GUI']]);
            rmpath( [parentFolder filesep 'SCRIPTS'] ); disp(['installVanellus: removed from search path: ' [parentFolder filesep 'SCRIPTS']]);
        end
    end
end

%% next add current folders to path
vanFolder = fileparts( mfilename('fullpath') );
addpath( vanFolder ); disp(['installVanellus: added to search path    : ' vanFolder]);
addpath( [vanFolder filesep 'CORE'] ); disp(['installVanellus: added to search path    : ' [vanFolder filesep 'CORE']]);
addpath( [vanFolder filesep 'GUI'] ); disp(['installVanellus: added to search path    : ' [vanFolder filesep 'GUI']]);
addpath( [vanFolder filesep 'SCRIPTS'] ); disp(['installVanellus: added to search path    : ' [vanFolder filesep 'SCRIPTS']]);
savepath;
disp(['installVanellus: current Vanellus version: ' Vanellus.VERSION]);

%% check whether Vanellus is latest version, Matlab version is up to date and necessary toolboxes are installed.
Vanellus.checkVanellusVersion();
Vanellus.checkMatlabVersion();

%% create default settings file
Vanellus.createDefaultSettingsFile();
