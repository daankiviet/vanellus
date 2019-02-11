classdef VAnnotations < VSettings & VData %% C
% VAnnotations Object that contains the annotations of a VRegion. 

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SUPER_SETTINGS  = { 'ann_class'                 , uint32(1), @VAnnotations ; ...
                                    'ann_initAnnotationIdx'     , uint32(1), 0 ; ...
                                    'ann_minPixelSpacing'       , uint32(1), 10 ; ...
                                    'ann_fontSize'              , uint32(1), 8 ; ...
                                  };
        SUPER_ANNOTATION_TYPES        = { 'division' };
        SUPER_ANNOTATION_COLORS       = { [1.0 0.0 0.0] };
        SUPER_ANNOTATION_DESCRIPTIONS = { 'Division of cell (first frame it is divided)' };
    end

    properties
        settings
        locations       % locations(cellNr) = [x_coor y_coor]
    end

    properties (Transient) % not stored
        region
        isSaved
    end
    
    properties (Dependent) % calculated on the fly
        parent
        frames
        cellNrs
        
        annotationTypes
        annotationColors
        annotationDescriptions
    end    
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VAnnotations( region )
            obj.settings            = {};
            obj.locations           = [];
            
            obj.update(region);
        end
       
        function update(obj, region)
            obj.region              = region;
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
            cellNrs = [];
            if size(obj.locations,2) ~= 2, return; end
            
            for i = 1:size(obj.locations,1)
                if obj.locations(i,1) ~= 0 && obj.locations(i,2) ~= 0
                    cellNrs = [cellNrs i];
                end
            end
        end         
        
        function annotationTypes = get.annotationTypes(obj)
            if isprop(obj,'ANNOTATION_TYPES')
                annotationTypes = obj.ANNOTATION_TYPES;
            else
                annotationTypes = obj.SUPER_ANNOTATION_TYPES;
            end
        end         
        
        function annotationColors = get.annotationColors(obj)
            if isprop(obj,'ANNOTATION_COLORS')
                annotationColors = obj.ANNOTATION_COLORS;
            else
                annotationColors = obj.SUPER_ANNOTATION_COLORS;
            end
        end         

        function annotationDescriptions = get.annotationDescriptions(obj)
            if isprop(obj,'ANNOTATION_DESCRIPTIONS')
                annotationDescriptions = obj.ANNOTATION_DESCRIPTIONS;
            else
                annotationDescriptions = obj.SUPER_ANNOTATION_DESCRIPTIONS;
            end
        end

        
        %% calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = calcData(obj, idf)
            % calculation of annotation not implemented
            data = uint8( zeros( [1 max(obj.frames)] ) );
        end
        
    end
    
    methods (Sealed)
        %% calculations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = canDataBeCalculated(obj, idf)
            tf = false;

            % check whether idf is valid cellNr
            if ~ismember(idf, obj.cellNrs),     return; end

            tf = true;
        end
        
        function ann = getAnnotation(obj, cellNr, frame)
            % if cellNr does not exist, cancel
            if ~ismember(cellNr, obj.cellNrs)
                disp(['VAnnotations.getAnnotation : cellNr does not exists. Cancelling!']);
                return;
            end

            % if frame is outside frames, cancel
            if ~ismember(frame, obj.frames)
                disp(['VAnnotations.getAnnotation : frame is outside frames. Cancelling!']);
                return;
            end
            
            % get annotations
            annCellNr = obj.getData( cellNr );
            ann = annCellNr( frame );
        end

        %% editing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function cellNr = addCellNr(obj, coor, cellNr)
            % note that coor are in region array coordinates (row, col)
            
            % if cellNr is not given, create new one
            if nargin < 3
                cellNr = size(obj.locations,1) + 1;
            end
            
            % if cellNr already exist, cancel
            if ismember(cellNr, obj.cellNrs)
                disp(['VAnnotations.addCellNr : cellNr already exists. Cancelling!']);
                cellNr = [];
                return;
            end

            % if another cellNr is to closeby, cancel
            [~, distance] = obj.findClosestCellNr( coor );
            if ~isempty(distance) && distance < obj.get('ann_minPixelSpacing')
                disp(['VAnnotations.addCellNr : another cellNr to closeby. Cancelling!']);
                cellNr = [];
                return;
            end
            
            % store cellNr
            obj.locations(cellNr,:) = coor;
            obj.isSaved = false;
            obj.calcAndSetData( cellNr );
            disp(['VAnnotations.addCellNr : added cellNr ' num2str(cellNr)]);
        end

        function tf = deleteCellNr(obj, cellNr)
            tf = false;
           
            % if cellNr is not given, cancel
            if nargin < 2 
                disp(['VAnnotations.deleteCellNr : cellNr not given. Cancelling!']);
                return;
            end
            
            % if cellNr does not exist, cancel
            if isempty(cellNr) || ~ismember(cellNr, obj.cellNrs)
                disp(['VAnnotations.deleteCellNr : cellNr does not exist. Cancelling!']);
                return;
            end
            
            % actual deletion
            obj.locations(cellNr,:) = [0 0];
            obj.unsetData( cellNr );
        
            % remove empty locations at end
            for i = size(obj.locations,1):-1:1
                if obj.locations(i,1) ~= 0 && obj.locations(i,2) ~= 0 
                    break
                end
                obj.locations(i,:) = [];
            end
            
            obj.isSaved = false;
            tf = true;
        end
        
        function editAnnotation(obj, cellNr, frame, ann)
            % if cellNr does not exist, cancel
            if ~ismember(cellNr, obj.cellNrs)
                disp(['VAnnotations.addAnnotation : cellNr does not exists. Cancelling!']);
                return;
            end

            % if frame is outside frames, cancel
            if ~ismember(frame, obj.frames)
                disp(['VAnnotations.addAnnotation : frame is outside frames. Cancelling!']);
                return;
            end
            
            % get old annotations
            anns = obj.getData( cellNr );
            
            % add new annotation
            anns(frame) = uint8(ann);
            
            % store new annotations
            obj.setData( cellNr, anns);
        end
        
        function [cellNr, distance] = findClosestCellNr( obj, coor )
            cellNr = [];
            distance = [];
            
            % if no cellNrs, return
            if size( obj.locations, 2) ~= 2, return; end
            if isempty( obj.cellNrs ), return; end
            
            % calc distances
            distances = sqrt( sum( (obj.locations - double(coor)).^2, 2) );
            
            % set [0 0] location to max value
            idx_empty = find(obj.locations(:,1)==0 & obj.locations(:,2)==0);
            distances( idx_empty ) = realmax;
            
            % find closest
            [distance, cellNr] = min( distances );
        end
        
    end
end
