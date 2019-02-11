classdef VSegmentationsPad < VSegmentations
% VSegmentationsPad

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SETTINGS =  {   'seg_magnification'         , uint32(1), 1          ; ...
                                'seg_imreconstruct'         , uint32(1), 0          ; ...
                                'seg_imdilate'              , uint32(1), 0          ; ...
                                'seg_minCellLength'         , uint32(1), 30         ; ...
                                'seg_minCellLength'         , uint32(1), 30         ; ...
                                'seg_minCellArea'           , uint32(1), 100        ; ...
                                'seg_minBgFraction'         , uint32(1), 0.5        ; ...

                                'seg_maxCellArea'           , uint32(1), 2000       ; ...

                                'seg_minDepth'              , uint32(1), 5          ; ...
                                'seg_neckDepth'             , uint32(1), 3          ; ...
                                'seg_maxThresh'             , uint32(1), 0.025      ; ...
                                'seg_minThresh'             , uint32(1), 0.025      ; ...
                                'seg_longCellLength'        , uint32(1), 70         };
    end
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VSegmentationsPad( region )
            obj@VSegmentations( region ); 
        end
        
        %% segmentation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = calcData(obj, idf)
            % actual calculation of segmentation
            segSize                 = obj.region.regionSize;
            data                    = uint16( zeros( segSize ) );

            % make sure that idf can be segmented
            if ~obj.canDataBeCalculated(idf), return; end

            % get settings
            seg_magnification       = obj.get('seg_magnification');
            seg_sigma               = obj.get('seg_sigma');
            seg_imdilate            = obj.get('seg_imdilate');
            seg_minCellArea         = obj.get('seg_minCellArea');
            seg_minCellLength       = obj.get('seg_minCellLength');
            seg_minBgFraction       = obj.get('seg_minBgFraction');
            
            mask = obj.region.getMask( idf );
            mask                    = imresize( mask, seg_magnification, 'nearest');
            
            im6                     = obj.getSegImage( idf(1) );
        	im7                 	= imdilate(im6, strel('disk', seg_imdilate));
            edgeImFull              = edge(im7, 'log', 0, seg_sigma);
            edgeIm                  = edgeImFull & mask;
            seg1                    = bwlabel( imcomplement(edgeIm), 4);
            r                       = regionprops( seg1, 'Area');
            bgObject                = find( [r.Area] == max([r.Area]) );
            seg2                    = seg1;
            seg2(seg1==bgObject)    = 0;
            seg2(seg1==0)           = bgObject;
            seg2(find(edgeIm))      = 0;
            
            seg3                    = VSegmentations.doForEachCell( seg2, @(x) bwareaopen(x, seg_minCellArea, 4));
            seg4                    = seg3;
            r                       = regionprops( seg4, 'majoraxislength');
            for i = 1:length(r)
                if r(i).MajorAxisLength < seg_minCellLength
                    seg4(seg4 == i) = 0;
                end
            end
            
            seg5                    = VSegmentations.doForEachCell( seg4, @(x) VSegmentations.imfillWithMaxSize(x, seg_minCellArea)); % was 20
            seg6                    = seg5;
            seg6(~mask)             = 0;
            seg7                    = seg6;
            maskBg                  = imdilate(+seg7, strel('disk',8)) & mask & ~imdilate(+seg7, strel('disk',2));
            Bg_min                  = min( im6( maskBg ) );
            Bg_max                  = max( im6( maskBg ) );
            
            area_nrs = unique(seg7)';
            for c = area_nrs(area_nrs~=0)
                area_min = min( imerode( im6( seg7==c ), strel('disk',4)));
                if area_min < Bg_min + seg_minBgFraction * (Bg_max - Bg_min)
                    seg7( seg7==c ) = 0;
                end                
            end
            
            seg8 = seg7;
            area_nrs = unique(seg8)';
            for c = area_nrs(area_nrs~=0)
                c0 = (seg8==c);
                c1 = imdilate( c0, strel('disk',4));
                c2 = imdilate( c1, strel('disk',4));
                seg8_wihtoutcell = seg8;
                seg8_wihtoutcell(seg8==c) = 0;
                c2inOtherCells = seg8_wihtoutcell & c2;
                nrEdgePixels1 = numel(find(c1)) - numel(find(c0));
                nrEdgePixels2inOtherCells = numel(find(c2inOtherCells));
                [nrEdgePixels1 nrEdgePixels2inOtherCells];
                if nrEdgePixels2inOtherCells > 0.9 * nrEdgePixels1
                    seg8( seg8==c ) = 0;
                end                    
            end
            
            SEG_9_seeds1 = seg8 & ~edgeIm;
            SEG_9_seeds2 = bwmorph(SEG_9_seeds1,'open');
            SEG_9_seeds2 = bwmorph(SEG_9_seeds2,'thin',inf);

            SEG_10_seeds2 = SEG_9_seeds2;
            SEG_10_seeds2 = bwmorph(SEG_10_seeds2,'spur',3);
            SEG_10_seeds2 = bwareaopen(SEG_10_seeds2,10,8);

            SEG_11_seeds2 = SEG_10_seeds2;
            icut = SEG_11_seeds2;
            continueToCut = true;
            while continueToCut
                [cellsToRemove, cutPoints] = VSegmentationsV1.PN_CutLongCells(icut, seg8, obj.get('seg_neckDepth'));
                if max(max(cutPoints))==0
                    continueToCut = false;
                else
                    cutPoints = bwmorph(cutPoints,'dilate',2);
                    SEG_11_seeds2(cutPoints) = false; %cuts the long cells on the seeds image
                    icut(cutPoints) = false;
                    icut = icut & ~cellsToRemove;
                end
            end
            
            SEG_12_filledEdges = bwmorph(seg8, 'dilate');
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

            seg10=SEG_12_segmentedImage;

            seg11 = seg10;
            r = regionprops( seg10, 'majoraxislength' );
            fbiggies = find(([r.MajorAxisLength] > obj.get('seg_longCellLength'))); 
            for j = 1:length(fbiggies)
                Lcell = +(seg10 == fbiggies(j)); % + converts logical to double
                Lcell(Lcell == 1)= fbiggies(j);
                cutcell = VSegmentationsV1.breakcell(Lcell, im6, obj.get('seg_maxThresh'), obj.get('seg_minThresh'), obj.get('seg_minCellLength')); %DJK 2013-09-26 add 1 to see figures
                seg11(seg10 == fbiggies(j))= 0;
                cellnos = unique(cutcell);  
                label = max(max(seg11));
                for k = 2:length(cellnos)
                    seg11(find(cutcell == cellnos(k)))= label+k;
                end
            end            
            
            seg12                   = imdilate( seg11, strel('diamond',1) );
            
            seg13                   = VSegmentationsV1.renumberSegmentation(seg12);

            seg14                   = VSegmentations.doForEachCell( seg13, @(x) VSegmentations.imfillWithMaxSize(x, seg_minCellArea)); % was 20
            
            seg15                   = imresize( seg14, 1/seg_magnification, 'nearest');

            data                    = uint16(seg15);
        end
        
        function im = getSegImage(obj, frame)
            types                   = obj.get('seg_imgType');
            seg_magnification       = obj.get('seg_magnification');
            seg_medFilt             = obj.get('seg_medFilt');
            seg_imreconstruct       = obj.get('seg_imreconstruct');

            for j = 1:length( types )
                im(:,:,j)           = obj.region.getImage( frame, types(j)); % useAddRot = false 
            end
            im1                     =  mean( im(:, :, :), 3);
            
            im2                     = VSegmentationsV1.scaleImage( im1 );
            
            im3                     = imresize( im2, seg_magnification, 'bilinear');

            im4                     = medfilt2( im3, [seg_medFilt seg_medFilt]);
            
            im5                     = imcomplement( im4);

	    	im                      = imreconstruct(imerode(im5, strel('disk',seg_imreconstruct)), im5);            
        end
        
        function imEdge = getSegEdge(obj, frame)
            seg_sigma               = obj.get('seg_sigma');
            seg_imdilate            = obj.get('seg_imdilate');

            im6                     = obj.getSegImage( frame );
            
        	im7                 	= imdilate(im6, strel('disk', seg_imdilate));
            
            imEdge                  = edge(im7, 'log', 0, seg_sigma);
        end        
        
    end
end