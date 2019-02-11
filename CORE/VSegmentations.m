classdef VSegmentations < VSettings & VData %% C
% VSegmentations Object that contains the segmentations of a VRegion. 

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SUPER_SETTINGS =  { 'seg_class'                 , uint32(1), @VSegmentations ; ...
                                    'seg_imgType'               , uint32(1), {'p'} ; ...
                                    'seg_sigma'                 , uint32(1), 3; ...
                                    'seg_medFilt'               , uint32(1), 3; ...
                                    'seg_isSegEdited'           , uint32(1), false; ...
                                    'seg_minCellArea'           , uint32(1), 10
                                };
    end
    
    properties
        settings
    end

    properties (Transient) % not stored
        region
        isSaved
    end
    
    properties (Dependent) % calculated on the fly
        parent
        frames
    end    
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VSegmentations( region )
            obj.settings            = {};
            
            obj.update(region);
        end
       
        function update(obj, region)
            obj.region              = region;
%             obj.isSaved             = true;
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
            % actual calculation of segmentation
            data = uint16( zeros( obj.region.regionSize ) );
        end
        
        
        %% segmentation images %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function im = getSegImage(obj, frame)
            % 2DO: settings could be different for this frame
            type = obj.get('seg_imgType');
            medFilt = obj.get('seg_medFilt');

            im = obj.region.getImage(frame, type);
            im = medfilt2(im, [medFilt medFilt]);
        end
        
        function imEdge = getSegEdge(obj, frame)
            % 2DO: settings could be different for this frame
            sigma = obj.get('seg_sigma');
            
            im = obj.getSegImage(frame);
            imEdge = edge(im, 'log', 0, sigma);
        end
        
    end
    
    methods (Sealed)
        %% data calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = canDataBeCalculated(obj, idf)
            tf = false;

            % check whether idf is valid frame number
            idf = uint16( idf(1) );
            if ~find( obj.frames == idf ), return; end
            
            % check whether there is an image to segment exists for this frame
            imageType = obj.get('seg_imgType');
            if obj.region.position.images.isImage( idf, imageType(1))
                tf = true;
                return;
            end
            
            warning(['VSegmentations -> a segmentation for frame ' num2str(idf) ' cannot be calculated. Probably image does not exist.']);
        end
        
        function tf = doesDataNeedUpdating(obj, idf)
            msk_lastChange  = obj.region.masks.getLastChange( idf );
            tf = doesDataNeedUpdating@VData(obj, idf, msk_lastChange);
        end        
        
        
        %% editing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = editByRemovingCell(obj, coor, frame)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            tf = false;

            seg = obj.getData(frame);
            cellNr = seg( round(coor(1)), round(coor(2)) );
            if cellNr > 0
                seg(seg==cellNr) = 0;
                obj.setData(uint16(frame(1)), seg);
                tf = true;
            end
        end
        
        function tf = editByJoiningCells(obj, coor1, coor2, frame)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            tf = false;
            coor1 = double(coor1); coor2 = double(coor2);

            seg = obj.getData(frame);

            % check whether coordinates are within segmentation
            if any(round(coor1) < [1 1]) || any(round(coor1) > size(seg)) || any(round(coor2) < [1 1]) || any(round(coor2) > size(seg))
                disp(['coordinates outside of area']);
                return;
            end
                
            cellNr1 = seg( round(coor1(1)), round(coor1(2)) );
            cellNr2 = seg( round(coor2(1)), round(coor2(2)) );
            
            if cellNr1 > 0 && cellNr2 > 0
                seg(seg==cellNr1) = cellNr2;

                seg = VSegmentations.drawline(seg, coor2 + [   0  0  ], coor1 + [   0  0  ], cellNr2);
                seg = VSegmentations.drawline(seg, coor2 + [-0.5  0  ], coor1 + [-0.5  0  ], cellNr2);
                seg = VSegmentations.drawline(seg, coor2 + [ 0.5  0  ], coor1 + [ 0.5  0  ], cellNr2);
                seg = VSegmentations.drawline(seg, coor2 + [   0  0.5], coor1 + [   0  0.5], cellNr2);
                seg = VSegmentations.drawline(seg, coor2 + [   0 -0.5], coor1 + [   0 -0.5], cellNr2);
                
                obj.setData(uint16(frame(1)), seg);
                tf = true;
            end
        end

        function editByFillingCells(obj, frame, cellNrs)
            seg                 = obj.getData(frame);
            
            if nargin < 3
                seg = VSegmentations.doForEachCell(seg, @(x) imfill(x,'holes'));
            else
                seg = VSegmentations.doForEachCell(seg, @(x) imfill(x,'holes'), cellNrs);
            end
            
            obj.setData(uint16(frame(1)), seg);
        end
        
        function editByClearingArea(obj, frame, mask)
            % note that mask should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % figure; imshow(mask);
            seg                 = obj.getData(frame);
            seg(mask)           = 0;
            
            obj.setData(uint16(frame(1)), seg);
        end        
        
        function editByAddingCell(obj, frame, mask)
            % note that mask should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % figure; imshow(mask);
            seg                 = obj.getData(frame);
            seg(mask)           = max(max(seg))+1;
            
            obj.setData(uint16(frame(1)), seg);
            
        end        
        
        function tf = editByAddingCellFromEdge(obj, coor, frame)
            tf = false;
            
            seg                 = obj.getData(frame);
            edge                = obj.getSegEdge(frame);
            mask                = obj.region.getMask(frame);
            maxFillPixels       = obj.get('seg_maxCellArea');
            if isempty(maxFillPixels), maxFillPixels = 600; end
            minPixelsIncrement  = 10;
            
            % image that is gonna be filled
            imageToFill         = edge;
            imageToFill(seg>1)  = 1;
            imageToFill(~mask)  = 1;

            % check whether coordinates are within segmentation
            if any(round(coor) < [1 1]) || any(round(coor) > size(seg))
                disp(['coordinates outside of area']);
                return;
            end
            
            % check whether point is clicked on valid point
            linearInd       = sub2ind(size(imageToFill), coor(1), coor(2));
            if imageToFill(linearInd) > 0
                disp(['coordinates on top of existing segmentation']);
                return;
            end
            
            % first try fully connected with imfill
            imageFilled     = imfill(imageToFill, linearInd);
            filling         = imageFilled & ~imageToFill;
            
            if sum(filling(:)) > maxFillPixels
                disp('not ok, so redo-ing');
                filling             = zeros(size(imageToFill));
                filling(linearInd)  = 1;
                
                steps = 1;
                sumfillPixels = sum(filling(:));
                while sumfillPixels < maxFillPixels 
                    filling = imdilate(filling, strel('disk',1)) & ~imageToFill;
                    
                    oldSumfillPixels = sumfillPixels;
                    sumfillPixels = sum(filling(:));
                    if (sumfillPixels-oldSumfillPixels) < minPixelsIncrement && sumfillPixels > minPixelsIncrement
                        steps = steps + 50; % 1 or 2 more rounds
                    end
                    
                    steps = steps + 1;
                    if steps > 100, break; end
                end
            end
            
            % add edge
            filling_dilated = imdilate( filling & ~edge, strel('disk',1) );
            filling_dilated = filling_dilated & mask & ~(seg>1);

            if obj.get('van_DEBUG')
                figure; 
                subplot(1,3,1); imshow(imageToFill);
                subplot(1,3,2); imshow(filling);
                subplot(1,3,3); imshow(filling_dilated);
            end
            
            seg( filling_dilated ) = max(seg(:)) + 1;
            obj.setData(uint16(frame(1)), seg);
            tf = true;
        end        
        
        function editByRemovingSmallCells(obj, frame)
            % settings
            seg_minCellArea = obj.get('seg_minCellArea');
            
            seg                 = obj.getData(frame);

            % if one of the cells is too small, no cutting
            for k = 1:max(max(seg))
                if sum( seg(:)==k ) < seg_minCellArea
                    seg( seg==k ) = 0;
                end
            end

            obj.setData(uint16(frame(1)), seg);
        end
        
        function tf = editByCuttingCell(obj, coor, frame)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            tf = false;

            % settings
            seg_minCellArea = obj.get('seg_minCellArea');
            
            seg                 = obj.getData(frame);
            cellNr              = seg( coor(1), coor(2) );
            if cellNr == 0, return; end
            
            [smallSeg, rect]    = VSegmentations.extractCellFromSeg( seg, cellNr); % rect = [left top width height oriWidth oriHeight] 
%             figure(10);imshow(VTools.segToRGB(smallSeg));pause;close(10);
            
            perim               = bwperim( imdilate( smallSeg, strel('disk',1) ) ); % perim is perimeter of dilated cell
%             figure(10);imshow(VTools.segToRGB(perim));pause;close(10);
            
            % starting from clicked point, will increase a box untill 2 sides are found: this will be perims
            perims = zeros( size(perim) );
            radp = 1;
            while max( max(perims) ) < 2 && radp < 41
                pxmin = max(coor(1)-rect(1)+1-radp,1);
                pxmax = min(coor(1)-rect(1)+1+radp,size(perims,1));
                pymin = max(coor(2)-rect(2)+1-radp,1);
                pymax = min(coor(2)-rect(2)+1+radp,size(perims,2));
                perims(pxmin:pxmax,pymin:pymax) = bwlabel(perim(pxmin:pxmax,pymin:pymax));
                radp = radp+1;
            end
%             figure(10);imshow(VTools.segToRGB(perims));pause;close(10);

            % if less than 2 perims are found, no cutting
            if max(max(perims)) < 2, return; end
            
            % kim is image with only clicked point drawn
            kim = zeros(size(smallSeg));
            kim(coor(1)-rect(1)+1, coor(2)-rect(2)+1) = 1;

            % look for start of Temp.drawline
            kim1 = kim;
            % increase size of kim untill it hits perims
            while ~any( any(kim1 & perims) )
                kim1 = imdilate(kim1, strel('disk',1));
            end
            % randomly select first point as start of Temp.drawline
            [cut1x, cut1y] = find(kim1 & perims);

            % now go for end of Temp.drawline, first remove points of side of start from perims
            color1 = perims(cut1x(1), cut1y(1));
            perims( perims==color1 ) = 0;
            kim2 = kim;
            while ~any( any(kim2 & perims) )
                kim2 = imdilate(kim2, strel('disk',1));
            end
            % randomly select first point as end of Temp.drawline
            [cut2x, cut2y] = find(kim2 & perims);

            % cut cell by drawing line
            smallSegCut = VSegmentations.drawline(smallSeg, [cut1x(1) cut1y(1)], [cut2x(1) cut2y(1)], 0);
            
            smallSegNewNrs = bwlabel(smallSegCut, 4);
%             figure(10);imshow(VTools.segToRGB(smallSegNewNrs));pause;close(10);

            % randomly add pixels of line to one of the 2 cells
            newNrs = unique(smallSegNewNrs); % newNrs(newNrs==0) = [];
            smallSegNewNrs = VSegmentations.drawline(smallSegNewNrs, [cut1x(1) cut1y(1)], [cut2x(1) cut2y(1)], newNrs(2));
            smallSegNewNrs( ~smallSeg ) = 0;
            
            % if one of the cells is too small, no cutting
            for k = 1:max(max(smallSegNewNrs))
                if sum( smallSegNewNrs(:)==k ) < seg_minCellArea
                    return;
                end
            end

            % place cut cells back in original size
            segNewNrs = VSegmentations.reEnlargeeSeg( smallSegNewNrs, rect); % rect = [left top width height oriWidth oriHeight] 

            % remove original cell in seg
            seg( seg==cellNr ) = 0;

            % first cell gets original color
            seg(segNewNrs==1) = cellNr;

            % new cells get new color
            for k = 2:max(max(segNewNrs)),
                seg(segNewNrs==k) = max(max(seg))+k-1;
            end;
%             figure(10);imshow(VTools.segToRGB(seg));pause;close(10);

            obj.setData(uint16(frame(1)), seg);
            tf = true;
        end
        
        function tf = editByCuttingCellUsingLine(obj, coor1, coor2, frame)
            % note that coors should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            tf = false;

            % settings
            seg_minCellArea     = obj.get('seg_minCellArea');

            % get seg
            seg                 = obj.getData(frame);
            
            % line coordinates
            lineCoors           = VSegmentations.getLineCoors(coor1, coor2);
            lineCoorsIdx        = sub2ind(size(seg),lineCoors(:,1),lineCoors(:,2));
            
            % select segNr that is going to be cut from middle of line
            segNrsInLine        = seg( lineCoorsIdx );
            if isempty(segNrsInLine), return; end
            segNr               = segNrsInLine(ceil(numel(segNrsInLine)/2));
            if segNr == 0, return; end
            
            % determine line coordinates where it overlaps with segNr
            lineCoorsInCellIdx  = intersect( lineCoorsIdx, find(seg==segNr));
            
            % extract image with segNr only
            seg_cellOnly        = seg;
            seg_cellOnly( seg~=segNr ) = 0;
            
            % remove line pixels and relabel
            seg_cellOnly(lineCoorsInCellIdx) = 0;
            seg_cellOnly = bwlabel(seg_cellOnly, 4);
            
            % randomly add pixels of line to one of the 2 cells
            newNrs = unique(seg_cellOnly);
            seg_cellOnly( lineCoorsInCellIdx ) = newNrs(2);

            % if one of the cells is too small, no cutting
            for k = 1:max(max(seg_cellOnly))
                if sum( seg_cellOnly(:)==k ) < seg_minCellArea
                    return;
                end
            end

            % remove original cell in seg
            seg( seg==segNr ) = 0;

            % first cell gets original color
            seg( seg_cellOnly==1 ) = segNr;

            % new cells get new color
            for k = 2:max(max(newNrs))
                seg( seg_cellOnly==k ) = max(max(seg))+k-1;
            end;

            obj.setData(uint16(frame(1)), seg);
            tf = true;
        end
        
        function tf = editByAddingPixel(obj, coor, frame, segNr)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            tf = false;

            seg = obj.getData(frame);
            if ~obj.isCoorInSeg(coor, seg)
                disp(['coordinates outside of area']);
                return;
            end

            seg(coor(1),coor(2)) = segNr;
            obj.setData(uint16(frame(1)), seg);
            tf = true;
        end
        
        function tf = editByRemovingPixel(obj, coor, frame)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            tf = false;

            seg = obj.getData(frame);
            if ~obj.isCoorInSeg(coor, seg)
                disp(['coordinates outside of area']);
                return;
            end
            
            seg(coor(1),coor(2)) = 0;
            obj.setData(uint16(frame(1)), seg);
            tf = true;
        end
        
        function tf = editByAddingLine(obj, coor1, coor2, frame, segNr)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            tf = false;

            seg = obj.getData(frame);
            if ~obj.isCoorInSeg(coor1, seg) || ~obj.isCoorInSeg(coor2, seg)
                disp(['coordinates outside of area']);
                return;
            end

            coor1 = double(coor1); 
            coor2 = double(coor2);
            seg = VSegmentations.drawline(seg, coor2 + [   0  0  ], coor1 + [   0  0  ], segNr);
            obj.setData(uint16(frame(1)), seg);
            tf = true;
        end        
        
        function tf = editByRemovingLine(obj, coor1, coor2, frame)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            tf = false;

            seg = obj.getData(frame);
            if ~obj.isCoorInSeg(coor1, seg) || ~obj.isCoorInSeg(coor2, seg)
                disp(['coordinates outside of area']);
                return;
            end
            
            coor1 = double(coor1); 
            coor2 = double(coor2);
            seg = VSegmentations.drawline(seg, coor2 + [   0  0  ], coor1 + [   0  0  ], 0);
            obj.setData(uint16(frame(1)), seg);
            tf = true;
        end        
        
        function editByAddingArea(obj, segAddition, frame, segNr)
            seg = obj.getData(frame);
            % 2DO: size checking
            
            seg( find(segAddition) ) = segNr;
            obj.setData(uint16(frame(1)), seg);
        end
        
        function editByRemovingArea(obj, segRemoval, frame)
            % 2DO: size checking
            seg = obj.getData(frame);

            seg(segRemoval) = 0;
            obj.setData(uint16(frame(1)), seg);
        end
        
        function editByAddingEdgefill(obj, coor, frame, segNr)
            seg = obj.getData(frame);
            % 2DO: size checking
            segEdge = obj.getSegEdge(frame);
            segAddition = imfill( segEdge, double(coor), 4) & ~segEdge;
            segAddition = imdilate(segAddition, strel('disk',1)) & (segAddition | segEdge);
            
            seg( segAddition ) = segNr;
            obj.setData(uint16(frame(1)), seg);
        end
        
        function editByRemovingEdgefill(obj, coor, frame)
            seg = obj.getData(frame);
            % 2DO: size checking
            segEdge = obj.getSegEdge(frame);

            segRemoval = imfill( segEdge, double(coor), 4) & ~segEdge;
            segRemoval = imdilate(segRemoval, strel('disk',1)) & (segRemoval | segEdge);

            seg(segRemoval) = 0;
            obj.setData(uint16(frame(1)), seg);
        end
        
        function tf = editByRemovingConnectedarea(obj, coor, frame)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            tf = false;

            seg = obj.getData(frame);
            if ~obj.isCoorInSeg(coor, seg)
                disp(['coordinates outside of area']);
                return;
            end
            
            % get labeled seg
            seg_label = uint16( bwlabel(seg, 4) );
            seg_label(~seg) = 0;
            seg_label = max(seg(:)) * seg_label + seg;
            
            % selected clicked label
            clicked_label = seg_label( round(coor(1)), round(coor(2)) );
            segRemoval = false(size(seg));
            segRemoval( seg_label==clicked_label ) = 1;
            
            seg(segRemoval) = 0;
            obj.setData(uint16(frame(1)), seg);
            tf = true;
        end        
        
        function tf = isCoorInSeg(obj, coor, seg)
            % check whether coordinates are within seg
            tf = false;
            if any(round(coor) >= [1 1]) && any(round(coor) <= size( seg ))
                tf = true;
            end
        end         
        
        
        %% ?? %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = segmentFrames(obj, frames)
            if nargin < 2
                frames = obj.frames;
            end
            tf = false;
            
            try 
                textprogressbar('VSegmentations -> segmenting frames: '); tic;
                for i = 1:length(frames)
                    obj.calcAndSetData( uint16( frames(i) ) );
                    textprogressbar( i/length(frames) );
                end
                textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);

                tf = true;
            catch
                warning(['VSegmentations -> error while calculation segmentations.']);
            end
        end         
        
        function segNrs = getSegNrs(obj, frame)
            seg     = obj.getData( uint16( frame ) );
            segNrs  = unique(seg);
            segNrs(segNrs==0) = [];
        end        
        
        function nrSegmentedFrames = getNrSegmentedFrames(obj)
            nrSegmentedFrames = obj.getNrData();
        end             

        function seg = renumberSegmentationLeftToRight(obj, seg)
            % rotate seg according to region rotation.
            seg = rot90( seg, obj.region.rotationAdditional90Idx);
            % renumber
            seg = VSegmentationsV1.renumberSegmentation(seg);
            % rotate seg back
            seg = rot90( seg, 4 - obj.region.rotationAdditional90Idx);
        end
        
    end
    
    methods (Static)
        %% ?? %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function im = drawline(im, pt1, pt2, color)
            coors = VSegmentations.getLineCoors(pt1, pt2);
            for i = 1:size(coors,1)
                im( coors(i,1), coors(i,2) ) = color;
            end
        end
        
        function coors = getLineCoors(pt1, pt2)
            pt1 = double(pt1); pt2 = double(pt2);
            vec = [pt2(1) - pt1(1) , pt2(2)-pt1(2)];
            D = sqrt(sum(vec.^2));
            coors = [ round(pt1(1)), round(pt1(2)) ];
            if D > 0
                for d = 0:0.25:D
                    thispt = round(pt1 + vec*d/D);
                    if thispt(1) ~= coors(end,1) || thispt(2) ~= coors(end,2)
                        coors(end+1,:) = [ thispt(1), thispt(2) ];
                    end
                end
            end
        end        
        
        function [smallSeg, rect] = extractCellFromSeg( seg, cellNr)
            % extract cell, return smaller image together with rect coordinates [left top width height oriWidth oriHeight] 
            PADDING = 5;
            
            smallSeg = zeros(size(seg));
            smallSeg( seg==cellNr ) = cellNr;

            [fx,fy] = find(smallSeg);
            rect = [    max( min(fx) - PADDING , 1) ...
                        max( min(fy) - PADDING , 1) ...
                        min( max(fx) + PADDING, size(smallSeg,1) ) - max( min(fx) - PADDING , 1) + 1 ...
                        min( max(fy) + PADDING, size(smallSeg,2) ) - max( min(fy) - PADDING , 1) + 1 ...
                        size(seg, 1) ...
                        size(seg, 2) ];

            smallSeg = smallSeg( rect(1):rect(1)+rect(3)-1, rect(2):rect(2)+rect(4)-1);
            
%             xmin = rect(1);
%             xmax = rect(1)+rect(3)-1;
%             ymin = rect(2);
%             ymax = rect(2)+rect(4)-1;            
        end
        
        function seg = reEnlargeeSeg( smallSeg, rect) % rect = [left top width height oriWidth oriHeight] 
            seg = zeros( [rect(5) rect(6)] );
            seg( rect(1):rect(1)+rect(3)-1, rect(2):rect(2)+rect(4)-1 ) = smallSeg;
        end        
      
        function imout = doForEachCell(imin, func, cellNrs)
            % Perform function on each cell separately, or for specified cells separately
            if nargin < 3
                cellNrs = unique(imin)';
                cellNrs = cellNrs(cellNrs~=0);
            end            
            
            imout = zeros( size(imin) );
            imout = cast(imout, 'like', imin);
            
            for c = cellNrs
                imtemp = (imin==c);
                funcDone = func(imtemp);
                funcDone = cast(funcDone, 'like', imin);
                imout = imout + c.*funcDone;
            end
        end
     
        function imout = remCellEachRegionForWhich(imin, func)
            % Remove each cell for which regionprops function is true
            imout = imin;
            
            for c = cellNrs
                imtemp = (imin==c);
                funcDone = func(imtemp);
                funcDone = cast(funcDone, 'like', imin);
                imout = imout + c.*funcDone;
            end
        end     
        
        function im_out = imfillWithMaxSize( im_in, maxSize)
            % Perform imfill but only accept holes below maxSize (in pixels)
            im_out = imfill(im_in,'holes');
            holes = im_out;
            holes(im_in) = 0;
            CC = bwconncomp(holes,4);
            for h = CC.PixelIdxList
                if length(h{1}) > maxSize
                    im_out(h{1}) = 0;
                end
            end
        end         
        
        function rect = getMaskMarginRect(mask, margin)
            rows    = find(sum(mask, 1));
            cols    = find(sum(mask, 2));
            if isempty(rows) || isempty(cols), rect = []; return; end % no Mask
            rect    = [rows(1) cols(1) rows(end)-rows(1)+1 cols(end)-cols(1)+1];
            rect    = rect + [-margin -margin 2*margin 2*margin];
            rect    = VTools.calcCorrectRect(rect, size(mask)); % make sure not outisde of image
        end

        function rect = getMaskMarginRectOld(mask, margin)
            % had problem with masks consisting of multiple unconnected areas
            stats = regionprops(mask, 'BoundingBox');
            if isempty(stats), rect = []; return; end % no Mask
            rect = stats.BoundingBox; % returns [minrow-0.5 mincol-0.5 height width]
            rect = rect + [-margin -margin 2*margin 2*margin] + [0.5 0.5 0 0];
            rect = VTools.calcCorrectRect(rect, size(mask)); % make sure not outisde of image
        end
        
    end
    
    %% FOR TRANSITION PHASE TO NEW VREGION STRUCTURE %%%%%%%%%%%%%%%%%%%%%%
    properties (Transient, Hidden) % not stored, hidden 
        temp_trackings
    end     
     
    methods (Static, Hidden)
        function obj = loadobj(s) % hidden
            if isstruct(s)
                obj = VSegmentations( [] );
                obj.settings = s.settings;
                obj.dataArray = s.dataArray;
                obj.dataArrayIdf = s.dataArrayIdf;
                obj.dataArrayLength = s.dataArrayLength;
                obj.Idf2Idx = s.Idf2Idx;
                
                obj.temp_trackings = s.trackings;
            else
                obj = s;
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end