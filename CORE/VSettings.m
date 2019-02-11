classdef (Abstract) VSettings < handle %% C
% VSettings Object for handling and storing settings in other
% Objects (Vanellus, VExperiment, VPosition, VRegion). 

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Abstract)
        settings % cell array { 'prop', uint32(timestamp), val ; ... next }
    end
    
    properties (Abstract, Transient) % not stored
        isSaved
    end    
    
    properties (Abstract, Dependent, Hidden) % calculated on the fly
        parent
    end
    
    methods (Sealed)
        
        %% settings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = set(obj, prop, val)
            tf = false;
            
            % check whether prop is char
            if ~ischar( prop ), return; end
            
            idx = obj.getPropIdx(prop);

            if isempty( idx ) 
                % instead of overwriting, add to end of settings
                idx = size(obj.settings,1) + 1;
                obj.settings{ idx(1), 1} = prop;
            else
                % in case of overwriting, check whether nothing changes, in which case do nothing (-> don't change timestamp)
                if isequal( val, obj.settings{ idx(1), 3} )
                    return;
                end
            end
                
            obj.settings{ idx(1), 3} = val;
            obj.settings{ idx(1), 2} = VTools.getUnixTimeStamp();

            tf = true;
            obj.isSaved = false;
        end
        
        function [val, timestamp] = get(obj, prop)

            idx = obj.getPropIdx(prop);

            if ~isempty( idx )
                % is set here, so return

                val = obj.settings{ idx(1), 3};
                if nargout > 1, timestamp = obj.settings{ idx(1), 2}; end
            else
                % not set here, so get from parent

                if ~isempty(obj.parent)
                    [val, timestamp] = obj.parent.get(prop);

                else
                    % no parent (probably Vanellus.m), so return empty
                    
                    val = [];
                    timestamp = uint32(0); % return 1 Jan 1970
                end
                
                if timestamp == uint32(0)
                    % setting was not set, so try to get from local default

                    [val, timestamp] = obj.getDefault(prop);
                end

                if timestamp == uint32(1)
                    % setting was retrieved from parent getDefault, so check whether there is a lower level getDefault so use that

                    [valLocal, timestampLocal] = obj.getDefault(prop);
                    if timestampLocal == uint32(1)
                        val = valLocal;
                    end
                end
            end
        end
        
        function [val, timestamp] = getLocal(obj, prop)
            
            idx = obj.getPropIdx(prop);

            if ~isempty( idx )
                % is set here, so return

                val = obj.settings{ idx(1), 3};
                if nargout > 1, timestamp = obj.settings{ idx(1), 2}; end

            else
                % not set here, so return empty

                val = [];
                if nargout > 1, timestamp = uint32(0); end % return 1 Jan 1970
            end
        end

        function [val, timestamp] = getDefault(obj, prop)
            if isprop(obj, 'DEFAULT_SETTINGS')

                % check whether obj.DEFAULT_SETTINGS is empty and prop is char
                if size(obj.DEFAULT_SETTINGS,1) && ischar(prop)

                    idx = find( strcmp(prop, obj.DEFAULT_SETTINGS(:,1)) );

                    if ~isempty( idx )
                        val = obj.DEFAULT_SETTINGS{ idx(1), 3};
                        timestamp = obj.DEFAULT_SETTINGS{ idx(1), 2};
                        return;
                    end
                end
            end

            if isprop(obj, 'DEFAULT_SUPER_SETTINGS')

                % check whether obj.DEFAULT_SUPER_SETTINGS is empty and prop is char
                if size(obj.DEFAULT_SUPER_SETTINGS,1) && ischar(prop)

                    idx = find( strcmp(prop, obj.DEFAULT_SUPER_SETTINGS(:,1)) );

                    if ~isempty( idx )
                        val = obj.DEFAULT_SUPER_SETTINGS{ idx(1), 3};
                        timestamp = obj.DEFAULT_SUPER_SETTINGS{ idx(1), 2};
                        return;
                    end
                end
            end
            
            val = [];
            timestamp = uint32(0); % return 1 Jan 1970
        end
        
        function tf = isSet(obj, prop)
            tf = ~isempty( obj.getPropIdx(prop) );
        end
        
        function tf = unset(obj, prop)
            tf = false;
            idx = obj.getPropIdx(prop);
            
            if ~isempty( idx )
                obj.settings(idx(1),:) = [];
                tf = true;
                obj.isSaved = false;
            end
        end        
        
        function settings = getCurrentDefaultSettings( obj )
            % returns all current settings (with timestamp and value) that
            % are defined in DEFAULT_SUPER_SETTINGS and DEFAULT_SETTINGS
            settings = {};
            
            % combine DEFAULT_SETTINGS & DEFAULT_SUPER_SETTINGS
            d_settings = {};
            if isprop(obj, 'DEFAULT_SETTINGS')
                d_settings = obj.DEFAULT_SETTINGS;
            end
            ds_settings = {};
            if isprop(obj, 'DEFAULT_SUPER_SETTINGS')
                ds_settings = obj.DEFAULT_SUPER_SETTINGS;
            end
            settingsProps = [ d_settings; ds_settings ];
            
            % no default values set, so return an empty settings
            if isempty(settingsProps), return; end
            
            % get unique prop values
            settingsProps = unique( settingsProps(:,1) );
            
            % fill settings
            for i = 1:length(settingsProps)
                prop = settingsProps{i};
                [val, timestamp] = obj.get( prop );
                settings(end+1,:) = {prop timestamp val};
            end           
        end
        
    end
    
    methods (Sealed, Hidden, Access = private)
        %% internal methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function idx = getPropIdx(obj, prop)
            % check whether obj.settings is empty, and whether prop is char
            if ~size(obj.settings,1) || ~ischar(prop)
                idx = []; 
                return
            end

            idx = find( strcmp(prop, obj.settings(:,1)) );
        end
        
        
        function tf = didDataSettingsChange(old_settings) 
        if ~isequal(data_settings, current_settings), tf = true; return; end
            
        end
        
    end
    
    
end
