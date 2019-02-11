classdef VMasks < VSettings & VData %% C
% VMasks Object that contains the masks of a VRegion. 
%
% VMasks are stored inside VRegion, and link back to current region is
% stored as a Transient property. When a mask is requested, it is checked whether it
% was calculated before, if not it is calculated now. Note that
% masks are stored in original rotation (Region.ADDITIONAL_ROTATIONS not added) 
%
% Within a VMasks there is saved:
% - settings
% - segmentations

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SUPER_SETTINGS =  { 'msk_class'                 , uint32(1), @VMasks ; ...
                                    'msk_imgType'               , uint32(1), {'p'} ; ...
                                    'msk_sigma'                 , uint32(1), 3; ...
                                    'msk_medFilt'               , uint32(1), 3; ...
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
        function obj = VMasks( region )
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
            % actual calculation of mask
            data = obj.region.regionmask.mask;
        end
        
        
        %% mask images %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function im = getMaskImage(obj, frame)
            % 2DO: settings could be different for this frame
            type = obj.get('msk_imgType');
            medFilt = obj.get('msk_medFilt');

            im = obj.region.getImage(frame, type);
            im = medfilt2(im, [medFilt medFilt]);
        end
        
        function imEdge = getMaskEdge(obj, frame)
            % 2DO: settings could be different for this frame
            sigma = obj.get('msk_sigma');
            
            im = obj.getMaskImage(frame);
            imEdge = edge(im, 'log', 0, sigma);
            
            % add boundary
            imEdge([1 end], 1:end) = 1;
            imEdge(1:end, [1 end]) = 1;
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
            imageType = obj.get('msk_imgType');
            if obj.region.position.images.isImage( idf, imageType)
                tf = true;
                return;
            end
            
            warning(['VMasks -> a mask for frame ' num2str(idf) ' cannot be calculated. Probably image does not exist.']);
        end
        
        function tf = doesDataNeedUpdating(obj, idf)
            rmsk_lastChange = obj.region.regionmask.get('rmsk_lastChange');
            tf = doesDataNeedUpdating@VData(obj, idf, rmsk_lastChange);
        end
        
        
        %% editing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function editByAddingPixel(obj, coor, frame)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            mask = obj.getData(frame);
            if ~obj.isCoorInMask(coor, mask)
                disp(['coordinates outside of area']);
                return;
            end

            mask(coor(1),coor(2)) = 1;
            obj.setData(uint16(frame(1)), mask);
        end
        
        function editByRemovingPixel(obj, coor, frame)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            mask = obj.getData(frame);
            if ~obj.isCoorInMask(coor, mask)
                disp(['coordinates outside of area']);
                return;
            end
            
            mask(coor(1),coor(2)) = 0;
            obj.setData(uint16(frame(1)), mask);
        end
        
        function editByAddingLine(obj, coor1, coor2, frame)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            mask = obj.getData(frame);
            if ~obj.isCoorInMask(coor1, mask) || ~obj.isCoorInMask(coor2, mask)
                disp(['coordinates outside of area']);
                return;
            end

            coor1 = double(coor1); 
            coor2 = double(coor2);
            mask = VSegmentations.drawline(mask, coor2 + [   0  0  ], coor1 + [   0  0  ], 1);
            obj.setData(uint16(frame(1)), mask);
        end        
        
        function editByRemovingLine(obj, coor1, coor2, frame)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            mask = obj.getData(frame);
            if ~obj.isCoorInMask(coor1, mask) || ~obj.isCoorInMask(coor2, mask)
                disp(['coordinates outside of area']);
                return;
            end
            
            coor1 = double(coor1); 
            coor2 = double(coor2);
            mask = VSegmentations.drawline(mask, coor2 + [   0  0  ], coor1 + [   0  0  ], 0);
            obj.setData(uint16(frame(1)), mask);
        end        
        
        function editByAddingArea(obj, maskAddition, frame)
            mask = obj.getData(frame);
            % 2DO: size checking
            
            mask( find(maskAddition) ) = 1;
            obj.setData(uint16(frame(1)), mask);
        end
        
        function editByRemovingArea(obj, maskRemoval, frame)
            % 2DO: size checking
            mask = obj.getData(frame);

            mask(maskRemoval) = 0;
            obj.setData(uint16(frame(1)), mask);
        end
        
        function editByAddingEdgefill(obj, coor, frame)
            mask = obj.getData(frame);
            % 2DO: size checking
            maskEdge = obj.getMaskEdge(frame);
            maskAddition = imfill( maskEdge, double(coor), 4) & ~maskEdge;
            maskAddition = imdilate(maskAddition, strel('disk',1)) & (maskAddition | maskEdge);
            
            mask( maskAddition ) = 1;
            obj.setData(uint16(frame(1)), mask);
        end
        
        function editByRemovingEdgefill(obj, coor, frame)
            mask = obj.getData(frame);
            % 2DO: size checking
            maskEdge = obj.getMaskEdge(frame);

            maskRemoval = imfill( maskEdge, double(coor), 4) & ~maskEdge;
            maskRemoval = imdilate(maskRemoval, strel('disk',1)) & (maskRemoval | maskEdge);

            mask(maskRemoval) = 0;
            obj.setData(uint16(frame(1)), mask);
        end
        
        function editByRemovingConnectedarea(obj, coor, frame)
            % note that coor should be in array coordinates (row, col), not in Vanellus coordinates (left, top)
            % check whether coordinates are within mask
            mask = obj.getData(frame);
            if ~obj.isCoorInMask(coor, mask)
                disp(['coordinates outside of area']);
                return;
            end
            
            % get labeled mask
            mask_label = bwlabel(mask, 4);
            mask_label(~mask) = 0;
            mask_label = max(mask(:)) * mask_label + mask;
            
            % selected clicked label
            clicked_label = mask_label( round(coor(1)), round(coor(2)) );
            maskRemoval = false(size(mask));
            maskRemoval( mask_label==clicked_label ) = 1;
            
            mask(maskRemoval) = 0;
            obj.setData(uint16(frame(1)), mask);
        end        
        
        function tf = isCoorInMask(obj, coor, mask)
            % check whether coordinates are within mask
            tf = false;
            if any(round(coor) >= [1 1]) && any(round(coor) <= size( mask ))
                tf = true;
            end
        end              
        
        function editByFillingHoles(obj, frame)
            mask    = obj.getData(frame);
            mask    = imfill(mask ,'holes');
            obj.setData(uint16(frame(1)), mask);
        end
        
        function editByClearingMask(obj, frame)
            mask    = false( obj.region.regionSize );
            obj.setData(uint16(frame(1)), mask);
        end
        
        function editByAddingEdges(obj, frame)
            mask            = obj.getData(frame);
            maskEdge        = obj.getMaskEdge(frame);
            maskAddition    = imdilate( mask & ~maskEdge, strel('disk',1) ) & maskEdge;
            mask            = mask | maskAddition;
            obj.setData(uint16(frame(1)), mask);
        end   

        
        %% ?? %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = calcMasks(obj, frames)
            if nargin < 2
                frames = obj.frames;
            end
            tf = false;
            
            try 
                textprogressbar('VMasks -> calculating masks: '); tic;
                for i = 1:length(frames)
                    obj.calcAndSetData( frames(i) );
                    textprogressbar( i/length(frames) );
                end
                textprogressbar([' DONE in ' num2str(round(toc,1)) ' sec']);

                tf = true;
            catch
                warning(['VMasks -> error while calculation masks.']);
            end
        end         
        
        function nrSetMasks = getNrSetMasks(obj)
            nrSetMasks = obj.getNrData();
        end             
        
    end
    
    methods (Static)
%         %% mask %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         function mask = calcMask(obj, frame, settings)
%             % actual calculation of mask
%             mask = obj.removePaddingFromMask(obj.regionMask, settings.get('msk_padding') );
%         end
%         
%         function mask = removePaddingFromMask(obj, mask, padding)
%             mask = imerode(mask, strel('disk',padding));
%         end        
% 
%         function mask = removeRegionPaddingFromMask(obj, mask, padding)
%             paddingMask     = logical( ones( size(mask) ) );
%             paddingWidth    = min(padding, ceil(0.5*size(mask,1)) );
%             paddingHeigth   = min(padding, ceil(0.5*size(mask,2)) );
%             
%             paddingMask(1:paddingWidth        ,:) = false;
%             paddingMask(end-paddingWidth+1:end,:) = false;
%             paddingMask(:                     ,1:paddingHeigth) = false;
%             paddingMask(:                     ,end-paddingHeigth+1:end) = false;
%             
%             mask = mask & paddingMask;
%         end
    end
    
    %% FOR TRANSITION PHASE TO NEW VREGION STRUCTURE %%%%%%%%%%%%%%%%%%%%%%
    properties (Transient, Hidden) % not stored, hidden
        temp_segmentations
    end     
     
    methods (Static)
        function obj = loadobj(s) % hidden
            if isstruct(s)
                obj = VMasks( [] );
                obj.settings = s.settings;
                obj.dataArray = s.dataArray;
                obj.dataArrayIdf = s.dataArrayIdf;
                obj.dataArrayLength = s.dataArrayLength;
                obj.Idf2Idx = s.Idf2Idx;
                
                obj.temp_segmentations = s.segmentations;
            else
                obj = s;
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end