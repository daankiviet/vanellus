classdef VImages < VSettings %% C
% VImages Object that contains all information of images of
% position on harddisk 
%
% VImages are stored inside VPosition, and link back to current position is
% stored as a Transient propertiy. Within a VImages there is saved:  
% - frames
% - types
% - imageTime
% - imageExist
% - typesSize
% - typesThumbnail
% - stabilization

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

properties (Constant)
        DEFAULT_SUPER_SETTINGS  = { 'img_typeOrder'             , uint32(1), {'p' 'g' 'r'} ; ...
                                    'img_resolution'            , uint32(1), 0.04'' ; ...
                                    'img_frameOffset'           , uint32(1), 0 ; ...
                                    'img_timestamp1stframe'     , uint32(1), 0 ; ...
                                    'img_timeBetweenFrames'     , uint32(1), 4*60 };
    end
    
    properties
        settings % cell array { 'prop', uint32(timestamp), val ; ... next }

        frames
        types
        
        imageTime       % double (frames, types)
        imageExist      % logical (frames, types)
        
        typesSize       % { [height width] } for each image_type
%         typesThumbnail  % { uint8 image } for each image_type
        
        stabilization
    end
    
    properties (Transient) % not stored
        position
        isSaved
    end    
    
    properties (Dependent) % calculated on the fly
        parent
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VImages(position)
            obj.position        = position;
            obj.isSaved         = true;
            obj.settings        = {};

            obj.frames          = uint16( [] );
            obj.types           = [];
            
            obj.imageTime       = double( zeros([0 1]) );
            obj.imageExist      = false( [0 1] );
            obj.typesSize       = {};
%             obj.typesThumbnail  = {};
            
            stabilizationType   = obj.position.get('stb_class');
            obj.stabilization   = stabilizationType( obj );
        end
        
        function tf = update(obj, position)
            tf = false;
            
            if nargin > 1, obj.position = position; end
            
            % deterime existing frames from imageExist -> update image_frames
            fr_idx = sum(obj.imageExist,2); % old: fr_idx = reshape( sum(sum(obj.imageExist,1),2), [1 size(obj.imageExist,3)]); %DJK2016-04-18 fr_idx = sum(obj.imageExist,2)'; 
            obj.frames = uint16( find(fr_idx) ); 
            
            % update typesSize
            for i = 1:length(obj.types)
                obj.typesSize{i} = [0 0];

                % find first image of this type
                [frame, type] = obj.getRefToFirstImage([], obj.types{i});
                if frame
                    im = obj.readImage( frame, type );
                    obj.typesSize{i} = size(im);
                end
            end             
            
            % reset stabilization
            stabilizationStorageType = obj.position.get('stb_class');
            obj.stabilization = stabilizationStorageType( obj );
            
            tf = true;
        end
        
        
        %% dependencies %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function parent = get.parent(obj)
            parent = obj.position;
        end  
        
        
        %% images %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [im, success] = readImage(obj, frame, type)
            % returns checkboard image
            
            success = false;
            
            % input checking
            if nargin < 2, frame    = []; end
            if nargin < 3, type     = ''; end
            
            % image file cannot be accessed -> return image of original size
            if obj.isImage( frame, type)
                outputSize = obj.typesSize{ obj.getTypeIdx(type) };

            % image was not initialized -> return image of size [100 100]
            else
                outputSize = [100 100];
            end
            
            % return checkerboard of outputSize
            N = 40;
            P = ceil( outputSize(1) / (2*N));
            Q = ceil( outputSize(2) / (2*N));
            im = (checkerboard(N,P,Q) > 0.5);
            im = im(1:outputSize(1),1:outputSize(2));
            im = uint16( double(intmax('uint16')) * im );
        end

        function tf = isImage(obj, frame, type )
            tf = false;

            % return false if not enough arguments
            if nargin < 3, return; end

            % convert types to typesIdx
            typeIdx = obj.getTypeIdx( type );
 
            % check whether frame and type are not empty
            if isempty( typeIdx ) || isempty( typeIdx ), return; end
            
            % return false if image is outside size obj.imageExist
            if frame > size(obj.imageExist,1) || typeIdx > size(obj.imageExist,2), return; end
            
            tf = obj.imageExist( frame, typeIdx );
        end
        
        function typeIdx = getTypeIdx(obj, type )
            typeIdx = uint16([]); 

            % in case type is string, convert to cell
            if ischar(type), type = { type }; end

            % check type is char
            if ~iscellstr( type ), return; end
            
            % check whether obj.types is empty
            if ~size(obj.types,2), return; end

            typeIdx = uint16( find( ismember( obj.types(1,:), type) ) );
        end
        
        function [frame, type] = getRefToFirstImage(obj, frames, types )
            % finds first image of this f/t, use all if nothing provided
            if nargin < 2, frames = []; end
            if nargin < 3, types  = ''; end
            
            % make sure that frames is vertical
            frames = reshape(frames, [numel(frames) 1]);
            
            % convert types to typesIdx
            typesIdx = obj.getTypeIdx( types );
            
            % if something is not set, use all
            if isempty(frames),     frames      = obj.frames; end
            if isempty(typesIdx),   typesIdx    = obj.getTypeIdx( obj.types ); end
            
            % make sure that nothing is outside of obj.imageExist
            frames      = intersect( frames, obj.frames);
            typesIdx    = intersect( typesIdx, [1:length(obj.types)]);
            
            % remove all non-selected frames and types
            imageOverview                                           = obj.imageExist;
            imageOverview( setdiff(1:length(obj.frames),frames), :) = false;
            imageOverview(:, setdiff(1:length(obj.types),typesIdx)) = false;

            % find valid images, first one will be in first type
            [frame, typeIdx] = find( imageOverview );
            
            % make sure to return only 1, and type instead of typeIdx
            if ~isempty(frame), frame = frame(1); end
            if ~isempty(typeIdx)
                type = obj.types{typeIdx(1)}; 
            else
                type = '';
            end
        end
        
        function [frames, types] = getExistingImages(obj, frames, types )
            % finds existing images of this f/t, use all if nothing provided
            if nargin < 2, frames = []; end
            if nargin < 3, types  = ''; end
            
            % make sure that frames is vertical
            frames = reshape(frames, [numel(frames) 1]);
            
            % convert types to typesIdx
            typesIdx = obj.getTypeIdx( types );
            
            % if something is not set, use all
            if isempty(frames),     frames      = obj.frames; end
            if isempty(typesIdx),   typesIdx    = obj.getTypeIdx( obj.types ); end
            
            % make sure that nothing is outside of obj.imageExist
            frames      = intersect( frames, obj.frames);
            typesIdx    = intersect( typesIdx, [1:length(obj.types)]);
            
            % remove all non-selected frames and types
            imageOverview                                           = obj.imageExist;
            imageOverview( setdiff(1:length(obj.frames),frames), :) = false;
            imageOverview(:, setdiff(1:length(obj.types),typesIdx)) = false;

            % find valid images, first one will be in first type
            [frames, typesIdx] = find( imageOverview );
        end
        
        function timestamp = getImageTimestamp(obj, frame, type)
            img_timestamp1stframe = obj.get('img_timestamp1stframe');
            img_timeBetweenFrames = obj.get('img_timeBetweenFrames');
            timestamp = double(img_timestamp1stframe + (uint32(frame)-1)*img_timeBetweenFrames );
        end

        
        %% rect %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rect = checkRect(obj, rect)
            % make sure rect ([left top width height]) is ok, if rect not given than max rect is returned
            
            % if images are not do alternative
            if isempty(obj.typesSize)
                if nargin < 2
                    warning(['VImages.checkRect() -> images are not set (yet), so setting rect to [1 1 100 100]']);
                    rect = [1 1 100 100];
                else
                    warning(['VImages.checkRect() -> images are not set (yet), so not checking rect']);
                end
                return;
            end
                
            % if rect not given, use max rect
            if nargin < 2
                rect = [1 1 obj.typesSize{1}(2) obj.typesSize{1}(1)];
            end
            
            % check rect
            rect = round(rect);
            if length(rect)<4, rect = [1 1 obj.typesSize{1}(2) obj.typesSize{1}(1)]; end
            if rect(1) < 1 || rect(1) > obj.typesSize{1}(2), rect(1) = 1; end
            if rect(2) < 1 || rect(2) > obj.typesSize{1}(1), rect(2) = 1; end
            if rect(3) < 1 || rect(1) + rect(3) - 1 > obj.typesSize{1}(2), rect(3) = obj.typesSize{1}(2) - rect(1) + 1; end
            if rect(4) < 1 || rect(2) + rect(4) - 1 > obj.typesSize{1}(1), rect(4) = obj.typesSize{1}(1) - rect(2) + 1; end
        end        
        
        
        %% stabilization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function stabilize(obj, position)
            if nargin > 1, obj.position = position; end

            stabilizationStorageType = obj.position.get('stb_class');
            obj.stabilization = stabilizationStorageType( obj );
            obj.stabilization.stabilize();
        end
        
        function rect = calcStabileFrame(obj, type) % rect = [top left height width]
        % Calculates what max rectangle is that is always present in stabilized images
            if nargin < 2, type = 1; end
            if ischar(type), type = find(strcmp(obj.types, type)); end

            MAX_CUTOF = 128; % if there is a lot of movement, this value restricts the amount that is cut of (adds black side)

            offset_col = obj.stabilization.shift(:,2);
            offset_row = obj.stabilization.shift(:,1);
            im_size = obj.imageSize{type};

            offset_col_min = min(offset_col(offset_col>-MAX_CUTOF));
            offset_col_max = max(offset_col(offset_col< MAX_CUTOF));
            offset_row_min = min(offset_row(offset_row>-MAX_CUTOF));
            offset_row_max = max(offset_row(offset_row< MAX_CUTOF));

            left    = max(1,ceil(abs(offset_col_max)));
            top     = max(1,ceil(abs(offset_row_max)));
            right   = im_size(2) - ceil(abs(offset_col_min));
            bottom  = im_size(1) - ceil(abs(offset_row_min));
            width   = right - left + 1;
            height  = bottom - top + 1;

            rect    = [top left height width];
            rect(3:4) = VTools.makeEven(rect(3:4));
            rect    = min(rect,[im_size(1) im_size(2) im_size(1) im_size(2)]);            
        end
        
    end
    
    methods (Static)
        function im = cropImage(im, rect)
            % if rect not given or empty, return uncropped image
            if nargin < 2 || isempty(rect), return; end
                
            % in case part of the cropping will be outside of current image, increase image size with 0 values
            if size(im,1) < rect(2)+rect(4)-1 || size(im,2) < rect(1)+rect(3)-1
                temp = im;
                im = cast(zeros([rect(2)+rect(4)-1 rect(1)+rect(3)-1]), class(temp));
                im(1:size(temp,1),1:size(temp,2)) = temp;
                
                warning off backtrace;
                warning(['VImage.cropImage() -> rect (' num2str(rect) ') is outside of image (' num2str(size(im)) '). Filling with zeros.']);
                warning on backtrace;
            end

            % crop (imcrop uses rect = [XMIN YMIN WIDTH HEIGHT], Region uses rect = [l t w h])
            im = imcrop(im, uint16(rect) - uint16([0 0 1 1])); % subtract 1 cause imcrop uses pixel centers
       end 
    end        
end
