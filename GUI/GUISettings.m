classdef GUISettings < handle
% GUISettings

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant)
        EDIT_TYPES      = { 'text', 'number', 'object', 'cell', 'logical' };
    end
    
    properties (Transient) % not stored
        vanellusGUI
        parent
        isSaved

        contentPanel
        controlPanel
        
        uiButtons
        uiTables
        uiPanels
        uiTexts
        uiEdits
    end

    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUISettings( vanellusGUI, parent)
            if nargin < 2
                error('Need an Object containing settings as argument');
            end
            if nargin < 1
                error('Need VanellusGUI as argument');
            end
            
            gui.vanellusGUI = vanellusGUI;
            gui.parent = parent;
            gui.isSaved = true;
            
            gui.guiBuild();
        end
 
        function guiBuild(gui)
            % SET CONTENTPANEL
            gui.contentPanel = ScrollPanel(gui.vanellusGUI.fig);

            gui.uiTables                            = uitable(gui.contentPanel.contentPanel);
%             gui.uiTables(1).Enable                  = 'inactive';
            gui.uiTables(1).RowStriping             = 'off'; 
            gui.uiTables(1).ColumnWidth             = {150};
            gui.uiTables(1).CellSelectionCallback   = @gui.actionTableClicked;
            
            % SET CONTROLPANEL
            gui.controlPanel                    = uipanel(gui.vanellusGUI.fig);
            gui.controlPanel.BackgroundColor    = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.controlPanel.BorderType         = 'none';
            gui.controlPanel.Units              = 'pixels';

            gui.uiPanels                        = uipanel(gui.controlPanel);
            gui.uiPanels(1).BackgroundColor     = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.uiPanels(1).Units               = 'pixels';
            gui.uiPanels(1).Title               = 'Modify';
            
            gui.uiPanels(2)                     = copyobj(gui.uiPanels(1), gui.controlPanel);
            gui.uiPanels(2).Title               = 'Display';
            
            gui.uiPanels(3)                     = copyobj(gui.uiPanels(1), gui.controlPanel);
            gui.uiPanels(3).Title               = 'Change Setting';
            gui.uiPanels(3).Visible             = 'off';

            gui.uiPanels(4)                     = copyobj(gui.uiPanels(1), gui.controlPanel);
            gui.uiPanels(4).Title               = 'Add Setting';
            
            gui.uiButtons                       = uicontrol(gui.uiPanels(1));
            gui.uiButtons(1).Style              = 'pushbutton';
            gui.uiButtons(1).String             = 'Save';
            gui.uiButtons(1).Callback           = @gui.actionSaveButtonClicked;
            
            gui.uiButtons(2)                    = copyobj(gui.uiButtons(1), gui.uiPanels(1));
            gui.uiButtons(2).String             = 'Reset';
            gui.uiButtons(2).Callback           = @gui.actionResetButtonClicked;
            
            gui.uiButtons(3)                    = uicontrol(gui.uiPanels(2));
            gui.uiButtons(3).Style              = 'togglebutton';
            gui.uiButtons(3).Min                = 0;
            gui.uiButtons(3).Max                = 1;
            gui.uiButtons(3).Value              = 0;
            gui.uiButtons(3).String             = 'Timestamp';
            gui.uiButtons(3).Callback           = @gui.guiUpdate;
            
            gui.uiButtons(4)                    = copyobj(gui.uiButtons(3), gui.uiPanels(2));
            gui.uiButtons(4).String             = 'Class';
            gui.uiButtons(4).Callback           = @gui.guiUpdate;
            
            gui.uiTexts                         = uicontrol(gui.uiPanels(3));
            gui.uiTexts(1).Style                = 'text';
            gui.uiTexts(1).Visible              = 'off';
            gui.uiTexts(1).String               = '';
            gui.uiTexts(1).BackgroundColor      = gui.controlPanel.BackgroundColor;
            gui.uiTexts(1).HorizontalAlignment  = 'left';
            
            gui.uiEdits                         = uicontrol(gui.uiPanels(3));
            gui.uiEdits(1).Style                = 'edit';
            gui.uiEdits(1).Visible              = 'off';
            gui.uiEdits(1).KeyPressFcn          = @gui.actionEditPressed;
            
            gui.uiButtons(5)                    = copyobj(gui.uiButtons(1), gui.uiPanels(3));
            gui.uiButtons(5).Visible            = 'off';
            gui.uiButtons(5).String             = '';
            gui.uiButtons(5).Callback           = @gui.actionChangeEditType;

            gui.uiButtons(6)                    = copyobj(gui.uiButtons(5), gui.uiPanels(3));
            gui.uiButtons(6).String             = 'Enter';
            gui.uiButtons(6).Callback           = @gui.actionEditPressed;

            gui.uiButtons(7)                    = copyobj(gui.uiButtons(5), gui.uiPanels(3));
            gui.uiButtons(7).String             = 'Cancel';
            gui.uiButtons(7).Callback           = @gui.actionEditPressed;

            gui.uiButtons(8)                    = copyobj(gui.uiButtons(5), gui.uiPanels(3));
            gui.uiButtons(8).String             = 'Delete';
            gui.uiButtons(8).Callback           = @gui.actionDeleteButtonClicked;
            
            gui.uiEdits(2)                      = copyobj(gui.uiEdits(1), gui.uiPanels(4));
            gui.uiEdits(2).Visible              = 'on';
            gui.uiEdits(2).KeyPressFcn          = @gui.actionEditPressed;
            
            gui.uiEdits(3)                      = copyobj(gui.uiEdits(2), gui.uiPanels(4));
            gui.uiEdits(3).KeyPressFcn          = @gui.actionEditPressed;
            
            gui.uiButtons(9)                    = copyobj(gui.uiButtons(1), gui.uiPanels(4));
            gui.uiButtons(9).String             = 'number';
            gui.uiButtons(9).Callback           = @gui.actionChangeEditType2;

            gui.uiButtons(10)                   = copyobj(gui.uiButtons(9), gui.uiPanels(4));
            gui.uiButtons(10).String            = 'Save';
            gui.uiButtons(10).Callback          = @gui.actionNewPressed;
            
            % SET TOOLTIPS
        end

        function guiPositionUpdate(gui, hObject, eventdata)
            % SET CONTROLPANEL BUTTONS
            controlPanelPosition        = gui.controlPanel.Position; %[left bottom width height]
            
            gui.uiPanels(1).Position    = [ 30 controlPanelPosition(4)-95 100 75];
            gui.uiButtons(1).Position   = [ 10 35 80 20];
            gui.uiButtons(2).Position   = [ 10 10 80 20];

            gui.uiPanels(2).Position    = [170 controlPanelPosition(4)-95 100 75];
            gui.uiButtons(3).Position   = [ 10 35 80 20];
            gui.uiButtons(4).Position   = [ 10 10 80 20];

            gui.uiPanels(3).Position    = [ 10  controlPanelPosition(4)-250 280 100];
            gui.uiTexts(1).Position     = [ 10  60 200  15];
            gui.uiEdits(1).Position     = [ 10  35 200  20];
            gui.uiButtons(5).Position   = [220  35  50  20];
            gui.uiButtons(6).Position   = [ 10  10  50  20];
            gui.uiButtons(7).Position   = [ 70  10  50  20];
            gui.uiButtons(8).Position   = [130  10  50  20];

            gui.uiPanels(4).Position    = [ 10  controlPanelPosition(4)-370 280 100];
            gui.uiEdits(2).Position     = [ 10  60 200  20];
            gui.uiEdits(3).Position     = [ 10  35 200  20];
            gui.uiButtons(9).Position   = [220  35  50  20];
            gui.uiButtons(10).Position  = [ 10  10  50  20];
        end
        
        function guiUpdate(gui, hObject, eventdata)
            % SET CONTENTPANEL

            % load data sequantially
            i = 1;
            settingsContainer{1} = gui.parent;
            while ~isempty( settingsContainer{i} )
                classNames{i}       = class(settingsContainer{i});
                
                settingsList{i}     = {};
                if numel( settingsContainer{i}.settings )
                    settingsList{i}     = settingsContainer{i}.settings(:,1);
                end
                
                currentDefaultSettings = settingsContainer{i}.getCurrentDefaultSettings();
                defaultSettingsList{i} = currentDefaultSettings(:,1);

                settingsContainer{i+1} = settingsContainer{i}.parent;
                i = i+1;
            end

            % set table column and row names
            rowNames = {};
            rowNamesDefault = {};
            for i = 1:length(classNames)
                columnNames{i} = classNames{i};
                rowNames = union(rowNames, settingsList{i}, 'stable');
                rowNamesDefault = union(rowNamesDefault, defaultSettingsList{i});
            end
            rowNames{end+1,1} = '';
            rowNames = union(rowNames, rowNamesDefault, 'stable');
            
            gui.uiTables(1).RowName                 = rowNames;
            gui.uiTables(1).ColumnName              = columnNames;
            gui.uiTables(1).ColumnEditable          = false; %[true false];

            % set table data
            data                                    = cell( [length(rowNames) length(columnNames)] );
            for r = 1:length(rowNames)
                text = '';
                for c = length(columnNames):-1:1
                    if settingsContainer{c}.isSet( rowNames{r} )

                        value = settingsContainer{c}.get( rowNames{r} );

                        % in case of array covert to colon text
                        if isnumeric(value) && isvector(value)
                            text = vect2colon(value);
                        else
                            text = VTools.convertValueToChar( value );
                        end
                        
                        if gui.uiButtons(4).Value % show class instead
                            text = class( settingsContainer{c}.get( rowNames{r} ) );
                        end

                        if gui.uiButtons(3).Value % show timestamp instead
                            [~, timestamp] = settingsContainer{c}.get( rowNames{r} );
                            text = char( VTools.getDatetimeFromUnixtimestamp( timestamp) );
                        end
                        

                        data{r,c} = VTools.getHTMLColoredText( text, [0 0 0]);
                    else
                        % DEFAULT VALUES
                        if isempty(text) && ~isempty( settingsContainer{c}.getDefault( rowNames{r} ) )
                            text = VTools.convertValueToChar( settingsContainer{c}.getDefault( rowNames{r} ) );
                        end
                        
                        data{r,c} = VTools.getHTMLColoredText( text, [0.3 0.3 0.3]);
                        
                        if gui.uiButtons(3).Value || gui.uiButtons(4).Value % show no timestamp/class instead
                            data{r,c} = '';
                        end
                    end
                end
            end
            gui.uiTables(1).Data                    = data;

            % set to right size
            gui.uiTables(1).Position    = [ 10 10 gui.uiTables(1).Extent(3) gui.uiTables(1).Extent(4)];
            gui.contentPanel.contentPanel.Position = [1 1 (gui.uiTables(1).Extent(3)+20) (gui.uiTables(1).Extent(4)+20)];
            gui.contentPanel.centerPanel();
            
            % SET CONTROLPANEL
            if gui.isSaved, gui.uiButtons(1).BackgroundColor = gui.uiButtons(2).BackgroundColor;
            else,           gui.uiButtons(1).BackgroundColor = [1 0 0]; end
        end

        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionKeyPressed(gui, hObject, eventdata)
%             if strcmp(gui.uiEdits(1).Visible, 'on')
%                 disp('key press ignored');
%                 return
%             end
            
            switch upper(eventdata.Key)
                case {'S'}
                    disp(['Clicked key: ' eventdata.Key ' -> saving']);
                    gui.actionSaveButtonClicked();                
%                 case {'R'}
%                     disp(['Clicked key: ' eventdata.Key ' -> resetting']);
%                     gui.actionResetButtonClicked();                
            end
        end

        function actionTableClicked(gui, hObject, eventdata)
            if isempty(eventdata.Indices), return; end % avoid error when changing display while cell is selected
            if gui.uiButtons(3).Value, return; end % don't respond when timestamps are shown
            
            if eventdata.Indices(2) < 2 % only respond to clicks in 1st column
                settingName = gui.uiTables(1).RowName{eventdata.Indices(1)};
                
                if isempty(settingName), return; end % avoid empty row error
                disp([ settingName ' clicked']);

                value = gui.parent.get(settingName);

                % in case of array covert to colon text
                if isnumeric(value) && isvector(value)
                    text = vect2colon(value);
                else
                    text = VTools.convertValueToChar( value );
                end
                
                gui.uiTexts(1).String               = settingName;
                gui.uiEdits(1).String               = text;
                gui.uiButtons(5).String             = gui.selectEditType( value );
                gui.changeEditBoxVisibility('on');
            end
        end
        
        function actionEditPressed(gui, hObject, eventdata)
            if hObject == gui.uiButtons(6)
                disp('edit: save button clicked');
            elseif hObject == gui.uiButtons(7)
                disp('edit: cancel button clicked');
                gui.changeEditBoxVisibility('off');
                return;
            else
                if ~isequal( eventdata.Key, 'return')
                    return;
                else
                    disp('edit: return entered');
                end
            end

            if isempty(gui.uiTexts(1).String) return; end
            
            drawnow; % makes sure that uiEdits(1) is up to date
            valueString = gui.uiEdits(1).String;
            switch gui.uiButtons(5).String
                case {gui.EDIT_TYPES{1}} % 'text'
                    valueString = ['''' valueString ''''];
                case {gui.EDIT_TYPES{2}} % 'number'
                    valueString = ['[' valueString ']'];
                case {gui.EDIT_TYPES{3}} % 'object'

                case {gui.EDIT_TYPES{4}} % 'cell'

                case {gui.EDIT_TYPES{5}} % 'logical'
            end

            action = ['gui.parent.set(''' gui.uiTexts(1).String ''', ' valueString ');']
            eval(action);
            gui.changeEditBoxVisibility('off');
            gui.isSaved = false;
            gui.guiUpdate();
        end

        function changeEditBoxVisibility(gui, newVisibility)
            gui.uiPanels(3).Visible             = newVisibility;
            gui.uiTexts(1).Visible              = newVisibility;
            gui.uiEdits(1).Visible              = newVisibility;
            gui.uiButtons(5).Visible            = newVisibility;
            gui.uiButtons(6).Visible            = newVisibility;
            gui.uiButtons(7).Visible            = newVisibility;
            gui.uiButtons(8).Visible            = newVisibility;
            
            if strcmp(newVisibility, 'off')
                gui.uiTexts(1).String               = '';
                gui.uiEdits(1).String               = '';
            end
        end

        function editType = selectEditType(gui, value)
            switch class(value)
                case {'char'} 
                    editType = gui.EDIT_TYPES{1};
                case {'double', 'uint32'}
                    editType = gui.EDIT_TYPES{2};
                case {'function_handle'}
                    editType = gui.EDIT_TYPES{3};
                case {'cell'}
                    editType = gui.EDIT_TYPES{4};
                case {'logical'}
                    editType = gui.EDIT_TYPES{5};
                otherwise 
                    editType = gui.EDIT_TYPES{1};
            end
        end
        
        function actionChangeEditType(gui, hObject, eventdata)
            currentIdx = find(strcmp(gui.EDIT_TYPES, gui.uiButtons(5).String));
            newIdx = rem(currentIdx, length(gui.EDIT_TYPES) ) + 1;
            gui.uiButtons(5).String = gui.EDIT_TYPES{newIdx};
        end
        
        function actionSaveButtonClicked(gui, hObject, eventdata)
            disp(['Save clicked']);
            gui.parent.save();
            gui.isSaved = true;
            gui.guiUpdate();
        end
        
        function actionResetButtonClicked(gui, hObject, eventdata)
            disp(['Reset clicked']);
            gui.parent = gui.parent.load();
            gui.parent.update();
            gui.isSaved = true;
            gui.guiUpdate();
        end

        function actionDeleteButtonClicked(gui, hObject, eventdata)
            disp(['Delete clicked']);
            gui.parent.unset(gui.uiTexts(1).String);
            gui.isSaved = false;
            gui.changeEditBoxVisibility('off');
            gui.guiUpdate();
        end
        
        function actionChangeEditType2(gui, hObject, eventdata)
            drawnow; % makes sure that uiEdits(1) is up to date
            currentIdx = find(strcmp(gui.EDIT_TYPES, gui.uiButtons(9).String));
            newIdx = rem(currentIdx, length(gui.EDIT_TYPES) ) + 1;
            gui.uiButtons(9).String = gui.EDIT_TYPES{newIdx};
        end
        
        function actionNewPressed(gui, hObject, eventdata)
            if hObject == gui.uiButtons(10)
                disp('edit: save button clicked');
            else
                if ~isequal( eventdata.Key, 'return')
                    return;
                else
                    disp('edit: return entered');
                end
            end
            
            pause(0.1); % required for uiEdits update ?
            propString  = gui.uiEdits(2).String;
            valueString = gui.uiEdits(3).String;
            switch gui.uiButtons(9).String
                case {gui.EDIT_TYPES{1}} % 'text'
                    valueString = ['''' valueString ''''];
                case {gui.EDIT_TYPES{2}} % 'number'
                    valueString = ['[' valueString ']'];
                case {gui.EDIT_TYPES{3}} % 'object'

                case {gui.EDIT_TYPES{4}} % 'cell'

                case {gui.EDIT_TYPES{5}} % 'logical'
            end

            if isempty(propString), return; end
            action = ['gui.parent.set(''' propString ''', ' valueString ');']
            eval(action);
            gui.isSaved = false;
            gui.guiUpdate();
        end
      
    end
end