classdef VPosition < VSettings %% C
% VPosition Object that contains all information of a Vanellus position. 

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SUPER_SETTINGS  = { 'pos_isImgUpdated'          , uint32(1), false ; ...
                                    'pos_isImgStabilized'       , uint32(1), false ; ...
                                    'pos_isMovSaved '           , uint32(1), false ; ...
                                    'img_folder'                , uint32(1), '' ; ...
                                    'img_rotation'              , uint32(1), 0 ; ...
                                    'img_useCache'              , uint32(1), true ; ...
                                    'img_autoCache'             , uint32(1), false ; ...
                                    'pos_autoSave'              , uint32(1), true ; ...
                                    'img_autoRotate_minAngle'   , uint32(1), 0.5 ; ...
                                    'img_autoRotate_maxAngle'   , uint32(1), 3 ; ...
                                    'img_autoRotate_resolutionAngle'    , uint32(1), 0.1 ; ...
                                    'img_autoRotate_nrLinesUsed', uint32(1), 10 ; ...
                                    'img_cacheBlockSize'        , uint32(1), 200 ; ...
                                  };
    end

    properties
        version
        settings
        images
    end
    
    properties (Transient) % not stored
        filename
        experiment
        cache
        isSaved
    end

    properties (Dependent) % calculated on the fly
        parent
        frames
        regionList
        
        isSavedAll                  % also whether children (images / stabilization) are saved
    end

    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VPosition(filename, silentMode)
            if nargin < 2, silentMode = false; end
            if nargin < 1 || strcmp(filename, ''), filename = [pwd filesep Vanellus.DEFAULT_POS_FILENAME]; end
            
            obj.filename    = filename;

            % check that folder / filename is ok
            if obj.checkFilename()
                
                % If file exist, try to load Position
                if VTools.isFile(obj.filename)
                    obj                 = obj.load(silentMode);
                    obj.update();       % sets obj.experiment & obj.cache
                    obj.images.position = obj;
                    obj.images.stabilization.images = obj.images;
                    obj.isSaved         = true;
                else
                    % otherwise finish creating VPosition and save
                    obj.update(); % sets obj.experiment & obj.cache
                    obj.settings        = {};

                    imageStorageType    = obj.get('img_class');

                    obj.version         = Vanellus.VERSION;
                    obj.images          = imageStorageType(obj);

                    obj.save(silentMode);
                    obj.isSaved         = true;
                end
            end
        end

        function position = load(obj, silentMode)
            if nargin < 2, silentMode = false; end
                
            if VTools.isFile(obj.filename)
                load(obj.filename);
                position.filename   = obj.filename;
                position.isSaved    = true;
                position.update();

                if ~silentMode, disp(['VPosition -> loaded Position from file:             ' obj.filename]); end
            else
                warning(['VPosition -> could not load file, cause does not exist: ' obj.filename]);
            end
        end
        
        function save(obj, silentMode)
            if nargin < 2, silentMode = false; end
            
            if obj.checkFilename()
                position            = obj;
                position.version    = Vanellus.VERSION; % will be saved as current version, whether it was old version or not
                save(obj.filename, 'position');
                obj.isSaved         = true;
                obj.images.isSaved  = true;
                obj.images.stabilization.isSaved = true;

                if ~silentMode, disp(['VPosition -> saved Position to file:                ' obj.filename]); end
            end
        end

        function tf = checkFilename(obj)
            % In case current obj.filename is an existing folder, just add 'vanellusPos.mat'
            if isdir(obj.filename)
                obj.filename = [VTools.addToEndOfString(obj.filename, filesep) Vanellus.DEFAULT_POS_FILENAME];
                tf = true;
                return;
            end
               
            % In case obj.filename indicates a 'vanellusPos.mat' file in an existing folder
            if VTools.endsWith(obj.filename, [filesep Vanellus.DEFAULT_POS_FILENAME]) && isdir(VTools.getParentfolderpath(obj.filename))
                tf = true;
                return;
            end

            tf = false;
            warning(['VPosition -> folder of filename does not exist: ' obj.filename]);
        end
        
        function autoSave(obj)
            % Saves object if it is not saved and autoSave setting is on
            if ~obj.isSaved
                if obj.get('pos_autoSave')
                    obj.save();
                end
            end
        end
                        
        
        %% updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function update(obj)
            obj.experiment      = VExperiment( VTools.getParentfolderpath( VTools.getParentfolderpath(obj.filename) ), 'silent');
            obj.cache           = VCachedImages( VTools.getParentfolderpath(obj.filename), obj );
        end

        function updateImages(obj)
            oldImages = obj.images; % in case nothing changes, can keep old stabilization
            
            % reload experiment, in case its settings have changed
            obj.update();
            imageStorageType    = obj.get('img_class');
            obj.images          = imageStorageType(obj);
            obj.images.update(obj);
            
            if ~isequal(obj.images, oldImages) % only change status if images have changed
                if isempty(obj.images.frames)
                    obj.set('pos_isImgUpdated', false);
                else
                    obj.set('pos_isImgUpdated', true);
                end                    
                obj.isSaved = false;
                obj.set('pos_isImgStabilized', false);
                obj.set('pos_isMovSaved', false);
                obj.cache.clearCacheMatFile();
            else
                obj.images = oldImages;
            end
        end
        
        
        %% dependencies %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function parent = get.parent(obj)
            parent = obj.experiment;
        end  

        function frames = get.frames(obj)
            if isempty( obj.get('img_frames') )
                frames  = obj.images.frames;
            else
                frames  = intersect( uint16( obj.get('img_frames') ) , obj.images.frames );
            end
        end      
        
        function isSavedAll = get.isSavedAll(obj)
            isSavedAll = all( [ obj.isSaved ...
                                obj.images.isSaved ...
                                obj.images.stabilization.isSaved ] );
        end         
        
        function regionList = get.regionList(obj)
            % get regionList
            regionList = {};
            subfolderNames = VTools.getSubfoldernames(VTools.getParentfolderpath(obj.filename));
            for i = 1:length(subfolderNames)
                positionFilename = [VTools.getParentfolderpath(obj.filename) subfolderNames{i} filesep Vanellus.DEFAULT_REG_FILENAME];
                if VTools.isFile(positionFilename)
                    regionList{end+1} = subfolderNames{i};
                end
            end
            
            % sort by number
            nrs = [];
            for i = 1:length(regionList);
                nr = str2double(regexpi(regionList{i},'.*\D(\d+)','tokens','once'));
                if isempty(nr), nr = realmax('double'); end
                nrs(i) = nr;
            end
            [~, idx] = sort(nrs);
            regionList = regionList(idx);
        end        

        
        %% region %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function reg = createRegion(obj, regName, rect, silentMode) % rect = [l t w h], and size(obj.images.imageSize{1}) gives [h w]
            % get regName
            if nargin < 2, regName = []; end
            if isempty(regName), regName = 'reg'; end
            
            % get rect
            if nargin < 3, rect = []; end
            if isempty(rect), rect = obj.images.checkRect(rect); end
            
            % get silentMode
            if nargin < 4, silentMode = false; end
            
            % make sure regName ends with /
            regName = VTools.addToEndOfString(regName, filesep);
            regFolderName = [VTools.getParentfolderpath(obj.filename) regName];
            regFilename = [regFolderName Vanellus.DEFAULT_REG_FILENAME];

            % if region already exists, don't create but do return
            if VTools.isFile(regFilename)
                if ~silentMode, warning(['VPosition -> could not create Region, as it already exists : ' regFolderName]); end
                reg = VRegion(regFilename);
                return;
            end            
            
            % create Region subfolder if necessary
            if ~isdir(regFolderName)
                tf = VTools.mkdir(regFolderName);
                if tf
                    if ~silentMode, disp(['VPosition -> created Region folder :                ' regFolderName]); end
                else
                    warning(['VPosition -> could not make Region folder : ' regFolderName]);
                end
            end
            
            % save region file
            reg = VRegion(regFilename, rect, 'silent');

            if ~silentMode, disp(['VPosition -> created Region :                       ' regFilename]); end
        end
        
        function regionListRect = getRegionListRect(obj)
            regList = obj.regionList;

            [regionListRect, regionListRectTimestamp] = obj.get('pos_regionListRect');
            if isempty(regionListRect), regionListRect = {'', [1 1 100 100]}; end            
            
            regionListRect_needsUpdating = false;
            for i = 1:length(regList)
                regFilename        = [VTools.getParentfolderpath(obj.filename) regList{i} filesep 'vanellusReg.mat'];
                
                regionListRectIdx = find( strcmp(regionListRect(:,1), regList{i} ));
                if ~isempty(regionListRectIdx)
                
                    % determine vanellusReg.mat file timestamp
                    file            = dir(regFilename);
                    file_timestamp  = VTools.getUnixTimeStamp_OldVersion( file.datenum );
                    
                    % compare to stored regionListRectTimestamp
                    if file_timestamp <= regionListRectTimestamp
                        regionListRect{i} = regionListRect{regionListRectIdx, 2};
                    else
                        regionListRect_needsUpdating = true;
                        break;
                    end
                else
                    regionListRect_needsUpdating = true;
                    break;
                end
            end
            
            if regionListRect_needsUpdating
                % get regionListRect by loading region files (slow)
                clear regionListRect                
                for i = 1:length(regList)
                    regFilename     = [VTools.getParentfolderpath(obj.filename) regList{i} filesep 'vanellusReg.mat'];
                    temp            = load(regFilename);

                    settingsIdx = find(strcmp('reg_rect',temp.region.settings(:,1)));
                    if settingsIdx
                        regionListRect{i} = temp.region.settings{settingsIdx,3};
                    else
                        reg = VRegion( regFilename , [], true);
                        regionListRect{i} = reg.rect;
                    end
                end                
                
                % store regionListRect for next time
                obj.unset('pos_regionListRect'); % needed to force time update
                obj.set('pos_regionListRect', {regList{:} ; regionListRect{:}}');
            end
        end        

        function [channel_periodicity, channel_width, channel_xoffset, channel_yranges] = autoDetectChannels(obj)
            % settings
            x_autocorr_minP     = 0.2;
            xoffset_resolution  = 0.1;
            xoffset_sum_smooth  = 19;
            min_channel_int     = 0.5;
            min_channel_length  = 50;
            
            % get image
            [frame, type]       = obj.images.getRefToFirstImage();
            im                  = obj.getImage(frame, type);
            im                  = medfilt2(im, [3 3]);
            
            % determine periodicity and width from autocorrelation mean x
            mean_x              = mean(im, 1);
            x_autocorr          = autocorr(mean_x, floor( 0.9*numel(mean_x) ) );
            x_autocorr          = x_autocorr - min(x_autocorr);
            x_autocorr          = x_autocorr / max(x_autocorr);

            [pks, locs, w, p]   = findpeaks( x_autocorr );
            idx                 = find( p > x_autocorr_minP );
            median_periodicity  = median( diff( locs(idx) ) );
            channel_periodicity = locs(idx) / (round(locs(idx)/median_periodicity));
            channel_width       = mean( w(idx) );

            % determine offset by maximizing intensity in mean_x
            func_channels_idx   = @(x, periodicity, width, offset) rem(x-offset+0.5*width, periodicity) <= width;
            offsets             = [xoffset_resolution:xoffset_resolution:channel_periodicity] + 0.5*channel_width;
            for i = 1:length(offsets)
                x_idx_channels  = func_channels_idx([1:numel(mean_x)-3*channel_periodicity], channel_periodicity, channel_width, offsets(i) );
                offset_sum( i ) = mean( mean_x(x_idx_channels) );
            end
            offset_sum          = [offset_sum(end-xoffset_sum_smooth+1:end) offset_sum offset_sum(1:xoffset_sum_smooth)]; % to correct for circular data
            offset_sum          = smooth(offset_sum, xoffset_sum_smooth);
            offset_sum          = offset_sum(xoffset_sum_smooth+1:end-xoffset_sum_smooth);
            [~, indexMax]       = max( offset_sum );
            channel_xoffset     = offsets(indexMax);
            
            % determine yranges from intensity mean y
            mean_y              = mean(im, 2)';
            channel_xIdx        = func_channels_idx([1:numel(mean_x)], channel_periodicity, channel_width, channel_xoffset );
            mean_y_ch           = mean(im(:,channel_xIdx), 2)';
            mean_y_noch         = mean(im(:,~channel_xIdx), 2)';
            mean_y_diff         = max(0, mean_y_ch - mean_y_noch);
            mean_y_diff         = mean_y_diff - min(mean_y_diff);
            mean_y_diff         = mean_y_diff / max(mean_y_diff);   
            mean_y_intHigh      = diff( (mean_y_diff > min_channel_int) );

            idx_upDown          = find(mean_y_intHigh==-1 | mean_y_intHigh==1);
            channel_yranges     = {};
            y_idx_channels      = logical(zeros([1 size(im,2)]));
            for i = 1:numel(idx_upDown)-1
                if mean_y_intHigh( idx_upDown(i) ) == 1 && mean_y_intHigh( idx_upDown(i+1) ) == -1
                    if idx_upDown(i+1) - (idx_upDown(i)+1) >= min_channel_length
                        
                        start_idx   = find(mean_y_diff == 0 & [1:numel(mean_y_diff)] < idx_upDown(i)+1, 1, 'last');
                        end_idx     = find(mean_y_diff == 0 & [1:numel(mean_y_diff)] > idx_upDown(i+1), 1) - 1;
                        
                        y_idx_channels(start_idx:end_idx) = 1;
                        
                        P = polyfit( [start_idx:end_idx], mean_y([start_idx:end_idx]), 1);
                        if P(1) < 0
                            channel_yranges{end+1} = [end_idx start_idx-end_idx];
                        else
                            channel_yranges{end+1} = [start_idx end_idx-start_idx];
                        end
                    end            
                end
            end

            % show when DEBUGGING
            if obj.get('van_DEBUG')

                disp(['Periodicity is : ' num2str(channel_periodicity)]);
                disp(['Width is : ' num2str(channel_width)]);
                disp(['Offset is : ' num2str( channel_xoffset )]);
                for r = 1:length(channel_yranges)
                    disp(['Range ' num2str(r) ' is : [' num2str(channel_yranges{r}(1)) ' ' num2str(channel_yranges{r}(2)) ']']);
                end
                
                hFig = figure;
                imshow(imadjust(im)); 
                for r = 1:length(channel_yranges)
                    for c = 0:floor( (size(im,1)-channel_xoffset-0.5*channel_width) / channel_periodicity)
                        if channel_yranges{r}(2) > 0
                            coor = [channel_xoffset+c*channel_periodicity-0.5*channel_width channel_yranges{r}(1) channel_width channel_yranges{r}(2) ];
                        else
                            coor = [channel_xoffset+c*channel_periodicity-0.5*channel_width channel_yranges{r}(1)+channel_yranges{r}(2) channel_width -channel_yranges{r}(2) ];
                        end                
                        hold on; rectangle('Position',coor,'EdgeColor','r')
                    end
                end
                
                hFig2 = figure;
                subplot(2,3,1);
                plot( mean_x ); ylabel('mean_x', 'interpreter', 'none');
                xlim([1 numel(mean_x)]);

                subplot(2,3,2);
                plot( mean_y ); ylabel('mean_y', 'interpreter', 'none');
                xlim([1 numel(mean_y)]);

                subplot(2,3,4);
                plot( x_autocorr ); ylabel('x_autocorr', 'interpreter', 'none');
                xlim([1 numel(x_autocorr)]);
                hold on; plot( locs(idx), pks(idx), 's', 'color', 'blue');                  
                
                subplot(2,3,5);
                plot( mean_y_diff); ylabel('mean_y_diff', 'interpreter', 'none');
                xlim([1 numel(mean_y_diff)]);

                subplot(2,3,3);
                plot( offset_sum); ylabel('offset_sum', 'interpreter', 'none');

                close(hFig2);
                waitforbuttonpress;
                close(hFig); 
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
                [frame, type] = obj.images.getRefToFirstImage(frame, type);
            end
            
            % convert type to typeIdx
            typeIdx = obj.images.getTypeIdx( type );
            
            % if useCache is activated, image is in cache, and is up2date, get cached image
            [inCacheTF, cacheTimestamp] = obj.cache.isImageInCache( frame, typeIdx);
            if useCache && inCacheTF && cacheTimestamp >= obj.getLastImageChange( frame, type)
                im          = obj.cache.getImageFromCache( frame, typeIdx );
                success     = true;
                
            % not using cache, so getting directly
            else
                % load from file
                [im, success] = obj.images.readImage( frame, type );

                % shift according to stabilization
                shift   = obj.images.stabilization.shift(frame ,:);
                if ~isempty(shift) && ~isequal(shift, [0 0])
                    im = imtranslate(im, [shift(2) shift(1)]); % im  = VTools.imtranslate(im, shift);
                end
                
                % rotate image
                img_rotation = obj.get('img_rotation');
                if ~isempty(img_rotation) && ~isequal(img_rotation, 0)
                    im = VTools.imrotate(im, img_rotation);
                end
                
                % cache image if autoCache is on
                if obj.get('img_autoCache') && success, obj.cache.storeImageInCache( frame, type, true, im ); end
            end
        end
        
        function tf = cacheImages(obj, frames, types)
            % if frame/type are not given or as [], obj.frames and all types will be used
            if nargin < 2,      frames  = []; end
            if nargin < 3,      types   = ''; end
            if isempty(frames), frames  = obj.frames; end
            if isempty(types),  types   = obj.images.types; end
            
            tf = obj.cache.storeImageInCache( frames, types);
        end        
        
        function img_rotation = autoRotate(obj)
            % get edge image
            [frame, type]   = obj.images.getRefToFirstImage();
            im              = obj.getImage(frame, type);
            im              = medfilt2(im, [3 3]);
            im_edge         = edge(im, 'canny'); 
            
            % find angle using Hough transform
            [H, theta, ~]   = hough(im_edge, 'Theta', [-obj.get('img_autoRotate_maxAngle'):obj.get('img_autoRotate_resolutionAngle'):obj.get('img_autoRotate_maxAngle')]);
            peaks           = houghpeaks(H, obj.get('img_autoRotate_nrLinesUsed'));
            img_rotation    = mean( theta( peaks(:,2) ) );
            disp(['VPosition.autoRotate : Angle is ' num2str(img_rotation)]);
            
            % check whether angle is of minimum size
            if abs(img_rotation) < obj.get('img_autoRotate_minAngle')
                disp(['VPosition.autoRotate : Angle is smaller than img_autoRotate_minAngle, so not applying']);
                img_rotation = 0;
            end
                        
            % store img_rotation
            obj.set('img_rotation', img_rotation);
        end
        
        
        %% thumbnail %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function im = getThumbnail(obj, type )
            if nargin < 2
                [~, type] = obj.images.getRefToFirstImage();
            end
            
            % in case images not initialized, show eye
            if isempty(type)
                im = uint8(255*eye(100));
                return;
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
                disp(['VPosition.updateThumbnail() : written thumbnail to ' thumbFilename]);
            else
                warning(['VPosition.updateThumbnail() : did not manage to get image']);
            end
        end
        
        
        
        %% stabilization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function stabilize(obj)
            obj.set('pos_isImgStabilized', false);
            oldRegistration = obj.images.stabilization; % in case nothing changes, can keep old stabilization
            
            % reload experiment, in case its settings have changed
            obj.update();
            obj.images.update(obj);

            % (re)do stabilization
            obj.images.stabilize(obj);
            
            if ~isequal(obj.images.stabilization, oldRegistration) % only change status if images have changed
                obj.isSaved = false;
                obj.set('pos_isMovSaved', false);
                obj.cache.clearCacheMatFile();
            else
                obj.images.stabilization = oldRegistration;
            end
            
            obj.set('pos_isImgStabilized', true);            
        end
        
        
        %% changes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = deletePosition(obj, areYouSure)
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
            % returns timestamp of last change that affects images: 'pos_isImgUpdated', 'img_rotation'
            [~, timestamp1] = obj.get('pos_isImgUpdated');
            [~, timestamp2] = obj.get('img_rotation');
            timestamp = max( [timestamp1 timestamp2] );
        end
    
    end
end
