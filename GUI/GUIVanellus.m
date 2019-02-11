classdef GUIVanellus < GUITogglePanel
% GUIVanellus Object

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Transient) % not stored
        vanellusGUI
        vanellus

        contentPanel
        controlPanel
        
        uiTogglePanels
        uiButtons
        uiListboxes
        uiEdits
        uiTexts
    end

    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUIVanellus( vanellusGUI, vanellus)
            if nargin < 1
                error('Need VanellusGUI as argument');
            end
            gui.vanellusGUI = vanellusGUI;
            gui.vanellus = vanellus;
            
            gui.guiBuild();
        end
 
        function guiBuild(gui)
            % SET CONTROLPANEL
            gui.controlPanel                        = uipanel(gui.vanellusGUI.fig);
            gui.controlPanel.BackgroundColor        = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.controlPanel.BorderType             = 'none';
            gui.controlPanel.Units                  = 'pixels';
            
            gui.uiTogglePanels                      = uipanel(gui.controlPanel);
            gui.uiTogglePanels(1).BackgroundColor   = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.uiTogglePanels(1).Units             = 'pixels';
            gui.uiTogglePanels(1).Title             = 'Version';
            
            gui.uiTogglePanels(2)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(2).Title             = 'New / Load';

            gui.uiTogglePanels(3)                   = copyobj(gui.uiTogglePanels(2), gui.controlPanel);
            gui.uiTogglePanels(3).Title             = 'Load Recent Experiment';

            gui.uiTogglePanels(4)                   = copyobj(gui.uiTogglePanels(2), gui.controlPanel);
            gui.uiTogglePanels(4).Title             = 'Project Folder';
                     
            %% Version Panel
            gui.uiTexts                             = uicontrol(gui.uiTogglePanels(1));
            gui.uiTexts(1).Style                    = 'text';
            gui.uiTexts(1).HorizontalAlignment      = 'left';
            gui.uiTexts(1).String                   = ['Vanellus version: ' Vanellus.VERSION];
            gui.uiTexts(1).BackgroundColor          = gui.uiTexts(1).Parent.BackgroundColor;

            gui.uiTexts(2)                          = copyobj(gui.uiTexts(1), gui.uiTogglePanels(1));
            gui.uiTexts(2).String                   = '';
            
            gui.uiButtons                           = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(1).Style                  = 'pushbutton';
            gui.uiButtons(1).String                 = 'Webpage';
            gui.uiButtons(1).Callback               = @gui.actionOpenWebpage;
            
            %% New / Load Panel
            gui.uiButtons(11)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(11).String                = 'New Experiment';
            gui.uiButtons(11).Callback              = @gui.actionNewExpButtonClicked;
            
            gui.uiButtons(12)                       = copyobj(gui.uiButtons(11), gui.uiTogglePanels(2));
            gui.uiButtons(12).String                = 'Load Experiment';
            gui.uiButtons(12).Callback              = @gui.actionLoadExpButtonClicked;

            %% Recent Panel
            gui.uiListboxes                         = uicontrol(gui.uiTogglePanels(3));
            gui.uiListboxes(1).Style                = 'listbox';
            gui.uiListboxes(1).String               = {''};
            gui.uiListboxes(1).Max                  = 2;
            gui.uiListboxes(1).Min                  = 0;
            gui.uiListboxes(1).Value                = [];
            gui.uiListboxes(1).Callback             = @gui.actionLoadRecentExperiment;
            
            gui.uiButtons(21)                       = copyobj(gui.uiButtons(11), gui.uiTogglePanels(3));
            gui.uiButtons(21).String                = 'Clear List';
            gui.uiButtons(21).Callback              = @gui.actionClearRecentExperimentList;
            
            %% Project Panel
            gui.uiEdits                             = uicontrol(gui.uiTogglePanels(4));
            gui.uiEdits(1).Style                    = 'edit';
            gui.uiEdits(1).Enable                   = 'inactive';
            gui.uiEdits(1).HorizontalAlignment      = 'right';
            
            gui.uiButtons(31)                       = copyobj(gui.uiButtons(11), gui.uiTogglePanels(4));
            gui.uiButtons(31).String                = 'Change';
            gui.uiButtons(31).Callback              = @gui.actionChangeProjectFolder;
            
            gui.uiListboxes(31)                     = copyobj(gui.uiListboxes(1), gui.uiTogglePanels(4));
            gui.uiListboxes(31).Callback            = @gui.actionLoadProjectExperiment;
            
            % SET TOOLTIPS
            
            % SET CONTENTPANEL
            gui.contentPanel                        = uipanel( gui.vanellusGUI.fig );
            gui.contentPanel.BackgroundColor        = 'white';
            gui.contentPanel.BorderType             = 'none';
            gui.contentPanel.Units                  = 'pixels';
            
            % If findjobj exists, get the listbox's underlying Java control
            % and set the mouse-movement event callback 
            if exist('findjobj', 'file') == 2
                jScrollPane = findjobj( gui.uiListboxes(1) );
                jListbox    = jScrollPane.getViewport.getComponent(0);
                set(jListbox, 'MouseMovedCallback', {@gui.mouseMovedCallback, gui.uiListboxes(1)});
            end
        end

        function mouseMovedCallback(gui, jListbox, jEventData, hListbox)
           % Show the complete folder of the currently-hovered experiment
           mousePos                 = java.awt.Point(jEventData.getX, jEventData.getY);
           hoverIndex               = jListbox.locationToIndex(mousePos) + 1;
           recentExperiments        = gui.getRecentExperimentList();
           hListbox.TooltipString   = recentExperiments{hoverIndex};
        end
        
        function guiPositionUpdate(gui, hObject, eventdata)
            % SET CONTROLPANEL BUTTONS
            % Position coordinates: [left bottom width height]
            
            gui.uiTogglePanels(1).Position  = [ 10 200 280  50]; % Version
            gui.uiTexts(1).Position         = [ 10  16 180  20];
            gui.uiButtons(1).Position       = [200  12  70  20];
            gui.uiTexts(2).Position         = [ 10   1 260  20];

            gui.uiTogglePanels(2).Position  = [ 10 200 280  50]; % New / Load
            gui.uiButtons(11).Position      = [ 20  10 110  20];
            gui.uiButtons(12).Position      = [150  10 110  20];

            gui.uiTogglePanels(3).Position  = [ 10 200 280 200]; % Recent
            gui.uiListboxes(1).Position     = [ 10  40 260 140];
            gui.uiButtons(21).Position      = [ 10  10 120  20];

            gui.uiTogglePanels(4).Position  = [ 10 200 280 200]; % Project
            gui.uiEdits(1).Position         = [ 10 160 180  20];
            gui.uiButtons(31).Position      = [200 160  60  20];
            gui.uiListboxes(31).Position    = [ 10  10 260 140];
            
            % INITIALIZE TOGGLE PANELS
            gui.guiInitializeTogglePanels();            
        end
        
        function guiUpdate(gui, hObject, eventdata)
            %% SET VERSION INFO
            gui.uiTexts(2).String           = '';
            latestVersionString             = VTools.getLatestVersionString();
            if ~isempty(latestVersionString)
                if strcmp(latestVersionString, Vanellus.VERSION)
                    gui.uiTexts(2).String   = 'This is the latest version';
                else
                    gui.uiTexts(2).String   = ['New version (' latestVersionString ') available'];
                    gui.uiButtons(1).BackgroundColor    = VanellusGUI.BUTTON_BGCOLOR_NOTSAVED;
                end
            end
            
            % SET LIST OF RECENT EXPERIMENTS
            recentExperiments = gui.getRecentExperimentList();
            recentExperimentsNames = {};
            for i = 1:length(recentExperiments)
                recentExperimentsNames{i} = VTools.getParentfoldername(recentExperiments{i});
            end
            gui.uiListboxes(1).String = recentExperimentsNames;

            % SET PROJECT FOLDER
            projectFolder = '';
            if ispref('Vanellus','GUIVanellus_projectFolder')
                projectFolder       = getpref('Vanellus','GUIVanellus_projectFolder');
            end
            gui.uiEdits(1).String = projectFolder;
            % If findjobj exists, set string to right 
            if exist('findjobj', 'file') == 2
                j = findjobj(gui.uiEdits(1));
                j.setCaretPosition( length(projectFolder));
            end
            
            % SET LIST OF PROJECT EXPERIMENTS
            projectExperimentNames = gui.getProjectExperimentNames();            
            gui.uiListboxes(31).String = projectExperimentNames;
            
            % SET CONTENTPANEL
            delete(gui.contentPanel.Children);
            gui.contentPanel.BackgroundColor = [0 0 0];
            [w, h]                          = gui.getContentPanelWidthHeight();
            bg_cdata                        = VTools.getBackground();
            centeredImage                   = uint8( zeros( [h w 3] ) );
            for i = 1:3
                centeredImage(:,:,i)        = VTools.implace(zeros([h w]), bg_cdata(:,:,i), w/2, h/2);
            end
            contentPanelAx                  = axes('Units','normal', 'Position', [0 0 1 1], 'Parent', gui.contentPanel);
            imshow(centeredImage, 'Parent', contentPanelAx);        
        end

        function [w, h] = getContentPanelWidthHeight(gui)
            contentPanelPosition            = get(gui.contentPanel, 'Position'); %[left bottom width height]
            w                               = contentPanelPosition(3);
            h                               = contentPanelPosition(4);
        end
        
        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionKeyPressed(gui, hObject, eventdata)
            switch upper(eventdata.Key)
            end
        end
        
        function actionNewExpButtonClicked(gui, ~, ~)
            disp(['New Experiment clicked']);
            folder_name = uigetdir;
                
            % 2DO: better folder_name checking
            if folder_name
                exp = gui.vanellus.createExperiment(folder_name);
                gui.getRecentExperimentList(exp);
                gui.vanellusGUI.changePanels( GUIExperiment(gui.vanellusGUI, exp) );
            end
        end
        
        function actionLoadExpButtonClicked(gui, ~, ~)
            disp(['Load Experiment clicked']);
            dialogTitle = 'Select a Vanellus Experiment, Position or Region';
            filterSpec = {  Vanellus.DEFAULT_EXP_FILENAME , 'Vanellus Experiment files' ; ...
                           [Vanellus.DEFAULT_SET_FILENAME ';' ...
                            Vanellus.DEFAULT_EXP_FILENAME ';' ...
                            Vanellus.DEFAULT_POS_FILENAME ';' ...
                            Vanellus.DEFAULT_REG_FILENAME], 'Vanellus files' ; ...
                            '*.*',  'All Files (*.*)' };
            [filename, pathname, ~] = uigetfile( filterSpec, dialogTitle, VTools.getParentfolderpath(gui.vanellus.filename));
            if filename
                switch filename
                    case Vanellus.DEFAULT_EXP_FILENAME
                        exp = VExperiment( [pathname filename] );
                        gui.getRecentExperimentList(exp); % add experiment to recent experiments list
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
        
        function actionLoadRecentExperiment(gui, hObject, eventdata)
            idx = get(hObject,'Value');
            if isempty(idx), return; end % no experiment selected
            
            % check whether everything is saved before leaving
            if ~gui.vanellusGUI.continueWithoutSaving(), return; end
            
            % If findjobj exists, get the listbox's underlying Java control
            % and set the mouse-movement event callback to empty (to avoid error) 
            if exist('findjobj', 'file') == 2
                jScrollPane = findjobj( gui.uiListboxes(1) );
                jListbox    = jScrollPane.getViewport.getComponent(0);
                set(jListbox, 'MouseMovedCallback', {});
            end            
            
            recentExperiments = gui.getRecentExperimentList();
            exp = VExperiment(recentExperiments{idx(1)});
            gui.getRecentExperimentList(exp);
            gui.vanellusGUI.changePanels( GUIExperiment(gui.vanellusGUI, exp) );
        end
        
        function actionClearRecentExperimentList(gui, hObject, eventdata)
            % dialog in case something has not been saved
            choice = questdlg('Remove experiments from list?', 'Are you sure?', 'Yes', 'No', 'No');
            % Handle response
            switch choice
                case 'Yes'
                    if ispref('Vanellus','GUIVanellus_recentExperiments')
                        rmpref('Vanellus','GUIVanellus_recentExperiments');
                    end
            end

            gui.guiUpdate();
        end
        
        function recentExperiments = getRecentExperimentList(gui, exp)
            % get current list
            recentExperiments = {};
            if ispref('Vanellus','GUIVanellus_recentExperiments')
                recentExperiments = getpref('Vanellus','GUIVanellus_recentExperiments');
            end
            
            % in case new experiment is given, add it
            if nargin > 1
                % in case experiment is already in list, remove it so it will move to top
                recentExperiments = setdiff(recentExperiments, exp.filename, 'stable');
                recentExperiments = union(exp.filename, recentExperiments, 'stable');
            end
            
            % remove experiments that don't exist anymore
            for i = length(recentExperiments):-1:1
                if ~VTools.isFile( recentExperiments{i} )
                    recentExperiments = setdiff(recentExperiments, recentExperiments{i}, 'stable');
                end
            end

            % update list in preferences
            setpref('Vanellus','GUIVanellus_recentExperiments', recentExperiments);
        end
      
        function actionChangeProjectFolder(gui, ~, ~)
            disp(['Change Project Folder clicked']);
            dialogTitle         = 'Select a Project Folder';
            
            if ispref('Vanellus','GUIVanellus_projectFolder')
                startpath       = getpref('Vanellus','GUIVanellus_projectFolder');
            else
                startpath       = VTools.getParentfolderpath(gui.vanellus.filename);
            end
            
            projectFolder       = uigetdir(startpath, dialogTitle);
            
            if projectFolder
                setpref('Vanellus','GUIVanellus_projectFolder', projectFolder);
                gui.guiUpdate();
            end
        end
        
        function projectExperimentNames = getProjectExperimentNames(gui)
            projectExperimentNames = {};

            if ispref('Vanellus','GUIVanellus_projectFolder')
                projectFolder       = getpref('Vanellus','GUIVanellus_projectFolder');
                expfoldernames      = VTools.getSubfoldernames( projectFolder );
                for i = 1:length(expfoldernames)
                    expFilename     = [projectFolder filesep expfoldernames{i} filesep Vanellus.DEFAULT_EXP_FILENAME];
                    if VTools.isFile(expFilename)
                        projectExperimentNames{ end+1 } = expfoldernames{i};
                    end
                end
            end
        end        
        
        function actionLoadProjectExperiment(gui, hObject, eventdata)
            idx = get(hObject,'Value');
            if isempty(idx), return; end % no experiment selected
            
            % check whether everything is saved before leaving
            if ~gui.vanellusGUI.continueWithoutSaving(), return; end
            
            % If findjobj exists, get the listbox's underlying Java control
            % and set the mouse-movement event callback to empty (to avoid error) 
            if exist('findjobj', 'file') == 2
                jScrollPane = findjobj( gui.uiListboxes(1) );
                jListbox    = jScrollPane.getViewport.getComponent(0);
                set(jListbox, 'MouseMovedCallback', {});
            end            
            
            projectExperimentNames = gui.getProjectExperimentNames();
            projectFolder       = getpref('Vanellus','GUIVanellus_projectFolder');
            exp = VExperiment( [projectFolder filesep projectExperimentNames{idx(1)}] );
            gui.vanellusGUI.changePanels( GUIExperiment(gui.vanellusGUI, exp) );
        end
        
        function actionOpenWebpage(gui, hObject, ~)
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from edit box / button
            web('http://kiviet.com/research/vanellus.php', '-browser');
        end
        
    end
end