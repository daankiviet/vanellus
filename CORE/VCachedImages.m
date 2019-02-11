classdef VCachedImages < handle %% C
% VCachedImages Object that provides interface with stored cached images. 

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties
        version
        cacheMap
    end
    
    properties (Transient) % not stored
        filename
        parent
    end

    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VCachedImages(filename, parent)
            % check filename and parent
            if nargin < 1, warning(['VCachedImages -> no filename/folder provided']); end
            if nargin < 2, parent = []; end

            % set properties
            obj.filename = filename;
            obj.parent = parent;

            % check that folder / filename is ok
            if obj.checkFilename()

                % If file exist, try to load cacheMap
                if VTools.isFile(obj.filename)
                    temp = load(obj.filename, 'cacheMap', 'version');
                    obj.cacheMap = temp.cacheMap;
                    obj.version  = temp.version;
                else
                    % otherwise finish creating VCachedImages
                    obj.cacheMap = containers.Map('KeyType', 'char', 'ValueType', 'uint32');
                    obj.version  = Vanellus.VERSION;
                end
            end
        end

        function tf = checkFilename(obj)
            % In case current obj.filename is an existing folder, just add 'vanellusCache.mat'
            if isdir(obj.filename)
                obj.filename = [VTools.addToEndOfString(obj.filename, filesep) Vanellus.DEFAULT_CAC_FILENAME];
                tf = true;
                return;
            end
               
            % In case obj.filename indicates a 'vanellusCache.mat' file in an existing folder
            if VTools.endsWith(obj.filename, [filesep Vanellus.DEFAULT_CAC_FILENAME]) && isdir(VTools.getParentfolderpath(obj.filename))
                tf = true;
                return;
            end

            tf = false;
            warning(['VCachedImages -> folder of filename does not exist: ' obj.filename]);
        end
        
        function tf = createCacheMatFile(obj, silentMode)
            if nargin < 2, silentMode = false; end

            tf = false;

            if VTools.isFile(obj.filename)
                warning(['VCachedImages -> attempting to create new image cache file, but already exists: ' obj.filename]);
            end
            
            version = obj.version;
            cacheMap = obj.cacheMap; 
            save(obj.filename, '-v6', 'version', 'cacheMap');
            if ~silentMode, disp(['VCachedImages -> created image cache file:          ' obj.filename]); end
            
            tf = true; % 2DO: check whether anything went wrong
        end
        
        function tf = clearCacheMatFile(obj, silentMode)
            if nargin < 2, silentMode = false; end
            
            tf = false;
            
            if VTools.isFile(obj.filename)
                delete(obj.filename);
                obj.cacheMap = containers.Map('KeyType', 'char', 'ValueType', 'uint32');
                if ~silentMode, disp(['VCachedImages -> deleted image cache file:          ' obj.filename]); end
            end
            
            tf = true; % 2DO: check whether anything went wrong
        end
        
        %% cache %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = storeImageInCache(obj, frames, types, silentMode, im)
            tf = false;

            % input checking
            if nargin < 4, silentMode = false; end
            if nargin < 3 || isempty(types)
                warning(['VCachedImages.storeImageInCache : types is empty']);
                return; 
            end            
            if nargin < 2 || isempty(frames)
                warning(['VCachedImages.storeImageInCache : frames is empty']);
                return; 
            end 

            % convert types to typeIdxs
            if isprop(obj.parent, 'images')
                typeIdxs = obj.parent.images.getTypeIdx( types );
            else
                typeIdxs = obj.parent.parent.images.getTypeIdx( types );
            end
            
            % in case cacheMatFile has not been created, do that first
            if ~VTools.isFile(obj.filename)
                obj.createCacheMatFile();
            end
            
            % directly cache given image (probably called by autoCache)
            if nargin > 4 && ~isempty( im )
                frame                   = frames(1);
                typeIdx                 = typeIdxs(1);
                
                % update cacheMap
                cacheKey                = VCachedImages.getCacheKey(frame, typeIdx);
                obj.cacheMap(cacheKey)  = VTools.getUnixTimeStamp();

                % cache image
                eval([cacheKey ' = im;']);
                cacheMap                = obj.cacheMap; 
                save( obj.filename, '-append', cacheKey, 'cacheMap');
                if ~silentMode, disp(['VCachedImages -> cached image:                      ' cacheKey]); end

                tf = true;
                return;
            end

            % further input checking
            if isempty(obj.parent)
                warning(['VCachedImages.storeImageInCache : cannot access images, as obj.parent is empty']);
                return; 
            end
            
            % prepare blockSize
            img_cacheBlockSize                  = obj.parent.get('img_cacheBlockSize');
            
            % loop over types
            for i = 1:length(typeIdxs)

                typeIdx                         = typeIdxs(i);
                type                            = obj.parent.images.types{typeIdx};
                
                if ~silentMode, textprogressbar(['VCachedImages -> caching ' type ' images: ']); tic; end

                nrFullBlocks                    = floor( length(frames)/img_cacheBlockSize );
                for bl = 0:nrFullBlocks
                    
                    % determine frame idxs in this block
                    if bl < nrFullBlocks
                        frameIdxs               = [1:img_cacheBlockSize] + bl * img_cacheBlockSize;
                    else
                        frameIdxs               = [nrFullBlocks*img_cacheBlockSize+1:length(frames)];
                    end
                    if isempty(frameIdxs), continue; end
                    
                    % prepare saveExpression
                    saveExpression              = ['save( obj.filename, ''-append'', ''cacheMap'''];
            
                    % loop over frames
                    for j = 1:length(frameIdxs)
                        frame                   = frames( frameIdxs(j) );

                        % get image, and if real image (success) put in memory and update saveExpression
                        [im, success]           = obj.parent.getImage( frame, type);
                        
                        if ~isempty( im ) && success
                            cacheKey                = VCachedImages.getCacheKey(frame, typeIdx);
                            eval([cacheKey ' = im;']);
                            saveExpression          = [saveExpression ', ''' cacheKey ''''];

                            % update cacheMap
                            obj.cacheMap(cacheKey)  = VTools.getUnixTimeStamp();
                        end

                        if ~silentMode, textprogressbar( frameIdxs(j)/length(frames) ); end
                    end
                    
                    % finish saveExpression and perform actual storage
                    saveExpression              = [saveExpression ');'];
                    cacheMap                    = obj.cacheMap;
                    eval(saveExpression);
                end
                
                if ~silentMode, textprogressbar([' DONE in ' num2str(round(toc)) ' sec']); end
            end

            tf = true;
        end     
        
        function [tf, timestamp] = isImageInCache(obj, frame, typeIdx)
            cacheKey = VCachedImages.getCacheKey(frame, typeIdx);
            tf = obj.cacheMap.isKey(cacheKey);
            if tf && nargout == 2
                timestamp = obj.cacheMap(cacheKey);
            else
                timestamp = uint32(0); % return 1 Jan 1970
            end
        end
        
        function im = getImageFromCache(obj, frame, typeIdx)
            if nargin < 3 || isempty(frame) || isempty(typeIdx)
                im = uint16([]);
                return; 
            end
            
            if obj.isImageInCache(frame, typeIdx)
                cacheKey = VCachedImages.getCacheKey(frame, typeIdx);
                temp = load(obj.filename, cacheKey); % disp(['VCachedImages -> loaded ' cacheKey]);
                im = temp.(cacheKey);
                clear temp;
            else
                im = uint16([]);
                warning(['VCachedImages -> trying to get cached image that does not exist.']);
            end
        end
        
        function nrCachedImages = getNrCachedImages(obj)
            nrCachedImages = obj.cacheMap.length;
        end
        
        function sizeInMB = getCacheFileSize(obj)
            s = dir(obj.filename);
            if isempty(s)
                sizeInMB = 0;
            else
                sizeInMB = s.bytes / 1000000; % 1048576
            end
        end

        function cachedFrames = getCachedFrames(obj)
            cachedFrames    = [];

            keySet          = keys(obj.cacheMap);
            for i = 1:length(keySet)
                cachedFrames = [cachedFrames VCachedImages.getFrameTypeIdxfromCacheKey(keySet{i})];
            end
            
            cachedFrames    = uint16( unique(cachedFrames) );
        end
        
    end
    
    methods (Static)
        function cacheKey = getCacheKey(frame, typeIdx)
            cacheKey = ['cachedImage_f' num2str(frame) '_t' num2str(typeIdx)];
        end
        
        function [frame, typeIdx] = getFrameTypeIdxfromCacheKey(cacheKey)
            frameStrStart   = strfind(cacheKey, 'cachedImage_f') + length('cachedImage_f'); 
            typeStrStart    = strfind(cacheKey, '_t') + length('_t'); 

            frame           = uint16( str2double( cacheKey(frameStrStart:typeStrStart-3) ) );
            typeIdx         = uint16( str2double( cacheKey(typeStrStart:end) ) );
            
            if frame < 1,    frame   = []; end
            if typeIdx < 1,  typeIdx = []; end
        end
        
    end
end
