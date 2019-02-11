classdef VStabilizationExample < VStabilization
% VStabilizationExample Object that calculates stabilization (alignment)
% information of VImages. 
%
% VStabilizationExample is an example implementation that does not analyze
% images, but arbritarily adds an increasing shift (set by the setting
% 'stb_fixedShift') to subsequent images.

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        % HERE YOU DEFINE DEFAULT SETTINGS. THESE CAN BE OVERRULED BY USER SETTINGS
        DEFAULT_SETTINGS  = { 'stb_class'                 , uint32(1), @VStabilizationExample ; ...
                              'stb_fixedShift'            , uint32(1), [0.1 0.1] };
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VStabilizationExample(images)
            % DO NOT EDIT ANYTHING HERE
            obj@VStabilization(images); 
        end

        %% stabilization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function shift = calcStabilization(obj)
            % THIS IS THE ONLY FUNCTION YOU NEED TO IMPLEMENT
            %
            % * YOU GET ACCESS TO SETTINGS AND IMAGES THROUGH "obj", eg:
            %   - setting_fixedShift  = obj.get('stb_fixedShift');
            %   - im = obj.images.readImage( 10, 'p');
            %
            % * THE FUNCTION SHOULD RETURN AN DOUBLE ARRAY SHIFT THAT
            %   CONTAINS THE SHIFT FOR ALL FRAMES, eg:
            %   - shift(1,:) = [ 0    0  ]; % -> frame 1 is the reference frame, so no shift
            %   - shift(2,:) = [-0.3  0.5]; % -> frame 2 has a row offset of -0.3 pixels, and a col offset of 0.5 pixels
            %   - shift(7,:) = [10   12.1]; % -> frame 7 has a row offset of 10 pixels, and a col offset of 12.1 pixels
            
            % get the frames to be analyzed, and remove the first frame
            framesToStabilize   = obj.frames;
            framesToStabilize( framesToStabilize==1 ) = [];
            
            % set the shift of the first frame to [0 0]
            shift = [0 0];
            
            % get the fixedShift setting
            setting_fixedShift  = obj.get('stb_fixedShift');
            
            % loop over the remaining frames and set the increasing shift
            for i = 1:length(framesToStabilize)
                fr = framesToStabilize(i);
                
                shift( fr, :) = i * setting_fixedShift; 
            
                % in case you want to use the actual image for stabilization, you can obtain it like this: 
                % im = obj.images.readImage( frame, type); % frame as nr and type as 'p' or 'y'
            end
        end            
    end
end