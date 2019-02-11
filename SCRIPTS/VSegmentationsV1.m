classdef VSegmentationsV1 < VSegmentations %% C
% VSegmentationsV1

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties
        DEFAULT_SETTINGS =  {   'seg_minCellArea'           , uint32(1), 100        ; ...
                                'seg_minDepth'              , uint32(1), 5          ; ...
                                'seg_neckDepth'             , uint32(1), 3          ; ...
                                'seg_distMask'              , uint32(1), 3          ; ...
                                'seg_bgFraction'            , uint32(1), 0.9        ; ...
                                'seg_maxThresh'             , uint32(1), 0.025      ; ...
                                'seg_minThresh'             , uint32(1), 0.025      ; ...
                                'seg_minCellLength'         , uint32(1), 40         ; ...
                                'seg_longCellLength'        , uint32(1), 70         ; ...
                                'seg_magnification'         , uint32(1), 1          ; ...
                                'seg_maskMargin'            , uint32(1), 5          ; ...
                                'seg_edgeSubtraction'       , uint32(1), 3000       ; ...
                                'seg_edgeDilation'          , uint32(1), [0.67 0.33]  ; ...
                                'seg_edgeErosion'           , uint32(1), [1 0.67 0.33] };
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VSegmentationsV1( region )
            obj@VSegmentations( region ); 
        end
  
        %% segmentation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = calcData(obj, idf)
            DEBUG = false;
            if DEBUG, hFig = figure(1037); end 
                        
            % actual calculation of segmentation
            data = uint16( zeros( obj.region.regionSize ) );
            
            % make sure that idf can be segmented
            if ~obj.canDataBeCalculated(idf), return; end
            
            % get mask
            mask = obj.region.getMask( idf );
            
%             imSegmentationSteps = zeros([0 0 3],'double');
            
            types = obj.get('seg_types');
            if isempty(types)
                types = obj.get('seg_imgType');
            end
            
            for j = 1:length( types )
                SEG_1_imageToSegment(:,:,j) = obj.region.getImage( idf(1), types(j));
            end
            SEG_1_imageToSegment = VSegmentationsV1.scaleImage( mean( SEG_1_imageToSegment(:, :, :), 3) );
            if DEBUG, subplot(1,10,1); imshow(imadjust(SEG_1_imageToSegment)); end 

            SEG_2_imageToSegment = imresize( SEG_1_imageToSegment, obj.get('seg_magnification'), 'bilinear');
            mask = imresize( mask, obj.get('seg_magnification'), 'nearest');
            SEG_2_imageToSegment = medfilt2(SEG_2_imageToSegment, [obj.get('seg_medFilt') obj.get('seg_medFilt')]);
            if DEBUG, subplot(1,10,2); imshow(imadjust(SEG_2_imageToSegment)); end 
            


            stats = regionprops(mask, 'BoundingBox');
            if isempty(stats), return; end % no Mask
            BB = stats.BoundingBox; % returns [minrow-0.5 mincol-0.5 height width]
            BB = BB + [-obj.get('seg_maskMargin') -obj.get('seg_maskMargin') 2*obj.get('seg_maskMargin') 2*obj.get('seg_maskMargin')] + [0.5 0.5 0 0];
            BB = VTools.calcCorrectRect(BB, size(mask)); % make sure not outisde of image
            SEG_3_imageToSegment = SEG_2_imageToSegment(BB(2):BB(2)+BB(4)-1, BB(1):BB(1)+BB(3)-1);
            mask_CROPPED                         = mask(BB(2):BB(2)+BB(4)-1, BB(1):BB(1)+BB(3)-1);
            if DEBUG, subplot(1,10,4); imshow(imadjust(SEG_3_imageToSegment)); end 
            
            SEG_4_imageToSegment = imcomplement(SEG_3_imageToSegment);
            if DEBUG, subplot(1,10,5); imshow(imadjust(SEG_4_imageToSegment)); end 

            SEG_4_imageToSegmentEroded = imerode(SEG_4_imageToSegment, strel('disk',1));
            SEG_4_imageToSegment = imreconstruct(SEG_4_imageToSegmentEroded, SEG_4_imageToSegment);
            SEG_4_imageToSegment = imdilate(SEG_4_imageToSegment, strel('disk',1));
            if DEBUG, subplot(1,10,6); imshow(imadjust(SEG_4_imageToSegment)); end 
            
            IM_SUBSTRACT = VSegmentationsV1.f_getSubtractionImageFromMask(mask_CROPPED, obj.get('seg_edgeDilation'), obj.get('seg_edgeErosion'), obj.get('seg_edgeSubtraction'));
            SEG_4C_imageToSegment = SEG_4_imageToSegment - uint16(IM_SUBSTRACT);
            if DEBUG, subplot(1,10,7); imshow(imadjust(IM_SUBSTRACT)); end 

            SEG_5_edge = edge(SEG_4C_imageToSegment, 'log', 0, obj.get('seg_sigma'));
            if DEBUG, subplot(1,10,8); imshow(SEG_5_edge); end 

            SEG_6_edge = SEG_5_edge;
            SEG_6_edge([1:1+obj.get('seg_maskMargin'),end-obj.get('seg_maskMargin'):end], 1:end) = 0;
            SEG_6_edge(1:end, [1:1+obj.get('seg_maskMargin'),end-obj.get('seg_maskMargin'):end]) = 0;
            SEG_6_edge(1:end, end) = 1;
            if DEBUG, subplot(1,10,9); imshow(SEG_6_edge); end 

            SEG_7_filledEdges = imfill(SEG_6_edge, 'holes');
            SEG_7_filledEdges = bwareaopen(SEG_7_filledEdges, obj.get('seg_minCellArea'), 4);
            SEG_7_edge = SEG_6_edge & SEG_7_filledEdges;
            SEG_7_edge = bwareaopen(SEG_7_edge, 30);
            if DEBUG, subplot(1,10,10); imshow(SEG_7_filledEdges); end 

            shading = repmat(SEG_3_imageToSegment(1,:), [size(SEG_3_imageToSegment,1) 1]);
            SEG_8_imageToSegment = SEG_3_imageToSegment - shading;

            SEG_8_filledEdges = SEG_7_filledEdges;
            SEG_8_filledEdges(find(SEG_6_edge)) = 0;

            BACKGROUND_mask = imerode(~SEG_7_filledEdges & mask_CROPPED, strel('disk',4));
            BACKGROUND_median = median(SEG_8_imageToSegment(BACKGROUND_mask));

            areas = bwlabel(SEG_8_filledEdges, 4);
            area_nrs = unique(areas)';
            for c = area_nrs(area_nrs~=0)
                area_median = median(imerode(SEG_8_imageToSegment(find(areas==c)), strel('disk',2))); % DJK 2013-09-26 Added making smaller of cells
                if area_median > obj.get('seg_bgFraction')*BACKGROUND_median % BACKGROUND_median - 2*BACKGROUND_std
                    SEG_8_filledEdges(find(areas==c)) = 0;
                end
            end

            SEG_8C_filledEdges = bwareaopen(SEG_8_filledEdges, obj.get('seg_minCellArea'), 4);

            SEG_8D_filledEdges = VSegmentationsV1.imfill_maxSize(SEG_8C_filledEdges, 20);

            SEG_8D_filledEdges = SEG_8D_filledEdges & mask_CROPPED;
            SEG_8_filledEdges = SEG_8D_filledEdges;

            SEG_9_seeds1 = SEG_8_filledEdges & ~SEG_7_edge;
            SEG_9_seeds2 = bwmorph(SEG_9_seeds1,'open');
            SEG_9_seeds2 = bwmorph(SEG_9_seeds2,'thin',inf);

            SEG_10_seeds2 = SEG_9_seeds2;
            SEG_10_seeds2 = bwmorph(SEG_10_seeds2,'spur',3);
            SEG_10_seeds2 = bwareaopen(SEG_10_seeds2,10,8);

            SEG_11_seeds2 = SEG_10_seeds2;
            icut = SEG_11_seeds2;
            continueToCut = true;
            while continueToCut
                [cellsToRemove, cutPoints] = VSegmentationsV1.PN_CutLongCells(icut, SEG_8_filledEdges, obj.get('seg_neckDepth'));
                if max(max(cutPoints))==0
                    continueToCut = false;
                else
                    cutPoints = bwmorph(cutPoints,'dilate',2);
                    SEG_11_seeds2(cutPoints) = false; %cuts the long cells on the seeds image
                    icut(cutPoints) = false;
                    icut = icut & ~cellsToRemove;
                end
            end
            
            SEG_12_filledEdges = bwmorph(SEG_8_filledEdges, 'dilate');
            SEG_12_background = ~SEG_12_filledEdges;
            SEG_12_seeds = bwmorph(SEG_11_seeds2, 'spur', 3);
            SEG_12_seeds = bwareaopen(SEG_12_seeds, 4, 8);
            SEG_12_d1 = -bwdist(SEG_12_background);
            SEG_12_d1 = imimposemin(SEG_12_d1, SEG_12_background | SEG_12_seeds);
            SEG_12_segmentedImage = watershed(SEG_12_d1);                     
            SEG_12_segmentedImage(SEG_12_background) = 0;
            SEG_12_segmentedImage = bwareaopen(SEG_12_segmentedImage, obj.get('seg_minCellArea')); % SEG_12_segmentedImage = bwareaopen(SEG_12_segmentedImage, 10);
            SEG_12_segmentedImage = bwlabel(SEG_12_segmentedImage);
            SEG_12_segmentedImage = imdilate(SEG_12_segmentedImage, strel('diamond',1));
            SEG_12_segmentedImage = VSegmentationsV1.renumberSegmentation(SEG_12_segmentedImage);

            SEG_12_segmentedImage = VSegmentationsV1.forEachCell(SEG_12_segmentedImage, @(x) VSegmentationsV1.imfill_maxSize(x,20)); %DJK 2013-09-03

            SEG_13A_segmentedImage = SEG_12_segmentedImage;
            r2 = regionprops( SEG_12_segmentedImage, 'majoraxislength' );
            fbiggies = find(([r2.MajorAxisLength] > obj.get('seg_longCellLength'))); 
            for j = 1:length(fbiggies)
                % get only the cell that is gonna be broken
                Lcell = +(SEG_12_segmentedImage == fbiggies(j)); % + converts logical to double
                Lcell(Lcell == 1)= fbiggies(j);
                % try to break cell, DJK 081229 used to use phsub(:,:,p.imNumber1), now phsegsub
                cutcell = VSegmentationsV1.breakcell(Lcell, SEG_3_imageToSegment, obj.get('seg_maxThresh'), obj.get('seg_minThresh'), obj.get('seg_minCellLength')); %DJK 2013-09-26 add 1 to see figures
                % remove original cell
                SEG_13A_segmentedImage(SEG_12_segmentedImage == fbiggies(j))= 0;
                % place cutcell (can be 1 or more cells)
                cellnos = unique(cutcell);  
                label = max(max(SEG_13A_segmentedImage));
                for k = 2:length(cellnos)
                    SEG_13A_segmentedImage(find(cutcell == cellnos(k)))= label+k;
                end
            end
            SEG_13A_segmentedImage = VSegmentationsV1.renumberSegmentation(SEG_13A_segmentedImage);

            SEG_13B_segmentedImage = imdilate( SEG_13A_segmentedImage, strel('diamond',1) );

            TEST_SETTING_MINDISTOPENING = obj.get('seg_distMask');

            SEG_13C_segmentedImage = SEG_13B_segmentedImage;
            area_nrs = unique(SEG_13C_segmentedImage)';
            for c=area_nrs(area_nrs~=0)
                [idx_r,idx_c] = find(SEG_13C_segmentedImage==c);
                
                % opening depends on additionalRotation
                rotationAdditional90Idx = obj.region.rotationAdditional90Idx;
                if rotationAdditional90Idx == 1 % '90 LEFT'
                    mostBottomMaskPixel = find(sum(mask_CROPPED,2),1,'last');
                    if max(idx_r) > mostBottomMaskPixel - TEST_SETTING_MINDISTOPENING;
                        SEG_13C_segmentedImage( find(SEG_13C_segmentedImage==c) ) = 0;
                    end
                    
                elseif rotationAdditional90Idx == 2 % '180'
                    mostLeftMaskPixel = find(sum(mask_CROPPED,1),1,'first');
                    if min(idx_c) < mostLeftMaskPixel + TEST_SETTING_MINDISTOPENING;
                        SEG_13C_segmentedImage( find(SEG_13C_segmentedImage==c) ) = 0;
                    end
                    
                elseif rotationAdditional90Idx == 3 % '90 RIGHT'
                    mostTopMaskPixel = find(sum(mask_CROPPED,2),1,'first');
                    if min(idx_r) < mostTopMaskPixel + TEST_SETTING_MINDISTOPENING;
                        SEG_13C_segmentedImage( find(SEG_13C_segmentedImage==c) ) = 0;
                    end
                    
                elseif rotationAdditional90Idx == 4 % 'NONE'
                    mostRightMaskPixel = find(sum(mask_CROPPED,1),1,'last');
                    if max(idx_c) > mostRightMaskPixel - TEST_SETTING_MINDISTOPENING;
                        SEG_13C_segmentedImage( find(SEG_13C_segmentedImage==c) ) = 0;
                    end
                end
            end
            SEG_13C_segmentedImage = obj.renumberSegmentationLeftToRight(SEG_13C_segmentedImage);

            SEG_14_segmentedImage = VSegmentationsV1.forEachCell(SEG_13C_segmentedImage, @(x) VSegmentationsV1.imfill_maxSize(x,20)); %DJK 2013-09-26
            
            % ENLARGE BACK TO ORIGINAL SIZE
            data = zeros(obj.region.regionSize);
            data(BB(2):BB(2)+BB(4)-1, BB(1):BB(1)+BB(3)-1) = SEG_14_segmentedImage;
        end

        function im = getSegImage(obj, frame)
            % 2DO: settings could be different for this frame
            types = obj.get('seg_types');
            if isempty(types)
                types = obj.get('seg_imgType');
            end
            seg_magnification = obj.get('seg_magnification');
            seg_medFilt = obj.get('seg_medFilt');
            
            
            for j = 1:length( types )
                im(:,:,j) = obj.region.getImage( frame, types(j));
            end
            im = VSegmentationsV1.scaleImage( mean( im(:, :, :), 3) );

            % SEG_2 : DOUBLE SIZE AND SUPPRESS SHOT NOISE WITH medfilt2 %%%
            im = imresize( im, seg_magnification, 'bilinear');
            im = medfilt2(im, [seg_medFilt seg_medFilt]);
            
            im = imresize( im, 1/seg_magnification, 'bilinear');
            
%             disp('calculating local getSegImage');
        end
        
        function imEdge = getSegEdge(obj, frame)
            % get settings
            seg_sigma               = obj.get('seg_sigma');
            seg_edgeDilation        = obj.get('seg_edgeDilation');
            seg_edgeErosion         = obj.get('seg_edgeErosion');
            seg_edgeSubtraction     = obj.get('seg_edgeSubtraction');

            % get seg image
            im                      = obj.getSegImage(frame);

            % get mask
            mask                    = obj.region.getMask( frame );
            
            % SEG_4A : IMAGE COMPLEMENT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            SEG_4_imageToSegment    = imcomplement(im);

            % SEG_4B : MORPHOLOGICAL RECONSTRUCTION %%%%%%%%%%%%%%%%%%%%%%%
            SEG_4_imageToSegmentEroded = imerode(SEG_4_imageToSegment, strel('disk',1));
            SEG_4_imageToSegment    = imreconstruct(SEG_4_imageToSegmentEroded, SEG_4_imageToSegment);
            SEG_4_imageToSegment    = imdilate(SEG_4_imageToSegment, strel('disk',1));
            
            % SEG_4C : REDUCE INTENSITY AT EDGE OF MASK %%%%%%%%%%%%%%%%%%%%%%%%%%%
            IM_SUBSTRACT            = VSegmentationsV1.f_getSubtractionImageFromMask(mask, seg_edgeDilation, seg_edgeErosion, seg_edgeSubtraction);
            SEG_4C_imageToSegment   = SEG_4_imageToSegment - uint16(IM_SUBSTRACT);

            % SEG_5 : EDGE DETECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            imEdge                  = edge(SEG_4C_imageToSegment, 'log', 0, seg_sigma);
        end        
        
    end
    
    %% STATIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Static)
        function im_out = scaleImage(im_in)
        % Function to scale image, such that 25th highest value is 10000 and the
        % 25th lowest value is 0
            x = double(im_in);
            s = sort(x(:));
            small = s(25);
            big = s(end-25);
            rescaled = (x - small)/(big - small);
            rescaled(rescaled<0) = 0;
            im_out = uint16(10000*rescaled);
        end
        
        function IM_SUBSTRACT = f_getSubtractionImageFromMask(MASK, FAC_DIL, FAC_ERO, INTENS)
            IM_SUBSTRACT = zeros(size(MASK)); LINE_CROPPED_ERODED = IM_SUBSTRACT; LINE_CROPPED_DILATED = IM_SUBSTRACT;
            temp = MASK;
            for i = 1:length(FAC_ERO)
                temp_eroded = imerode(temp,strel('disk',1));
                temp_line = temp & ~temp_eroded;
                LINE_CROPPED_ERODED(:,:,i) = temp_line .* FAC_ERO(i) .* INTENS;
                temp = temp_eroded;
            end
            temp = MASK;
            for i = 1:length(FAC_DIL)
                temp_dilated = imdilate(temp,strel('disk',1));
                temp_line = ~temp & temp_dilated;
                LINE_CROPPED_DILATED(:,:,i) = temp_line .* FAC_DIL(i) .* INTENS;
                temp = temp_dilated;
            end
            IM_SUBSTRACT = sum(LINE_CROPPED_ERODED,3) + sum(LINE_CROPPED_DILATED,3);
        end        
        
        function im_out = forEachCell(im_in, func)
            im_out = zeros(size(im_in));
            cells = unique(im_in)';
            for c = cells(cells~=0)
                imtemp = (im_in==c);
                im_out = im_out + c.*func(imtemp);
            end
        end

        function im_out = imfill_maxSize(im_in,maxSize)
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
        
        function seg_new = renumberSegmentation(seg_old)
            seg_new = seg_old;
            [u,i] = unique(seg_old, 'stable'); % u = seg_old(sort(i));
            for i = 2:length(u),
                seg_new(seg_old==u(i))=i-1;
            end
        end
        
        function [nonCutCells cutImage] = PN_CutLongCells(skelim,refim,neckDepth)
            sref = size(refim);
            cutImage = zeros(sref);
            nonCutCells = zeros(sref);

            dimage = bwdist(~refim);%distance transform
            cc=bwconncomp(skelim);
            stats = regionprops(cc,'Area','BoundingBox','Image');
            characSize = median([stats.Area]);
            idx = find([stats.Area] > characSize*1.5); %suspicious cells

            for ii = idx  %study the case of long cells individually

                %extracts the subimage containing the long cell
                s = stats(ii);
                xb = ceil(s.BoundingBox(1));    yb = ceil(s.BoundingBox(2));
                lx = s.BoundingBox(3);          ly = s.BoundingBox(4);
                subImage = imcrop(dimage,[xb yb lx-1 ly-1]);
                localSkel = s.Image;    %local skeleton
                subImage(~localSkel) = inf; %local restriction of distance transform to the skeleton 

                %cuts under the condition that the necking has a certain depth
                [m xm ym] = VSegmentationsV1.MinCoordinates2(subImage);    %potentiel division point
                localSkel(ym,xm)=false; %cut...
                localCc=bwconncomp(localSkel); %...and examin the 2 sides of the cells
                cutHappened = false;
                if localCc.NumObjects == 2 %avoid cases in which the cut point is at a cell end
                    av_left = mean(subImage(localCc.PixelIdxList{1}));    %average thickness on one side
                    av_right = mean(subImage(localCc.PixelIdxList{2}));    %average thickness on other side
                    if (av_left-m > neckDepth) && (av_right-m > neckDepth) %cusp of sufficient depth
                        cutImage(ym+yb-1,xm+xb-1)=1;
                        cutHappened = true;
                    end
                end

                %cells which have not been cut are stored for erasion to not be reexamined
                if ~cutHappened
                   nonCutCells(cc.PixelIdxList{ii}) = 1; 
                end
            end
        end
        
        function [Min XMin YMin] = MinCoordinates2(matr)
            [values,Ypositions] = min(matr);
            [Min,XMin] = min(values);
            YMin = Ypositions(XMin);
        end        
        
        function cutcell= breakcell(cell, phcell, maxthresh, minthresh, mincelllength, figs, thinx, thiny)
            if nargin == 5
                figs= 0; % figs= 1 for graphical output (debug mode)
            end
            maxdist= 4; % distance from pt used to test if it is a maximum
            mindist= 4; % distance from pt used to test if it is a minimum
            diffthresh= 3; % size of jump in diff of minpts or maxpts 

            % make sure image is black and white and not logical
            cellno= max(max(double(cell)));
            cell= +(cell > 0);
            phcell= +phcell;

            % check Euler Number
            if nargin < 7
                r= regionprops(cell, 'eulernumber');
                if [r.EulerNumber] ~= 1
                    if figs==1
                        disp(['Circular region in thin. Euler Number= ',num2str([r.EulerNumber])]);
                    end
                    cutcell= bwlabel(cell, 4);
                    return;
                end
            end

            % extract subimages
            [fx, fy]= find(cell);
            extra= 5;
            xmin= max(min(fx) - extra, 1);
            xmax= min(max(fx) + extra, size(cell,1));
            ymin= max(min(fy) - extra, 1);
            ymax= min(max(fy) + extra, size(cell,2));
            subcell= cell(xmin:xmax, ymin:ymax);
            originalsubcell= subcell;
            subphcell= phcell(xmin:xmax, ymin:ymax);


            % FIND THIN (CENTRE LINE) OF CELL

            if nargin < 7

                % make thin of image
                thin= VSegmentationsV1.bwmorphmelow(subcell, 'thin', inf);
                % clean up thin (remove spurious spurs)
                thin= VSegmentationsV1.bwmorphmelow(VSegmentationsV1.bwmorphmelow(thin, 'diag', 1), 'thin', inf);

                % find spur points
                spurs= thin & ~VSegmentationsV1.bwmorphmelow(thin, 'spur', 1);
                [sx, sy]= find(spurs > 0);
                if figs == 1
                    disp(['No of spur points in thin= ',num2str(length(sx))]);
                end
                if length(sx) > 2
                    for i= 2:length(sx)
                        subcell2= zeros(size(subcell));
                        subcell2(sx(1), sy(1))= 1;
                        subcell2(sx(i), sy(i))= 1;
                        subcell2= imdilate(subcell2, strel('disk', 2));
                        subcell3= subcell2 | thin;
                        subcell4= VSegmentationsV1.bwmorphmelow(subcell3, 'spur', inf);
                        subcell5= VSegmentationsV1.bwmorphmelow(subcell4, 'thin', inf);
                        subcellthin{i-1}= VSegmentationsV1.bwmorphmelow(subcell5, 'spur', 2);
                    end
                else
                    subcellthin{1}= thin;
                end

            else

                % create thin image
                thin= zeros(size(subcell));
                fx= thinx - xmin + 1;
                fy= thiny - ymin + 1;
                for i= 1:length(fx)
                    thin(fx(i), fy(i))= 1;
                end
                subcellthin{1}= thin;

                % find spur points
                spurs= thin & ~VSegmentationsV1.bwmorphmelow(thin, 'spur', 1);
                [sx, sy]= find(spurs > 0);
                if length(sx) ~= 2
                    disp('Given thin has multiple spur points.');
                    cutcell= cell;
                    return;
                end

            end

            % RUN THROUGH EACH THIN TO FIND POINTS TO CUT

            for k= 1:length(sx)-1

                % obtain points ordered along thin of image
                clear avp avs;
                if nargin < 7
                    [fx, fy]= VSegmentationsV1.walkthin(subcellthin{k});
                    if isempty(fx)
                        continue;
                    end
                end
                j= 1;
                for bsize= 2:5
                    for i= 1:length(fx),
                        % extract mean of pixels in phase image lying in box bsize
                        axmin= max(1, fx(i) - bsize);
                        axmax= min(size(subcell,1), fx(i) + bsize);
                        aymin= max(1, fy(i) - bsize);
                        aymax= min(size(subcell,2), fy(i) + bsize);
                        avp(j,i)= mean2(subphcell(axmin:axmax, aymin:aymax));
                        avs(j,i)= mean2(originalsubcell(axmin:axmax, aymin:aymax));
                    end
                    j= j+1;
                end
                % normalize 
                avs= mean(avs)/median(median(avs));
                avp= mean(avp)/median(median(avp));


                % find local maxima in phase (potential points to be cut)
                maxpts= [];
                for i= 1 + maxdist:length(avp) - maxdist
                    if (avp(i - maxdist) < avp(i)) & (avp(i + maxdist) < avp(i))
                        maxpts= [maxpts i];
                    end
                end 
                if ~isempty(maxpts)
                    % maxpts contains multiple points for each maximum
                    % find boundaries between sets of points
                    maxboundaries= unique([1 find(diff(maxpts) > diffthresh) length(maxpts)]);

                    if length(maxpts) == 1
                        maxs{k}= maxpts;
                        % measure steepness of maximum
                        maxsc{k}= mean([avp(maxs{k}) - avp(maxs{k}-maxdist),...
                                avp(maxs{k}) - avp(maxs{k}+maxdist)]);
                    else
                        % each maximum is the average of each set of points associated with it
                        for i= 2:length(maxboundaries)
                            submaxpts= maxpts(maxboundaries(i-1) + 1:maxboundaries(i));
                            [av2m, av2mi]= max(avp(submaxpts));
                            maxs{k}(i-1)= submaxpts(av2mi);
                            % measure steepness of maximum
                            maxsc{k}(i-1)= mean([avp(maxs{k}(i-1)) - avp(maxs{k}(i-1)-maxdist),...
                                    avp(maxs{k}(i-1)) - avp(maxs{k}(i-1)+maxdist)]);
                        end
                    end

                    % choose steep maxima only
                    cutptsmax{k}= [maxs{k}(find(maxsc{k} > maxthresh))];
                else
                    cutptsmax{k}= [];
                    maxsc{k}= [];
                end




                % find local minima in segmented (potential points to be cut)
                minpts= [];
                for i= 1 + mindist:length(avs) - mindist
                    if (avs(i - mindist) > avs(i)) & (avs(i + mindist) > avs(i))
                        minpts= [minpts i];
                    end
                end 
                if ~isempty(minpts)
                    % minpts contains multiple points for each minimum
                    % find boundaries between sets of points
                    minboundaries= unique([1 find(diff(minpts) > diffthresh) length(minpts)]);

                    if length(minpts) == 1
                        mins{k}= minpts;
                        % measure steepness of minimum
                        minsc{k}= mean([avs(mins{k}-mindist) - avs(mins{k}),...
                                avs(mins{k}+mindist) - avs(mins{k})]);
                    else
                        % each minimum is the average of each set of points associated with it
                        for i= 2:length(minboundaries)
                            subminpts= minpts(minboundaries(i-1) + 1:minboundaries(i));
                            [av2m, av2mi]= min(avs(subminpts));
                            mins{k}(i-1)= subminpts(av2mi);
                            % measure steepness of minimum
                            minsc{k}(i-1)= mean([avs(mins{k}(i-1)-mindist) - avs(mins{k}(i-1)),...
                                    avs(mins{k}(i-1)+mindist) - avs(mins{k}(i-1))]);
                        end
                    end


                    % choose large minima only
                    cutptsmin{k}= [mins{k}(find(minsc{k} > minthresh))];
                else
                    cutptsmin{k}= [];    
                    minsc{k}= [];
                end


               % find cutpts
               cutpts{k}= unique([cutptsmin{k} cutptsmax{k}]);



                % CUT CELLS

                if ~isempty(cutpts{k})
                    % must cut cells

                    % sort cutpts in order of distance from centre of thin
                    [cs, csi]= sort(abs(cutpts{k} - round(length(fx)/2)));
                    cutpts{k}= cutpts{k}(csi);

                    cutx= fx(cutpts{k});
                    cuty= fy(cutpts{k});

                    % now divide the cell into seperate cells by cutting it across
                    perim= bwperim(imdilate(subcell, strel('disk',1)));

                    for i= 1:length(cutpts{k})

                        bsize= 8;
                        sxmin= max(1, cutx(i) - bsize);
                        sxmax= min(size(perim,1), cutx(i) + bsize);
                        symin= max(1, cuty(i) - bsize);
                        symax= min(size(perim,2), cuty(i) + bsize);
                        subperim= perim(sxmin:sxmax, symin:symax);
                        [subperim, noperims]= bwlabel(subperim);

                        % if noperims ~= 1  % JCR: noperims==0 causes problems below
                        if noperims > 1

                            % cutpt is not near end of cell. Go ahead and cut.
                            currcell= subcell;
                            [px, py]= find(subperim> 0);

                            % find distances to perimeter from cutpt
                            d= sqrt((px - bsize - 1).^2 + (py - bsize - 1).^2);
                            [ds, di]= sort(d);

                            % find first cutting point on perimeter
                            cutperim1x= px(di(1)) + sxmin - 1;
                            cutperim1y= py(di(1)) + symin - 1;
                            colour1= subperim(px(di(1)), py(di(1)));

                            % find second cutting point on perimeter
                            colour= colour1;
                            j= 2;
                            while colour == colour1
                                colour= subperim(px(di(j)), py(di(j)));
                                j= j+1;
                            end
                            cutperim2x= px(di(j-1)) + sxmin - 1;
                            cutperim2y= py(di(j-1)) + symin - 1;

                            % carry out cut 
                            subcell= VSegmentationsV1.drawline(currcell, [cutperim1x(1) cutperim1y(1)],...
                                [cutperim2x(1) cutperim2y(1)], 0);
                            subcell= bwlabel(subcell, 4);

                            % check cut
                            rf= regionprops(subcell, 'majoraxislength');
                            if min([rf.MajorAxisLength]) > mincelllength 
                                % accept cut if it has not created too small cells
                                currcell= subcell;
                            else
                                % ignore cut
                                subcell= currcell;
                            end

                        end
                    end   
                else

                    cutx= [];

                end

            end

            cutcell= zeros(size(cell));
            cutcell(xmin:xmax, ymin:ymax)= subcell;    


            % OUTPUT FIGURES

            % figure output
            if figs == 1

                figure; clf; 
                title(cellno);

                subplot(3,1,1);
                plot(1:length(avp), avp, 'b.', 1:length(avs), avs, 'k.');
                legend('phase','segmented',-1);
                xlabel(['cell number ', num2str(cellno)]);

                % plot phase and thin
                subplot(3,1,2);
                cutptsim= zeros(size(thin));
                if ~isempty(cutx)
                    for i= 1:length(cutx)
                        cutptsim(cutx(i), cuty(i))= 1;
                    end
                    imshow(thin);
                else 
                    imshow(segToRGB(thin, 'overlay', subphcell));
                end

                % plot output cell
                subplot(3,1,3);
                imshow(VTools.segToRGB(subcell)); % was Temp.imshowlabel(subcell);

                for i= 1:length(sx)-1
                    disp([num2str(i),': maxsc(',num2str(size(maxsc{i},2)),') ',num2str(maxsc{i})]);
                    disp([num2str(i),': minsc(',num2str(size(minsc{i},2)),') ',num2str(minsc{i})]);
                end
            end
        end        
        
        function bw2 = bwmorphmelow(bw1,operation,n)
            marg = 3;

            [fx,fy] = find(bw1);
            x1 = max(min(fx)-marg,1);
            x2 = min(max(fx)+marg,size(bw1,1));

            y1 = max(min(fy)-marg,1);
            y2 = min(max(fy)+marg,size(bw1,2));

            if nargin <= 2,
                Z = bwmorph(bw1(x1:x2,y1:y2),operation);
            else
                Z = bwmorph(bw1(x1:x2,y1:y2),operation,n);
            end

            bw2 = zeros(size(bw1));
            bw2(x1:x2,y1:y2) = Z;
        end        
       
        function [px, py] = walkthin(thin)
            thin2= zeros(size(thin)+2);
            thin2(2:end-1, 2:end-1)= thin;
            nopts= length(find(thin > 0));

            if nopts < 5
                px= [];
                py= [];
                return
            end

            % find spurs
            spur= thin2 & ~VSegmentationsV1.bwmorphmelow(thin2,'spur',1);
            [sx, sy]= find(spur);
            if isempty(sx)
                px= [];
                py= [];
                return
            end

            % find path
            i= 1; 
            px(1)= sx(1);
            py(1)= sy(1);
            while any(any(thin2)),

                thin2(px(i), py(i))= 0;
                [nx, ny]= VSegmentationsV1.neighbours(thin2, px(i), py(i));

                i= i+1;
                if length(nx) > 1
                    % pick closest
                    [~, dI]= min(sqrt((nx - px(i-1)).^2 + (ny - py(i-1)).^2));
                    px(i)= nx(dI);
                    py(i)= ny(dI);
                elseif length(nx) == 1
                    px(i)= nx(1);
                    py(i)= ny(1);
                else
                    break;
                end

                if i > nopts
                    break;
                end

            end

            px= px - 1;
            py= py - 1;
        end        
        
        function [nx, ny, colour]= neighbours(img, x, y, bsize)
            if nargin == 3
                bsize= 1;
            end
            colour= [];

            img2= zeros(size(img) + 2*bsize);
            img2(bsize+1:size(img2,1)-bsize, bsize+1:size(img2,2)-bsize)= img;

            bxmin= x;
            bxmax= x + 2*bsize;
            bymin= y;
            bymax= y + 2*bsize;
            subimg= img2(bxmin:bxmax, bymin:bymax);
            if bsize > 1
                subimg(2:2*bsize, 2:2*bsize)= zeros(2*bsize-1);
            end
            subimg(bsize+1, bsize+1)= 0;

            [nx, ny]= find(subimg > 0);
            for i= 1:length(nx)
                colour(i,1)= subimg(nx(i), ny(i));
            end

            nx= nx + bxmin - 1 - bsize;
            ny= ny + bymin - 1 - bsize;
        end        
        
        function newim = drawline(oldim,pt1,pt2,color)
            vec = [pt2(1) - pt1(1) , pt2(2)-pt1(2)];
            D = sqrt(sum(vec.^2));
            if (D==0)
              oldim(pt1(1),pt1(2)) = color;
            else
              for d = 0:0.25:D,
                thispt = round(pt1 + vec*d/D);
                oldim(thispt(1), thispt(2)) = color;
              end
            end
            newim = oldim;
        end        
        
    end
end
