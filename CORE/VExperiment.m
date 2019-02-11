classdef VExperiment < VSettings %% C
% VExperiment Object that contains all information of a Vanellus Experiment. 
%
% Each folder can only contain a single Experiment, that can be saved and
% loaded to a vanellusExp.mat file. Within an Experiment file there is saved:
% - version
% - settings

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SUPER_SETTINGS  = { 'img_maxThumbSize'          , uint32(1), [256 256]; ...
                                    'img_micronPerPixel'        , uint32(1), 0.041 };
    end

    properties
        version
        settings
    end
    
    properties (Transient) % not stored
        filename
        vanellus
        isSaved
    end

    properties (Dependent) % calculated on the fly
        parent
        positionList
    end   
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VExperiment(filename, silentMode)
            if nargin < 2, silentMode = false; end
            if nargin < 1 || strcmp(filename, ''), filename = [pwd filesep Vanellus.DEFAULT_EXP_FILENAME]; end
            
            obj.filename    = filename;

            % check that folder / filename is ok
            if obj.checkFilename()
                
                % If file exist, try to load VExperiment
                if VTools.isFile(obj.filename)
                    obj         = obj.load(silentMode);
                    obj.update(); % sets obj.vanellus
                    obj.isSaved = true;
                else
                    % otherwise finish creating VExperiment and save
                    obj.update(); % sets obj.vanellus

                    obj.version         = Vanellus.VERSION;
                    obj.settings        = {};
                    
                    obj.save(silentMode);
                    obj.isSaved         = true;
                end
            end
        end
        
        function experiment = load(obj, silentMode)
            if nargin < 2, silentMode = false; end
                
            if VTools.isFile(obj.filename)
                load(obj.filename);
                experiment.filename = obj.filename;
                experiment.isSaved  = true;
                experiment.update();

                if ~silentMode, disp(['VExperiment -> loaded Experiment from file:         ' obj.filename]); end
            else
                warning(['VExperiment -> could not load file, cause does not exist: ' obj.filename]);
            end
        end
        
        function save(obj, silentMode)
            if nargin < 2, silentMode = false; end
            
            if obj.checkFilename()
                % in order to facilitate exchange of files, current (probably default) class are saved for:
                %  - images / stabilization / maskregion / masks / segmentations / trackings / tree
                obj.set('img_class', obj.get('img_class'));
                obj.set('stb_class', obj.get('stb_class'));
                obj.set('rmsk_class', obj.get('rmsk_class'));
                obj.set('msk_class', obj.get('msk_class'));
                obj.set('seg_class', obj.get('seg_class'));
                obj.set('trk_class', obj.get('trk_class'));
                obj.set('tree_class', obj.get('tree_class'));

                experiment          = obj;
                experiment.version  = Vanellus.VERSION; % will be saved as current version, whether it was old version or not
                save(obj.filename, 'experiment');
                obj.isSaved         = true;

                if ~silentMode, disp(['VExperiment -> saved VExperiment to file:           ' obj.filename]); end
            end
        end
        
        function tf = checkFilename(obj)
            % In case current obj.filename is an existing folder, just add 'vanellusExp.mat'
            if isdir(obj.filename)
                obj.filename = [VTools.addToEndOfString(obj.filename, filesep) Vanellus.DEFAULT_EXP_FILENAME];
                tf = true;
                return;
            end
               
            % In case obj.filename indicates a 'vanellusExp.mat' file in an existing folder
            if VTools.endsWith(obj.filename, [filesep Vanellus.DEFAULT_EXP_FILENAME]) && isdir(VTools.getParentfolderpath(obj.filename))
                tf = true;
                return;
            end

            tf = false;
            warning(['VExperiment -> folder of filename does not exist: ' obj.filename]);
        end
        
        %% updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function update(obj)
            obj.vanellus        = Vanellus('', 'silent');
        end

        %% dependencies %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function parent = get.parent(obj)
            parent = obj.vanellus;
        end        
        
        %% position %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function pos = createPosition(obj, posName, silentMode)
            if nargin < 3, silentMode = false; end
            if nargin < 2, posName = 'pos'; end
            
            % make sure posName ends with /
            posName         = VTools.addToEndOfString(posName, filesep);
            posFolderName   = [VTools.getParentfolderpath(obj.filename) posName];
            posFilename     = [posFolderName Vanellus.DEFAULT_POS_FILENAME];

            % if position already exists, don't create but do return
            if VTools.isFile(posFilename)
                if ~silentMode, warning(['VExperiment -> could not create Position, as it already exists : ' posFilename]); end
                pos         = VPosition(posFilename);
                return;
            end
            
            % create Position subfolder if necessary
            if ~isdir(posFolderName)
                tf          = VTools.mkdir(posFolderName);
                if tf
                    if ~silentMode, disp(['VExperiment -> created Position folder :            ' posFolderName]); end
                else
                    warning(['VExperiment -> could not make Position folder : ' posFolderName]);
                end
            end
            
            % save position file
            pos             = VPosition(posFilename, 'silent');
            
            % Update images and save again
            pos.updateImages(); 
            pos.save('silent');
            
            if ~silentMode, disp(['VExperiment -> created Position :                   ' posFilename]); end
        end
        
        function positionList = get.positionList(obj)
            positionList = {};
            subfolderNames = VTools.getSubfoldernames(VTools.getParentfolderpath(obj.filename));
            for i = 1:length(subfolderNames)
                positionFilename = [VTools.getParentfolderpath(obj.filename) subfolderNames{i} filesep Vanellus.DEFAULT_POS_FILENAME];
                if VTools.isFile(positionFilename)
                    positionList{end+1} = subfolderNames{i};
                end
            end
            
            % sort by number
            nrs = [];
            for i = 1:length(positionList);
                nr = str2double(regexpi(positionList{i},'.*\D(\d+)','tokens','once'));
                if ~length(nr), nr = realmax('double'); end
                nrs(i) = nr;
            end
            [~, idx] = sort(nrs);
            positionList = positionList(idx);
        end
        
        %% thumbnail %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function im = getThumbnail(obj)
            % thumbnail filename 
            thumbFilename = [obj.filename(1:end-4) '.jpg'];

            % if thumbFilename does not exist, create / update 
            if ~exist(thumbFilename, 'file')
                obj.updateThumbnail( );
            else
                % check whether existing thumbnail is up to date
                file            = dir( thumbFilename );
                file_timestamp  = VTools.getUnixTimeStamp( file.datenum );

                % get timestamp of last position fileChange
                posLastChange_timestamp = uint32(0);
                for i = 1:length(obj.positionList)
                    posFilename     = [VTools.getParentfolderpath(obj.filename) obj.positionList{i} filesep Vanellus.DEFAULT_POS_FILENAME];
                    file            = dir( posFilename );
                    file_timestamp  = VTools.getUnixTimeStamp( file.datenum );
                    posLastChange_timestamp = max( posLastChange_timestamp, file_timestamp);
                end
                
                if file_timestamp < posLastChange_timestamp
                    obj.updateThumbnail( );
                end
            end
            
            % load thumbnail
            im = imread(thumbFilename);
        end
        
        function updateThumbnail(obj)
            if isempty(obj.positionList)
            % if no positions, show eye
                rgb             = repmat(uint8(255*eye(100)), [1 1 3]);
            else
            % create image maximum 4 positions wide
                nrPos               = length(obj.positionList);
                nrRows              = ceil( nrPos / 4 );
                nrCols              = min(4,nrPos);
                posImSize           = obj.get('img_maxThumbSize');
                margin              = 10;
                imWidth             = margin + nrCols * (posImSize(1) + margin);
                imHeight            = margin + nrRows * (posImSize(2) + margin);
                temp                = 0.9 * ones([imHeight imWidth]);

                % add position thumbnails
                for i = 1:length(obj.positionList)
                    % get thumb
                    pos     = VPosition([VTools.getParentfolderpath(obj.filename) obj.positionList{i}], 'silent');
                    thumb   = pos.getThumbnail();
                    thumb   = double(thumb);
                    thumb   = thumb/max(thumb(:));
                    thumb   = imresize(thumb, min( posImSize / size(thumb)) );

                    % place in image
                    xPos    = margin + 0.5*posImSize(1) +     (rem(i-1, 4)) * (posImSize(1) + margin) + 1;
                    yPos    = margin + 0.5*posImSize(2) + (floor( (i-1)/4)) * (posImSize(2) + margin) + 1;
                    temp    = VTools.implace(temp, thumb, xPos, yPos);
                end
                rgb = repmat(temp, [1 1 3]);

                % add position names
                for i = 1:length(obj.positionList)
                    % place in image
                    xPos    = margin + 0.5*posImSize(1) +     (rem(i-1, 4)) * (posImSize(1) + margin) + 1;
                    yPos    = margin + 0.5*posImSize(2) + (floor( (i-1)/4)) * (posImSize(2) + margin) + 1;
                    rgb = insertText( rgb, [xPos yPos], obj.positionList{i}, ...
                                        'AnchorPoint', 'Center', ...
                                        'FontSize', 18, ...
                                        'TextColor', [1 1 1], ...
                                        'BoxColor', [0 1 0], ...
                                        'BoxOpacity', 0.4);
                end                   
            end

            % save as jpg
            if numel(rgb) > 0
                % thumbnail filename 
                thumbFilename = [obj.filename(1:end-4) '.jpg'];
                imwrite( rgb, thumbFilename);
                disp(['VExperiment.updateThumbnail() : written thumbnail to ' thumbFilename]);
            else
                warning(['VExperiment.updateThumbnail() : did not manage to get image']);
            end
        end
        
    end
end