classdef VSegmentationsThreshold < VSegmentations
% VSegmentationsThreshold

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SETTINGS =  {   'seg_imgThreshold'          , uint32(1), 0.5 ; ...
                                'seg_useOtsuThreshold'      , uint32(1), true; ...
                                'seg_imgType'               , uint32(1), {'p'} ; ...
                                'seg_sigma'                 , uint32(1), 3; ...
                                'seg_medFilt'               , uint32(1), 3 };
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VSegmentationsThreshold( region )
            obj@VSegmentations( region ); 
        end
        
        %% segmentation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = calcData(obj, idf)
            % actual calculation of segmentation
            data = uint16( zeros( obj.region.regionSize ) );
            
            % make sure that idf can be segmented
            if ~obj.canDataBeCalculated(idf), return; end
            
            % get image
            im      = obj.getSegImage( idf(1) );

            % get mask
            mask = obj.region.getMask( idf(1) );
            
            % get threshold
            if obj.get('seg_useOtsuThreshold')
                % sets the threshold for given frame to one obtained using
                % graythresh within mask (Global image threshold using Otsu's method)
                threshold = graythresh( im(mask) );
            else
                threshold = obj.get('seg_imgThreshold');
            end

            % perform threshold
            BW = ~im2bw(im, threshold);
            BW( ~mask ) = 0;
            
            data = uint16( BW );            
        end

        function im = getSegImage(obj, frame)
            type    = obj.get('seg_imgType');
            medFilt = obj.get('seg_medFilt');

            im      = obj.region.getImage(frame, type);
            im      = medfilt2(im, [medFilt medFilt]);
        end
        
        function imEdge = getSegEdge(obj, frame)
            sigma   = obj.get('seg_sigma');
            
            im      = obj.getSegImage(frame);
            imEdge  = edge(im, 'log', 0, sigma);
        end
        
    end
end