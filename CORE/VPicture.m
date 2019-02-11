classdef VPicture < VSettings %% C
% VPicture Object that can return or save a rgb picture

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SUPER_SETTINGS  = { 'pic_imageType'         , uint32(1), 'p' ; ...
                                    'pic_imageFrame'        , uint32(1), 1 ; ...
                                    'pic_rescale'           , uint32(1), 1 ; ...
                                    'pic_autoContrast'      , uint32(1), true ; ...
                                    'pic_contrast'          , uint32(1), [] ; ...
                                    'pic_color'             , uint32(1), [1 1 1] ; ...
                                    'pic_colorMap'          , uint32(1), 'none' ; ...
                                    'pic_backgroundColor'   , uint32(1), [0 0 0] };
    end
    
    properties
        settings
    end    
    
    properties (Transient) % not stored
%         filename
        parent
        isSaved
    end

    properties (Dependent) % calculated on the fly
%         parent
        frames
    end    
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VPicture( parent )
            obj.settings            = {};
            
            obj.update( parent );
        end

        function update(obj, parent)
            obj.parent              = parent;
            obj.isSaved             = true;
        end        
        
        %% dependencies %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function frames = get.frames(obj)
            if isempty( obj.get('img_frames') )
                frames  = obj.parent.frames;
            else
                frames  = intersect( uint16( obj.get('img_frames') ) , obj.parent.frames );
            end
        end        
        
        %% picture creation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rgb = getRGB(obj, frame, type)
            % make sure frame and type are correct
            if nargin < 2, frame = []; end
            if nargin < 3, type  = ''; end

            if isempty(frame), frame = obj.get('pic_imageFrame'); end
            if isempty(type), type = obj.get('pic_imageType'); end
                 
            if isempty(frame) || isempty(type) || length(type)>1 || length(frame)>1
                [frame, type] = obj.parent.images.getRefToFirstImage(frame, type);
            end            
            
            % check whether image exists
            typeIdx = obj.parent.images.getTypeIdx( type );
            if ~obj.parent.images.imageExist(frame, typeIdx)
                warning(['VPosition -> trying to load non-existing image: fr' num2str(frame) ' ' num2str(type) ]);
                rgb = eye(100);
                rgb = rgb(:,:,[1 1 1]);
                return;
            end
            
            % load image
            TIFFData = obj.parent.getImage( frame, type );
            im = double(TIFFData) / double(max(TIFFData(:)));
            
            % resize
            pic_rescale = obj.get('pic_rescale');
            if ~isempty(pic_rescale) && pic_rescale ~= 1 && pic_rescale > 0
                im = imresize(im, pic_rescale, 'bilinear');
            end
            
            % determine contrast
            if obj.get('pic_autoContrast') % autocontrast
                contrast = stretchlim( im );
            elseif isequal(size(obj.get('pic_contrast')), [1 2])  % fixed contrast
                contrast = double( obj.get('pic_contrast') );
            else % full contrast
                contrast = double([min(min(TIFFData(:))) max(max(TIFFData(:)))]);
            end
        
            % set contrast
            im = VPicture.scaleRange( im, contrast, [0 1]);

            % convert to rgb -> no colormap
            colorMapName = obj.get('pic_colorMap');
            
            if strcmp(colorMapName, 'none') || ~VPicture.colorMapExists(colorMapName)
                im = repmat(im, [1 1 3]);
                im = im .* repmat(reshape(obj.get('pic_color') - obj.get('pic_backgroundColor'), [1 1 3]), [size(im,1) size(im,2) 1]);
                rgb = repmat(reshape(obj.get('pic_backgroundColor'), [1 1 3]), [size(im,1) size(im,2) 1]);
                rgb = rgb + im;

            % convert to rgb -> colormap
            else
                number_of_colors = 250;
                eval(['myColorMap = ' colorMapName '(number_of_colors);']);
                imColorMap = round( VPicture.scaleRange( im, [0 1], [1 number_of_colors]) );
                rgb = ind2rgb(imColorMap, myColorMap);
            end            
            
        	rgb = obj.addLabelToRGB(rgb, frame);
        	rgb = obj.addVanellusStampToRGB(rgb);
        end
        
        function rgb = addLabelToRGB(obj, rgb, frame)
            % stamp settings
            text            = [VTools.str(frame) ' - ' obj.getFrameLabel(frame)]; % 2DO: add timestamp
            position        = [1 1]; 
            font            = 'Andale Mono';
            fontSize        = 12;
            textColor       = [1 1 1];
            boxColor        = [0 0 0];
            boxOpacity      = 1;

            % reduce label if it is to wide
            max_length      = floor( size(rgb,1) / (fontSize * 1.25 * 0.5) );
            if length(text) > max_length
                text        = text(1:max_length);
            end

            % add label
            rgb             = insertText(rgb, position, text, ...
                                         'Font', font, ...
                                         'FontSize', fontSize, ...
                                         'TextColor', textColor, ...
                                         'BoxColor', boxColor, ...
                                         'BoxOpacity', boxOpacity, ...
                                         'AnchorPoint', 'LeftTop' );
        end        

        function rgb = addVanellusStampToRGB(obj, rgb)
            % add Vanellus stamp
            position        = [5 size(rgb,1)-5];
            text            = 'Vanellus';
            font            = 'Andale Mono';
            fontSize        = 12;
            textColor       = [0.5 0.5 0.5];
            boxOpacity      = 0;
            
            rgb             = insertText(rgb, position, text, ...
                                         'Font', font, ...
                                         'FontSize', fontSize, ...
                                         'TextColor', textColor, ...
                                         'BoxOpacity', boxOpacity, ...
                                         'AnchorPoint', 'LeftBottom' );
        end        
        
        function frameLabel = getFrameLabel(obj, frame)
            frameLabel = '';
            if nargin < 2, return; end
            if isempty(frame), return; end

            mov_label = obj.get('mov_label');
            for i = 1:size(mov_label,1)
                if find(mov_label{i,1} == frame)
                    frameLabel = mov_label{i,2};
                    break;
                end
            end
        end        
    end
    
    methods(Static)
        function out = scaleRange(in, r1, r2) % Copied from DJK_scaleRange
            % correct for error, when source range is not a range but a point
            if r1(1) == r1(2), r1 = r1 + [-1 1]; end

            scale_factor = (r2(2) - r2(1)) / (r1(2) - r1(1)) ;
            shift_factor = ( r2(1)*r1(2) - r2(2)*r1(1) ) / (r1(2) - r1(1));

            out = in * scale_factor + shift_factor;
            out(find(out>r2(2))) = r2(2);
            out(find(out<r2(1))) = r2(1);        
        end
                        
        function tf = colorMapExists(colorMapName)
            % 2DO: test that coloMapName exists 
            tf = true;
        end        
    end
end