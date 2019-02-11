classdef VStabilization < VSettings %% C
% VStabilization Object that contains registration (alignment)
% information of VImages. (2-D rigid translation, no rotation)

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SUPER_SETTINGS  = { 'stb_class'                 , uint32(1), @VStabilization; ...
                                    'stb_imgRefType'            , uint32(1), { 'p' }; ...
                                    'stb_imgRefFrame'           , uint32(1), [ 1 ]; ...
                                    'stb_resolution'            , uint32(1), 1; ...
                                    'stb_sequential'            , uint32(1), false };
    end

    properties
        settings
        shift               % [row, col]
    end
    
    properties (Transient) % not stored
        images
        isSaved
    end
    
    properties (Dependent) % calculated on the fly
        parent
        frames
    end    
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VStabilization( images )
            obj.update( images );

            obj.settings            = {};
            obj.shift               = zeros([length(obj.images.frames) 2]);
        end

        %% dependencies %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function parent = get.parent(obj)
            parent = obj.images;
        end  
        
        function frames = get.frames(obj)
            if isempty( obj.get('img_frames') )
                frames  = obj.images.frames;
            else
                frames  = intersect( uint16( obj.get('img_frames') ) , obj.images.frames );
            end
        end        
        
        %% stabilization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function shift = calcStabilization(obj)
            % prepare frames to be stabilized
            framesToStabilize   = obj.frames;
            shift = [0 0];
            
            % check ref image and set its shift to [0 0]
            refFrame            = obj.get('stb_imgRefFrame');
            refType             = obj.get('stb_imgRefType');
            [refFrame, refType] = obj.images.getRefToFirstImage(refFrame, refType );
            if isempty(refFrame) || isempty(refType)
                disp(['VStabilization -> not stabilizing, while there is no valid stb_imgRefFrame or stb_imgRefType set (images are probably not set yet).']);
                return;
            end

            % loop over frames and stabilize
            textprogressbar('VStabilization -> setting stabilization of images to [0 0]: '); tic;
            for i = length(framesToStabilize)
                fr = framesToStabilize(i);
                shift(fr, :) = [0 0];
                textprogressbar( i/length(framesToStabilize) );
            end
            textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);
        end
        
        %% plotting %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function offsetPlot = getOffsetPlot(obj, outputType)
        % return an offset plot, as figure handle or as color image (outputType = 'im')
            if nargin < 2, outputType = 'fig'; end

            offsetPlot = figure( 'Position', [100 100 800 600], 'visible','off');
            ylim([-150 150]); xlim([0 max(obj.frames)]);
            line(obj.frames,obj.shift(:,2),'Color','b','LineStyle','none','Marker','.','MarkerSize',10);
            line(obj.frames,obj.shift(:,1),'Color','r','LineStyle','none','Marker','.','MarkerSize',10);
            title(''); xlabel('frame'); ylabel('offset in pixels');
            legend('column offset','row offset');
            
            if strcmp(outputType, 'im')
                [im, ~] = frame2im( getframe(offsetPlot) );
                close(offsetPlot);
                pause(0.1);
                offsetPlot = im;
            else
                set(offsetPlot, 'visible','on');
            end
        end
        
    end
     
    methods (Sealed)
        
        %% updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function update(obj, images)
            obj.images          = images;
            obj.isSaved         = true;
        end        
        
        %% stabilization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = stabilize(obj, frames)
            tf = false;
            
            % in case desired, update local frames
            if nargin > 1, 
                obj.set('img_frames', frames);
            end
            
            % calculation
            shift = obj.calcStabilization();
             
            % add [0 0] shift for missing frames
            if size(shift,1) < size(obj.images.frames,1)
                shift(end+1:size(obj.images.frames,1),:) = repmat([0 0], [size(obj.images.frames,1)-size(shift,1) 1]);
            end
            
            % convert to double
            shift = double( shift );
            
            % check whether something changed
            if isequal( shift, obj.shift), return; end

            % set new shift
            obj.shift       = shift;
            obj.isSaved     = false;
            tf              = true;
        end
    end
    
end

