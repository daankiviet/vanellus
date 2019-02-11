classdef VRegionmask < VSettings %% C
% VRegionmask Object that contains the (region) mask of a VRegion. 

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SUPER_SETTINGS  = { 'rmsk_class'            , uint32(1), @VRegionmask ; ...
                                    'rmsk_sigma'            , uint32(1), 3 ; ...
                                    'rmsk_medFilt'          , uint32(1), 1};
    end
    
    properties
        settings
        mask
        avIm
        avIm_edge
    end

    properties (Transient) % not stored
        region
        isSaved
        
        undoDataArray
    end
    
    properties (Dependent) % calculated on the fly
        parent
        frames
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VRegionmask( region )
            obj.update( region );

            obj.settings     = {};

            % start of with full mask, empty avIm and empty edge
            obj.mask        = true( obj.region.regionSize );
            obj.avIm        = double( zeros( obj.region.regionSize ) );
            obj.avIm_edge   = false( obj.region.regionSize );
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
        
        
        %% calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function regionmask = calcRegionmask(obj)
            % make sure that avIM and and avIm_edge are up to date
            obj.updateAvImage();
            
            % actual calculation of region mask
            regionmask = true( obj.region.regionSize );
        end

        function [avIm, avIm_edge] = calcAvImage(obj)
            % GET BASIC SETTINGS
            sigma       = obj.get('rmsk_sigma');
            medFilt     = obj.get('rmsk_medFilt');

            % prepare avIm
            avIm        =  double( zeros( obj.region.regionSize ) );
            
            % loop over all frames to get avIm
            textprogressbar('VRegionmask -> calculating an average image: '); tic;
            for i = 1:length(obj.frames)
                im = obj.region.getImage(obj.frames(i), []); 
                avIm = avIm + double(im); 
                textprogressbar(i/length(obj.frames));
            end
            avIm = avIm / length(obj.frames);
            textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);
            
            % apply medfilt2
            if ~isempty(medFilt)
                avIm = medfilt2(avIm, [medFilt medFilt]);
            end
            
            % normalize to 1
            avIm = avIm / max(max(avIm));

            % calculate avIm_edge
            avIm_edge = edge(avIm, 'log', 0, sigma);
            
            % add border around avIm_edge
            avIm_edge(1:end, [1 end]) = 1; 
            avIm_edge([1 end], 1:end) = 1;
        end
        
        function tf = updateAvImage(obj)
            % Check whether relevant settings have changed, and if so calculate AvImage
            % Checking last change of:
            % - region
            % - img_frames
            % - rmsk_sigma
            % - rmsk_medFilt
            timestamp_region            = obj.region.lastChange;
            [~, timestamp_img_frames]   = obj.get('img_frames');
            [~, timestamp_rmsk_sigma]   = obj.get('rmsk_sigma');
            [~, timestamp_rmsk_medFilt] = obj.get('rmsk_medFilt');

            % timestamp of last calculation of avIm
            [val, timestamp] = obj.get('rmsk_avImLastChange');

            if obj.get('van_DEBUG')
                disp(['VRegionmask -> updateAvImage : last change of avIm was on        : ' char(VTools.getDatetimeFromUnixtimestamp(timestamp))]);
                disp(['VRegionmask -> updateAvImage : last change of region was on      : ' char(VTools.getDatetimeFromUnixtimestamp(timestamp_region))]);
                disp(['VRegionmask -> updateAvImage : last change of img_frames was on  : ' char(VTools.getDatetimeFromUnixtimestamp(timestamp_img_frames))]);
                disp(['VRegionmask -> updateAvImage : last change of rmsk_sigma was on  : ' char(VTools.getDatetimeFromUnixtimestamp(timestamp_rmsk_sigma))]);
                disp(['VRegionmask -> updateAvImage : last change of rmsk_medFilt was on: ' char(VTools.getDatetimeFromUnixtimestamp(timestamp_rmsk_medFilt))]);
            end
            
            if ( numel(val) < 4 || ...
                 val(1) ~= timestamp_region || ...
                 val(2) ~= timestamp_img_frames || ...
                 val(3) ~= timestamp_rmsk_sigma || ...
                 val(4) ~= timestamp_rmsk_medFilt )
                
                if obj.get('van_DEBUG'), disp(['VRegionmask -> updateAvImage : calculating']); end
                tf = obj.calcAndSetAvImage();
            else
                if obj.get('van_DEBUG'), disp(['VRegionmask -> updateAvImage : not calculating']); end
                tf = false;
            end
        end        
        
    end
    
    methods (Sealed)
        
        %% updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function update(obj, region)
            obj.region          = region;
            obj.isSaved         = true;
        end
        
        
        %% changes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = setRegionmask(obj, regionmask)
            tf = false;
            
            % check whether correct size
            if size(regionmask,1) ~= obj.region.regionSize(1) || size(regionmask,2) ~= obj.region.regionSize(2)
                warning(['VRegionmask -> provided regionmask is not the same size as Region itself']);
                return;
            end

            % convert to logical
            regionmask          = logical( regionmask );
            
            % check whether something changed
            if isequal( regionmask, obj.mask), return; end

            % set undo data
            undoIdx = size(obj.undoDataArray,1)+1;
            obj.undoDataArray{ undoIdx, 1 } =  obj.mask;            

            % set new mask
%             obj.lastMaskChange  = xor(regionmask, obj.mask);
            obj.mask            = regionmask;
            obj.isSaved         = false;
            obj.set('rmsk_lastChange', VTools.getUnixTimeStamp());
            tf                  = true;
        end
        
        function tf = undo(obj)
            tf = false;
            
            for undoIdx = size(obj.undoDataArray,1):-1:1
                
                % reset
                obj.mask = obj.undoDataArray{ undoIdx, 1 };
                
                % remove from undoDataArray
                obj.undoDataArray( undoIdx, :) = [];

                tf          = true;
                obj.isSaved = false;
                return
            end
        end        
        
        function tf = setAvImage(obj, avIm, avIm_edge)
            tf              = false;
            
            % check whether correct size
            if size(avIm,1) ~= obj.region.regionSize(1) || size(avIm,2) ~= obj.region.regionSize(2) || ...
               size(avIm_edge,1) ~= obj.region.regionSize(1) || size(avIm_edge,2) ~= obj.region.regionSize(2)     
                warning(['VRegionmask -> provided avIm / avIm_edge is not the same size as Region itself']);
                return;
            end

            % convert to double and logical
            avIm            = double( avIm );
            avIm_edge       = logical( avIm_edge );
            
%             % check whether something changed
%             if isequal( avIm, obj.avIm) && isequal( avIm_edge, obj.avIm_edge), return; end

            % set
            obj.avIm        = avIm;
            obj.avIm_edge   = avIm_edge;
            obj.isSaved     = false;
            tf              = true;
            
            % set timestamps
            timestamp_region = obj.region.lastChange;
            [~, timestamp_img_frames] = obj.get('img_frames');
            [~, timestamp_rmsk_sigma] = obj.get('rmsk_sigma');
            [~, timestamp_rmsk_medFilt] = obj.get('rmsk_medFilt');
            obj.set('rmsk_avImLastChange', [timestamp_region timestamp_img_frames timestamp_rmsk_sigma timestamp_rmsk_medFilt]);
        end
        
        function tf = calcAndSetRegionmask(obj)
            % calculation
            regionmask = obj.calcRegionmask();
             
            % set regionmask
            tf = obj.setRegionmask(regionmask);
        end
        
        function tf = calcAndSetAvImage(obj)
            % calculation
            [avIm, avIm_edge] = obj.calcAvImage();
             
            % setting
            tf = obj.setAvImage( avIm, avIm_edge);            
        end
        
        
        %% editing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function editByAddingPixel(obj, coor)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            if ~obj.isCoorInMask(coor)
                disp(['coordinates outside of area']);
                return;
            end
            
            newMask = obj.mask;
            newMask(coor(1),coor(2)) = 1;
            obj.setRegionmask( newMask );
        end
        
        function editByRemovingPixel(obj, coor)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            if ~obj.isCoorInMask(coor)
                disp(['coordinates outside of area']);
                return;
            end
            
            newMask = obj.mask;
            newMask(coor(1),coor(2)) = 0;
            obj.setRegionmask( newMask );
        end
        
        function editByAddingLine(obj, coor1, coor2)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            if ~obj.isCoorInMask(coor1) || ~obj.isCoorInMask(coor2)
                disp(['coordinates outside of area']);
                return;
            end
            
            coor1 = double(coor1); 
            coor2 = double(coor2);
            newMask = VSegmentations.drawline(obj.mask, coor2 + [   0  0  ], coor1 + [   0  0  ], 1);
            obj.setRegionmask( newMask );
        end        
        
        function editByRemovingLine(obj, coor1, coor2)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            if ~obj.isCoorInMask(coor1) || ~obj.isCoorInMask(coor2)
                disp(['coordinates outside of area']);
                return;
            end
            
            coor1 = double(coor1); 
            coor2 = double(coor2);
            newMask = VSegmentations.drawline(obj.mask, coor2 + [   0  0  ], coor1 + [   0  0  ], 0);
            obj.setRegionmask( newMask );
        end        
        
        function editByAddingArea(obj, maskAddition)
            % 2DO: size checking
            
            newMask = obj.mask | maskAddition;
            obj.setRegionmask( newMask );
        end
        
        function editByRemovingArea(obj, maskRemoval)
            % 2DO: size checking

            newMask = obj.mask & ~maskRemoval;
            obj.setRegionmask( newMask );
        end
        
        function editByAddingEdgefill(obj, coor)
            % 2DO: size checking

            maskAddition = imfill(obj.avIm_edge, double(coor), 4) & ~obj.avIm_edge;
            newMask = obj.mask | maskAddition;
            obj.setRegionmask( newMask );
        end
        
        function editByRemovingEdgefill(obj, coor)
            % 2DO: size checking

            maskRemoval = imfill(obj.avIm_edge, double(coor), 4) & ~obj.avIm_edge;
            newMask = obj.mask & ~maskRemoval;
            obj.setRegionmask( newMask );
        end
        
        function editByRemovingConnectedarea(obj, coor)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            if ~obj.isCoorInMask(coor)
                disp(['coordinates outside of area']);
                return;
            end
            
            % get labeled mask
            mask_label = bwlabel(obj.mask, 4);
            mask_label(~obj.mask) = 0;
            
            % selected clicked label
            clicked_label = mask_label( round(coor(1)), round(coor(2)) );
            maskRemoval = false(size(obj.mask));
            maskRemoval( mask_label==clicked_label ) = 1;
            
            newMask = obj.mask & ~maskRemoval;
            obj.setRegionmask( newMask );
        end
        
        function changeMaskFillHoles(obj)
            newMask = imfill( obj.mask, 'holes');
            obj.setRegionmask( newMask );
        end          

        function changeMaskClear(obj)
            newMask = false(size(obj.mask));
            obj.setRegionmask( newMask );
        end
        
        function changeMaskAddEdges(obj)
            maskAddition = imdilate( obj.mask & ~obj.avIm_edge, strel('disk',1) ) & obj.avIm_edge;
            newMask = obj.mask | maskAddition;
            obj.setRegionmask( newMask );
        end        
    
        function tf = isCoorInMask(obj, coor)
            % check whether coordinates are within mask
            tf = false;
            if any(round(coor) >= [1 1]) && any(round(coor) <= size(obj.mask))
                tf = true;
            end
        end        
        
        
    end
end
