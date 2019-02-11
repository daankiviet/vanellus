classdef VRegionmaskFlow < VRegionmask
% VRegionmaskFlow

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SETTINGS = {    'rmsk_class'            , uint32(1), @VRegionmaskFlow ; ...
                                'rmsk_sigma'            , uint32(1), 3 ; ...
                                'rmsk_medFilt'          , uint32(1), 1 ; ...
                                'rmsk_numPyramidLevels' , uint32(1), 1 ; ...
                                'rmsk_minFlow'          , uint32(1), 0.33 };
    end

    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VRegionmaskFlow( region )
            obj@VRegionmask( region ); 
        end

        %% calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function regionmask = calcRegionmask(obj)
            % make sure that avIM and and avIm_edge are up to date
            obj.updateAvImage();

            % actual calculation of region mask
            regionmask          = false( obj.region.regionSize );

            % GET BASIC SETTINGS
            numPyramidLevels    = obj.get('rmsk_numPyramidLevels');
            rmsk_minFlow        = obj.get('rmsk_minFlow');
            
            % prepare stuff
            opticFlow           = opticalFlowFarneback( 'NumPyramidLevels', numPyramidLevels);
            normFlow            = zeros( obj.region.regionSize );

            % show flow when DEBUGGING
            if obj.get('van_DEBUG')
                hFig = figure; 
                cColormap = parula; 
                cColormap(end,:) = [1 1 1]; 
            end
            
            % loop over all frames
            textprogressbar('VRegionmaskFlow -> checking flow in frames: '); tic;
            for i = 1:length(obj.frames)
                im = obj.region.getImage( obj.frames(i), []);
                flow = estimateFlow( opticFlow, uint8( double(im) .* (double(intmax('uint8'))/double(max(max(im)))) ));
                normFlow = normFlow + flow.Magnitude;
                textprogressbar( i/length(obj.frames) );
                
                if obj.get('van_DEBUG')
                    tempIm = imerode(normFlow, strel('disk',10));
                    tempIm(obj.avIm_edge) = max(max(tempIm)); 
                    figure(hFig);
                    imshow( tempIm, cColormap ); 
                end
            end
            textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);
            
            % normalize
            normFlow = normFlow / max(normFlow(:));

            % fill holes in edge with a low of movement
            holes = imcomplement(obj.avIm_edge);
            areas = bwlabel(holes, 4);
            area_nrs = unique(areas)';
            for a = area_nrs(area_nrs~=0)
                idx = find(areas == a);
                avFlow = mean(normFlow(idx));
                if avFlow > rmsk_minFlow
                    regionmask(idx) = true;
                end
            end
            
            % close DEBUG figure
            if obj.get('van_DEBUG'), close(hFig); end
            
            % add edge
            regionmask_dilated  = imdilate(regionmask, strel('disk',1));
            regionmask          =  regionmask | (regionmask_dilated & obj.avIm_edge);            
            
            % fill mask
            regionmask          = imfill(regionmask, 'holes');
            
            % make sure is logical
            regionmask = logical( regionmask );
        end
        
    end
end
