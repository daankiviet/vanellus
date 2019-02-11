classdef VTrackingsRandom < VTrackings
% VTrackingsRandom Object that calculates tracking between segmentation
% images.
%
% VTrackingsRandom is an example implementation that does not really track
% segmentations, but randomly links cells. 

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        % HERE YOU DEFINE DEFAULT SETTINGS. THESE CAN BE OVERRULED BY USER SETTINGS
        DEFAULT_SETTINGS =    { 'trk_class'             , uint32(1), @VTrackingsRandom ; ...
                                'trk_allowCellDivision' , uint32(1), false };
    end

    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VTrackingsRandom( region )
            % DO NOT EDIT ANYTHING HERE
            obj@VTrackings( region ); 
        end
    
        %% tracking %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = calcData(obj, idf)
            % THIS IS THE ONLY FUNCTION YOU NEED TO IMPLEMENT
            %
            % * YOU GET ACCESS TO SETTINGS AND SEGMENTATIONS THROUGH "obj", eg:
            %   - trk_allowCellDivision  = obj.get('trk_allowCellDivision');
            %   - seg1 = obj.region.getSeg( idf(1) );
            %   - seg2 = obj.region.getSeg( idf(2) );
            %
            % * THE FUNCTION SHOULD RETURN AN DOUBLE ARRAY SHIFT THAT
            %   CONTAINS THE SHIFT FOR ALL FRAMES, eg:
            %   - shift(1,:) = [ 0    0  ]; % -> frame 1 is the reference frame, so no shift
            %   - shift(2,:) = [-0.3  0.5]; % -> frame 2 has a row offset of -0.3 pixels, and a col offset of 0.5 pixels
            %   - shift(7,:) = [10   12.1]; % -> frame 7 has a row offset of 10 pixels, and a col offset of 12.1 pixels

            % actual calculation of tracking
            data = uint16( [] );
            
            % make sure that idf can be tracked
            if ~obj.canDataBeCalculated(idf), return; end
            
			% get cell numbers
            seg1 = obj.region.getSeg( idf(1) );
            seg2 = obj.region.getSeg( idf(2) );
  			segNrs1 = unique(seg1);
  			segNrs1 = segNrs1(segNrs1~=0);
  			segNrs2 = unique(seg2);
  			segNrs2 = segNrs2(segNrs2~=0);
            
            % link each cell to a random other cell
            segNrs1_random = segNrs1( randperm( numel(segNrs1) ) );
            segNrs2_random = segNrs2( randperm( numel(segNrs2) ) );
            segNrs2_random(end+1:numel(segNrs1_random)) = 0;
            segNrs1_random(end+1:numel(segNrs2_random)) = 0;
            data(:,1) = segNrs1_random;
            data(:,2) = segNrs2_random;
            
            % store as uint16
            data = uint16(data);
            
            % make sure that output is correct
            data = obj.correctData(data, segNrs1, segNrs2);            
        end
    end
        
end
