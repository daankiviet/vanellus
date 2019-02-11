classdef VanellusGUI < handle %% C
% VanellusGUI Overarching GUI containing the Navigation Panel

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant, Hidden)
        MAGNIFICATIONS              = [0.25 0.375 0.5 0.75 1 1.5 2 3 4 6 8];
        
        NAVPANEL_WIDTH              = 300;
        NAVPANEL_HEIGHT             = 145;
        NAVPANEL_BGCOLOR            = [0.8  0.8  0.8 ];
        CONTROLPANEL_MIN_HEIGHT     = 400;
        CONTROLPANEL_BGCOLOR        = [0.9  0.9  0.9 ];

        BUTTON_BGCOLOR              = [0.8  0.8  0.8 ];
        BUTTON_FGCOLOR              = [0.0  0.0  0.0 ];
        BUTTON_BGCOLOR_HIGHLIGHT    = [0.94 0.94 0.94];
        BUTTON_FGCOLOR_HIGHLIGHT    = [0.0  0.0  0.0 ];
        BUTTON_BGCOLOR_NOTSAVED     = [1.0  0.0  0.0 ];
        
        DISPLAYPANEL_BGCOLOR        = [0.9  0.9  0.9 ];
        ANALYSISPANEL_BGCOLOR       = [0.9  0.92 0.9 ];
        EDITPANEL_BGCOLOR           = [0.92 0.92 0.9 ];
        SETTINGSPANEL_BGCOLOR       = [0.9  0.9  0.92];
        CACHINGPANEL_BGCOLOR        = [0.92 0.9  0.9 ];
    end
    
    properties (Transient)
        fig
        mainPanels
        currentMagnification

        navPanel
        uiTexts
        uiButtons
    end

    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = VanellusGUI( model )            
            gui.guiBuild();

            if nargin < 1, model = Vanellus('', true); end
            switch class(model)
                case {'VRegion'}
                    gui.mainPanels      = GUIRegion(gui, model);
                case {'VPosition'}
                    gui.mainPanels      = GUIPosition(gui, model);
                case {'VExperiment'}
                    gui.mainPanels      = GUIExperiment(gui, model);
                otherwise % including case {'Vanellus'}
                    gui.mainPanels      = GUIVanellus(gui, model);
            end
            
            gui.currentMagnification = 1;
            gui.changeToRecentMagnification();
            
            gui.fig.Visible     = 'on';
            gui.guiPositionUpdate();
            gui.guiUpdate();
            
            gui.checkMatlabVersion();
        end
 
        function guiBuild(gui)
            gui.fig                     = figure;
            gui.fig.MenuBar             = 'none';
            gui.fig.NumberTitle         = 'off';
            gui.fig.Resize              = 'on';
            gui.fig.CloseRequestFcn     = @gui.actionCloseGUI;
            gui.fig.WindowKeyPressFcn   = @gui.actionKeyPressed;
            gui.fig.ResizeFcn           = @gui.actionFigResize;
            gui.fig.Visible             = 'off';

            % SET WINDOW POSITION
            position = get(0, 'Screensize') + [100 100 -200 -200];
            if ispref('Vanellus','VanellusGui_position')
                position = getpref('Vanellus','VanellusGui_position');
            end
            gui.fig.Position = position;
            
            % SET NAVPANEL
            gui.navPanel                    = uipanel(gui.fig);
            gui.navPanel.BackgroundColor    = gui.NAVPANEL_BGCOLOR;
            gui.navPanel.BorderType         = 'none';
            gui.navPanel.Units              = 'pixels';
            
            gui.uiButtons                   = uicontrol(gui.navPanel);
            gui.uiButtons(1).Style          = 'pushbutton';
            gui.uiButtons(1).String         = 'VAN';
            gui.uiButtons(1).FontWeight     = 'bold';
            gui.uiButtons(2)                = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(2).String         = '';

            gui.uiButtons(3)                = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(3).String         = 'EXP';
            gui.uiButtons(4)                = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(4).String         = '';
            gui.uiButtons(5)                = copyobj(gui.uiButtons(2), gui.navPanel);

            gui.uiButtons(6)                = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(6).String         = 'POS';
            gui.uiButtons(7)               = copyobj(gui.uiButtons(4), gui.navPanel);
            gui.uiButtons(8)                = copyobj(gui.uiButtons(2), gui.navPanel);

            gui.uiButtons(9)                = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(9).String         = 'REG';
            gui.uiButtons(10)               = copyobj(gui.uiButtons(4), gui.navPanel);
            gui.uiButtons(11)               = copyobj(gui.uiButtons(2), gui.navPanel);

            gui.uiButtons(12)               = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(12).String        = 'RMSK';
            gui.uiButtons(13)               = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(13).String        = 'MSK';
            gui.uiButtons(14)               = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(14).String        = 'SEG';
            gui.uiButtons(15)               = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(15).String        = 'TRK';
            gui.uiButtons(16)               = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(16).String        = 'TREE';

            gui.uiButtons(17)               = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(17).String        = 'IMG';
            gui.uiButtons(18)               = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(18).String        = 'STB';
            
            gui.uiButtons(19)               = copyobj(gui.uiButtons(1), gui.navPanel);
            gui.uiButtons(19).String        = 'ANN';
            
            set(gui.uiButtons([1 3 6 9 12:19]), 'Callback', @gui.actionNavButtonClicked);
            set(gui.uiButtons([2 5 8 11]),      'Callback', @gui.actionNavButtonClicked);
            set(gui.uiButtons([4 7 10]),        'Callback', @gui.actionSaveButtonClicked);
            
            gui.uiTexts                     = uicontrol(gui.navPanel);
            gui.uiTexts(1).Style            = 'text';
            gui.uiTexts(1).String           = '';
            gui.uiTexts(1).BackgroundColor  = gui.navPanel.BackgroundColor;
            gui.uiTexts(1).HorizontalAlignment = 'left';
            gui.uiTexts(1).FontWeight       = 'bold';
            
            gui.uiTexts(2)                  = copyobj(gui.uiTexts(1), gui.navPanel);
            gui.uiTexts(3)                  = copyobj(gui.uiTexts(1), gui.navPanel);
            
            % SET TOOLTIPS
            gui.uiButtons(4).TooltipString      = 'keyboard shortcut = s';            
            gui.uiButtons(7).TooltipString      = 'keyboard shortcut = s';            
            gui.uiButtons(10).TooltipString     = 'keyboard shortcut = s';            
        end

        function guiPositionUpdate(gui, ~, ~)
            % SET PANEL POSITIONS
            position = gui.fig.Position; %[left bottom width height]
            
            % if there is a sidePanel, show it
            if isprop(gui.mainPanels, 'sidePanel') && strcmp(gui.mainPanels.sidePanel.Visible, 'on')
                gui.mainPanels.sidePanel.Position = [1 1 gui.NAVPANEL_WIDTH position(4)]; 
                gui.mainPanels.contentPanel.Position = [1+gui.NAVPANEL_WIDTH 1 position(3)-2*gui.NAVPANEL_WIDTH position(4)]; 
            else
                gui.mainPanels.contentPanel.Position = [1 1 position(3)-gui.NAVPANEL_WIDTH position(4)];
            end
            gui.mainPanels.controlPanel.Position = [position(3)-gui.NAVPANEL_WIDTH+1 1 gui.NAVPANEL_WIDTH position(4)-gui.NAVPANEL_HEIGHT];
            gui.navPanel.Position = [position(3)-gui.NAVPANEL_WIDTH+1 position(4)-gui.NAVPANEL_HEIGHT+1 gui.NAVPANEL_WIDTH gui.NAVPANEL_HEIGHT]; 
            drawnow;
             
            % SET PANELS POSITIONS
            gui.mainPanels.guiPositionUpdate();

            % SET NAVPANEL POSITIONS
            gui.uiButtons(1).Position = [ 10 115  40  20];
            gui.uiButtons(3).Position = [ 10  90  40  20];
            gui.uiButtons(6).Position = [ 10  65  40  20];
            gui.uiButtons(9).Position = [ 10  40  40  20];
            
            gui.uiTexts(1).Position = [ 55  86-5 185  20+5];
            gui.uiTexts(2).Position = [ 55  61 185  20];
            gui.uiTexts(3).Position = [ 55  36 185  20];
            
            gui.uiButtons(2).Position = [270 115  20  21];
            gui.uiButtons(5).Position = [270  90  20  20];
            gui.uiButtons(8).Position = [270  65  20  20];
            gui.uiButtons(11).Position = [270  40  20  20];

            CData = load('vanellusImages.mat', 'cdata_settings', 'alphadata_settings');
            imSettings = VTools.applyAlpha( CData.cdata_settings, CData.alphadata_settings, gui.BUTTON_BGCOLOR);
            set(gui.uiButtons([2 5 8 11]), 'CData', imSettings);

            gui.uiButtons(4).Position = [245  90  20  20];
            gui.uiButtons(7).Position = [245  65  20  20];
            gui.uiButtons(10).Position = [245  40  20  20];

            gui.uiButtons(19).Position = [ 10  11  40  20];
            gui.uiButtons(12).Position = [ 55  11  40  20];
            gui.uiButtons(13).Position = [100  11  40  20];
            gui.uiButtons(14).Position = [145  11  40  20];
            gui.uiButtons(15).Position = [190  11  40  20];
            gui.uiButtons(16).Position = [235  11  40  20];
            
            gui.uiButtons(17).Position = [ 55  40  40  20];
            gui.uiButtons(18).Position = [100  38  40  20];

            % DRAW LINE AT BOTTOM
            navPanelAx = axes('Parent', gui.navPanel, 'Visible', 'off', 'Position', [0, 0, 1, 1], 'Xlim', [0, 1], 'YLim', [0, 1]);
            line([0 1], [0.01 0.01], 'Parent', navPanelAx, 'Color', [0 0 0]); %, 'LineWidth', 1
        end

        function guiUpdate(gui ,~, ~)
            % UPDATE FIGURE TITLE
            titleText = 'Vanellus';
            switch class(gui.mainPanels)
                case {'GUISettings'}
                    settingsClass = class(gui.mainPanels.parent);
                    titleText = [titleText ' - ' settingsClass ' Settings'];
                case {'GUIExperiment'}
                    titleText = [titleText ' Experiment'];
                case {'GUIPosition'}
                    titleText = [titleText ' Position'];
                case {'GUIRegion', 'GUIMasks', 'GUISegmentations', 'GUITrackings', 'GUITree'}
                    titleText = [titleText ' Region'];
                case {'GUIRegionmask'}
                    titleText = [titleText ' Region Mask'];

            end            
            titleText = [titleText ' (' num2str(100*gui.currentMagnification) '%)'];
            gui.fig.Name = titleText;
            gui.fig.Pointer = 'arrow';            

            % UPDATE NAVPANEL
            gui.guiUpdateNavPanel();

            % UPDATE PANELS
            gui.mainPanels.guiUpdate();
        end

        function guiUpdateNavPanel(gui ,~, ~)
            % UPDATE NAVPANEL
            
            % clear everything
            set(gui.uiButtons,          'BackgroundColor', VanellusGUI.BUTTON_BGCOLOR, ...
                                        'ForegroundColor', VanellusGUI.BUTTON_FGCOLOR, ...
                                        'Visible', 'off'); % 'Enable', 'inactive', ...
            set(gui.uiTexts,            'String', '', ...
                                        'Visible', 'off' );

            % get currentData
            [currentExp, currentPos, currentReg] = gui.getCurrentExpPosReg();

            switch class(gui.mainPanels)
                case {'GUIVanellus'}
                    currentLevel = 1;
                    buttonNr_highlight = 1;
                case {'GUIExperiment'}
                    currentLevel = 2;
                    buttonNr_highlight = 3;
                case {'GUIPosition'}
                    currentLevel = 3;
                    buttonNr_highlight = 6;
                case {'GUIImages'}
                    currentLevel = 3;
                    buttonNr_highlight = 17;
                case {'GUIStabilization'}
                    currentLevel = 3;
                    buttonNr_highlight = 18;
                case {'GUIRegion'}
                    currentLevel = 4;
                    buttonNr_highlight = 9;
                case {'GUIRegionmask'}
                    currentLevel = 4;
                    buttonNr_highlight = 12;
                case {'GUIMasks'}
                    currentLevel = 4;
                    buttonNr_highlight = 13;
                case {'GUISegmentations'}
                    currentLevel = 4;
                    buttonNr_highlight = 14;
                case {'GUITrackings'}
                    currentLevel = 4;
                    buttonNr_highlight = 15;
                case {'GUITree'}
                    currentLevel = 4;
                    buttonNr_highlight = 16;
                case {'GUIAnnotations'}
                    currentLevel = 4;
                    buttonNr_highlight = 19;
                case {'GUISettings'} % special case
                    
                    switch class(gui.mainPanels.parent)
                        case {'Vanellus'}
                            currentLevel = 1;
                            buttonNr_highlight = 2;
                            
                        case {'VExperiment'}
                            currentLevel = 2;
                            buttonNr_highlight = 5;

                        case {'VPosition'}
                            currentLevel = 3;
                            buttonNr_highlight = 8;

                        case {'VRegion'}                    
                            currentLevel = 4;
                            buttonNr_highlight = 11;
                    
                        otherwise
                            buttonNr_highlight = 0;
                            disp('Daan: to implement');
                    end
                case {'GUIPicture'} % special case
                    
                    switch class(gui.mainPanels.picture.parent)
                        case {'VExperiment'}
                            buttonNr_highlight = 3;
                            currentLevel = 2;

                        case {'VPosition'}
                            buttonNr_highlight = 6;
                            currentLevel = 3;

                        case {'VRegion'}                    
                            buttonNr_highlight = 9;
                            currentLevel = 4;
                    
                        otherwise
                            buttonNr_highlight = 0;
                            disp('Daan: to implement');
                    end
                case {'GUILineages'}
                    currentLevel = 1;
                    buttonNr_highlight = 1;
                    
                otherwise
                    currentLevel = 0; 
                    buttonNr_highlight = 0;
            end
            
            % setting highlighted button
            if buttonNr_highlight
                gui.uiButtons( buttonNr_highlight ).BackgroundColor = gui.BUTTON_BGCOLOR_HIGHLIGHT;
                gui.uiButtons( buttonNr_highlight ).ForegroundColor = gui.BUTTON_FGCOLOR_HIGHLIGHT;
            end
            
            % setting save button color
            if ~isempty(currentExp) && ~currentExp.isSaved,     gui.uiButtons(4).BackgroundColor  = gui.BUTTON_BGCOLOR_NOTSAVED; end
            if ~isempty(currentPos) && ~currentPos.isSavedAll,  gui.uiButtons(7).BackgroundColor  = gui.BUTTON_BGCOLOR_NOTSAVED; end
            if ~isempty(currentReg) && ~currentReg.isSavedAll,  gui.uiButtons(10).BackgroundColor = gui.BUTTON_BGCOLOR_NOTSAVED; end
            CData = load('vanellusImages.mat', 'cdata_save', 'alphadata_save');
            for but = [4 7 10]
                gui.uiButtons(but).CData = VTools.applyAlpha(   CData.cdata_save, ...
                                                                CData.alphadata_save, ...
                                                                gui.uiButtons(but).BackgroundColor);
            end

            % turning visibility on
            switch currentLevel
                case 1
                    set(gui.uiButtons([1 2]),   'Enable', 'on', ...
                                                'Visible', 'on');
                    
                case 2
                    set(gui.uiButtons(1:5),   'Enable', 'on', ...
                                                'Visible', 'on');
                    set(gui.uiTexts(1),         'String', VTools.getParentfoldername(currentExp.filename), ...
                                                'Visible', 'on' );
                    
                case 3
                    set(gui.uiButtons([1:8 17 18]),   'Enable', 'on', ...
                                                'Visible', 'on');
                    set(gui.uiTexts(1),         'String', VTools.getParentfoldername(currentExp.filename), ...
                                                'Visible', 'on' );
                    set(gui.uiTexts(2),         'String', VTools.getParentfoldername(currentPos.filename), ...
                                                'Visible', 'on' );
                    set(gui.uiButtons(17:18),         'Enable', 'off');
                                            
                case 4
                    set(gui.uiButtons(1:16),  'Enable', 'on', ...
                                                'Visible', 'on');
                    set(gui.uiTexts(1),         'String', VTools.getParentfoldername(currentExp.filename), ...
                                                'Visible', 'on' );
                    set(gui.uiTexts(2),         'String', VTools.getParentfoldername(currentPos.filename), ...
                                                'Visible', 'on' );
                    set(gui.uiTexts(3),         'String', VTools.getParentfoldername(currentReg.filename), ...
                                                'Visible', 'on' );
                    v = Vanellus([], true);
                    if v.get('ann_show')
                        set(gui.uiButtons(19), 'Enable', 'on', ...
                                                 'Visible', 'on');
                    end
            end
        end
        
        function delete(gui)
            delete(gui.fig);
        end

        
        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function changePanels(gui, newPanels)
            % try to remember currentFrameIdx
            if isprop(gui.mainPanels,'currentFrameIdx') && isprop(newPanels,'currentFrameIdx')
                newPanels.currentFrameIdx = gui.mainPanels.currentFrameIdx;
            end
            
            % delete old mainPanels, special case when contentPanel is a ScrollPanel
            % in case new panel has scrollpanel, set setVisibleLocation to left top
            if isa(gui.mainPanels.contentPanel, 'ScrollPanel')
                delete( get(gui.mainPanels.contentPanel.panel, 'Children') );
            else
                delete( get(gui.mainPanels.contentPanel, 'Children') );
            end
            delete( get(gui.mainPanels.controlPanel, 'Children') );

            delete(gui.mainPanels);

            gui.mainPanels = newPanels;
            gui.changeToRecentMagnification();
            gui.guiPositionUpdate();
            gui.guiUpdate();
        end

        function actionFigResize(gui,~,~)
            pause(0.1);
            gui.guiPositionUpdate();
        end
        
        function actionKeyPressed(gui,hObject,eventdata)
            % ignore key clicks when editing uiEdit
            if isa(gui.fig.CurrentObject, 'matlab.ui.control.UIControl')
                if strcmp( gui.fig.CurrentObject.Style, 'edit')
                    disp('key press ignored');
                    return
                end
            end
            % ignore key clicks when editing in table
            if isa(gui.fig.CurrentObject, 'matlab.ui.control.Table')
                disp('key press ignored');
                return
            end
            if isa(gui.mainPanels, 'GUISettings') 
                if strcmp(gui.mainPanels.uiEdits(1).Visible, 'on')
                    disp('key press ignored');
                    return
                end
            end
            
            disp(['Clicked key: ' eventdata.Key]);
            switch upper(eventdata.Key)
                case {'Q'}
                    if strcmp(eventdata.Modifier, 'shift')
                        gui.actionCloseGUI();
                    end
                case {'MULTIPLY','B'}
                    gui.actionChangeMagnification(0);
                case {'SUBTRACT','N','HYPHEN'}
                    gui.actionChangeMagnification(-1);
                case {'ADD','M','EQUAL'}
                    gui.actionChangeMagnification(+1);
                case {'L'}
                    if strcmp(eventdata.Modifier, 'shift')
                        lin_filename = '/Users/kivietda/CloudStation/WORK/RESEARCH/SINGLE_CELL_GROWTH/LINEAGES/2017-02-27 All data/'; % 2017-02-24 Test
                        lin = VLineages([lin_filename]);                        
                        gui.changePanels( GUILineages( gui, lin ) );
                    end
                otherwise
                    gui.mainPanels.actionKeyPressed(hObject,eventdata)
            end
        end
        
        function actionCloseGUI(gui, ~, ~)
            choice = questdlg('Are you sure that you want to exit Vanellus?', 'Exit?', 'Yes', 'No', 'No');
            % Handle response
            switch choice
                case 'Yes'
                    disp('Exiting VanellusGUI....')
                    setpref('Vanellus', 'VanellusGui_position', gui.fig.Position);
                    gui.delete();
                case 'No'
                    disp('Not exiting VanellusGUI.')
            end
        end

        function actionChangeMagnification(gui, hObject, ~)
            if hObject == -1 && gui.currentMagnification > gui.MAGNIFICATIONS(1)
                idx = find(gui.MAGNIFICATIONS<gui.currentMagnification);
                gui.currentMagnification = gui.MAGNIFICATIONS(idx(end));
            elseif hObject == +1 && gui.currentMagnification < gui.MAGNIFICATIONS(end)
                idx = find(gui.MAGNIFICATIONS>gui.currentMagnification);
                gui.currentMagnification = gui.MAGNIFICATIONS(idx(1));
            elseif hObject == 0
                gui.currentMagnification = 1;
            end
            gui.guiUpdate();
                
            % Only do this when contentPanel is a ScrollPanel 
            if isa(gui.mainPanels.contentPanel, 'ScrollPanel')
                gui.mainPanels.guiUpdate();
            end
            
            % update recent magnification
            gui.setRecentMagnification();
        end        

        function actionNavButtonClicked(gui, hObject, ~)
            if ~gui.continueWithoutSaving(hObject), return; end

            [currentExp, currentPos, currentReg] = gui.getCurrentExpPosReg();
            
            if hObject == gui.uiButtons(1) % VAN
                gui.changePanels( GUIVanellus(gui, Vanellus('', true)) );
            elseif hObject == gui.uiButtons(3) % EXP
                exp = VExperiment( currentExp.filename );
                gui.changePanels( GUIExperiment(gui, exp) );
            elseif hObject == gui.uiButtons(6) % POS
                pos = VPosition( currentPos.filename );
                gui.changePanels( GUIPosition(gui, pos) );
            elseif hObject == gui.uiButtons(9) % REG
%                 reg = VRegion( currentReg.filename );
%                 gui.changePanels( GUIRegion(gui, reg) );
                gui.changePanels( GUIRegion(gui, currentReg) );
            elseif hObject == gui.uiButtons(2) % SETTINGS VAN
                gui.changePanels( GUISettings(gui, Vanellus('', true)) );
            elseif hObject == gui.uiButtons(5) % SETTINGS EXP
                exp = VExperiment( currentExp.filename );
                gui.changePanels( GUISettings(gui, exp) );
            elseif hObject == gui.uiButtons(8) % SETTINGS POS
                pos = VPosition( currentPos.filename );
                gui.changePanels( GUISettings(gui, pos) );
            elseif hObject == gui.uiButtons(11) % SETTINGS REG
                reg = VRegion( currentReg.filename );
                gui.changePanels( GUISettings(gui, reg) );
            elseif hObject == gui.uiButtons(12) % RMSK
                regionmask = currentReg.regionmask;
                gui.changePanels( GUIRegionmask(gui, regionmask) );
            elseif hObject == gui.uiButtons(13) % MSK
                masks = currentReg.masks;
                gui.changePanels( GUIMasks(gui, masks) );
            elseif hObject == gui.uiButtons(14) % SEG
                segmentations = currentReg.segmentations;
                gui.changePanels( GUISegmentations(gui, segmentations) );
            elseif hObject == gui.uiButtons(15) % TRK
                trackings = currentReg.trackings;
                gui.changePanels( GUITrackings(gui, trackings) );
            elseif hObject == gui.uiButtons(16) % TREE
                tree = currentReg.tree;
                gui.changePanels( GUITree(gui, tree) );
            elseif hObject == gui.uiButtons(17) % IMG

            
            elseif hObject == gui.uiButtons(18) % STB

            
            elseif hObject == gui.uiButtons(19) % ANN
                annotations = currentReg.annotations;
                gui.changePanels( GUIAnnotations(gui, annotations) );
            end
            
        end

        function actionSaveButtonClicked(gui, hObject, ~)
           	[currentExp, currentPos, currentReg] = gui.getCurrentExpPosReg();

            if hObject == gui.uiButtons(4) % EXP
                currentExp.save;
            elseif hObject == gui.uiButtons(7) % POS
                currentPos.save;
            elseif hObject == gui.uiButtons(10) % REG
                currentReg.save;
            end
            
            gui.guiUpdateNavPanel();
        end
        
        function tf = continueWithoutSaving(gui, hObject)

            switch class(gui.mainPanels)
                case {'GUIExperiment'}
                    isSaved = gui.mainPanels.experiment.isSaved;

                case {'GUIPosition'}
                    gui.mainPanels.position.autoSave();
                    isSaved = gui.mainPanels.position.isSaved;

                case {'GUIRegion'}
                    isSaved = gui.mainPanels.region.isSavedAll;
                    if hObject == gui.uiButtons(9) || hObject == gui.uiButtons(19) || hObject == gui.uiButtons(12) || hObject == gui.uiButtons(13) || hObject == gui.uiButtons(14) || hObject == gui.uiButtons(15) || hObject == gui.uiButtons(16) % REG, ANN, RMSK, MSK, SEG, TRK, TREE
                        isSaved = true;
                    end

                case {'GUIAnnotations'}
                    isSaved = gui.mainPanels.annotations.region.isSavedAll;
                    if hObject == gui.uiButtons(9) || hObject == gui.uiButtons(19) || hObject == gui.uiButtons(12) || hObject == gui.uiButtons(13) || hObject == gui.uiButtons(14) || hObject == gui.uiButtons(15) || hObject == gui.uiButtons(16) % REG, ANN, RMSK, MSK, SEG, TRK, TREE
                        isSaved = true;
                    end
                    
                case {'GUIRegionmask'}
                    isSaved = gui.mainPanels.regionmask.region.isSavedAll;
                    if hObject == gui.uiButtons(9) || hObject == gui.uiButtons(19) || hObject == gui.uiButtons(12) || hObject == gui.uiButtons(13) || hObject == gui.uiButtons(14) || hObject == gui.uiButtons(15) || hObject == gui.uiButtons(16) % REG, ANN, RMSK, MSK, SEG, TRK, TREE
                        isSaved = true;
                    end

                case {'GUIMasks'}
                    isSaved = gui.mainPanels.masks.region.isSavedAll;
                    if hObject == gui.uiButtons(9) || hObject == gui.uiButtons(19) || hObject == gui.uiButtons(12) || hObject == gui.uiButtons(13) || hObject == gui.uiButtons(14) || hObject == gui.uiButtons(15) || hObject == gui.uiButtons(16) % REG, ANN, RMSK, MSK, SEG, TRK, TREE
                        isSaved = true;
                    end
                    
                case {'GUISegmentations'}
                    isSaved = gui.mainPanels.segmentations.region.isSavedAll;
                    if hObject == gui.uiButtons(9) || hObject == gui.uiButtons(19) || hObject == gui.uiButtons(12) || hObject == gui.uiButtons(13) || hObject == gui.uiButtons(14) || hObject == gui.uiButtons(15) || hObject == gui.uiButtons(16) % REG, ANN, RMSK, MSK, SEG, TRK, TREE
                        isSaved = true;
                    end
                    
                case {'GUITrackings'}
                    isSaved = gui.mainPanels.trackings.region.isSavedAll;
                    if hObject == gui.uiButtons(9) || hObject == gui.uiButtons(19) || hObject == gui.uiButtons(12) || hObject == gui.uiButtons(13) || hObject == gui.uiButtons(14) || hObject == gui.uiButtons(15) || hObject == gui.uiButtons(16) % REG, ANN, RMSK, MSK, SEG, TRK, TREE
                        isSaved = true;
                    end

                case {'GUITree'}
                    isSaved = gui.mainPanels.tree.region.isSavedAll;
                    if hObject == gui.uiButtons(9) || hObject == gui.uiButtons(19) || hObject == gui.uiButtons(12) || hObject == gui.uiButtons(13) || hObject == gui.uiButtons(14) || hObject == gui.uiButtons(15) || hObject == gui.uiButtons(16) % REG, ANN, RMSK, MSK, SEG, TRK, TREE
                        isSaved = true;
                    end
                    
                    
                otherwise
                    isSaved = true;
            end
            
            if isSaved
                tf = true;
            else
                % dialog in case something has not been saved
                choice = questdlg('Leave without saving?', 'Leave without saving?', 'Yes', 'No', 'No');
                % Handle response
                switch choice
                    case 'Yes'
                        tf = true;
                    case 'No'
                        tf = false;
                end
            end
        end
        
        function changeToRecentMagnification(gui)
            gui.currentMagnification = 1;
            if ispref('Vanellus','VanellusGUI_recentMagnifications')
                
                % get saved magnifications
                recentMagnifications = getpref('Vanellus','VanellusGUI_recentMagnifications');

                % get mainPanels class
                mainPanels_class = class(gui.mainPanels);
                
                % get current magnification
                idx = find( strcmp(mainPanels_class, recentMagnifications(:,1)) );
                if ~isempty(idx)
                    gui.currentMagnification = recentMagnifications{idx,2};
                end                    
            end
        end

        function setRecentMagnification(gui)
            % get mainPanels class
            mainPanels_class = class(gui.mainPanels);
            
            % get saved recentMagnifications
            if ispref('Vanellus','VanellusGUI_recentMagnifications')
                recentMagnifications = getpref('Vanellus','VanellusGUI_recentMagnifications');
                
                % avoid error with older save version
                if ~iscell(recentMagnifications), recentMagnifications = {mainPanels_class, gui.currentMagnification}; end
                    
                % update or add current magnification
                idx = find( strcmp(mainPanels_class, recentMagnifications(:,1)) );
                if isempty(idx), idx = size(recentMagnifications,1)+1; end
                recentMagnifications(idx,:) = {mainPanels_class, gui.currentMagnification};
            else
                % add current magnification
                recentMagnifications(1,:) = {mainPanels_class, gui.currentMagnification};
            end
            
            % save magnification
            setpref('Vanellus','VanellusGUI_recentMagnifications', recentMagnifications);
        end
        
        
        %% helper %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function [currentExp, currentPos, currentReg] = getCurrentExpPosReg( gui )
            currentExp = [];
            currentPos = [];
            currentReg = [];
            switch class(gui.mainPanels)
                case {'GUIVanellus'}

                case {'GUIExperiment'}
                    currentExp = gui.mainPanels.experiment;

                case {'GUIPosition'}
                    currentExp = gui.mainPanels.position.experiment;
                    currentPos = gui.mainPanels.position;

                case {'GUIImages'}
                    currentExp = gui.mainPanels.images.position.experiment;
                    currentPos = gui.mainPanels.images.position;
                    
                case {'GUIRegistration'}
                    currentExp = gui.mainPanels.registration.images.position.experiment;
                    currentPos = gui.mainPanels.registration.images.position;
                    
                case {'GUIRegion'}
                    currentExp = gui.mainPanels.region.position.experiment;
                    currentPos = gui.mainPanels.region.position;
                    currentReg = gui.mainPanels.region;

                case {'GUIAnnotations'}
                    currentExp = gui.mainPanels.annotations.region.position.experiment;
                    currentPos = gui.mainPanels.annotations.region.position;
                    currentReg = gui.mainPanels.annotations.region;
                    
                case {'GUIRegionmask'}
                    currentExp = gui.mainPanels.regionmask.region.position.experiment;
                    currentPos = gui.mainPanels.regionmask.region.position;
                    currentReg = gui.mainPanels.regionmask.region;

                case {'GUIMasks'}
                    currentExp = gui.mainPanels.masks.region.position.experiment;
                    currentPos = gui.mainPanels.masks.region.position;
                    currentReg = gui.mainPanels.masks.region;

                case {'GUISegmentations'}
                    currentExp = gui.mainPanels.segmentations.region.position.experiment;
                    currentPos = gui.mainPanels.segmentations.region.position;
                    currentReg = gui.mainPanels.segmentations.region;

                case {'GUITrackings'}
                    currentExp = gui.mainPanels.trackings.region.position.experiment;
                    currentPos = gui.mainPanels.trackings.region.position;
                    currentReg = gui.mainPanels.trackings.region;

                case {'GUITree'}
                    currentExp = gui.mainPanels.tree.region.position.experiment;
                    currentPos = gui.mainPanels.tree.region.position;
                    currentReg = gui.mainPanels.tree.region;
                    
                case {'GUISettings'}
                    switch class(gui.mainPanels.parent)
                        case {'Vanellus'}

                        case {'VExperiment'}
                            currentExp = gui.mainPanels.parent;

                        case {'VPosition'}
                            currentExp = gui.mainPanels.parent.experiment;
                            currentPos = gui.mainPanels.parent;

                        case {'VRegion'}
                            currentExp = gui.mainPanels.parent.position.experiment;
                            currentPos = gui.mainPanels.parent.position;
                            currentReg = gui.mainPanels.parent;
                    end
                    
                case {'GUIPicture'}
                    switch class(gui.mainPanels.picture.parent)
                        case {'VPosition'}
                            currentExp = gui.mainPanels.picture.parent.experiment;
                            currentPos = gui.mainPanels.picture.parent;

                        case {'VRegion'}
                            currentExp = gui.mainPanels.picture.parent.position.experiment;
                            currentPos = gui.mainPanels.picture.parent.position;
                            currentReg = gui.mainPanels.picture.parent;
                    end                    
            end
        end
        
        function checkMatlabVersion( gui )
            messages = Vanellus.checkMatlabVersion();
            if numel(messages)
                warndlg(messages);
            end
        end
        
        function removeFocusFromObject( gui, hObject)
            gui.fig.CurrentObject = gui.fig;
            hObject.Enable = 'off';
            drawnow;
            hObject.Enable = 'on';
        end
        
    end
end
