classdef VTree < VSettings & VData %% C
% VTree Object that contains the tree of a VRegion. 

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant, Hidden)
        DEFAULT_SUPER_SETTINGS = {  'tree_class'                 , uint32(1), @VTree ; ...
                                 };
                      
        VTREE_POSSIBLE_IDFS    = {  'cellNr', 'frame', 'segNr', 'parent', ...
                                    'timestamp', 'time', ...
                                    'daughter1', 'daughter2', 'generation', ...
                                    'area', 'areaPixels', ...
                                    'length', 'width', 'angle', 'solidity', 'cenX', 'cenY', 'volume', ...
                                 };
    end
    
    properties
        settings
        
        nrIdxs
        cell2idx
        frame2idx
        seg2cell
        seg2parent
    end

    properties (Transient) % not stored
        region
        isSaved
    end
    
    properties (Dependent) % calculated on the fly
        parent
        frames
        
        cellNrs
        featureList
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VTree( region )
            obj.settings            = {};
            obj.cell2idx            = cell.empty;
            obj.frame2idx           = cell.empty;
            obj.seg2cell            = cell.empty;
            obj.seg2parent          = cell.empty;
            
            obj.update(region);
        end
       
        function update(obj, region)
            obj.region              = region;
            obj.isSaved             = true;
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

        function cellNrs = get.cellNrs(obj)
            cellNrs = find(~cellfun(@isempty, obj.cell2idx));
        end
        
        function featureList = get.featureList(obj)
            featureList = obj.getFeatureList();
        end
        
        
        %% create local tree from trackings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function updateTree(obj)
            % warn if trackings need to be updated
            if obj.doesTrackingsNeedUpdating()
                warning off backtrace; 
                warning('VTree: trackings need to updated (probably a segmentation has changed without an update of the trackings)'); 
                warning on backtrace; 
            end
            
            % calculate and store cellNr, frame, segNr, parent if they need updating
            if obj.doesDataNeedUpdating('cellNr')
                obj.calcTree();
            end
            
            % get data
            data_cellNr         = obj.getUpdatedData('cellNr');
            data_frame          = obj.getUpdatedData('frame');
            data_segNr          = obj.getUpdatedData('segNr');
            data_parent         = obj.getUpdatedData('parent');
            
            % prepare data
            obj.nrIdxs          = 0;
            obj.cell2idx        = cell.empty;
            obj.frame2idx       = cell.empty; 
            obj.seg2cell        = cell.empty; 
            obj.seg2parent      = cell.empty; 
            
            % get frames for this tree
            treeFrames = obj.frames;
            
            % if no frames, no calculation needed
            if isempty(treeFrames), return; end
            
            obj.nrIdxs                  = numel(data_cellNr);
            for cellNr = 1:max(data_cellNr)
                obj.cell2idx{ cellNr }  = find( data_cellNr==cellNr );
            end
            for i = 1:length(treeFrames)
                frame                   = treeFrames(i);
                obj.frame2idx{ frame }  = find( data_frame==frame ); 
            end
            for idx = 1:length(data_cellNr)
                obj.seg2cell{ data_frame(idx) } ( data_segNr(idx) ) = data_cellNr(idx);
            end
            [~,firstFrameIdxs,~]                                          = unique(data_cellNr);
            for idx = 1:length(data_cellNr)
                if ismember(idx,firstFrameIdxs)
                    obj.seg2parent{ data_frame(idx) } ( data_segNr(idx) ) = data_parent(idx);
                else
                    obj.seg2parent{ data_frame(idx) } ( data_segNr(idx) ) = data_cellNr(idx);
                end                    
            end
        end
        
        function tf = doesTrackingsNeedUpdating(obj)
            tf = false;
            
            % get frames for this tree
            treeFrames = obj.frames;
            
            % if no frames, no updating needed
            if isempty(treeFrames), return; end
            
            seg_lastChange  = obj.region.segmentations.getLastChange();
            for i = 1:length(treeFrames)-1
                if obj.region.trackings.getTimestamp( [treeFrames(i) treeFrames(i+1)] ) > seg_lastChange
                    return
                end
            end
            tf = true;
        end

        %% calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = calcData(obj, idf)
            % actual calculation of data, by calling other functions
            data = [];
            
            % make sure that idf can be tracked
            if ~obj.canDataBeCalculated(idf), return; end
            
            % call respective function to calculate
            switch idf
                case {'cellNr', 'frame', 'segNr', 'parent'}
                    data = obj.calcTree( idf ); return;
                case {'timestamp', 'time'}
                    data = obj.calcTimes( idf ); return;
                case {'daughter1', 'daughter2', 'generation'}
                    data = obj.calcGenealogy( idf ); return;
                case {'area', 'areaPixels'}
                    data = obj.calcIntensity( idf ); return;
                case {'length', 'width', 'angle', 'solidity', 'cenX', 'cenY', 'volume'}
                    data = obj.calcRegionprops( idf ); return;
            end
            
            % check for p_sum
            [tf_sum, imageType]  = VTree.getFeatureField( idf, '_sum');
            if tf_sum && ismember(obj.region.images.types, imageType)
                data = obj.calcIntensity( idf ); return; 
            end
                
            % check for y_mean
            [tf_mean, imageType]  = VTree.getFeatureField( idf, '_mean');
            if tf_mean && ismember(obj.region.images.types, imageType)
                data = obj.calcIntensity( idf ); return; 
            end
            
            % check for length_mu
            [tf_mu, lengthField] = VTree.getFeatureField( idf, '_mu' );
            if tf_mu && obj.canDataBeCalculated( lengthField )
                data = obj.calcMu( idf ); return; 
            end
        end
        
        function tf = canDataBeCalculated(obj, idf)
            tf = true;
            
            % check wether idf is string
            if ~ischar( idf ), tf = false; return; end
            
            % check whether idf is known from obj.VTREE_POSSIBLE_IDFS
            if any( ismember(obj.VTREE_POSSIBLE_IDFS, idf) ), return; end

            % check for p_sum
            [tf_sum, imageType]  = VTree.getFeatureField( idf, '_sum');
            if tf_sum && ismember(obj.region.images.types, imageType), return; end
                
            % check for y_mean
            [tf_mean, imageType]  = VTree.getFeatureField( idf, '_mean');
            if tf_mean && ismember(obj.region.images.types, imageType), return; end
            
            % check for length_mu
            [tf_mu, lengthField] = VTree.getFeatureField( idf, '_mu' );
            if tf_mu && obj.canDataBeCalculated( lengthField ), return; end

            % idf cannot be calculated, give warning
            warning off backtrace; 
            warning(['VTree.canDataBeCalculated(): data idf ''' idf ''' cannot be calculated']);
            warning on backtrace; 
            
            tf = false;
        end
        
        function tf = doesDataNeedUpdating(obj, idf)
            tf = false;
            
            % if data cannot be calculated, not need to update
            if ~obj.canDataBeCalculated( idf ), return; end

            % if data is not set, it needs updating
            if ~obj.isDataSet( idf ), tf = true; return; end
            
            % set parent's lastChange to zero, in case no parent is found
            parentLastChange = 0;
            
            % call respective function to calculate
            switch idf
                case {'cellNr', 'frame', 'segNr', 'parent'}
                    regionLastChange            = obj.region.lastChange;
                    [~, timestamp_img_frames]   = obj.get('img_frames');
                    trackingsLastChange         = obj.region.trackings.getLastChange();
                    parentLastChange            = max([regionLastChange timestamp_img_frames trackingsLastChange]);

                    if obj.get('van_DEBUG')
                        disp(['VTree -> updateTree : last update of tree was on        : ' char(VTools.getDatetimeFromUnixtimestamp(obj.getTimestamp( idf )))]);
                        disp(['VTree -> updateTree : last update of region was on      : ' char(VTools.getDatetimeFromUnixtimestamp(regionLastChange))]);
                        disp(['VTree -> updateTree : last update of img_frames was on  : ' char(VTools.getDatetimeFromUnixtimestamp(timestamp_img_frames))]);
                        disp(['VTree -> updateTree : last update of trackings was on   : ' char(VTools.getDatetimeFromUnixtimestamp(trackingsLastChange))]);
                    end
                    
                case {'timestamp', 'time'}
                    parentList = { 'cellNr', 'parent' };
                    [tf, parentLastChange] = obj.doIdfsNeedUpdating( parentList);
                    imagesLastChange = 0; % 2DO
                    [~, timestamp_exp_syncTimestamps] = obj.get('exp_syncTimestamps');
                    parentLastChange = max([parentLastChange imagesLastChange timestamp_exp_syncTimestamps]);

                case {'daughter1', 'daughter2', 'generation'}
                    parentList = { 'cellNr', 'parent' };
                    [tf, parentLastChange] = obj.doIdfsNeedUpdating( parentList);
                    
                case {'area', 'areaPixels'}
                    parentList = { 'frame' };
                    [tf, parentLastChange] = obj.doIdfsNeedUpdating( parentList);
                    [~, timestamp_img_micronPerPixel] = obj.get('img_micronPerPixel');
                    parentLastChange = max([parentLastChange timestamp_img_micronPerPixel]);

                case {'length', 'width', 'angle', 'solidity', 'cenX', 'cenY', 'volume'}
                    parentList = { 'frame' };
                    [tf, parentLastChange] = obj.doIdfsNeedUpdating( parentList);
                    [~, timestamp_img_micronPerPixel] = obj.get('img_micronPerPixel');
                    parentLastChange = max([parentLastChange timestamp_img_micronPerPixel]);
            end            
            
            % check for p_sum or y_mean
            [tf_sum, ~]  = VTree.getFeatureField( idf, '_sum');
            [tf_mean, ~]  = VTree.getFeatureField( idf, '_mean');
            if tf_sum || tf_mean
                parentList = { 'frame' };
                [tf, parentLastChange] = obj.doIdfsNeedUpdating( parentList);
            end
                
            % check for length_mu
            [tf_mu, lengthField] = VTree.getFeatureField( idf, '_mu' );
            if tf_mu
                parentList = { lengthField };
                [tf, parentLastChange] = obj.doIdfsNeedUpdating( parentList);
            end
            
            % if parent has changed, it needs updating
            if obj.getTimestamp( idf ) < parentLastChange, tf = true; end
        end
        
        
        %% additional calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = calcTree(obj, idf)
        % calculates cellNr frame segNr and parent
        % in case no idf is given, all are saved immediately and empty returned
            data = [];
            
            % get frames for this tree
            treeFrames = obj.frames;
            nrFrames   = length(treeFrames);
            
            % if no frames, no calculation needed
            if isempty(treeFrames), return; end

            textprogressbar('VTree -> calculating tree: '); tic;
            
            % determine how many datapoints will be stores (sum of segNrs in frames)
            count                           = numel( obj.region.segmentations.getSegNrs( treeFrames(1) ) );
            for i = 1:length(treeFrames)-1
                track                       = obj.region.trackings.getTrack( treeFrames(i), treeFrames(i+1));
                if isempty(track), continue; end
                count                       = count + sum( track(:,2) > 0 );
            end

            % prepare data
            data_cellNr                     = nan([1 count]);
            data_frame                      = nan([1 count]);
            data_segNr                      = nan([1 count]);
            data_parent                     = nan([1 count]);
            
            % add data for first frame
            segNrs1                         = obj.region.segmentations.getSegNrs( treeFrames(1) );
            idx                             = numel(segNrs1);
            lastCellNr                      = idx;
            data_cellNr(1:idx)              = 1:numel(segNrs1);
            data_frame(1:idx)               = double(treeFrames(1)) * ones( size(segNrs1) );
            data_segNr(1:idx)               = segNrs1;
            data_parent(1:idx)              = nan( size(segNrs1) );
            
            % now loop over next frames and add data and new cells
            for i = 1:nrFrames-1
                frame1                      = treeFrames(i);
                frame2                      = treeFrames(i+1);
                track                       = obj.region.trackings.getTrack( frame1, frame2); % 2DO: getFrameTrack could be faster
                if isempty(track), continue; end

                % loop over rows in track
                for trackIdx = 1:size(track,1)

                    segNr1                  = track(trackIdx,1);
                    segNr2                  = track(trackIdx,2);

                    % if no seg in frame2, ignore row (indicates that cell in frame1 is not linked to anything)
                    if ~segNr2, continue; end

                    idx                     = idx+1;
                    data_frame(idx)         = frame2;
                    data_segNr(idx)         = segNr2;
                    
                    % if no seg in frame1, cell is appearing in frame2
                    if ~segNr1
                        lastCellNr          = lastCellNr + 1;
                        data_cellNr(idx)    = lastCellNr;
                        data_parent(idx)    = 0;
                        continue;
                    end

                    % find nr of times segNr1 is repeated
                    nrLinks                 = numel( find( track(:,1) == segNr1) );
                    segNr1_idx              = find(data_segNr==segNr1 & data_frame==frame1);
                    if numel(segNr1_idx) > 1
                        warning(['VTree.calcTree() -> problem with tracking from frame ' num2str(frame1) ' to ' num2str(frame2)]);
                    end
                    
                    if nrLinks == 1 % not dividing -> add to exisiting cell
                        data_cellNr(idx)    = data_cellNr( segNr1_idx );
                        data_parent(idx)    = data_parent( segNr1_idx );
                        
                    elseif nrLinks > 1 % dividing -> cell is appearing in frame2
                        lastCellNr          = lastCellNr + 1;
                        data_cellNr(idx)    = lastCellNr;
                        data_parent(idx)    = data_cellNr( segNr1_idx );
                    end
                end
                
                if ~mod(i,100), textprogressbar(i/(nrFrames-1)); end
            end
            textprogressbar(1); textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);

            % in case no idf is given, all are saved immediately and empty returned
            if nargin < 2
                obj.setData('cellNr', data_cellNr);
                obj.setData('frame', data_frame);
                obj.setData('segNr', data_segNr);
                obj.setData('parent', data_parent);
                return
            end
            
            % if data is requested try to return
            if nargout > 0
                switch idf
                    case {'cellNr'}
                        data = data_cellNr;
                    case {'frame'}
                        data = data_frame;
                    case {'segNr'}
                        data = data_segNr;
                    case {'parent'}
                        data = data_parent;
                end
            end
        end

        function data = calcTimes(obj, idf)
            data = [];

            % first make sure tree is up to date
            obj.updateTree();

            % get necessary data
            data_frame                          = obj.getUpdatedData('frame');
            
            % get frames for this tree
            treeFrames                          = unique(data_frame);
            nrFrames                            = length(treeFrames);
            
            % if no frames, no calculation needed
            if isempty(treeFrames), return; end

            textprogressbar('VTree   -> adding times: '); tic;
            
            % prepare data
            data_timestamp                      = nan([1 obj.nrIdxs]);

            % loop over each frame and add timestamp and time
            for i = 1:nrFrames
                fr                              = treeFrames(i);
                timestamp                       = obj.region.position.images.getImageTimestamp( fr );
                frame_idxs                      = obj.frame2idx{ fr };
                data_timestamp( frame_idxs )    = timestamp;
                
                if ~mod(i,100), textprogressbar(i/(nrFrames)); end
            end
            
            %% now move to time calculation
            % get necessary data
            exp_syncTimestamps                  = obj.get('exp_syncTimestamps');
            
            % in case exp_syncTimestamps not set, time = timestamp - timestamp(frame1) 
            if isempty(exp_syncTimestamps)
                % get timestamp of first frame
                timestampFirstFrame             = data_timestamp( obj.frame2idx{treeFrames(1)}(1) );
                data_time                       = data_timestamp - timestampFirstFrame;
            else
                
                uniqueTimestamps                = VTools.uniqueExcluding(data_timestamp, NaN);
                approx_interval                 = mean( diff( uniqueTimestamps ) );

                % prepare data
                data_time                       = data_timestamp;

                % use first syncTimestamp to change all time points
                if ~isempty(exp_syncTimestamps)
                    realTimestamp               = double( exp_syncTimestamps{1}(1) );
                    syncedTime                  = double( exp_syncTimestamps{1}(2) );
                    timeOffset                  = syncedTime - realTimestamp;
                    nonNanIdx                   = ~isnan(data_time);
                    data_time(nonNanIdx)        = data_time(nonNanIdx) + timeOffset;
                end

                % loop over each subsequent syncTimestamp offset
                for i = 2:size(exp_syncTimestamps, 1)
                    realTimestamp               = double( exp_syncTimestamps{i}(1) );
                    syncedTime                  = double( exp_syncTimestamps{i}(2) );
                    timeOffset                  = syncedTime - realTimestamp;

                    % find idx in timestamp closest to realTimestamp
                    [timeDiff, idx]             = min( abs(uniqueTimestamps - realTimestamp) );

                    % check whether time offset is large than time interval (in which case idx is probably wrong) 
                    if timeDiff > approx_interval
                        warning off backtrace; 
                        warning('VTree.calcTimes: time offset setting is larger than interval time'); 
                        warning on backtrace; 
                    end
                    
                    % correct data_time for data with timestamp above uniqueTimestamps(idx) - 0.5*approx_interval
                    data_idx                    = data_timestamp > (uniqueTimestamps(idx) - 0.5*approx_interval);
                    data_time(data_idx)         = data_timestamp(data_idx) + timeOffset;

                    % set data_time that for other data with to high time to NaN
                    data_idx                    = (data_time > (uniqueTimestamps(idx) - 0.5*approx_interval + timeOffset)) & (data_timestamp <= (uniqueTimestamps(idx) - 0.5*approx_interval));
                    data_time(data_idx)         = NaN;
                    
                    % check whether cells don't divide within removed (NaN) frames
                    removedFrames               = VTools.uniqueExcluding(data_frame(data_idx), NaN);
                    obj.warnIfCellsDivideInFrames( removedFrames );
                end
            end
            
            textprogressbar(1); textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);            

            % in case no idf is given, all are saved immediately and empty returned
            if nargin < 2
                obj.setData('timestamp', data_timestamp);
                obj.setData('time', data_time);
                return;
            end
            
            % if data is requested try to return
            if nargout > 0
                switch idf
                    case {'timestamp'}
                        data = data_timestamp;
                    case {'time'}
                        data = data_time;
                end
            end
        end

        function warnIfCellsDivideInFrames(obj, frames)
            % get necessary data
            data_frame                      = obj.getUpdatedData('frame');
            allFrames                       = unique(data_frame);
            
            for fr2 = frames
                idx                         = find(allFrames == fr2);
                if idx > 1
                    fr1                     = allFrames(idx-1);
                    track                   = obj.region.getTrack( [fr1 fr2]);
                    segNrs1                 = track(:,1);
                    segNrs1(segNrs1==0)     = [];
                    for segNr1 = segNrs1'
                        if sum(segNrs1==segNr1) > 1
                            warning off backtrace; 
                            warning(['VTree: cells divide in between frames ' num2str([fr1 fr2]) '. Should not remove frame ' num2str( fr2 ) ]); 
                            warning on backtrace;
                            return;
                        end
                    end
                end
            end
        end
        
        function data = calcGenealogy(obj, idf)
            data = [];

            % first make sure tree is up to date
            obj.updateTree();

            % get necessary data
            data_parent             = obj.getUpdatedData('parent');
            data_cellNr             = obj.getUpdatedData('cellNr');

            textprogressbar('VTree   -> adding genealogy: '); tic;

            % prepare data
            data_daughter1      = nan([1 obj.nrIdxs]);
            data_daughter2      = nan([1 obj.nrIdxs]);
            data_generation     = zeros([1 obj.nrIdxs]);

            % get unique cellNrs
            % faster would be to not load data_cellNr and use : cellNrs = find(~cellfun(@isempty, obj.cell2idx)); 
            cellNrs             = unique( data_cellNr );
            
            % loop over each cell and add itself to parent's daughters
            for i = 1:length(cellNrs)
                cell_cellNr                         = cellNrs(i);
                cell_idxs                           = obj.cell2idx{cell_cellNr};
                parent_cellNr                       = data_parent( cell_idxs(1) );
                
                % if cell has no parent, continue with next cell
                if isnan(parent_cellNr) || ~parent_cellNr, continue; end
                
                % update generation
                parent_idxs                         = obj.cell2idx{parent_cellNr};
                parent_generation                   = data_generation(parent_idxs(1));
                data_generation(cell_idxs)          = parent_generation + 1;

                % add itself to parent's daughters
                if isnan( data_daughter1( parent_idxs(1) ) )
                    data_daughter1( parent_idxs )   = cell_cellNr;
                elseif isnan( data_daughter2( parent_idxs(1) ) )
                    data_daughter2( parent_idxs )   = cell_cellNr;
                else
                    warning('VTree.calcGenealogy(): Seems like cell has more than 2 daughters...');
                end
                if ~mod(i,100), textprogressbar(i/(length(cellNrs))); end
            end
            textprogressbar(1); textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);            

            % in case no idf is given, all are saved immediately and empty returned
            if nargin < 2
                obj.setData('daughter1', data_daughter1);
                obj.setData('daughter2', data_daughter2);
                obj.setData('generation', data_generation);
                return;
            end
            
            % if data is requested try to return
            if nargout > 0
                switch idf
                    case {'daughter1'}
                        data = data_daughter1;
                    case {'daughter2'}
                        data = data_daughter2;
                    case {'generation'}
                        data = data_generation;
                end
            end
        end
        
        function data = calcIntensity(obj, idf)
            data = [];

            % first make sure tree is up to date
            obj.updateTree();

            % get necessary data
            data_frame                          = obj.getUpdatedData('frame');
            micronPerPixel                      = obj.get('img_micronPerPixel');

            % get frames for this tree
            treeFrames                          = unique(data_frame);
            nrFrames                            = length(treeFrames);
            
            % if no frames, no calculation needed
            if isempty(treeFrames), return; end

            hWairbar = waitbar(0, 'VTree   -> adding intensity: '); tic; % textprogressbar('VTree   -> adding intensity: '); tic;
            
            % prepare data
            imageTypes                          = obj.region.images.types;
            nrImageTypes                        = length(imageTypes);
            data_area                           = nan([1 obj.nrIdxs]);
            data_areaPixels                     = nan([1 obj.nrIdxs]);
            data_sum                            = nan([nrImageTypes obj.nrIdxs]);
            data_mean                           = nan([nrImageTypes obj.nrIdxs]);
            
            % loop over each frame and add stuff
            for i = 1:nrFrames
                fr                              = treeFrames(i);

                % load segmentation for this frameNum
                seg                             = obj.region.getSeg(fr);

                % loop over segs in this frame
                segNrs                          = obj.region.segmentations.getSegNrs( fr );

                for segNr = segNrs'
                    cellNr                      = obj.seg2cell{ fr }( segNr );
                    idx                         = intersect( obj.cell2idx{cellNr}, obj.frame2idx{fr} );
                    [y,~]                       = find( seg == segNr); % note: returns (row, column), which will be used as (y,x)
                    data_area( idx )            = numel(y) * micronPerPixel * micronPerPixel;
                    data_areaPixels( idx )      = numel(y);
                end
                
                % load images for this frameNum
                for typesIdx = 1:nrImageTypes
                    type    = imageTypes{typesIdx};
                    im      = obj.region.getImage(fr, type);
                    
                    for segNr = segNrs'
                        cellNr                      = obj.seg2cell{ fr }( segNr );
                        idx                         = intersect( obj.cell2idx{cellNr}, obj.frame2idx{fr} );
                        loc                         = find(seg == segNr); % loc are pixels where this cell is located
                        
                        data_sum( typesIdx, idx)    = sum( im(loc) );
                        data_mean( typesIdx, idx)   = data_sum( typesIdx, idx) / data_areaPixels( idx );
                    end
                end                
                
                if ~mod(i,10) && ishandle(hWairbar), waitbar(i/nrFrames, hWairbar); end % textprogressbar(i/nrFrames); 
            end
            if ishandle(hWairbar), close(hWairbar); end; disp(['VTree   -> added intensity in ' num2str(round(toc,1)) ' sec']); % textprogressbar(1); textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);            
            
            % in case no idf is given, all are saved immediately and empty returned
            if nargin < 2
                obj.setData('area', data_area);
                obj.setData('areaPixels', data_areaPixels);
                for typeIdx = 1:nrImageTypes
                    type    = imageTypes{typeIdx};
                    obj.setData([type '_sum'], data_sum( typeIdx, :) );
                    obj.setData([type '_mean'], data_mean( typeIdx, :) );
                end
                return;
            end
            
            % if data is requested try to return
            if nargout > 0
                switch idf
                    case {'area'}
                        data = data_area;
                    case {'areaPixels'}
                        data = data_areaPixels;
                    otherwise
                        % check for _sum
                        [tf_sum, imageType]  = VTree.getFeatureField( idf, '_sum');
                        if tf_sum
                            typeIdx         = obj.region.images.getTypeIdx(imageType);
                            data            = data_sum( typeIdx, :);
                        end

                        % check for _mean
                        [tf_mean, imageType]  = VTree.getFeatureField( idf, '_mean');
                        if tf_mean
                            typeIdx         = obj.region.images.getTypeIdx(imageType);
                            data            = data_mean( typeIdx, :);
                        end
                end
            end
        end
        
        function data = calcRegionprops(obj, idf)
            data = [];

            % set properties that will be calculated
            allowedIdfs     = {'length' 'width' 'angle' 'solidity' 'cenX' 'cenY' 'volume' };
            if nargin < 2
                idfs        = allowedIdfs;
            else
                idfs        = intersect(allowedIdfs, idf);
            end
            
            % don't do anything, if nothing to calculate
            if isempty(idfs), return; end            
            
            % first make sure tree is up to date
            obj.updateTree();

            % get necessary data
            data_frame                          = obj.getUpdatedData('frame');
            micronPerPixel                      = obj.get('img_micronPerPixel');

            % get frames for this tree
            treeFrames                          = unique(data_frame);
            nrFrames                            = length(treeFrames);
            
            % if no frames, no calculation needed
            if isempty(treeFrames), return; end
            
            textprogressbar('VTree   -> adding regionprops: '); tic;
            
            % prepare data
            data_fields         = nan([numel(idfs) obj.nrIdxs]);
            
            % determine properties that need to be calculated
            requiredProperties = {{'MajorAxisLength'}; {'MinorAxisLength'}; {'Orientation'}; {'Solidity'}; {'Centroid'}; {'Centroid'}; {'MajorAxisLength' 'MinorAxisLength'}};
            [~, idfs_idx, ~] = intersect(allowedIdfs, idfs);
            properties = unique([requiredProperties{idfs_idx}]);
            
            % loop over each frame and add stuff
            for i = 1:nrFrames
                fr                              = treeFrames(i);

                % load segmentation for this frameNum
                seg                             = obj.region.segmentations.getData(fr);

                % get shape properties for cells in this frame
                rp                              = regionprops(seg, properties);
                
                % loop over segs in this frame
                segNrs                          = obj.region.segmentations.getSegNrs( fr );

                for segNr = segNrs'
                    cellNr                      = obj.seg2cell{ fr }( segNr );
                    idx                         = intersect( obj.cell2idx{cellNr}, obj.frame2idx{fr} );
                    
                    for j = 1:length(idfs)
                        switch idfs{j}
                            case {'length'}
                                data_fields(j, idx)     = micronPerPixel * rp(segNr).MajorAxisLength;
                                
                            case {'width'}
                                data_fields(j, idx)     = micronPerPixel * rp(segNr).MinorAxisLength;

                            case {'angle'}
                                data_fields(j, idx)     = rp(segNr).Orientation;
                                
                            case {'solidity'}
                                data_fields(j, idx)     = rp(segNr).Solidity;

                            case {'cenX'}
                                data_fields(j, idx)     = rp(segNr).Centroid(1) + obj.region.rect(2) - 1;

                            case {'cenY'}
                                data_fields(j, idx)     = rp(segNr).Centroid(2) + obj.region.rect(1) - 1;

                            case {'volume'}
                                r                       = 0.5 * micronPerPixel * rp(segNr).MinorAxisLength;
                                l                       = micronPerPixel * rp(segNr).MajorAxisLength;
                                data_fields(j, idx)     = (4/3)*pi*r*r*r + pi*r*r*(l-2*r); % cigar shape estimation of volume of cell in micron^3

                        end
                    end
                end
                
                if ~mod(i,100), textprogressbar(i/nrFrames); end
            end
            textprogressbar(1); textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);            

            % in case no idf is given, all are saved immediately and empty returned
            if nargin < 2
                for j = 1:length(idfs)
                    obj.setData( idfs{j}, data_fields(j, :));
                end
                return;
            end

            % if data is requested try to return
            if nargout > 0
                data = data_fields( 1, :); % [~, idf_idx] = ismember(idfs, idf); if ~isempty(idf_idx) && idf_idx, data = data_fields( idf_idx, :); end
            end            
        end
        
        function data = calcMu(obj, idf)
            data = [];
            if nargin < 2, idf = 'length_mu'; end

            % determine length measure
            [tf, lengthField]   = VTree.getFeatureField( idf, '_mu' );
            
            % if no valid request, return empty data
            if ~tf, return; end

            % if lengthField cannot be calculated, return empty data
            if ~obj.canDataBeCalculated(lengthField)
                warning(['VTree.calcMu() : lengthField ' lengthField ' cannot be calculated']);
                return; 
            end

            % first make sure tree is up to date
            obj.updateTree();

            % get necessary data
            data_cellNr                 = obj.getUpdatedData('cellNr');
            data_length                 = obj.getUpdatedData( lengthField );
            data_time                   = obj.getUpdatedData('time');
            
            textprogressbar(['VTree   -> adding ' idf ': ']); tic;

            % prepare data
            data_mu                     = nan([1 obj.nrIdxs]);

            % get unique cellNrs
            % faster would be to not load data_cellNr and use : cellNrs = find(~cellfun(@isempty, obj.cell2idx)); 
            cellNrs                     = unique( data_cellNr );
            
            % loop over each cell and add mu
            for i = 1:length(cellNrs)
                cell_cellNr                     = cellNrs(i);
                cell_idxs                       = obj.cell2idx{cell_cellNr};
                cell_idxs( isnan( data_time(cell_idxs) ) ) = []; % remove NaN values
                
                if numel(cell_idxs) > 1
                    % set first time value to 0, and convert to hours
                    cell_time                   = ( data_time( cell_idxs ) - data_time( cell_idxs(1) ) ) / 3600;
                    [data_mu( cell_idxs ), ~]   = VTree.exponentialFit( cell_time, data_length( cell_idxs ) );
                else
                    data_mu( cell_idxs )        = NaN;
                end
                if ~mod(i,100), textprogressbar(i/(length(cellNrs))); end
            end
            textprogressbar(1); textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);            
            
            % in case no idf is given, all are saved immediately and empty returned
            if nargin < 2
                obj.setData(idf, data_mu);
                return;
            end
            
            % if data is requested try to return
            if nargout > 0
                data = data_mu;
            end
        end

        
        %% additional %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function featureList = getFeatureList(obj)
            featureList             = obj.VTREE_POSSIBLE_IDFS; 
            imageTypes              = obj.region.images.types;
            for i = 1:length(imageTypes)
                featureList{end+1}  = [imageTypes{i} '_sum'];
                featureList{end+1}  = [imageTypes{i} '_mean'];
            end
            featureList{end+1}      = 'length_mu';
            
            % add calculated ones
            featureList         = union(featureList, obj.dataArrayIdf, 'stable');
        end

        function calcAllData(obj)
            obj.calcTree();
            obj.calcTimes();
            obj.calcGenealogy();
            obj.calcIntensity();
            obj.calcRegionprops();
            obj.calcMu();
        end
        
        
        %% schnitzcells %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function schnitzcellsTree = getSchnitzcellsTree(obj, idfs)
           % if idfs not given, add all caculated ones
            if nargin < 2
                idfs = obj.featureList;
            end

            % remove non used idfs
            idfs = setdiff(idfs, {'cellNr'});
            
             % get idfs data
            for i = 1:length(idfs)
                data_idfs{i} = obj.getUpdatedData(idfs{i});
            end
            
            textprogressbar('VTree -> creating schnitzcells like tree: '); tic;
            
            % XX 
            idfsWithDifferentFieldname  = {'parent', 'daughter1', 'daughter2',  'frame',  'segNr', 'generation', 'length',    'width',       'angle',    'solidity',    'cenX',    'cenY',    'volume', 'length_mu'; ...
                                                'P',         'D',         'E', 'frames',  'segno',        'gen', 'rp_length', 'rp_width', 'rp_angle', 'rp_solidity', 'rp_cenX', 'rp_cenY', 'rp_volume',     'av_mu' };
            dataIdfsWithOnlyFirst = {'parent', 'daughter1', 'daughter2', 'generation', 'length_mu'};
            idfs_fieldnames = idfs;
            idfs_onlyFirst = false([1 length(idfs)]);
            for i = 1:length(idfs)
                [~, idx] = ismember( idfs{i}, idfsWithDifferentFieldname(1,:));
                if idx
                    idfs_fieldnames{i} = idfsWithDifferentFieldname{2,idx(1)};
                end                    
                if ismember(idfs{i}, dataIdfsWithOnlyFirst)
                    idfs_onlyFirst(i) = true;
                end
            end
            
            % create tree
            schnitzcellsTree = struct;
            
            % get unique cellNrs
            cellNrs             = find(~cellfun(@isempty, obj.cell2idx)); % unique( obj.getData('cellNr') );

            % loop over each cell and add data
            for i = 1:length(cellNrs)
                cell_cellNr                         = cellNrs(i);
                cell_idxs                           = obj.cell2idx{cell_cellNr};
                
                for j = 1:length(idfs)
                    if idfs_onlyFirst(j)
                        schnitzcellsTree(cell_cellNr).(idfs_fieldnames{j})   = data_idfs{j}( cell_idxs(1) );
                    else
                        schnitzcellsTree(cell_cellNr).(idfs_fieldnames{j})   = data_idfs{j}( cell_idxs );
                    end
                end                
                
                textprogressbar(i/(length(cellNrs)));
            end
            textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);    
        end
    end
    
    methods (Sealed)
        function [tf, idfsLastChange] = doIdfsNeedUpdating(obj, idfsList)
            tf                  = false;
            idfsLastChange      =  uint32(0);
            
            for i = 1:length(idfsList)
                % check whether this parent needs updating
                if obj.doesDataNeedUpdating( idfsList{i} ), tf = true; end            
            
                % update parentLastChange
                idfsLastChange = max([idfsLastChange obj.getLastChange(idfsList{i}) ]);
            end
        end
        
        function values = getValuesCellNr(obj, idf, cellNr, frame)
            values = [];
            
            if nargin < 2
                warning off backtrace; 
                warning('VTree: need idf'); 
                warning on backtrace; 
                return; 
            end
            if ~obj.canDataBeCalculated(idf)
                warning off backtrace; 
                warning(['VTree: idf (''' idf ''') cannot be calculated']); 
                warning on backtrace; 
                return; 
            end
            if nargin < 3 || isempty(cellNr)
                warning off backtrace; 
                warning('VTree: need cellNr'); 
                warning on backtrace; 
                return; 
            end
            % check wether cellNr exists
            if cellNr > length( obj.cell2idx )
                warning off backtrace; 
                warning('VTree: cellNr does not exist'); 
                warning on backtrace;
                return;
            end
            
            if nargin < 4 % all frames
                idx = [ obj.cell2idx{cellNr} ];
            else
                % make sure that frame(s) are not longer than allowed
                frame( frame>length(obj.frame2idx) ) = [];
                if isempty(frame)
                    idx = [];
                else
                    idx = intersect( [obj.cell2idx{cellNr}], [obj.frame2idx{frame}] );
                end
            end
            
            if isempty(idx)
                return;
            else
                values = obj.getUpdatedData( idf );
                values = values( idx );
            end
        end
       
        function values = getValuesFrame(obj, idf, cellNr, frame)
            values = [];
            
            if nargin < 2
                warning off backtrace; 
                warning('VTree: need idf'); 
                warning on backtrace; 
                return; 
            end
            if ~obj.canDataBeCalculated(idf)
                warning off backtrace; 
                warning(['VTree: idf (''' idf ''') cannot be calculated']); 
                warning on backtrace; 
                return; 
            end
            if nargin < 4 || isempty(frame)
                warning off backtrace; 
                warning('VTree: need frame'); 
                warning on backtrace; 
                return; 
            end
            % check wether frame exists
            if frame > length( obj.frame2idx )
                warning off backtrace; 
                warning('VTree: frame does not exist'); 
                warning on backtrace;
                return;
            end
            
            if isempty( cellNr ) % all cellNrs
                idx = [ obj.frame2idx{frame} ];
            else
                % make sure that cellNr(s) are not longer than allowed
                cellNr( cellNr>length(obj.cell2idx) ) = [];
                if isempty(cellNr)
                    idx = [];
                else
                    idx = intersect( [obj.frame2idx{frame}], [obj.cell2idx{cellNr}] );
                end
            end
            
            if isempty(idx)
                return;
            else
                values = obj.getUpdatedData( idf );
                values = values( idx );
            end
        end
        
        function values = getLineageCellNr(obj, idf, cellNr)
            values = [];
            obj.updateTree();
            
            if nargin < 2
                warning off backtrace; 
                warning('VTree: need idf'); 
                warning on backtrace; 
                return; 
            end
            if ~obj.canDataBeCalculated(idf)
                warning off backtrace; 
                warning(['VTree: idf (''' idf ''') cannot be calculated']); 
                warning on backtrace; 
                return; 
            end
            if nargin < 3 || isempty(cellNr)
                warning off backtrace; 
                warning('VTree: need cellNr'); 
                warning on backtrace; 
                return; 
            end
            % check wether cellNr exists
            if cellNr > length( obj.cell2idx )
                warning off backtrace; 
                warning('VTree: cellNr does not exist'); 
                warning on backtrace;
                return;
            end
            
            data_parent = obj.getUpdatedData( 'parent' );
            data_idf    = obj.getUpdatedData( idf );
            
            % now iteratively fill that data and move to parent
            while ~isnan( cellNr ) && cellNr > 0
                idx         = obj.cell2idx{cellNr(1)};
                values      = [data_idf( idx ) values];
                cellNr      = data_parent(idx(1));
            end
        end
    end
    
    methods (Static)
        function [power, x0] = exponentialFit( x, y)
            % Performs an exponential fit by linearization of log values with base 2
            p = polyfit(x,log2(y),1);
            power = p(1);
            x0 = 2^p(2);
        end
        
        function [tf, featureField] = getFeatureField( idf, ending )
            tf                  = false;
            featureField        = '';
            k                   = strfind(idf, ending);
            if numel(k) == 1 && k > 1 && k == length(idf) - length(ending) + 1
                tf              =  true;
                featureField    = idf(1:k-1);
            end
        end        
    end
    
end