classdef GUIExperiment < GUITogglePanel
% GUIExperiment

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Transient) % not stored
        vanellusGUI
        experiment

        contentPanel
        controlPanel
        
        uiTogglePanels
        uiTexts
        uiButtons
        uiListboxes
    end

    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUIExperiment(vanellusGUI, experiment)
            if nargin < 1
                error('Need VanellusGUI as argument');
            end
            if nargin < 2
                error('Need experiment as argument');
            end
            gui.vanellusGUI = vanellusGUI;
            gui.experiment = experiment;
            
            gui.guiBuild();
        end
 
        function guiBuild(gui)
            gui.controlPanel                    = uipanel(gui.vanellusGUI.fig);
            gui.controlPanel.BackgroundColor    = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.controlPanel.BorderType         = 'none';
            gui.controlPanel.Units              = 'pixels';

            % SET CONTROLPANEL
            gui.uiTogglePanels                        = uipanel(gui.controlPanel);
            gui.uiTogglePanels(1).BackgroundColor     = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.uiTogglePanels(1).Units               = 'pixels';
            gui.uiTogglePanels(1).Title               = 'New / Load';
            
            gui.uiTogglePanels(2)                     = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(2).Title               = 'Load Existing Position';
            
            gui.uiButtons                       = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(1).Style              = 'pushbutton';
            gui.uiButtons(1).String             = 'New Position';
            gui.uiButtons(1).Callback           = @gui.actionNewPosButtonClicked;
                                    
            gui.uiButtons(2)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(1));
            gui.uiButtons(2).String             = 'Load Position';
            gui.uiButtons(2).Callback           = @gui.actionLoadPosButtonClicked;
            
            gui.uiListboxes                     = uicontrol(gui.uiTogglePanels(2));
            gui.uiListboxes(1).Style            = 'listbox';
            gui.uiListboxes(1).Min              = 0;
            gui.uiListboxes(1).Max              = 2;
            gui.uiListboxes(1).Value            = [];
            gui.uiListboxes(1).String           = {''};
            gui.uiListboxes(1).Callback         = @gui.actionLoadPosition;

            % SET TOOLTIPS
            
            % SET CONTENTPANEL
            gui.contentPanel = ScrollPanel(gui.vanellusGUI.fig);
        end

        function guiPositionUpdate(gui,hObject,eventdata)
            % SET CONTROLPANEL BUTTONS
            % Position coordinates: [left bottom width height]
            
            gui.uiTogglePanels(1).Position    = [ 10 200 280 50]; % New / Load
            gui.uiButtons(1).Position   = [ 20  10 110  20];
            gui.uiButtons(2).Position   = [150  10 110  20];

            gui.uiTogglePanels(2).Position    = [ 10 200 280 160]; % Recent
            gui.uiListboxes(1).Position = [ 10  10 260 130];
            
            % INITIALIZE TOGGLE PANELS
            gui.guiInitializeTogglePanels();            
        end

        function guiUpdate(gui,hObject,eventdata)
            % SET LIST OF POSITIONS
            positionList = gui.experiment.positionList;
            gui.uiListboxes(1).String = positionList;
            
            % UPDATE CONTENTPANEL (=SCROLLPANEL)
            rgb = gui.getExperimentImage();
            hIm = gui.contentPanel.showImage(rgb, gui.vanellusGUI.currentMagnification);
            set(hIm, 'ButtonDownFcn', @gui.actionImageClicked);
        end
        
        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rgb = getExperimentImage(gui)
            % get thumbnail
            rgb = gui.experiment.getThumbnail();
        end        
        
        
        %% Image or Key Click %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionKeyPressed(gui,hObject,eventdata)
            switch upper(eventdata.Key)
            end
        end

        function actionImageClicked(gui, hObject, ~)
            contentPanelAx      = findall(gui.contentPanel.contentPanel, 'type', 'axes');
            hIm                 = contentPanelAx.Children;
            if hObject == hIm
                coor = uint16(get(contentPanelAx,'CurrentPoint')); % returns [col row]
                coor = coor(1,[2 1]); 
                
                coor                = double(coor);
                posImSize           = gui.experiment.get('img_maxThumbSize');
                margin              = 10;
                if rem( coor(2), (posImSize(1) + margin) ) < margin, return; end
                if rem( coor(1), (posImSize(2) + margin) ) < margin, return; end
                col                 = ceil( coor(2) / (posImSize(1) + margin) );
                row                 = ceil( coor(1) / (posImSize(2) + margin) ); % disp(['col ' num2str(col) ' row ' num2str(row)]); 
                posIdx              = col + 4 * (row-1);
                positionList        = gui.experiment.positionList;
                if posIdx > 0 && posIdx <= numel(positionList)
                    % check whether everything is saved before leaving
                    if ~gui.vanellusGUI.continueWithoutSaving(), return; end

                    pos = VPosition( [VTools.getParentfolderpath(gui.experiment.filename) gui.experiment.positionList{posIdx}] );
                    gui.vanellusGUI.changePanels( GUIPosition(gui.vanellusGUI, pos) );
                end
            end
        end
        
        
        %% Actions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionNewPosButtonClicked(gui, ~, ~)
            disp(['New Position clicked']);
            position_name = inputdlg('Position Name', 'Enter a name for the position (eg. pos1):', [1 30]);                 

            % 2DO: better position_name checking
            if ~isempty(position_name)
                pos = gui.experiment.createPosition(position_name{1});
                gui.vanellusGUI.changePanels( GUIPosition(gui.vanellusGUI, pos) );
            end
        end
        
        function actionLoadPosButtonClicked(gui, ~, ~)
            disp(['Load Position clicked']);
            dialogTitle = 'Select a Vanellus Experiment, Position or Region';
            filterSpec = {  Vanellus.DEFAULT_POS_FILENAME , 'Vanellus Position files' ; ...
                           [Vanellus.DEFAULT_SET_FILENAME ';' ...
                            Vanellus.DEFAULT_EXP_FILENAME ';' ...
                            Vanellus.DEFAULT_POS_FILENAME ';' ...
                            Vanellus.DEFAULT_REG_FILENAME], 'Vanellus files' ; ...
                            '*.*',  'All Files (*.*)' };
            [filename, pathname, ~] = uigetfile( filterSpec, dialogTitle, VTools.getParentfolderpath(gui.experiment.filename));
            if filename
                switch filename
                    case Vanellus.DEFAULT_EXP_FILENAME
                        exp = VExperiment( [pathname filename] );
                        gui.vanellusGUI.changePanels( GUIExperiment(gui.vanellusGUI, exp) );

                    case Vanellus.DEFAULT_POS_FILENAME
                        pos = VPosition( [pathname filename] );
                        gui.vanellusGUI.changePanels( GUIPosition(gui.vanellusGUI, pos) );

                    case Vanellus.DEFAULT_REG_FILENAME
                        reg = VRegion( [pathname filename] );
                        gui.vanellusGUI.changePanels( GUIRegion(gui.vanellusGUI, reg) );
                end
            end                
        end        
        
        function actionLoadPosition(gui, hObject, eventdata)
            idx = get(hObject,'Value');
            if isempty(idx), return; end % no position selected
            if idx(1) > length(gui.experiment.positionList), return; end % should not happen
            
            % check whether everything is saved before leaving
            if ~gui.vanellusGUI.continueWithoutSaving(), return; end
            
            pos = VPosition( [VTools.getParentfolderpath(gui.experiment.filename) gui.experiment.positionList{idx(1)}] );
            gui.vanellusGUI.changePanels( GUIPosition(gui.vanellusGUI, pos) );
        end
    end
end
