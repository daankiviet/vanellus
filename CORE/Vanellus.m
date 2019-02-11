classdef Vanellus < VSettings %% C
% Vanellus Object

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        VERSION                 = '2017-03-07';
        DEFAULT_SET_FILENAME    = 'DefaultSettings.m';
        DEFAULT_EXP_FILENAME    = 'vanellusExp.mat';
        DEFAULT_POS_FILENAME    = 'vanellusPos.mat';
        DEFAULT_REG_FILENAME    = 'vanellusReg.mat';
        DEFAULT_LIN_FILENAME    = 'vanellusLin.mat';
        DEFAULT_IMAGE_FOLDER    = ['IMAGES' filesep];
        DEFAULT_CAC_FILENAME    = 'vanellusCache.mat';
        DEFAULT_SUPER_SETTINGS  = { 'van_logToFile',    uint32(1),  true ; ...
                                    'img_class',        uint32(1),  @VImages ; ...
                                    'stb_class',        uint32(1),  @VStabilization ; ...
                                    'rmsk_class',       uint32(1),  @VRegionmask ; ...
                                    'msk_class',        uint32(1),  @VMasks ; ...
                                    'seg_class',        uint32(1),  @VSegmentations ; ...
                                    'trk_class',        uint32(1),  @VTrackings ; ...
                                    'tree_class',       uint32(1),  @VTree ; ...
                                    'ann_class',        uint32(1),  @VAnnotations ; ...
                                    'ann_show',         uint32(1),  false ; ...
                                    'van_matFileVersion', uint32(1), '-v7'};
    end

    properties
        settings
    end
    
    properties (Transient) % not stored
        filename
        isSaved
    end
    
    properties (Dependent) % calculated on the fly
        parent
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = Vanellus(filename, silentMode)
            if nargin < 2, silentMode = false; end
            if nargin < 1 || strcmp(filename, '') || isempty(filename)
                filename = '';
                if ispref('Vanellus','defaultSettingsFilename')
                    filename = getpref('Vanellus','defaultSettingsFilename');
                end
                if ~VTools.isFile(filename)
                    filename = [VTools.getCurrentScriptFolderpath() Vanellus.DEFAULT_SET_FILENAME];
                end
            end
            
            obj.filename = filename;

            % check that folder / filename is ok
            if obj.checkFilename()
                
                % If file exist, try to load Vanellus
                if VTools.isFile(obj.filename)
                    obj         = obj.load(silentMode);
                    obj.isSaved = true;                    
                    setpref('Vanellus','defaultSettingsFilename', obj.filename); 
                else
                    % otherwise finish creating Vanellus and save
                    obj.settings    = {};
                    obj.save(silentMode);
                    obj.isSaved     = true;
                    warning(['Vanellus -> could not load default settings file, cause does not exist: ' obj.filename]);
                    disp(['Vanellus -> create a default settings file by running: Vanellus.createDefaultSettingsFile()']);
                end                    
            end
            
            VTools.addLog4jAppender(); % avoid error for CellSens images (subsequent calls cost little time)
            if ~silentMode, obj.checkMatlabVersion(); end % check Matlab version
        end
        
        function obj = load(obj, silentMode)
            if nargin < 2, silentMode = false; end
                
            if VTools.isFile(obj.filename)
                % move to folder of file
                previousFolder      = pwd;
                cd( VTools.getFolderpath(obj.filename) );

                % get properties
                props               = meta.class.fromName( VTools.getFilename(obj.filename) );
                props               = props.PropertyList;

                % fill settings
                obj.settings        = {};
                for i = 1:numel(props)
                    obj.settings{i,1} = props(i).Name;
                    obj.settings{i,2} = uint32(2);
                    obj.settings{i,3} = props(i).DefaultValue;
                end
                
                % move back to original folder
                cd( previousFolder );
                
                if ~silentMode, disp(['Vanellus -> loaded Vanellus Settings from file:     ' obj.filename]); end
            else
                warning(['Vanellus -> could not load file, cause does not exist: ' obj.filename]);
            end
        end        
        
        function save(obj, silentMode)
            if nargin < 2, silentMode = false; end
            
            if obj.checkFilename()
                settings            = obj.settings;
                save(obj.filename, 'settings');
                obj.isSaved         = true;
                setpref('Vanellus', 'defaultSettingsFilename', obj.filename); 

                if ~silentMode, disp(['Vanellus -> saved Settings to file:                 ' obj.filename]); end
            end
        end
        
        function tf = checkFilename(obj)
            % In case current obj.filename is an existing folder, just add 'settings_default.mat'
            if isdir(obj.filename)
                obj.filename = [VTools.addToEndOfString(obj.filename, filesep) Vanellus.DEFAULT_SET_FILENAME];
                tf = true;
                return;
            end
               
            % In case obj.filename indicates a file in an existing folder
            if isdir(VTools.getParentfolderpath(obj.filename))
                tf = true;
                return;
            end

            tf = false;
            warning(['Vanellus -> folder of filename does not exist: ' obj.filename]);
        end
        
        %% dependencies %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function parent = get.parent(obj)
            parent = [];
        end
        
        %% experiment %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function exp = createExperiment(obj, expFolderName, silentMode)
            if nargin < 3, silentMode = false; end
            
            % if expFolderName is not given, take current folder
            if nargin < 2, expFolderName = pwd; end
            
            % make sure expFolderName ends with /
            expFolderName   = VTools.addToEndOfString(expFolderName, filesep);
            imageFolderName = [expFolderName Vanellus.DEFAULT_IMAGE_FOLDER];
            expFileName     = [expFolderName Vanellus.DEFAULT_EXP_FILENAME];
            
            % if experiment already exists, don't create but do return
            if VTools.isFile(expFileName)
                if ~silentMode, warning(['Vanellus -> could not create Experiment, as it already exists : ' expFolderName]); end
                exp = VExperiment(expFileName);
                return;
            end            
            
            % create Experiment subfolder if necessary
            if ~isdir(expFolderName)
                tf = VTools.mkdir(expFolderName);
                if tf
                    if ~silentMode, disp(['Vanellus -> created Experiment folder :             ' expFolderName]); end
                else
                    warning(['Vanellus -> could not create Experiment folder : ' expFolderName]);
                end
            end

            % create IMAGES subfolder if necessary
            if ~isdir(imageFolderName)
                tf = VTools.mkdir(imageFolderName);
                if tf
                    if ~silentMode, disp(['Vanellus -> created Experiment IMAGES folder :      ' imageFolderName]); end
                else
                    warning(['Vanellus -> could not create Experiment IMAGES folder : ' imageFolderName]);
                end
            end            
            
            % save experiment file
            exp = VExperiment(expFileName, 'silent');
            
            % Update imageFolderName and save again
            exp.set('img_folder', imageFolderName);
            exp.save('silent');

            if ~silentMode, disp(['Vanellus -> created Experiment :                    ' expFileName]); end
        end        
    end
    
    methods (Static)
        function createDefaultSettingsFile( filename, settings )
            if nargin < 1 || isempty( filename )
                filename = [VTools.getParentfolderpath( VTools.getParentfolderpath( mfilename('fullpath') ) ) Vanellus.DEFAULT_SET_FILENAME];
            end
            if nargin < 2
                settings = Vanellus.DEFAULT_SUPER_SETTINGS;
            end
            
            % open file
            fid = fopen(filename, 'w', 'n', 'UTF-8');
            
            % write header
            [~, name] = fileparts(filename);
            headerText = ['classdef ' name char(10) ... 
                          '% default settings for Vanellus' char(10) ... 
                          '    properties (Constant)' char(10)];
            fwrite(fid, headerText, 'char*1');

            % write settings
            for i = 1:size(settings,1)
                name = settings{i,1};
                value = VTools.all2str( settings{i,3} );
                settingText = [ repmat( char(32), 1, 8) name ...
                                repmat( char(32), 1, 28-numel(name)) '= ' value ';' char(10)];
                fwrite(fid, settingText, 'char*1');
            end
            
            % write footer
            footerText = ['    end' char(10) ... 
                          'end' char(10)];
            fwrite(fid, footerText, 'char*1');

            % close file
            fclose(fid);

            % save as default in setpref
            setpref('Vanellus', 'defaultSettingsFilename', filename); 
        end        
        
        function messages = checkMatlabVersion()
            messages = {};
            
            % Test Matlab verison
            if verLessThan('matlab','8.4') % Earlier than MATLAB R2014b
                messages{end+1} = ['You are running Matlab ' version('-release') '. Vanellus requires version 2014b or higher.'];
            end
    
            % Test licenses
            if ~license('test','image_toolbox')
                messages{end+1} = ['You are running Matlab without the image_toolbox. Vanellus will probably not run at all.'];
            end
            if ~license('test','video_and_image_blockset')
                messages{end+1} = ['You are running Matlab without the video_and_image_blockset toolbox.' ...
                         ' Vanellus needs this toolbox to draw text on images, and will now probably run into problems.'];
            end
            if ~license('test','statistics_toolbox')
                messages{end+1} = ['You are running Matlab without the statistics_toolbox. Vanellus will probably not work well.'];
            end
            
            if nargout < 1 % display messages
                warning off backtrace;
                for i = 1:numel(messages)
                    warning(messages{i});
                end
                warning on backtrace;
            end
        end
        
        function checkVanellusVersion()
            latestVersionString = VTools.getLatestVersionString();
            
            if ~isempty(latestVersionString)
                if strcmp(latestVersionString, Vanellus.VERSION)
                    disp(['This (' Vanellus.VERSION ' ) is the latest Vanellus version']);
                else
                    disp(['New Vanellus version available (' latestVersionString ')']);
                end
            end
        end
    end
end
