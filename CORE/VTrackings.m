classdef VTrackings < VSettings & VData %% C
% VTrackings Object that contains the trackings of a VRegion. 

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SUPER_SETTINGS =  { 'trk_class'                 , uint32(1), @VTrackings ; ...
                                    'trk_XX'                    , uint32(1), 0 };
    end
    
    properties
        settings
    end

    properties (Transient) % not stored
        region
        isSaved
        
        frameTracks
    end
    
    properties (Dependent) % calculated on the fly
        parent
        frames
    end    
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VTrackings( region )
            obj.settings            = {};
            
            obj.update(region);
        end
       
        function update(obj, region)
            obj.region              = region;            
            obj.frameTracks         = {};
        end

        
        %% dependencies %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function parent = get.parent(obj)
            parent = obj.region;
        end         
        
        function frames = get.frames(obj)
            if isempty( obj.get('img_frames') )
                frames  = obj.parent.frames;
            else
                frames  = intersect( uint16( obj.get('img_frames') ) , obj.parent.frames );
            end
        end

        
        %% data calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = calcData(obj, idf)
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
            
            % link each cell to nothing
            data = uint16( zeros( length(segNrs1) + length(segNrs2), 2) );
            data(1:length(segNrs1), 1) = segNrs1;
            data(length(segNrs1)+1:length(segNrs1)+length(segNrs2), 2) = segNrs2;
            
            % make sure that output is correct
            data = obj.correctData(data, segNrs1, segNrs2);
        end
        
    end
    
    methods (Sealed)
        %% data calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = canDataBeCalculated(obj, idf)
            tf = false;

            % make sure that idf is horizontal
            idf = reshape(idf, [1 numel(idf)]);            
            
            % check whether idf is valid frame number
            idf = uint16( idf );
            if length(idf) < 2, return; end
            if ~all(ismember(idf, obj.frames)), return; end
%             if ~find( obj.frames == idf(1) ), return; end
%             if ~find( obj.frames == idf(2) ), return; end
            
            % check whether there is an image to segment exists for this frame
            imageType = obj.get('seg_imgType');
            if ~obj.region.position.images.isImage( idf(1), imageType) || ~obj.region.position.images.isImage( idf(1), imageType)
                warning(['VTrackings -> 1 or more trackings missing, so cannot track.']);
            end
            
            tf = true;
        end

        function tf = doesDataNeedUpdating(obj, idf)
            seg1_lastChange  = obj.region.segmentations.getLastChange( idf(1) );
            seg2_lastChange  = obj.region.segmentations.getLastChange( idf(2) );
            tf = doesDataNeedUpdating@VData(obj, idf, max([seg1_lastChange seg2_lastChange]) );
        end        
        
        function track = getTrack(obj, frame1, frame2)
            track = obj.getData( uint16( [frame1 frame2] ) );
        end        
        
        %% editing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = editByUnlinkingCell(obj, coor1, coor2, frame1, frame2)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            tf = false;

            seg1 = obj.region.getSeg( frame1 );
            seg2 = obj.region.getSeg( frame2 );
            
            segNr1 = 0; segNr2 = 0;
            if ~isempty(coor1)
                segNr1 = seg1( round(coor1(1)), round(coor1(2)) );
                % disp(['Clicked on segNr1 : ' num2str(segNr1)]);
            end            
            if ~isempty(coor2)
                segNr2 = seg2( round(coor2(1)), round(coor2(2)) );
                % disp(['Clicked on segNr2 : ' num2str(segNr2)]);
            end            
            
            if segNr1 > 0 || segNr2 > 0
                
                track   = obj.getData( uint16([frame1 frame2]) );
            
                if segNr1 > 0
                    idx_segNr1 = find( track(:,1) == segNr1 );
                    track(idx_segNr1,2) = 0;
                end

                if segNr2 > 0
                    idx_segNr2 = find( track(:,2) == segNr2 );
                    track(idx_segNr2,1) = 0;
                end

                % make sure that track is correct
                segNrs1 = unique(seg1);
                segNrs1 = segNrs1(segNrs1~=0);
                segNrs2 = unique(seg2);
                segNrs2 = segNrs2(segNrs2~=0);
                track = obj.correctData(track, segNrs1, segNrs2);
                
                % store
                obj.setData(uint16([frame1 frame2]), track);
                tf = true;
                
                % update local frameTracks
                frameIdx = find(obj.frames == frame1);
                obj.frameTracks{frameIdx(1)} = track;
            end                
        end
        
        function tf = editBylinkingCells(obj, coor1, coor2, frame1, frame2)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            tf = false;

            if ~isempty(coor1) & ~isempty(coor2)
                track   = obj.getData( uint16([frame1 frame2]) );
            
                seg1 = obj.region.getSeg( frame1 );
                segNr1 = seg1( round(coor1(1)), round(coor1(2)) );
                % disp(['Clicked on segNr1 : ' num2str(segNr1)]);

                seg2 = obj.region.getSeg( frame2 );
                segNr2 = seg2( round(coor2(1)), round(coor2(2)) );
                % disp(['Clicked on segNr2 : ' num2str(segNr2)]);
                
                if segNr2 > 0
                    idx_segNr2 = find( track(:,2) == segNr2 );
                    if ~isempty( idx_segNr2 )
                        track(idx_segNr2,1) = segNr1;
                    else
                        track(end+1,:) = [segNr1 segNr2];
                    end
                else
                    if segNr1 > 0
                        idx_segNr1 = find( track(:,1) == segNr1 );
                        if ~isempty( idx_segNr1 )
                            track(idx_segNr1,2) = segNr2;
                        else
                            track(end+1,:) = [segNr1 segNr2];
                        end
                    end
                end
                
                % make sure that track is correct
                segNrs1 = unique(seg1);
                segNrs1 = segNrs1(segNrs1~=0);
                segNrs2 = unique(seg2);
                segNrs2 = segNrs2(segNrs2~=0);
                track = obj.correctData(track, segNrs1, segNrs2);
                
                % store
                obj.setData(uint16([frame1 frame2]), track);
                tf = true;
                
                % update local frameTracks
                frameIdx = find(obj.frames == frame1);
                obj.frameTracks{frameIdx(1)} = track;
            end                
        end

        %% correcting Data %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = correctData(obj, data, segNrs1, segNrs2)
            % if no segNrs, just return an empty data
            if isempty(segNrs1) && isempty(segNrs2), data = uint16( [] ); return; end

            % if data is empty, but segNrs exist, initialize to avoid errors lateron
            if isempty(data)
                for i = 1:numel(segNrs1), data(i, :) = [segNrs1(i) 0]; end
                for i = 1:numel(segNrs2), data(numel(segNrs1)+i, :) = [0 segNrs2(i)]; end
            end
            
            % remove duplicate entries
            data = unique(data, 'rows', 'stable');
            
            % correct if cells are not in segNrs1
            incorrectSegs1 = setdiff( data(:,1), segNrs1);
            for i = 1:length(incorrectSegs1)
                idx = data(:,1) == incorrectSegs1(i);
                data(idx, :) = [];
            end

            % correct if cells are not in segNrs2
            incorrectSegs2 = setdiff( data(:,2), segNrs2);
            for i = 1:length(incorrectSegs2)
                idx = data(:,2) == incorrectSegs2(i);
                data(idx, :) = [];
            end
            
            % correct if cell from segNrs1 is linked to more than 2 cells in segNrs2
            for i = 1:size(data,1)
                idx = find( data(:,1) == data(i,1) );
                for j = 3:length(idx)
                    data(j,1) = 0;
                end
            end

            % correct if cell from segNrs2 is linked to more than 1 cell in segNrs1 
           for i = 1:size(data,1)
                idx = find( data(:,2) == data(i,2) );
                for j = 2:length(idx)
                    data(j,2) = 0;
                end
            end
            
            % correct if cells from segNrs1 are missing
            missingSegs1 = setdiff( segNrs1, data(:,1));
            for i = 1:length(missingSegs1)
                data(end+1, :) = [missingSegs1(i) 0];
            end
            
            % correct if cells from segNrs2 are missing
            missingSegs2 = setdiff( segNrs2, data(:,2));
            for i = 1:length(missingSegs2)
                data(end+1, :) = [0 missingSegs2(i)];
            end
            
            data = uint16( data );
        end
        
        function correctTrackingOfFrames(obj, frames)
            if nargin < 2
                frames = obj.frames;
            end
            
            textprogressbar('VTrackings -> correcting trackings: '); tic;
            for i = 1:length(frames)-1

                % get track
                idf = uint16([frames(i) frames(i+1)]);
                track = obj.getData( idf );

                % get cell numbers
                segNrs1 = obj.region.segmentations.getSegNrs( frames(i) );
                segNrs2 = obj.region.segmentations.getSegNrs( frames(i+1) );

                % do correction
                data = obj.correctData(track, segNrs1, segNrs2);

                % if something changed, update
                if ~isequal( data, track )
                    obj.setData(idf, data);
                end
                
                if ~mod(i,10), textprogressbar( i/(length(frames)-1) ); end
            end
            textprogressbar(1); textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);
        end
        
        %% ?? %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = trackFrames(obj, frames)
            if nargin < 2
                frames = obj.frames;
            end
            tf = false;
            
            try 
                textprogressbar('VTrackings -> tracking frames: '); tic;
                for i = 1:length(frames)-1
                    obj.calcAndSetData( [frames(i) frames(i+1)] );
                    textprogressbar( i/(length(frames)-1) );
                end
                textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);

                tf = true;
            catch ME
                rethrow(ME);
            end
        end         
        
        function nrTrackedFrames = getNrTrackedFrames(obj)
            nrTrackedFrames = obj.getNrData();
        end        

    end
    
    %% FOR TRANSITION PHASE TO NEW VREGION STRUCTURE %%%%%%%%%%%%%%%%%%%%%%
    properties (Transient, Hidden) % not stored, hidden 
        temp_tree
    end     
     
    methods (Static)
        function obj = loadobj(s) % hidden
            if isstruct(s)
                obj = VTrackings( [] );
                obj.settings = s.settings;
                obj.dataArray = s.dataArray;
                obj.dataArrayIdf = s.dataArrayIdf;
                obj.dataArrayLength = s.dataArrayLength;
                obj.Idf2Idx = s.Idf2Idx;
                
                obj.temp_tree = s.tree;
            else
                obj = s;
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end