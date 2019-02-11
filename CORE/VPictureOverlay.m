classdef VPictureOverlay < VPicture %% C
% VPictureOverlay 

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07
    
    properties (Constant)
        DEFAULT_SETTINGS =  {   'pic_imageType'         , uint32(1), {'g' 'r'} };                            
    end

    properties (Transient) % not stored
        pic1
        pic2
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VPictureOverlay( pic1, pic2 )
            if nargin < 2
                warning(['VPictureOverlay: requires 2 VPictures']);
            end
            obj@VPicture(pic2.parent); 
            obj.pic1 = pic1;
            obj.pic2 = pic2;
        end
        
        %% picture creation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rgb = getRGB(obj, frame, type)
            type1 = type;
            type2 = type;
            
            if obj.pic1.isSet('pic_imageType'), type1 = obj.pic1.get('pic_imageType'); end
            if obj.pic2.isSet('pic_imageType'), type2 = obj.pic2.get('pic_imageType'); end

            rgb1 = obj.pic1.getRGB(frame, type1);
            rgb2 = obj.pic2.getRGB(frame, type2);

            rgb = obj.blendImages_Test(rgb1, rgb2);
        end
    end
    
    methods(Static)
        function rgb = blendImages_Test( rgb1, rgb2)
            rgb = 0.5 * (rgb1 + rgb2);
        end
    end
end