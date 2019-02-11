classdef VStabilizationDFT < VStabilization %% C
% VStabilizationDFT

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SETTINGS  = { 'stb_class'                 , uint32(1), @VStabilizationDFT };
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VStabilizationDFT(images)
            obj@VStabilization(images); 
        end

        %% stabilization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function shift = calcStabilization(obj)
            framesToStabilize   = obj.frames;
            shift = [0 0];

            % check ref image and set its shift to [0 0]
            refFrame            = obj.get('stb_imgRefFrame');
            refType             = obj.get('stb_imgRefType');
            [refFrame, refType] = obj.images.getRefToFirstImage(refFrame, refType );
            if isempty(refFrame) || isempty(refType)
                disp(['VStabilizationDFT -> not stabilizing, while there is no valid stb_imgRefFrame or stb_imgRefType set (images are probably not set yet).']);
                return;
            end
            
            % in case of sequential: start with first and make sure that refFrame is included 
            if obj.get('stb_sequential')
                framesToStabilize = union(framesToStabilize, refFrame); 
                refFrame = framesToStabilize(1);
            end
            
            % obtain reference image
            im_ref = obj.images.readImage( refFrame, refType );
            
            % loop over frames and stabilize
            textprogressbar('VStabilizationDFT -> stabilizing images: '); tic;
            for i = 1:length(framesToStabilize)
                fr = framesToStabilize(i);
                
                im = obj.images.readImage( fr, refType );
                shift( fr, :) = obj.registrerDFT_subpixel(im_ref, im, obj.get('stb_resolution')); 
                
                % reference image changes when done sequentially
                if obj.get('stb_sequential')
                    im_ref = im;
                end
                
                textprogressbar( i/length(framesToStabilize) );
            end
            
            % do sequential correction
            if obj.get('stb_sequential')
                shift = shift - shift( obj.get('stb_imgRefFrame'), :);
            end
            
            textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);
        end            
        
    end
    
    methods (Static)
        function shift = registrerDFT_subpixel(im_ref, im, resolution)
        % Uses dftregistration function written by Manuel Guizar-Sicairos.
            if nargin < 3, resolution = 1; end
            output = dftregistration( fft2(im_ref), fft2(im), round(1/resolution));
            shift = [output(3), output(4)];
        end
    end
end
