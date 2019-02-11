classdef (Abstract) VData < handle %% C
% VData Object for handling and storing data 
%
% following functions can be used:
% - getData( idf )
% - getSettings( idf )
% - getTimestamp( idf )
% - getLastChange( idf )
% - setData( idf, data )
% - unsetData( idf )
% - isDataSet( idf )
% - calcAndSetData( idf )
% - getUpdatedData( idf )
% - undo( idf )
%
% For internal speed up:
% - nr of data in dataArray is stored in dataArrayLength

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Hidden)
        dataArrayIdf        = {};
        dataArrayData       = {};
        dataArraySettings   = {};
        dataArrayTimestamp  = {};
        dataArrayLastChange = {};

        dataArrayLength     = uint16(0);
    end
    
    properties (Transient, Abstract)
        isSaved
    end
    
    properties (Transient, Hidden)
        undoDataArray       = {};           % cell array { idf, data, settings, timestamp, lastChange ; ... next }
        dataArray                           % left here (Transient) for conversion from old VData setup
        Idf2Idx                             % left here (Transient) for conversion from old VData setup
    end
    
    methods (Abstract)
        %% data calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        data = calcData(obj, idf);
        
        tf = canDataBeCalculated(obj, idf);
    end    
    
    methods
        %% data calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function tf = doesDataNeedUpdating(obj, idf, parentLastChange)
            tf = false;
            
            if ~obj.canDataBeCalculated( idf ), return; end
            if ~obj.isDataSet( idf ), tf = true; return; end
            if obj.getTimestamp( idf ) <= parentLastChange, tf = true; return; end
        end
        
    end
    
    methods (Sealed)
        %% dataArray access %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function data = getData(obj, idf)
            data            = [];
            idfIdx          = obj.getDataIdx(idf);
            if ~isempty( idfIdx )
                data        = obj.dataArrayData{ idfIdx(1) };
            end
        end

        function settings = getSettings(obj, idf)
            settings        = {};
            idfIdx          = obj.getDataIdx(idf);
            if ~isempty( idfIdx )
                settings    = obj.dataArraySettings{ idfIdx(1) };
            end
        end
        
        function timestamp = getTimestamp(obj, idf)
            timestamp       = uint32(0); % return 1 Jan 1970
            idfIdx          = obj.getDataIdx(idf);
            if ~isempty( idfIdx )
                timestamp   = obj.dataArrayTimestamp{ idfIdx(1) };
            end
        end
        
        function lastChange = getLastChange(obj, idf)
            lastChange          = uint32(0); % return 1 Jan 1970
            
            % in case no idf, looking for last change of any of the data
            if nargin < 2
                if numel(obj.dataArrayLastChange) > 1
                    lastChange  = max([obj.dataArrayLastChange{:}]);
                end
                return;
            end
            
            idfIdx              = obj.getDataIdx(idf);
            if ~isempty( idfIdx )
                lastChange      = obj.dataArrayLastChange{ idfIdx(1) };
            end
        end
        
        function setData(obj, idf, data)
            idfIdx                                  = obj.getDataIdx( idf );

            if isempty( idfIdx )
                idfIdx                              = obj.dataArrayLength + 1;
                obj.dataArrayLength                 = obj.dataArrayLength + 1;
                obj.dataArrayLastChange{ idfIdx(1) }    = VTools.getUnixTimeStamp();
            else
                if ~isequal( data, obj.dataArrayData{ idfIdx(1) } )
                    obj.dataArrayLastChange{ idfIdx(1) }    = VTools.getUnixTimeStamp();
                    undoIdx                             = size(obj.undoDataArray,1)+1;
                    obj.undoDataArray{ undoIdx, 1 }     = obj.dataArrayIdf{ idfIdx(1) };
                    obj.undoDataArray{ undoIdx, 2 }     = obj.dataArrayData{ idfIdx(1) };
                    obj.undoDataArray{ undoIdx, 3 }     = obj.dataArraySettings{ idfIdx(1) };
                    obj.undoDataArray{ undoIdx, 4 }     = obj.dataArrayTimestamp{ idfIdx(1) };
                    obj.undoDataArray{ undoIdx, 5 }     = obj.dataArrayLastChange{ idfIdx(1) };
                end
            end
                
            obj.dataArrayIdf{ idfIdx(1) }           = idf;
            obj.dataArrayData{ idfIdx(1) }          = data;
            obj.dataArraySettings{ idfIdx(1) }      = obj.getCurrentDefaultSettings();
            obj.dataArrayTimestamp{ idfIdx(1) }     = VTools.getUnixTimeStamp();
            obj.isSaved                             = false;
        end

        function tf = unsetData(obj, idf)
            tf                              = false;
            idfIdx                          = obj.getDataIdx(idf);
            
            if ~isempty( idfIdx )
                tf                                  = true;
                obj.dataArrayIdf(idfIdx(1))         = [];
                obj.dataArrayData(idfIdx(1))        = [];
                obj.dataArraySettings(idfIdx(1))    = [];
                obj.dataArrayTimestamp(idfIdx(1))   = [];
                obj.dataArrayLastChange(idfIdx(1))  = [];
                obj.isSaved                         = false;
            end
        end        
        
        function tf = isDataSet(obj, idf)
            tf = ~isempty( obj.getDataIdx(idf) );
        end
        
        function data = calcAndSetData(obj, idf)
            data = [];

            % check whether data can be calculated
            if ~obj.canDataBeCalculated( idf), return; end

            % actual calculation of data
            data = obj.calcData( idf );
            
            % setting of data
            obj.setData( idf, data);
        end        

        function data = getUpdatedData(obj, idf)
            % if data is not up2date, calc and set it
            if obj.doesDataNeedUpdating( idf )
                data = obj.calcAndSetData( idf );
            else
                % if data did not need updating, get it in case requested
                if nargout > 0
                    data = obj.getData(idf); 
                end
            end
        end        
        
        function tf = undo(obj, idf)
            tf = false;
            
            for undoIdx = size(obj.undoDataArray,1):-1:1
                if isequal(obj.undoDataArray{undoIdx,1}, idf)

                    % reset
                    idfIdx                                  = obj.getDataIdx( idf );
                    obj.dataArrayIdf{ idfIdx(1) }           = obj.undoDataArray{ undoIdx, 1 };
                    obj.dataArrayData{ idfIdx(1) }          = obj.undoDataArray{ undoIdx, 2 };
                    obj.dataArraySettings{ idfIdx(1) }      = obj.undoDataArray{ undoIdx, 3 };
                    obj.dataArrayTimestamp{ idfIdx(1) }     = obj.undoDataArray{ undoIdx, 4 };
                    obj.dataArrayLastChange{ idfIdx(1) }    = obj.undoDataArray{ undoIdx, 5 };
                    tf                                      = true;
                    obj.isSaved                             = false;

                    % remove from undoDataArray
                    obj.undoDataArray( undoIdx, :)  = [];
                    return
                end
            end
        end
        
        %% info %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function nrData = getNrData(obj)
            obj.updateDataArrayLength();
            nrData = obj.dataArrayLength;
        end   
        
        function idfList = getIdfList(obj)
            idfList = obj.dataArrayIdf;
        end   
        
    end
    
    methods (Sealed, Hidden, Access = private)
        %% internal methods %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function idfIdx = getDataIdx(obj, idf)
            obj.updateDataArrayLength();
            
            % loop over whole array and check whether we can find idf
            for idfIdx = 1:obj.dataArrayLength
                if isequal(obj.dataArrayIdf{idfIdx}, idf)
                    return
                end
            end
            idfIdx = [];            
        end  
        
        function updateDataArrayLength(obj)
            obj.dataArrayLength = size(obj.dataArrayIdf,2);
        end
    end
end
