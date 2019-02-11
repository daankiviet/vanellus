classdef VImagesCellSens < VImages
% VImagesCellSens -> Object that links VImages to CellSens vsi files of
% position on harddisk. Multiple types per vsi file are NOT allowed
%
% Expects files to have this filename format:
% - "pos2-p-A1.vsi" , "pos2-g-A1.vsi" or "pos2-g1-A1.vsi" for different image types / layers (in this case p, g and g1)
% - if frames are collected in seperate files -> -A1.vsi & -B1.vsi

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        DEFAULT_SETTINGS  = { };
    end
    
    properties
        fileReference       % fileReference( frame, type ) = { filename , iPlane }
    end
    
    properties (Transient) % not stored
%         reader
    end    
    
    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VImagesCellSens(position)
            obj@VImages(position); 
        end
        
        function tf = update(obj, position) 
            if nargin > 1, obj.position = position; end

            tf = false;
            
            imgFolder               = obj.position.get('img_folder');
            position_name               = VTools.getFoldername( obj.position.filename );
            
            image_listing = struct.empty;
            % collect pos1-py-A1.vsi type filenames if imageFolder exists
            if VTools.isFolder( imgFolder )
                image_listing = dir([imgFolder position_name '-*-*.vsi']);
            end
                
            if ~isempty(image_listing)
                % get unique names (alphabetically sorted)
                filenames       = unique( {image_listing.name} );
                
                % convert to cell array of filename parts
                filenames_part  = regexp(filenames, '[-.]', 'split');
                filenames_part  = vertcat(filenames_part{:});

                % get unique types, order them according to img_typeOrder and set types 
                all_types = unique( filenames_part(:,2) ,'stable' )';
                img_typeOrder = obj.get('img_typeOrder');
                if isempty(img_typeOrder), img_typeOrder = {}; end
                [~, idx] = ismember(all_types, img_typeOrder);
                idx_0 = find(idx==0);
                idx( idx==0 ) = max(idx)+1:max(idx)+length(idx_0);
                [~,idx_sort] = sort(idx);
                all_types = all_types(idx_sort);
                obj.types = all_types;
                
                % sort on 'A1' (1st) and types (2nd)
                [~, idx] = ismember(filenames_part(:,2), obj.types);
                filenames_part(:,5) = num2cell(idx);
                [filenames_part,idx] = sortrows( filenames_part, [3 5] );
                filenames = filenames(idx);
                
                % keep track of which frame we are at
                lastFrameSoFar = 0; lastLetterSoFar = 'A'; nrFrames = 0;
                images_cellSens_frameOffset = obj.position.get('img_frameOffset');
                if ~isempty(images_cellSens_frameOffset)
                    lastFrameSoFar = lastFrameSoFar + images_cellSens_frameOffset;
                end
                
                % loop over files, should be sorted already A1 - B1 etc
                for fileNr = 1:size(filenames_part,1)
                    % update lastFrameSoFar
                    if ~strcmp( filenames_part{fileNr,3}(1), lastLetterSoFar)
                        lastFrameSoFar = lastFrameSoFar + nrFrames;
                    end
                    lastLetterSoFar = filenames_part{fileNr,3}(1);
                    
                    % extract type from filename
                    currentType = filenames_part{fileNr,2};
                    currentTypeIdx = find( ismember(obj.types, currentType));
                    
                    % load file and extract nrFrames and nrTypes from it
                    reader = bfGetReader([imgFolder filenames{fileNr}]);
                    nrFrames = reader.getSizeT; % frames
                    nrTypes = reader.getSizeC; % types
                    if nrTypes > 1
                        warning(['VImagesCellSens: file contains ' num2str(nrTypes) ' different types, use VImagesCellSensMultitype instead']); 
                    end
                    % NOT USED: width = reader.getSizeX; height = reader.getSizeY; nrLayers = reader.getSizeZ
                    
                    % update imageExist
                    frameNrs = [1:nrFrames] + lastFrameSoFar;
                    obj.imageExist(frameNrs, currentTypeIdx) = true;
                    
                    % update fileReference( frame, type ) = { filename , iPlane }
                    serie = 1;
                    ty = 1;
                    for fr = 1:nrFrames
                        frameNr = fr + lastFrameSoFar;
                        iPlane = reader.getIndex( serie - 1, ty -1, fr - 1) + 1;
                        obj.fileReference{ frameNr, currentTypeIdx} = {filenames{fileNr}, iPlane};
                    end
                    
                    reader.close();
                end
  
            else
                warning off backtrace;
                warning(['VImagesCellSens -> cannot find any ' position_name '-*-*.vsi images in folder ' imgFolder]);
                warning on backtrace;
            end
            
            % postprocessing steps by calling supercall VImages
            update@VImages(obj);
        end
        
        %% images %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [im, success] = readImage(obj, frame, type)
            % input checking
            if nargin < 2, frame    = []; end
            if nargin < 3, type     = ''; end

            success = true;
            
            % if frame and typeIdx don't make sense, give warning and return VImages.readImage()
            if isempty(frame) || isempty(type) || ~obj.isImage( frame, type )
                warning off backtrace;
                warning(['VImagesCellSens.readImage() -> requested image (frame=' num2str(frame) ' type=''' type ''') does not seem to exist.']);
                warning on backtrace;
                [im, success] = readImage@VImages(obj, frame, type);
                return;
            end
            
            try
                % get file and plane reference
                typeIdx         = obj.getTypeIdx( type );
                fileRef         = obj.fileReference{ frame, typeIdx };
                filename        = [obj.parent.get('img_folder') fileRef{1} ];
                iPlane          = fileRef{2};

                if VTools.isFile( filename )
                    reader      = bfGetReader(filename);

                    % actual reading of image
                    im      = bfGetPlane(reader, iPlane);

                    reader.close();
                    return;
                else
                    warning off backtrace;
                    warning(['VImagesCellSens.readImage() -> cannot load image from file: ' filename]);
                    warning on backtrace;
                end
            catch
                warning off backtrace;
                warning(['VImagesCellSens.readImage() -> error while trying to load image (frame=' num2str(frame) ' type=''' type ''' in: ' obj.parent.get('img_folder')]);
                warning on backtrace;
            end
            
            % did not manage to read image, so returning VImages.readImage()
            [im, success] = readImage@VImages(obj, frame, type);
        end
    end
end