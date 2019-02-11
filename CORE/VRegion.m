classdef VRegion < VSettings %% C
% VRegion Object that contains all information of a Vanellus region. 

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        ADDITIONAL_ROTATIONS    = { '90 LEFT', '180', '90 RIGHT', 'NONE'};
        DEFAULT_SUPER_SETTINGS  = { 'reg_rotation90'        , uint32(1), 'NONE' ; ...
                                    'reg_rect'              , uint32(1), [1 1 100 100] ; ...
                                    'reg_isSegmented'       , uint32(1), false ; ...
                                    'reg_isTracked'         , uint32(1), false ; ...
                                    'reg_isCompiled'        , uint32(1), false ; ...
                                    'seg_imgType'           , uint32(1), { 'p' } ; ...
                                    'seg_isMaskManuallySet' , uint32(1), false ; ...
                                    'seg_isSegManuallySet'  , uint32(1), false ; ...
                                    'seg_sigma'             , uint32(1), 3 ; ...
                                    'seg_medFilt'           , uint32(1), 1 ; ...
                                    'img_cacheBlockSize'    , uint32(1), 200 ; ...
                                    'reg_useCachedPos'      , uint32(1), true ; ...
                                  };
    end
    
    properties
        version
        settings
        
        regionmask
        masks
        segmentations
        trackings
        tree
        
        annotations
    end
    
    properties (Transient) % not stored
        filename
        position
        cache
        isSaved
    end

    properties (Dependent) % calculated on the fly
        parent
        images
        frames
        rect
        isSavedAll                  % also whether children (regionmask / masks / segmentations / trackings) are saved
        lastChange

        regionSize                  % [h w] in position image
        rotationAdditional90Idx     % [1 2 3 or 4] indicating additional rotation
        rotatedRegionSize           % [h w] in additionally rotated position image
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VRegion(filename, rect, silentMode)
            % get filename
            if nargin < 1, filename = []; end
            if isempty(filename) || strcmp(filename, ''), filename = [pwd filesep Vanellus.DEFAULT_REG_FILENAME]; end 
            
            % get rect
            if nargin < 2, rect = []; end
            
            % get silentMode
            if nargin < 3, silentMode = false; end
            
            obj.filename    = filename;

            % check that folder / filename is ok
            if obj.checkFilename()
                
                % If file exist, try to load Position
                if VTools.isFile(obj.filename)
                    obj                             = obj.load(silentMode);
                    obj.update();                   % sets obj.position & obj.cache and updates region in regionmask and masks
                    obj.isSaved                     = true;
                    obj                             = obj.checkVersion(); % correct old version files 
                else
                    % otherwise finish creating VRegion and save
                    obj.version                     = Vanellus.VERSION;
                    obj.settings                    = {};
                    obj.update();                   % sets obj.position & obj.cache

                    % make sure rect is ok
                    obj.changeRect(rect);

                    regionmaskType                  = obj.get('rmsk_class');
                    obj.regionmask                  = regionmaskType( obj );

                    masksType                       = obj.get('msk_class');
                    obj.masks                       = masksType( obj );

                    segmentationsType               = obj.get('seg_class');
                    obj.segmentations               = segmentationsType( obj );

                    trackingsType                   = obj.get('trk_class');
                    obj.trackings                   = trackingsType( obj );

                    treeType                        = obj.get('tree_class');
                    obj.tree                        = treeType( obj );

                    annotationsType                 = obj.get('ann_class');
                    obj.annotations                 = annotationsType( obj );
                    
                    obj.save(silentMode);
                end
            end            
        end

        function region = load(obj, silentMode)
            if nargin < 2, silentMode = false; end
                
            if VTools.isFile(obj.filename)
                load(obj.filename);

                region.filename     = obj.filename;
                region.isSaved      = true;
                
                if ~silentMode, disp(['VRegion -> loaded Region from file:                 ' obj.filename]); end
            else
                warning(['VRegion -> could not load file, cause does not exist: ' obj.filename]);
            end
        end
        
        function tf = save(obj, silentMode)
            tf = false;
            
            if nargin < 2, silentMode = false; end
            
            if obj.checkFilename()
                region                              = obj;
                region.version                      = Vanellus.VERSION; % will be saved as current version, whether it was old version or not
                van_matFileVersion                  = obj.get('van_matFileVersion');
                save(obj.filename, 'region', van_matFileVersion);
                obj.isSaved                         = true;
                obj.regionmask.isSaved              = true;
                obj.masks.isSaved                   = true;
                obj.segmentations.isSaved           = true;
                obj.trackings.isSaved               = true;
                obj.tree.isSaved                    = true;
                obj.annotations.isSaved             = true;

                if ~silentMode, disp(['VRegion -> saved Region to file:                    ' obj.filename]); end
                
                tf = true;
            end
        end        
        
        function tf = checkFilename(obj)
            % In case current obj.filename is an existing folder, just add 'vanellusReg.mat'
            if isdir(obj.filename)
                obj.filename = [VTools.addToEndOfString(obj.filename, filesep) Vanellus.DEFAULT_REG_FILENAME];
                tf = true;
                return;
            end
               
            % In case obj.filename indicates a 'vanellusReg.mat' file in an existing folder
            if VTools.endsWith(obj.filename, [filesep Vanellus.DEFAULT_REG_FILENAME]) && isdir(VTools.getParentfolderpath(obj.filename))
                tf = true;
                return;
            end

            tf = false;
            warning(['VRegion -> folder of filename does not exist: ' obj.filename]);
        end
        
        
        %% updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function update(obj)
            obj.position    = VPosition( VTools.getParentfolderpath( VTools.getParentfolderpath(obj.filename) ), 'silent');
            obj.cache       = VCachedImages( VTools.getParentfolderpath(obj.filename), obj );
            
            % in case regionmask not set, or regionmask Type has changed, create new
            if isempty(obj.regionmask) || ~strcmp( char( obj.get('rmsk_class') ), class(obj.regionmask) )
                regionmaskType                  = obj.get('rmsk_class');
                obj.regionmask                  = regionmaskType( obj );
                obj.regionmask.isSaved          = false;
            end
            obj.regionmask.update(obj); % update region in regionmask
            
            % in case masks is not set, or masks Type has changed, create new
            if isempty(obj.masks) || ~strcmp( char( obj.get('msk_class') ), class(obj.masks) )
                masksType                       = obj.get('msk_class');
%                 if ~exist(func2str(masksType), 'class'), masksType = obj.parent.get('msk_class'); end
                obj.masks                       = masksType( obj );
                obj.masks.isSaved               = false;
            end
            obj.masks.update(obj); % update region in masks

            % in case segmentations is not set, or segmentations Type has changed, create new
            if isempty(obj.segmentations) || ~strcmp( char( obj.get('seg_class') ), class(obj.segmentations) )
                segmentationsType               = obj.get('seg_class');
                obj.segmentations               = segmentationsType( obj );
                obj.segmentations.isSaved       = false;
            end
            obj.segmentations.update(obj); % update region in segmentations

            % in case trackings is not set, or trackings Type has changed, create new
            if isempty(obj.trackings) || ~strcmp( char( obj.get('trk_class') ), class(obj.trackings) )
                trackingsType                   = obj.get('trk_class');
                obj.trackings                   = trackingsType( obj );
                obj.trackings.isSaved           = false;
            end
            obj.trackings.update(obj); % update region in trackings

            % in case tree not set, or tree Type has changed, create new
            if isempty(obj.tree) || ~strcmp( char( obj.get('tree_class') ), class(obj.tree) )
                treeType                        = obj.get('tree_class');
                obj.tree                        = treeType( obj );
                obj.tree.isSaved                = false;
            end
            obj.tree.update(obj); % update region in tree
            
            % in case annotations is not set, or annotations Type has changed, create new
            if isempty(obj.annotations) || ~strcmp( char( obj.get('ann_class') ), class(obj.annotations) )
                annotationsType                 = obj.get('ann_class');
                obj.annotations                 = annotationsType( obj );
                obj.annotations.isSaved         = false;
            end
            obj.annotations.update(obj); % update region in annotations
        end
        
        
        %% dependencies %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rect = get.rect(obj)
            rect = obj.get('reg_rect');
            if isempty(rect), rect = [1 1 100 100]; end
        end        
        
        function frames = get.frames(obj)
            if isempty( obj.get('img_frames') )
                frames  = obj.parent.frames;
            else
                frames  = intersect( uint16( obj.get('img_frames') ) , obj.parent.frames );
            end
        end        
        
        function parent = get.parent(obj)
            parent = obj.position;
        end         

        function images = get.images(obj)
            images = obj.position.images;
        end        
        
        function isSavedAll = get.isSavedAll(obj)
            isSavedAll = all( [ obj.isSaved ...
                                obj.regionmask.isSaved ...
                                obj.masks.isSaved ...
                                obj.segmentations.isSaved ...
                                obj.trackings.isSaved ...
                                obj.tree.isSaved ...
                                obj.annotations.isSaved] );
        end         
        
        function lastChange = get.lastChange(obj)
            masksLastChange             = obj.masks.getLastChange();
            segmentationsLastChange     = obj.segmentations.getLastChange();
            trackingsLastChange         = obj.trackings.getLastChange();
            lastChange                  = max([masksLastChange segmentationsLastChange trackingsLastChange]);
        end         
        
        function regionSize = get.regionSize(obj)
            regionSize = obj.rect(4:-1:3);
        end        
        
        function rotationAdditional90Idx = get.rotationAdditional90Idx(obj)
            rotationAdditional90 = obj.get('reg_rotation90');
            if isempty(rotationAdditional90), rotationAdditional90 = 'NONE'; end
            rotationAdditional90Idx = find( strcmp(rotationAdditional90, VRegion.ADDITIONAL_ROTATIONS) );
        end
        
        function rotatedRegionSize = get.rotatedRegionSize(obj)
            rotatedRegionSize = obj.regionSize;
            if obj.rotationAdditional90Idx == 1 || obj.rotationAdditional90Idx == 3
                rotatedRegionSize = rotatedRegionSize(2:-1:1);
            end
        end  

        
        %% images %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [im, success] = getImage(obj, frame, type, useCache)
            % input checking
            if nargin < 2, frame    = []; end
            if nargin < 3, type     = ''; end
            if nargin < 4, useCache = []; end
            if isempty(useCache), useCache = obj.get('img_useCache'); end

            % if type/frame are not given or as [], or multiple, first image will be returned
            if isempty(frame) || isempty(type) || length(type)>1 || length(frame)>1
                [frame, type] = obj.position.images.getRefToFirstImage(frame, type);
            end
            
            % convert type to typeIdx
            typeIdx = obj.position.images.getTypeIdx( type );
            
            % if useCache is activated, image is in cache, and is up2date, get cached image
            [inCacheTF, cacheTimestamp] = obj.cache.isImageInCache( frame, typeIdx);
            if useCache && inCacheTF && cacheTimestamp >= obj.getLastImageChange( frame, type)
                im          = obj.cache.getImageFromCache( frame, typeIdx );
                success     = true;
                
            % not using cache, so getting directly
            else
                % load from file
                if useCache && obj.get('reg_useCachedPos') % 2DO: check whether region img_rotation is the same as that of position
                    [im, success] = obj.position.getImage(frame, type, true);
                else
                    [im, success] = obj.position.images.readImage( frame, type );

                    % shift according to stabilization
                    shift   = obj.position.images.stabilization.shift(frame ,:);
                    if ~isempty(shift) && ~isequal(shift, [0 0])
                        im = imtranslate(im, [shift(2) shift(1)]); % im  = VTools.imtranslate(im, shift);
                    end

                    % rotate image
                    img_rotation    = obj.get('img_rotation');
                    if ~isempty(img_rotation) && ~isequal(img_rotation, 0)
                        im = VTools.imrotate(im, rotation);
                    end
                end
                
                % if reg_rect is set, crop
                reg_rect        = obj.get('reg_rect');
                if ~isempty(reg_rect)
                    im = VImages.cropImage(im, reg_rect);
                end
                
                % cache image if autoCache is on
                if obj.get('img_autoCache') && success, obj.cache.storeImageInCache( frame, type, true, im ); end
            end
        end
        
        function im = getImageWithAddedRotation(obj, frame, type, useCache)
            % input checking
            if nargin < 2, frame    = []; end
            if nargin < 3, type     = ''; end
            if nargin < 4, useCache = []; end

            im = obj.getImage( frame, type, useCache);
        
            % apply additional 90-degrees rotation
            if obj.rotationAdditional90Idx ~= 4
                im = rot90(im, obj.rotationAdditional90Idx);
            end
        end        
        
        function im = addRotation(obj, im)
            % apply additional 90-degrees rotation
            if obj.rotationAdditional90Idx ~= 4
                im = rot90(im, obj.rotationAdditional90Idx);
            end
        end
        
        function tf = cacheImages(obj, frames, types)
            % if frame/type are not given or as [], obj.frames and all types will be used
            if nargin < 2,      frames  = []; end
            if nargin < 3,      types   = ''; end
            if isempty(frames), frames  = obj.frames; end
            if isempty(types),  types   = obj.position.images.types; end
            
            tf = obj.cache.storeImageInCache( frames, types);
        end        
        
        function im = getThumbnail(obj, type )
            if nargin < 2
                [~, type] = obj.images.getRefToFirstImage();
            end

            % thumbnail filename 
            thumbFilename = [obj.filename(1:end-4) '-' type '.jpg'];

            % if thumbFilename does not exist, create / update 
            if ~exist(thumbFilename, 'file')
                obj.updateThumbnail( type );
            else
                % check whether existing thumbnail is up to date
                file            = dir( thumbFilename );
                file_timestamp  = VTools.getUnixTimeStamp( file.datenum );

                if file_timestamp < obj.getLastImageChange()
                    obj.updateThumbnail( type );
                end
            end
            
            % load thumbnail
            im = imread(thumbFilename);
        end
        
        function updateThumbnail(obj, type )
            % input checking
            if nargin < 2, type = []; end

            % find first image
            [frame, type] = obj.images.getRefToFirstImage([], type);

            % get image
            im = obj.getImage( frame, type );
            
            % adjust contrast of image
            im = imadjust(im2uint8(im));

            % save as jpg
            if numel(im) > 0 && ~isempty(type)
                % thumbnail filename 
                thumbFilename = [obj.filename(1:end-4) '-' type '.jpg'];

                imwrite( im, thumbFilename); 
                disp(['VRegion.updateThumbnail() : written thumbnail to ' thumbFilename]);
            else
                warning(['VRegion.updateThumbnail() : did not manage to get image']);
            end
        end
        
        function deleteThumbnails(obj)
            % loop over types
            for i = 1:numel( obj.images.types )
                % thumbnail filename 
                filename = [obj.filename(1:end-4) '-' obj.images.types{i} '.jpg'];
                % if file exists, delete file
                if VTools.isFile(filename), delete(filename);end
            end
        end
        
        %% changes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = changeRect(obj, rect)
            tf = obj.set('reg_rect', obj.position.images.checkRect(rect));
        end
        
        function tf = deleteRegion(obj, areYouSure)
            tf = false;
            
            if nargin < 2
                areYouSure = input('Are you sure? (yes / no):', 's');
            end
            
            if strcmp('yes', areYouSure)
                [tf, ~, ~] = rmdir( VTools.getParentfolderpath(obj.filename) ,'s');
                obj.delete();
            end
        end
        
        %% timestamps %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function timestamp = getLastImageChange(obj, frame, type)
            % returns timestamp of last change that affects images: 'pos_isImgUpdated', 'img_rotation', 'reg_rect'
            [~, timestamp1] = obj.get('pos_isImgUpdated');
            [~, timestamp2] = obj.get('img_rotation');
            [~, timestamp3] = obj.get('reg_rect');
            timestamp = max( [timestamp1 timestamp2 timestamp3] );
        end
        
        %% get data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function regionmask = getRegionmask(obj)
            regionmask = obj.regionmask.mask;
        end
        
        function mask = getMask(obj, frame)
            mask = obj.masks.getUpdatedData( uint16( frame ) );
        end

        function seg = getSeg(obj, frame)
            seg = uint16( obj.segmentations.getUpdatedData( uint16( frame ) ) );
        end
        
        function track = getTrack(obj, idf)
            track = obj.trackings.getUpdatedData( uint16( idf ) );
        end
       
        function data = getTreeData(obj, idf)
            data = obj.tree.getUpdatedData( idf );
        end
        
        function tree = getTree(obj)
            tree = obj.tree.getSchnitzcellsTree();
        end
    end
    
    %% FOR TRANSITION PHASE TO NEW VREGION STRUCTURE %%%%%%%%%%%%%%%%%%%%%%
    methods (Hidden)
        function obj = checkVersion(obj)
            % WARN IF VREGION VERSION IS NEWER THAN VANELLUS
            if VTools.dataStringLessThan( Vanellus.VERSION, obj.version)
                warning off backtrace;
                warning(['VRegion version (' obj.version ') is newer than current Vanellus version (' Vanellus.VERSION '). Update Vanellus now!']);
                warning on backtrace;
            end            
            
            % VREGION UPDATE
            if VTools.dataStringLessThan( obj.version, '2016-11-18')
                
                warning off backtrace;
                warning(['Converting old VRegion version (' obj.version ') to new one. Save updated region now!']);
                warning on backtrace;
                try
                    obj.segmentations.settings          = obj.masks.temp_segmentations.settings;
                    obj.segmentations.dataArray         = obj.masks.temp_segmentations.dataArray;
                    obj.segmentations.dataArrayIdf      = obj.masks.temp_segmentations.dataArrayIdf;
                    obj.segmentations.dataArrayLength   = obj.masks.temp_segmentations.dataArrayLength;
                    obj.segmentations.Idf2Idx           = obj.masks.temp_segmentations.Idf2Idx;

                    obj.trackings.settings              = obj.masks.temp_segmentations.temp_trackings.settings;
                    obj.trackings.dataArray             = obj.masks.temp_segmentations.temp_trackings.dataArray;
                    obj.trackings.dataArrayIdf          = obj.masks.temp_segmentations.temp_trackings.dataArrayIdf;
                    obj.trackings.dataArrayLength       = obj.masks.temp_segmentations.temp_trackings.dataArrayLength;
                    obj.trackings.Idf2Idx               = obj.masks.temp_segmentations.temp_trackings.Idf2Idx;

                    obj.tree.settings                   = obj.masks.temp_segmentations.temp_trackings.temp_tree.settings;
                    obj.tree.dataArray                  = obj.masks.temp_segmentations.temp_trackings.temp_tree.dataArray;
                    obj.tree.dataArrayIdf               = obj.masks.temp_segmentations.temp_trackings.temp_tree.dataArrayIdf;
                    obj.tree.dataArrayLength            = obj.masks.temp_segmentations.temp_trackings.temp_tree.dataArrayLength;
                    obj.tree.Idf2Idx                    = obj.masks.temp_segmentations.temp_trackings.temp_tree.Idf2Idx;
                    obj.isSaved                         = false;
                catch
                    warning off backtrace;
                    warning(['Something went wrong trying to convert old VRegion version to new one!']);
                    warning on backtrace;
                end
            end
            
            % VDATA UPDATE
            if VTools.dataStringLessThan( obj.version, '2017-02-01')

                warning off backtrace;
                warning(['Converting old VData version (' obj.version ') to new one. Save updated region now!']);
                warning on backtrace;
                try
                    classList = { 'annotations' 'masks' 'segmentations' 'trackings' 'tree' };
                    for i = 1:length(classList)
                        if ~isempty( obj.(classList{i}).dataArray )
                            obj.(classList{i}).dataArrayIdf          = obj.(classList{i}).dataArray(:,1)';
                            obj.(classList{i}).dataArrayData         = obj.(classList{i}).dataArray(:,4)';
                            obj.(classList{i}).dataArraySettings     = obj.(classList{i}).dataArray(:,3)';
                            obj.(classList{i}).dataArrayTimestamp    = obj.(classList{i}).dataArray(:,2)';
                            obj.(classList{i}).dataArrayLastChange   = obj.(classList{i}).dataArray(:,2)';
%                             obj.(classList{i}).updateDataArrayIdf2Idx();
                        end
                    end
                    obj.isSaved                          = false;
                catch exc
                    warning off backtrace;
                    warning(['Something went wrong trying to convert old VData version to new one!']);
                    warning on backtrace;
                end
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
