classdef VImagesTiff < VImages
% VImagesTiff Object that contains all information of Tiff images. Names
% of tiff files should be formatted like in Schnitzells: "pos1-p-0001.tif",
% "pos1-y-0001.tif", "pos1-p-0002.tif", etc. 
%
% The update script stores information about detected images in:
% obj.frames                        (in parent VImages)
% obj.types                         (in parent VImages)
% obj.imageExist                    (in parent VImages)
% obj.images_schnitzcells_baseName  (locally)

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        % HERE YOU DEFINE DEFAULT SETTINGS. THESE CAN BE OVERRULED BY USER SETTINGS
        DEFAULT_SETTINGS  = { 'img_schnitzcells_leading0' , uint32(1), 4 };
    end
    
    properties
        images_schnitzcells_baseName
    end

    methods
        %% loading and saving %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = VImagesTiff(position)
            % DO NOT EDIT ANYTHING HERE
            obj@VImages(position); 
        end
        
        %% updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = update(obj, position)
            % THERE ARE TWO FUNCTIONS THAT NEED TO BE IMPLEMENTED. THIS IS
            % THE FIRST, WHICH 'UPDATES' THE IMAGES. WHEN THIS FUNCTION IS
            % CALLED, THIS SCRIPT WILL SEARCH FOR IMAGE FILES, AND KEEP A
            % REFERENCE TO THEM

            % tf (true/false) will be returned, indicating whether images
            % were successfully found or not.
            tf = false;

            % DO NOT CHANGE THIS FOLLOWING LINE
            if nargin > 1, obj.position = position; end
            
            % the script will look in this folder for images
            imgFolder = [   obj.get('img_folder') filesep ...
                            VTools.getFoldername(obj.position.filename) filesep];
            
            % collect tif filenames if imageFolder exists
            image_listing = struct.empty;
            if VTools.isFolder( imgFolder )
                image_listing = dir([imgFolder '*-*-*.tif']);
            end
            
            % if image were found, check which ones exist and keep a
            % reference to them
            if ~isempty(image_listing)
                % get parts from filenames that indicate what image each file is
                [pos, types, frames]                = VImagesTiff.imageparts( {image_listing.name} );
                
                % order types according to img_typeOrder
                uniqueTypes         = unique(types);
                img_typeOrder       = obj.get('img_typeOrder');
                if isempty(img_typeOrder), img_typeOrder = {}; end
                [~, idx]            = ismember(uniqueTypes, img_typeOrder);
                idx_0               = find(idx==0);
                idx( idx==0 )       = max(idx)+1:max(idx)+length(idx_0);
                [~,idx_sort]        = sort(idx);
                uniqueTypes         = uniqueTypes(idx_sort);
                
                % store this information locally
                obj.frames                          = unique( uint16(str2double(frames)) );
                obj.types                           = uniqueTypes;
                obj.images_schnitzcells_baseName    = pos{1};
                
                % determine which images exist -> update imageExist
                obj.imageExist                      = false([max(obj.frames) length(obj.types) ]);
                for i = 1:length(image_listing)
                    % convert type to typeIdx
                    typeIdx                         = obj.getTypeIdx( types{i} ); % function defined in parent VImages
                    frame                           = uint16( str2double(frames{i}) );
                    obj.imageExist( frame, typeIdx) = 1;
                end
                
                % DO NOT CHANGE THE FOLLOWING 2 LINES
                % postprocessing steps by calling supercall VImages
                tf = update@VImages(obj);
            else
                % in case no image files were found, a warning is given
                warning(['VImagesTiff -> cannot find any *-*-*.tif images in folder ' imgFolder]);
            end
        end
        
        
        %% images %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [im, success] = readImage(obj, frame, type )
            % THIS IS THE 2ND FUNCTION THAT NEEDS TO BE IMPLEMENTED. IT
            % LOAD AND RETURNS A REQUESTED IMAGE.
            
            success = true;

            % convert type to typeIdx
            typeIdx     = obj.getTypeIdx( type );
            
            if obj.imageExist( frame, typeIdx )
                
                imgFolder   = [ obj.get('img_folder') filesep ...
                                VTools.getFoldername(obj.position.filename) filesep];
                            
                images_schnitzcells_leading0    = obj.get('img_schnitzcells_leading0');
                
                filename    = [ imgFolder obj.images_schnitzcells_baseName ...
                                '-' obj.types{typeIdx} '-' ...
                                VTools.str(frame, 'leadingZeros', images_schnitzcells_leading0) '.tif'];
                            
                if VTools.isFile( filename )
                    try
                        im = uint16( imread(filename) );
                        return;
                    catch
                        warning(['VImagesTiff -> problem reading image (frame=' num2str(frame) ' type=' num2str(type) ' from filename: ' filename]);
                    end
                end
            end
            warning(['VImagesTiff -> requested image (frame=' num2str(frame) ' type=' num2str(type) ' does not seem to exist in ' imgFolder]);
            [im, success] = readImage@VImages(obj, frame, type );
        end
        
    end
    
    %% static methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods(Static = true)
        function [pos, type, frames] = imageparts(name)
        % breaks down image name into parts
        
            % in case only a single name is provided, convert to cell first
            if ischar(name), name = {name}; end
        
            if isempty(name) % IF NAME IS EMPTY, RETURN EMPTY
                disp('VImagesTiff.imageparts: input name was empty -> probably filename does not exist');
                pos = ''; type = ''; frames = ''; 
                return;
            end
    
            for i = 1:size(name,2)
                [~, nameWithoutExtension{i}, ~] = fileparts(name{i});
            end

            for i = 1:size(nameWithoutExtension,2)
                idx         = strfind(nameWithoutExtension{i}, '-');

                if length(idx) < 2
                    disp('VImagesTiff.imageparts: input name does not have two - in there');
                    pos = ''; type = ''; frames = ''; 
                    return;
                end
                
                pos{i}      = nameWithoutExtension{i}(1:idx(1)-1);
                type{i}     = nameWithoutExtension{i}(idx(1)+1:idx(end)-1);
                frames{i}   = nameWithoutExtension{i}(idx(end)+1:end);
            end
        end     
    end
end
