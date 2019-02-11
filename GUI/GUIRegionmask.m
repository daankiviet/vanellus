classdef GUIRegionmask < GUITogglePanel
% GUIRegionmask GUI to perform manual setting of Region mask

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant = true)
        VIS_BGCOLOR             = [0.0 0.0 0.0];
        VIS_EDGECOLOR           = [1.0 1.0 1.0];
        VIS_MASKCOLOR           = [0.5 0.5 1.0];
        VIS_LASTCHANGECOLOR     = [1.0 0.5 0.5];
        BUT_SELECTEDCOLOR       = [0.7 0.7 0.7];
    end
    
    properties (Transient) % not stored
        vanellusGUI
        regionmask
        
        contentPanel
        controlPanel

        uiTogglePanels
        uiTexts
        uiButtons
        uiTables
        uiEdits
        
        prevClickCoor
    end

    properties (Dependent) % calculated on the fly
    end    
    
    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUIRegionmask(vanellusGUI, regionmask)
            if nargin < 1, error('Need VanellusGUI as argument'); end
            if nargin < 2, error('Need VRegionmask as argument'); end
            
            gui.vanellusGUI = vanellusGUI;
            gui.regionmask = regionmask;
            
            gui.guiBuild();
%             gui.regionmask.updateAvImage();
        end
 
        function guiBuild(gui)
            % SET CONTROLPANEL
            gui.controlPanel                        = uipanel(gui.vanellusGUI.fig);
            gui.controlPanel.BackgroundColor        = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.controlPanel.BorderType             = 'none';
            gui.controlPanel.Units                  = 'pixels';

            gui.uiTogglePanels                      = uipanel(gui.controlPanel);
            gui.uiTogglePanels(1).BackgroundColor   = gui.vanellusGUI.DISPLAYPANEL_BGCOLOR;
            gui.uiTogglePanels(1).Title             = 'Display';
            gui.uiTogglePanels(1).BorderType        = 'beveledin';
            gui.uiTogglePanels(1).BorderWidth       = 2;
            gui.uiTogglePanels(1).Units             = 'pixels';            
            
            gui.uiTogglePanels(2)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(2).BackgroundColor   = gui.vanellusGUI.EDITPANEL_BGCOLOR;
            gui.uiTogglePanels(2).Title             = 'Edit';

            gui.uiTogglePanels(3)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(3).BackgroundColor   = gui.vanellusGUI.ANALYSISPANEL_BGCOLOR;
            gui.uiTogglePanels(3).Title             = 'Analysis';
            
            gui.uiTogglePanels(4)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(4).Title             = 'Click behavior';

            gui.uiTogglePanels(5)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(5).BackgroundColor   = gui.vanellusGUI.SETTINGSPANEL_BGCOLOR;
            gui.uiTogglePanels(5).Title             = 'Relevant settings';
            
            %% Display Panel
            gui.uiButtons                           = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(1).Style                  = 'togglebutton';
            gui.uiButtons(1).Min                    = 0;
            gui.uiButtons(1).Max                    = 1;
            gui.uiButtons(1).Value                  = 1;
            gui.uiButtons(1).String                 = 'Phase';
            gui.uiButtons(1).Callback               = @gui.actionChangeDisplay;

            gui.uiButtons(2)                        = copyobj(gui.uiButtons(1), gui.uiTogglePanels(1));
            gui.uiButtons(2).String                 = 'Mask';
            gui.uiButtons(2).Callback               = @gui.actionChangeDisplay;

            gui.uiButtons(3)                        = copyobj(gui.uiButtons(1), gui.uiTogglePanels(1));
            gui.uiButtons(3).String                 = 'Edge';
            gui.uiButtons(3).Value                  = 0;
            gui.uiButtons(3).Callback               = @gui.actionChangeDisplay;

           
            %% Edit Panel
            gui.uiButtons(11)                       = uicontrol(gui.uiTogglePanels(2));
            gui.uiButtons(11).Style                 = 'pushbutton';
            gui.uiButtons(11).String                = 'Clear';
            gui.uiButtons(11).Callback              = @gui.actionClear;

            gui.uiButtons(12)                       = copyobj(gui.uiButtons(11), gui.uiTogglePanels(2));
            gui.uiButtons(12).String                = 'Fill holes';
            gui.uiButtons(12).Callback              = @gui.actionFill;
            
            gui.uiButtons(13)                       = copyobj(gui.uiButtons(11), gui.uiTogglePanels(2));
            gui.uiButtons(13).String                = 'Add edges';
            gui.uiButtons(13).Callback              = @gui.actionAddEdges;
            
            gui.uiTexts                             = uicontrol(gui.uiTogglePanels(2));
            gui.uiTexts(1).Style                    = 'text';
            gui.uiTexts(1).String                   = 'Selected Frames';
            gui.uiTexts(1).BackgroundColor          = gui.uiTexts(1).Parent.BackgroundColor;
            gui.uiTexts(1).HorizontalAlignment      = 'left';

            gui.uiEdits                             = uicontrol(gui.uiTogglePanels(2));
            gui.uiEdits(1).Style                    = 'edit';
            gui.uiEdits(1).String                   = '';
            gui.uiEdits(1).KeyPressFcn              = @gui.actionChangeSelectedFrames;
            
            gui.uiButtons(14)                       = copyobj(gui.uiButtons(11), gui.uiTogglePanels(2));
            gui.uiButtons(14).String                = 'Clear';
            gui.uiButtons(14).Callback              = @gui.actionClearSelectedFrames;            
            
            gui.uiButtons(15)                       = copyobj(gui.uiButtons(11), gui.uiTogglePanels(2));
            gui.uiButtons(15).String                = 'Undo';
            gui.uiButtons(15).Callback              = @gui.actionUndoButtonPressed;                                  
            
            %% Analysis Panel
            gui.uiButtons(21)                       = copyobj(gui.uiButtons(11), gui.uiTogglePanels(3));
            gui.uiButtons(21).String                = 'Recalculate';
            gui.uiButtons(21).Callback              = @gui.actionCalculate;
            
            gui.uiButtons(22)                       = copyobj(gui.uiButtons(11), gui.uiTogglePanels(3));
            gui.uiButtons(22).String                = 'Recalc Av Im';
            gui.uiButtons(22).Callback              = @gui.actionCalculateAvImage;            
            
            %% Click Behavior Panel
            gui.uiTexts(31)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(31).BackgroundColor         = gui.uiTexts(31).Parent.BackgroundColor;
            gui.uiTexts(31).String                  = 'Left click   : Add';

            gui.uiTexts(32)                         = copyobj(gui.uiTexts(31), gui.uiTogglePanels(4));
            gui.uiTexts(32).String                  = 'Right click : Remove';
            
            gui.uiButtons(31)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(4));
            gui.uiButtons(31).String                = 'P';
            gui.uiButtons(31).TooltipString         = 'Pixel';
            gui.uiButtons(31).Value                 = 0;
            gui.uiButtons(31).Callback              = @gui.actionChangeClickBehavior;
            
            gui.uiButtons(32)                       = copyobj(gui.uiButtons(31), gui.uiTogglePanels(4));
            gui.uiButtons(32).String                = 'L';
            gui.uiButtons(32).TooltipString         = 'Line';
            gui.uiButtons(32).Callback              = @gui.actionChangeClickBehavior;
            
            gui.uiButtons(33)                       = copyobj(gui.uiButtons(31), gui.uiTogglePanels(4));
            gui.uiButtons(33).String                = 'A';
            gui.uiButtons(33).TooltipString         = 'Area';
            gui.uiButtons(33).Callback              = @gui.actionChangeClickBehavior;

            gui.uiButtons(34)                       = copyobj(gui.uiButtons(31), gui.uiTogglePanels(4));
            gui.uiButtons(34).String                = 'E';
            gui.uiButtons(34).TooltipString         = 'Edgefill';
            gui.uiButtons(34).Callback              = @gui.actionChangeClickBehavior;
            gui.uiButtons(34).Value                 = 1;

            gui.uiButtons(35)                       = copyobj(gui.uiButtons(31), gui.uiTogglePanels(4));
            gui.uiButtons(35).String                = 'C';
            gui.uiButtons(35).TooltipString         = 'Connected area';
            gui.uiButtons(35).Callback              = @gui.actionChangeClickBehavior;
            
            %% Relevant Settings Panel
            gui.uiTables                            = uitable(gui.uiTogglePanels(5));
            gui.uiTables(1).ColumnName              = [];
            gui.uiTables(1).ColumnWidth             = {130 125};
            gui.uiTables(1).Enable                  = 'on';
            gui.uiTables(1).RowStriping             = 'off';
            
            %% SET TOOLTIPS
%             gui.uiButtons(XX).TooltipString     = 'keyboard shortcut = u';
            gui.uiButtons(3).TooltipString          = 'keyboard shortcut = 2';
            gui.uiButtons(2).TooltipString          = 'keyboard shortcut = 3';
            gui.uiButtons(1).TooltipString          = 'keyboard shortcut = 4';
            gui.uiButtons(31).TooltipString         = 'add/remove a pixel (keyboard shortcut = p)';
            gui.uiButtons(32).TooltipString         = 'add/remove a line (keyboard shortcut = l)';
            gui.uiButtons(33).TooltipString         = 'add/remove an area (keyboard shortcut = a)';
            gui.uiButtons(34).TooltipString         = 'add/remove an edge bound region (keyboard shortcut = e)';
            gui.uiButtons(35).TooltipString         = 'add/remove a connected area (keyboard shortcut = c)';
            gui.uiButtons(12).TooltipString         = 'keyboard shortcut = i';
            
            % SET CONTENTPANEL
            gui.contentPanel = ScrollPanel(gui.vanellusGUI.fig);
        end

        function guiPositionUpdate(gui)
            % SET CONTROLPANEL BUTTONS
            % Position coordinates: [left bottom width height]
            
            gui.uiTogglePanels(1).Position      = [ 10 200 280 95]; % Display
            gui.uiButtons(3).Position           = [180  60  80  20];
            gui.uiButtons(2).Position           = [180  35  80  20];
            gui.uiButtons(1).Position           = [180  10  80  20];
            
            gui.uiTogglePanels(2).Position      = [ 10 200 280  80]; % Edit
            gui.uiTexts(1).Position             = [ 10  38  75  20];
            gui.uiEdits(1).Position             = [ 85  40 145  20];
            gui.uiButtons(11).Position          = [ 10  10  60  20];
            gui.uiButtons(12).Position          = [ 80  10  60  20];
            gui.uiButtons(13).Position          = [150  10  60  20];
            gui.uiButtons(14).Position          = [230  40  40  20];
            gui.uiButtons(15).Position          = [220  10  50  20];

            gui.uiTogglePanels(3).Position      = [ 10 200 280  50]; % Analysis
            gui.uiButtons(21).Position          = [ 10  10  80  20];
            gui.uiButtons(22).Position          = [100  10  80  20];
            
            gui.uiTogglePanels(4).Position      = [ 10 200 280 65]; % Click Behavior
            gui.uiTexts(31).Position            = [ 10  28 100  15];
            gui.uiTexts(32).Position            = [ 10   8 100  15];
            gui.uiButtons(31).Position          = [160  15  20  20];
            gui.uiButtons(32).Position          = [182  15  20  20];
            gui.uiButtons(33).Position          = [204  15  20  20];
            gui.uiButtons(34).Position          = [226  15  20  20];
            gui.uiButtons(35).Position          = [248  15  20  20];
            
            gui.uiTogglePanels(5).Position      = [10 200 280 280]; % Relevant Settings Panel
            gui.uiTables(1).Position            = [ 10 10 260 250];
            
            % INITIALIZE TOGGLE PANELS
            gui.guiInitializeTogglePanels();            
        end

        function guiUpdate(gui, hObject, eventdata)
            gui.vanellusGUI.fig.Pointer = 'watch'; drawnow; % indicate that GUI is working
            % UPDATE CONTROLPANEL
            
            % update settings Table
            [~, ~, combined]            = gui.getSettingsData();
            gui.uiTables(1).RowName     = {};  % settingsList
            gui.uiTables(1).Data        = combined; % data;
            if gui.uiTables(1).Extent(3) < gui.uiTables(1).Position(3), gui.uiTables(1).Position(3) = gui.uiTables(1).Extent(3); end            
            
            % SET SELECTED FRAMES
            gui.uiEdits(1).String = vect2colon( gui.regionmask.frames' );
            % coloring dependend on whether img_frames is set locally
            if isempty( gui.regionmask.getLocal('img_frames') ) % not set here, but inherited from parent
                gui.uiEdits(1).ForegroundColor = [0.4 0.4 0.4];
            else
                gui.uiEdits(1).ForegroundColor = [0 0 0];
            end
            
            % DRAW CLICK BEHAVIOR BUTTONS
            for i = 31:35
                if gui.uiButtons(i).Value
                    gui.uiButtons(i).BackgroundColor   = gui.BUT_SELECTEDCOLOR;
                    gui.uiButtons(i).FontWeight        = 'bold';
                else
                    gui.uiButtons(i).BackgroundColor   = gui.uiButtons(i).Parent.BackgroundColor;
                    gui.uiButtons(i).FontWeight        = 'normal';
                end
            end
            
            % UPDATE CONTENTPANEL (=SCROLLPANEL)
            rgb = gui.getMaskImage();
            hIm = gui.contentPanel.showImage(rgb, gui.vanellusGUI.currentMagnification);
            set(hIm, 'ButtonDownFcn', @gui.actionImageClicked);

            % UPDATE NAVPANEL
            gui.vanellusGUI.guiUpdateNavPanel();
            
            gui.vanellusGUI.fig.Pointer = 'arrow'; % indicate that GUI is finished
        end

        function save(gui, hObject, eventdata)
            if gui.regionmask.save()
                % set view to phase with mask only
                gui.uiButtons(1).Value              = 1;
                gui.uiButtons(3).Value              = 0;
                gui.uiButtons(2).Value              = 1;
            end
            
            gui.guiUpdate();
        end
        
        
        %% Gui %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rgb = getMaskImage(gui)
            gui.regionmask.updateAvImage();
            avImage = gui.regionmask.avIm;
            edge    = gui.regionmask.avIm_edge;
            mask    = gui.regionmask.mask;

            % Set background color
            rgb = ones([size(mask) 3]) .* repmat(reshape(gui.VIS_BGCOLOR, [1 1 3]), size(mask));
            
            % add mask
            if gui.uiButtons(2).Value
                tmp = ones([size(mask) 3]) .* repmat(reshape(gui.VIS_MASKCOLOR, [1 1 3]), size(mask));
                rgb( repmat(mask, [1 1 3]) ) = tmp( repmat(mask, [1 1 3]) );
            end

            % add edge
            if gui.uiButtons(3).Value
                tmp = ones([size(mask) 3]) .* repmat(reshape(gui.VIS_EDGECOLOR, [1 1 3]), size(mask));
                rgb( repmat(edge, [1 1 3]) ) = tmp( repmat(edge, [1 1 3]) );
            end
            
            % add phase
            if gui.uiButtons(1).Value
                rgb = VTools.addPhaseOverlayToRGB(rgb, avImage);
            end
            
            % apply additional region rotation (only for visualization)
            rotationAdditional90Idx = gui.regionmask.region.rotationAdditional90Idx;
            if rotationAdditional90Idx ~= 4
                rgb_old = rgb; clear rgb;
                for i=1:3
                    rgb(:,:,i) = rot90( rgb_old(:,:,i), rotationAdditional90Idx);
                end
            end
        end
        
        function [settingsList, data, combined] = getSettingsData(gui) 
            settings        = gui.regionmask.getCurrentDefaultSettings();
            settingsList    = settings(:,1);
            data            = cell( numel(settingsList), 1);
            combined        = cell( numel(settingsList), 2);
            for i = 1:numel(settingsList)
                text = VTools.convertValueToChar( settings{i,3} );
                data{i,1} = VTools.getHTMLColoredText( text, [0 0 0]);
                text2 = VTools.convertValueToChar( settings{i,1} );
                combined{i,1} = VTools.getHTMLColoredText( text2, [  0   0   0], [0.8 0.8 0.8]);
                combined{i,2} = VTools.getHTMLColoredText( text , [0.2 0.2 0.2]);
            end
        end       
        
        
        %% Image or Key Click %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionKeyPressed(gui, hObject, eventdata)
            switch upper(eventdata.Key)
                case {'P'}
                    disp(['Clicked key: ' eventdata.Key ' -> Pixel']);
                    gui.actionChangeClickBehavior( gui.uiButtons(31) );
                case {'L'}
                    disp(['Clicked key: ' eventdata.Key ' -> Line']);
                    gui.actionChangeClickBehavior( gui.uiButtons(32) );
                case {'A'}
                    disp(['Clicked key: ' eventdata.Key ' -> Area']);
                    gui.actionChangeClickBehavior( gui.uiButtons(33) );
                case {'E'}
                    disp(['Clicked key: ' eventdata.Key ' -> Edgefill']);
                    gui.actionChangeClickBehavior( gui.uiButtons(34) );
                case {'C'}
                    disp(['Clicked key: ' eventdata.Key ' -> Connected area']);
                    gui.actionChangeClickBehavior( gui.uiButtons(35) );
                    
                case {'I'}
                    disp(['Clicked key: ' eventdata.Key ' -> filling holes']);
                    gui.actionFill();
                case {'U'}
                    disp(['Clicked key: ' eventdata.Key ' -> Undo']);
                    gui.regionmask.undo();
                    gui.guiUpdate();
                case {'S'}
                    disp(['Clicked key: ' eventdata.Key ' -> saving']);
                    gui.actionSaveRegionmask();

                case {'2'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Edge in Display']);
                    gui.uiButtons(3).Value = ~gui.uiButtons(3).Value;
                    gui.guiUpdate();
                case {'3'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Mask in Display']);
                    gui.uiButtons(2).Value = ~gui.uiButtons(2).Value;
                    gui.guiUpdate();
                case {'4'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Phase in Display']);
                    gui.uiButtons(1).Value = ~gui.uiButtons(1).Value;
                    gui.guiUpdate();
            end
        end
        
        function actionImageClicked(gui, hObject, eventdata)
            mouseButtonType     = get(gui.vanellusGUI.fig,'SelectionType');
            contentPanelAx      = findall(gui.contentPanel.contentPanel, 'type', 'axes');
            hIm                 = contentPanelAx.Children;

            if hObject == hIm
                coor = uint16(get(contentPanelAx,'CurrentPoint')); % returns [col row]
                coor = coor(1,[2 1]);
                
                % in case image was shown with additional region rotation, will need to convert coor
                coor = VTools.rotateCoordinates( coor, gui.regionmask.region.rotationAdditional90Idx, gui.regionmask.region.regionSize); 
                % disp(['Rotated Screen coordinates     : (' num2str(coor(1)) ',' num2str(coor(2)) ') [ L, T ] ']);
                
                if mouseButtonType(1)=='n' % normal = left mouse button
                    if gui.uiButtons(31).Value % 'P'
                        disp(['Clicked mouse : left -> add pixel to mask @ ' num2str(coor)]);
                        gui.regionmask.editByAddingPixel(coor);
                        
                    elseif gui.uiButtons(32).Value % 'L'
                        if isempty( gui.prevClickCoor ) % first click
                            disp(['Clicked mouse : left -> add line to mask, 1st click at @ ' num2str(coor)]);
                            gui.prevClickCoor = coor;
                        else % second click
                            disp(['Clicked mouse : left -> add line to mask, 2nd click at @ ' num2str(coor)]);
                            gui.regionmask.editByAddingLine( gui.prevClickCoor, coor);
                            gui.prevClickCoor   = [];
                        end
                        
                    elseif gui.uiButtons(33).Value % 'A'
                        disp(['Clicked mouse : left -> draw area to add to mask']);
                        contentPanelAx  = gui.contentPanel.contentPanel.Children; % findall(gui.contentPanel.contentPanel, 'type', 'axes');
                        polygon         = impoly(contentPanelAx);
                        area            = polygon.getPosition();
                        polygon.delete();
                        mask = poly2mask( area(:,1), area(:,2), double(gui.regionmask.region.rotatedRegionSize(1)), double(gui.regionmask.region.rotatedRegionSize(2)));
                        mask = rot90(mask, -gui.regionmask.region.rotationAdditional90Idx); % in case image was shown with additional region rotation, will need to convert mask
                        gui.regionmask.editByAddingArea( mask );
                        
                    elseif gui.uiButtons(34).Value % 'E'
                        disp(['Clicked mouse : left -> add edgeFill to mask @ ' num2str(coor)]);
                        gui.regionmask.editByAddingEdgefill(coor);

                    elseif gui.uiButtons(35).Value % 'C'
                        disp(['Clicked mouse : left -> add connected area to mask @ ' num2str(coor) ' -> not doing anything']);
                        
                    end

                elseif mouseButtonType(1)=='a' % alternate = ctrl+left button or right mouse button
                    if gui.uiButtons(31).Value % 'P'
                        disp(['Clicked mouse : right -> remove pixel from mask @ ' num2str(coor)]);
                        gui.regionmask.editByRemovingPixel(coor);
                        
                    elseif gui.uiButtons(32).Value % 'L'
                        if isempty( gui.prevClickCoor ) % first click
                            disp(['Clicked mouse : right -> remove line from mask, 1st click at @ ' num2str(coor)]);
                            gui.prevClickCoor = coor;
                        else % second click
                            disp(['Clicked mouse : right -> remove line from mask, 2nd click at @ ' num2str(coor)]);
                            gui.regionmask.editByRemovingLine( gui.prevClickCoor, coor);
                            gui.prevClickCoor   = [];
                        end
                        
                    elseif gui.uiButtons(33).Value % 'A'
                        disp(['Clicked mouse : right -> draw area to remove from mask']);
                        contentPanelAx  = gui.contentPanel.contentPanel.Children; % findall(gui.contentPanel.contentPanel, 'type', 'axes');
                        polygon         = impoly(contentPanelAx);
                        area            = polygon.getPosition();
                        polygon.delete();
                        mask = poly2mask( area(:,1), area(:,2), double(gui.regionmask.region.rotatedRegionSize(1)), double(gui.regionmask.region.rotatedRegionSize(2)));
                        mask = rot90(mask, -gui.regionmask.region.rotationAdditional90Idx); % in case image was shown with additional region rotation, will need to convert mask
                        gui.regionmask.editByRemovingArea( mask );
                    
                    elseif gui.uiButtons(34).Value % 'E'
                        disp(['Clicked mouse : right -> remove edgeFill from mask @ ' num2str(coor)]);
                        gui.regionmask.editByRemovingEdgefill(coor);
                        
                    elseif gui.uiButtons(35).Value % 'C'
                        disp(['Clicked mouse : right -> remove connected area from mask @ ' num2str(coor)]);
                        gui.regionmask.editByRemovingConnectedarea(coor);

                    end

                end
                
                gui.guiUpdate();
            end
        end
        
        
        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionClear(gui, hObject, eventdata)
            gui.regionmask.changeMaskClear();
            gui.guiUpdate();
        end
        
        function actionFill(gui, hObject, eventdata)
            gui.regionmask.changeMaskFillHoles();
            gui.guiUpdate();
        end

        function actionAddEdges(gui, hObject, eventdata)
            gui.regionmask.changeMaskAddEdges();
            gui.guiUpdate();
        end
        
        function actionCalculate(gui, hObject, eventdata)
            gui.regionmask.calcAndSetRegionmask();
            gui.guiUpdate();
        end

        function actionCalculateAvImage(gui, hObject, eventdata)
            gui.regionmask.calcAndSetAvImage();
            gui.guiUpdate();
        end
        
        function actionSaveRegionmask( gui, ~, ~)
            gui.regionmask.region.save();
            gui.vanellusGUI.guiUpdateNavPanel();
        end         
        
        function actionChangeDisplay(gui, hObject, eventdata)
            gui.guiUpdate();
        end
        
        function actionChangeSelectedFrames( gui, ~, eventdata)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            if ~isequal( eventdata.Key, 'return'), return; end
            drawnow; % makes sure that uiEdits(1) is up to date
            action = ['gui.regionmask.set(''img_frames'', ' '[' gui.uiEdits(1).String ']' ');'];
            eval(action);
            gui.guiUpdate();
        end

        function actionClearSelectedFrames( gui, ~, ~)
            gui.regionmask.unset('img_frames');
            gui.guiUpdate();
        end
        
        function actionChangeClickBehavior(gui, hObject, ~)
            switch upper( hObject.String )
                case {'P','L','A','E','C'}
                    for i = 31:35
                        gui.uiButtons(i).Value  = 0;
                    end
                    hObject.Value  = 1;
                    gui.vanellusGUI.removeFocusFromObject(hObject);
                    gui.prevClickCoor = []; % forget previous clicks
                    
                    % turn edge display on
                    if strcmp(upper(hObject.String), 'E')
                        gui.uiButtons(3).Value              = 1;
                    end
            end
            gui.guiUpdate();
        end
        
        function actionUndoButtonPressed(gui, ~, ~)
            gui.regionmask.undo();
            gui.guiUpdate();
        end
        
    end
end


%                 % in case image was shown with additional region rotation, will need to convert coor
%                 rotationAdditional90Idx = gui.regionmask.region.rotationAdditional90Idx;
%                 if rotationAdditional90Idx ~= 4
%                     % 2DO: this works, but can probably be faster with a direct mathematical formula
%                     t = zeros(size(gui.regionmask.mask));
%                     t = rot90(t, rotationAdditional90Idx);
%                     t(coor(1), coor(2)) = 1; % disp(['size=' num2str(size(gui.regionMask.mask)) ' & coor=' num2str(coor)]);
%                     t = rot90(t, -rotationAdditional90Idx);
%                     [coor(1),coor(2)] = find(t); % disp(['new coor=' num2str(coor)]);
%                 end