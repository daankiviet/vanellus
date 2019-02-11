classdef GUIAnnotations < GUITogglePanel
% GUIAnnotations

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant = true)
        BACKGROUND_COLOR        = [0.0 0.0 0.0];
        BOX_COLOR               = [1.0 1.0 1.0];
        BOX_COLOR_SELECTED      = [0.8 0.4 0.4];
        BOX_OPACITY             = 0.2;
        BOX_OPACITY_SELECTED    = 0.8;
    end
    
    properties (Transient) % not stored
        vanellusGUI
        annotations

        contentPanel
        controlPanel
        sidePanel

        sidePanelAxes
        uiTogglePanels
        uiTexts
        uiButtons
        uiEdits
        uiTables
        
        currentFrameIdx
        currentCellNrIdx
        currentAnnIdx
    end 
   
    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUIAnnotations(vanellusGUI, annotations)
            if nargin < 1, error('Need VanellusGUI as argument'); end
            if nargin < 2, error('Need annotations as argument'); end

            gui.vanellusGUI     = vanellusGUI;
            gui.annotations     = annotations;
            gui.currentFrameIdx = 1;
            gui.currentCellNrIdx = 1;
            gui.currentAnnIdx   = 1;
            
%             gui.guiUpdateColorTable();
            gui.guiBuild();
        end
 
        function guiBuild(gui)
            % SET CONTROLPANEL
            gui.controlPanel                        = uipanel(gui.vanellusGUI.fig);
            gui.controlPanel.BackgroundColor        = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.controlPanel.BorderType             = 'none';
            gui.controlPanel.Units                  = 'pixels';
            
            % SET CONTROLPANEL
            gui.uiTogglePanels                      = uipanel(gui.controlPanel);
            gui.uiTogglePanels(1).BackgroundColor   = gui.vanellusGUI.DISPLAYPANEL_BGCOLOR;
            gui.uiTogglePanels(1).Title             = 'Display';
            gui.uiTogglePanels(1).BorderType        = 'beveledin'; % 'etchedin' (default) | 'etchedout' | 'beveledin' | 'beveledout' | 'line' | 'none'
            gui.uiTogglePanels(1).BorderWidth       = 2; % 1 (default)
            gui.uiTogglePanels(1).Units             = 'pixels';
            
            gui.uiTogglePanels(2)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(2).BackgroundColor   = gui.vanellusGUI.EDITPANEL_BGCOLOR;
            gui.uiTogglePanels(2).Title             = 'Cells';
            
            gui.uiTogglePanels(3)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(3).BackgroundColor   = gui.vanellusGUI.ANALYSISPANEL_BGCOLOR;
            gui.uiTogglePanels(3).Title             = 'Annotations';
            
            gui.uiTogglePanels(4)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(4).Title             = 'Click behavior';

            gui.uiTogglePanels(5)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(5).BackgroundColor   = gui.vanellusGUI.SETTINGSPANEL_BGCOLOR;
            gui.uiTogglePanels(5).Title             = 'Relevant settings';
            
            gui.uiTexts                         = uicontrol(gui.uiTogglePanels(1));
            gui.uiTexts(1).Style                = 'text';
            gui.uiTexts(1).String               = 'Frame';
            gui.uiTexts(1).BackgroundColor      = gui.controlPanel.BackgroundColor;
            gui.uiTexts(1).HorizontalAlignment  = 'left';

            gui.uiButtons                       = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(1).Style              = 'pushbutton';
            gui.uiButtons(1).String             = 'Prev';
            gui.uiButtons(1).Callback           = @gui.actionChangeFrame;
            
            gui.uiEdits                         = uicontrol(gui.uiTogglePanels(1));
            gui.uiEdits(1).Style                = 'edit';
            gui.uiEdits(1).String               = '';
            gui.uiEdits(1).KeyPressFcn          = @gui.actionChangeFrame;
                                    
            gui.uiButtons(2)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(1));
            gui.uiButtons(2).String             = 'Next';
            gui.uiButtons(2).Callback           = @gui.actionChangeFrame;                                  

            gui.uiButtons(4)                    = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(4).Style              = 'togglebutton';
            gui.uiButtons(4).Min                = 0;
            gui.uiButtons(4).Max                = 1;
            gui.uiButtons(4).Value              = 1;
            gui.uiButtons(4).String             = 'Cell #';
            gui.uiButtons(4).Callback           = @gui.actionTogglePicture;

            gui.uiButtons(7)                    = copyobj(gui.uiButtons(4), gui.uiTogglePanels(1));
            gui.uiButtons(7).String             = 'Phase';
            gui.uiButtons(7).Value              = 1;
            gui.uiButtons(7).Callback           = @gui.actionTogglePicture;

            gui.uiButtons(8)                    = copyobj(gui.uiButtons(4), gui.uiTogglePanels(1));
            gui.uiButtons(8).String             = 'Plot';
            gui.uiButtons(8).Value              = 1;
            gui.uiButtons(8).Callback           = @gui.actionTogglePlot;
            
            gui.uiTexts(2)                      = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
            gui.uiTexts(2).String               = 'Left click   : Select Cell';
            
            gui.uiTexts(3)                      = copyobj(gui.uiTexts(2), gui.uiTogglePanels(4));
            gui.uiTexts(3).String               = 'Right click : Create Cell';
            
            gui.uiTexts(4)                      = copyobj(gui.uiTexts(2), gui.uiTogglePanels(4));
            gui.uiTexts(4).String               = 'Shift click  : Delete Cell';
            
            gui.uiTables                        = uitable(gui.uiTogglePanels(5));
            gui.uiTables(1).ColumnName          = [];
            gui.uiTables(1).ColumnWidth         = {130 125};
            gui.uiTables(1).ColumnEditable      = [false true];
            gui.uiTables(1).Enable              = 'on';
            gui.uiTables(1).RowStriping         = 'off';
            gui.uiTables(1).CellEditCallback    = @gui.actionEditedTable;
            
            gui.uiButtons(9)                    = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(9).String             = 'Delete Cell';
            gui.uiButtons(9).Callback           = @gui.actionDeleteCellNr;                                  
            
            gui.uiButtons(10)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
            gui.uiButtons(10).String            = 'Next Cell';
            gui.uiButtons(10).Callback          = @gui.actionNextCellNr;                                  

            gui.uiButtons(11)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(11).String            = 'Add Ann.';
            gui.uiButtons(11).Callback          = @gui.actionAddAnnotation;                                  
            
            gui.uiButtons(12)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(12).String            = 'Remove Ann.';
            gui.uiButtons(12).Callback          = @gui.actionRemoveAnnotation;                                  

            gui.uiButtons(13)                   = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
            gui.uiButtons(13).String            = 'Next Ann. Type';
            gui.uiButtons(13).Callback          = @gui.actionNextAnnotationType;                                  
            
            gui.uiTexts(20)                     = copyobj(gui.uiTexts(1), gui.uiTogglePanels(3));
            gui.uiTexts(20).BackgroundColor     = gui.vanellusGUI.ANALYSISPANEL_BGCOLOR;
            gui.uiTexts(20).String              = '>>';
            gui.uiTexts(20).FontWeight          = 'bold';

            annotationTypes                     = gui.annotations.annotationTypes;
            annotationColors                    = gui.annotations.annotationColors;
            annotationDescriptions              = gui.annotations.annotationDescriptions;
            for i = 1:numel( annotationTypes )
                gui.uiButtons(20+i)                 = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
                gui.uiButtons(20+i).String          = '';
                gui.uiButtons(20+i).Callback        = @gui.actionChangeAnnotationType;                                  
                gui.uiButtons(20+i).BackgroundColor = annotationColors{i};
                gui.uiTexts(20+i)                   = copyobj(gui.uiTexts(1), gui.uiTogglePanels(3));
                gui.uiTexts(20+i).BackgroundColor   = gui.vanellusGUI.ANALYSISPANEL_BGCOLOR;
                gui.uiTexts(20+i).String            = annotationTypes{i};
                gui.uiTexts(20+i).TooltipString     = annotationDescriptions{i};
            end
            
            % SET TOOLTIPS
            gui.uiEdits(1).TooltipString        = 'keyboard shortcut = g';
            gui.uiButtons(1).TooltipString      = 'keyboard shortcut = < or ,';
            gui.uiButtons(2).TooltipString      = 'keyboard shortcut = > or .';
            gui.uiButtons(4).TooltipString      = 'keyboard shortcut = BACKQUOTE';
            gui.uiButtons(7).TooltipString      = 'keyboard shortcut = 4';
            gui.uiButtons(9).TooltipString      = 'keyboard shortcut = ';
            gui.uiButtons(10).TooltipString     = 'keyboard shortcut = f';
            gui.uiButtons(11).TooltipString     = 'keyboard shortcut = SPACE';
            gui.uiButtons(12).TooltipString     = 'keyboard shortcut = BACKSPACE';
            gui.uiButtons(13).TooltipString     = 'keyboard shortcut = v';
            
            % SET CONTENTPANEL
            gui.contentPanel = ScrollPanel(gui.vanellusGUI.fig);
            
            % SET SIDEPANEL
            gui.sidePanel                       = uipanel(gui.vanellusGUI.fig);
            gui.sidePanel.BackgroundColor       = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.sidePanel.BorderType            = 'none';
            gui.sidePanel.Units                 = 'pixels';
            gui.sidePanel.Visible               = 'on';
            
            gui.sidePanelAxes                   = axes('Parent', gui.sidePanel, 'Units', 'pixels');            
        end

        function guiPositionUpdate(gui, ~, ~)
            % SET CONTROLPANEL BUTTONS [left bottom width height]
            gui.uiTogglePanels(1).Position  = [ 10 150 280  90];
            gui.uiTexts(1).Position         = [ 58  60  60  15];
            gui.uiButtons(1).Position       = [ 10  40  40  20];
            gui.uiEdits(1).Position         = [ 55  40  40  20];
            gui.uiButtons(2).Position       = [100  40  40  20];
            gui.uiButtons(4).Position       = [180  50  80  20];
            gui.uiButtons(7).Position       = [180  25  80  20];            
            gui.uiButtons(8).Position       = [ 10  10  60  20];

            gui.uiTogglePanels(2).Position  = [ 10 200 280  50];
            gui.uiButtons(9).Position       = [ 10  10  80  20];
            gui.uiButtons(10).Position      = [100  10  80  20];
            
            nrAnnotationTypes               = numel( gui.annotations.annotationTypes );
            gui.uiTogglePanels(3).Position  = [ 10 200 280 50+25*nrAnnotationTypes];
            y                               = 10 + 25*nrAnnotationTypes;
            gui.uiButtons(11).Position      = [ 10   y  60  20];
            gui.uiButtons(12).Position      = [ 80   y  80  20];
            gui.uiButtons(13).Position      = [170   y 100  20];
            for i = 1:nrAnnotationTypes
                y                               = y - 25;
                gui.uiButtons(20+i).Position    = [ 30   y  30  18];
                gui.uiTexts(20+i).Position      = [ 70 y-3 200  20];
                if i == gui.currentAnnIdx
                    gui.uiTexts(20).Position    = [ 10 y-3  20  20];
                end
            end
            
            gui.uiTogglePanels(4).Position  = [ 10 200 280  85];
            gui.uiTexts(2).Position         = [ 10  48 200  15];
            gui.uiTexts(3).Position         = [ 10  28 200  15];
            gui.uiTexts(4).Position         = [ 10   8 200  15];
            
            gui.uiTogglePanels(5).Position  = [ 10 200 280 280];
            gui.uiTables(1).Position        = [ 10  10 260 250];
            
            sidePanelPosition               = gui.sidePanel.Position; % [left bottom width height]
            gui.sidePanelAxes.Position      = [ 50 50 sidePanelPosition(3)-60 sidePanelPosition(4)-60];
            
            % INITIALIZE TOGGLE PANELS
            gui.guiInitializeTogglePanels();            
        end

        function guiUpdate(gui, ~, ~)

            % UPDATE CONTROLPANEL
            if isempty(gui.annotations.frames)
                gui.uiEdits(1).String = '-';
            else
                gui.uiEdits(1).String = gui.annotations.frames(gui.currentFrameIdx);
            end                

            % update settings Table
            [~, ~, combined]            = gui.getSettingsData();
            gui.uiTables(1).RowName     = {};  % settingsList
            gui.uiTables(1).Data        = combined; % data;
            if gui.uiTables(1).Extent(3) < gui.uiTables(1).Position(3), gui.uiTables(1).Position(3) = gui.uiTables(1).Extent(3); end            
            
            % UPDATE CONTENTPANEL (=SCROLLPANEL)
            rgb = gui.getAnnotationImage();
            hIm = gui.contentPanel.showImage(rgb, gui.vanellusGUI.currentMagnification);
            set(hIm, 'ButtonDownFcn', @gui.actionImageClicked);

            % UPDATE NAVPANEL
            gui.vanellusGUI.guiUpdateNavPanel();
            
            % UPDATE SIDEPANEL
            if strcmp(gui.sidePanel.Visible, 'on')
                frames                  = gui.annotations.frames;
                cellNrs                 = gui.annotations.cellNrs;
                annotationTypes         = gui.annotations.annotationTypes;
                annotationColors        = gui.annotations.annotationColors;
                
                cla( gui.sidePanelAxes )
                box(gui.sidePanelAxes,'on');
                gui.sidePanelAxes.YLim      = [frames(1)-1 frames(end)+1];
                gui.sidePanelAxes.XLim      = [0 numel(cellNrs)+1];
                gui.sidePanelAxes.XTick     = [1:numel(cellNrs)];
                gui.sidePanelAxes.XTickLabel = num2cell( cellNrs );
                gui.sidePanelAxes.TickLength = [0 0];
                
                axes( gui.sidePanelAxes );

                % determine intermittent frames
                nan_idx                 = find( diff(frames) ~= 1 );
                nan_idx                 = nan_idx + [1:numel(nan_idx)];
                frames_intermittent     = zeros( [1 numel(frames) + numel(nan_idx)] );
                frames_intermittent( nan_idx ) = NaN;
                frames_intermittent( ~isnan(frames_intermittent) ) = frames;
                
                for i = 1:numel(cellNrs)
                    % plot line
                    if i == gui.currentCellNrIdx
                        lineColor       = [0 0 0];
                    else
                        lineColor       = [0.8 0.8 0.8];
                    end
                    hold on;
                    plot( repmat(i, size(frames_intermittent)), frames_intermittent, ...
                            'Color', lineColor);
                    
                    cellNr = cellNrs(i);
                    anns = gui.annotations.getData( cellNr );
                    for j = 1:numel(annotationTypes)
                        annFrames = find( anns == j);
                        if numel(annFrames) > 0
                            hold on;
                            plot( repmat(i, size(annFrames)), annFrames, ...
                                  'Marker', 'o', 'MarkerSize', 6, ...
                                  'LineStyle', 'none', 'MarkerEdgeColor', 'none', ...
                                  'MarkerFaceColor', annotationColors{j});
                        end
                    end
                end
            end            
        end
        
        function save(gui, ~, ~)
            if gui.annotations.save()
                % set view to XX
%                 gui.uiButtons(1).Value              = 1;
            end
            
            gui.guiUpdate();
        end        
        
        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rgb = getAnnotationImage(gui)
            segSize     = gui.annotations.region.regionSize;
            frame       = gui.annotations.frames(gui.currentFrameIdx);

            % Setup output
            rgb = repmat(reshape(GUIAnnotations.BACKGROUND_COLOR, [1 1 3]), segSize);
            
            % add phase
            if gui.uiButtons(7).Value
                im      = gui.annotations.region.getImage( frame, []);
                im      = double(im);
                im      = VTools.scaleRange( im, [min(min(im)) max(max(im))], [0 1]);
                rgb     = repmat( im, [1 1 3]);
            end
            
            % add cell numbers
            if gui.uiButtons(4).Value
%                 rgb = rot90( rgb, gui.annotations.region.rotationAdditional90Idx);
                for i = 1:numel(gui.annotations.cellNrs)
                    c = gui.annotations.cellNrs(i);
                    if i == gui.currentCellNrIdx
                        boxColor = gui.BOX_COLOR_SELECTED;
                        boxOpacity = gui.BOX_OPACITY_SELECTED;
                    else
                        boxColor = gui.BOX_COLOR;
                        boxOpacity = gui.BOX_OPACITY;
                    end
                    rgb = insertText( rgb, gui.annotations.locations(c,[2 1]), num2str(c), ...
                                        'AnchorPoint', 'Center', ...
                                        'FontSize', gui.annotations.get('ann_fontSize'), ...
                                        'BoxColor', boxColor, ...
                                        'BoxOpacity', boxOpacity);

                    ann = gui.annotations.getAnnotation(c, frame);
                    if ann > 0
                        circlePosition = [ gui.annotations.locations(c,[2 1]) 4] + [-0.5 13 0];
                        rgb = insertShape( rgb, 'FilledCircle', circlePosition, ...
                                                'Color', gui.annotations.annotationColors{ann} );
                    end
                end 
            end
    
            % apply additional region rotation (only for visualization)
            rotationAdditional90Idx = gui.annotations.region.rotationAdditional90Idx;
            if rotationAdditional90Idx ~= 4
                rgb_old = rgb; clear rgb;
                for i=1:3
                    rgb(:,:,i) = rot90( rgb_old(:,:,i), rotationAdditional90Idx);
                end
            end            
        end
        
        function [settingsList, data, combined] = getSettingsData(gui) 
            settings        = gui.annotations.getCurrentDefaultSettings();
            settingsList    = settings(:,1);
            data            = cell( numel(settingsList), 1);
            combined        = cell( numel(settingsList), 2);
            for i = 1:numel(settingsList)
                text = VTools.convertValueToChar( settings{i,3} );
                data{i,1} = VTools.getHTMLColoredText( text, [0 0 0]);
                text2 = VTools.convertValueToChar( settings{i,1} );
                combined{i,1} = VTools.getHTMLColoredText( text2, [  0   0   0], [0.8 0.8 0.8]);
                combined{i,2} = text; %VTools.getHTMLColoredText( text , [0.2 0.2 0.2]);
            end
        end

        
        %% Image or Key Click %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionKeyPressed(gui, hObject, eventdata)
            switch upper(eventdata.Key)
                case {'LEFTARROW','COMMA'}
                    gui.actionChangeFrame(gui.uiButtons(1));
                case {'RIGHTARROW','PERIOD'}
                    gui.actionChangeFrame(gui.uiButtons(2));
                    
                case {'U'}
                    disp(['Clicked key: ' eventdata.Key ' -> Undo']);
                    gui.annotations.undo( gui.annotations.frames(gui.currentFrameIdx) );
                    gui.guiUpdate();
                case {'S'}
                    disp(['Clicked key: ' eventdata.Key ' -> saving']);
                    gui.actionSaveRegion();
                case {'D'}
                    disp(['Clicked key: ' eventdata.Key ' -> deleting']);
                    gui.actionDeleteCellNr();
                case {'F'}
                    disp(['Clicked key: ' eventdata.Key ' -> next cellNr']);
                    gui.actionNextCellNr();
                case {'V'}
                    disp(['Clicked key: ' eventdata.Key ' -> next annotation type']);
                    gui.actionNextAnnotationType();
                    
                case {'G'}
                    disp(['Clicked key: ' eventdata.Key ' -> Goto frame']);
                    uicontrol( gui.uiEdits(1) );
                    
                case {'SPACE'}
                    disp(['Clicked key: ' eventdata.Key ' -> adding annotation']);
                    gui.editAnnotationCellNr( gui.currentAnnIdx );
                case {'BACKSPACE'}
                    disp(['Clicked key: ' eventdata.Key ' -> removing annotation']);
                    gui.editAnnotationCellNr( 0 );
                    
                case {'BACKQUOTE'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling # in Display']);
                    gui.uiButtons(4).Value = ~gui.uiButtons(4).Value;
                    gui.guiUpdate();
                case {'4'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Phase in Display']);
                    gui.uiButtons(7).Value = ~gui.uiButtons(7).Value;
                    gui.guiUpdate();
            end
        end        
        
        function actionImageClicked(gui, hObject, eventdata)
            mouseButtonType     = get(gui.vanellusGUI.fig, 'SelectionType');
            contentPanelAx      = findall(gui.contentPanel.contentPanel, 'type', 'axes');
            hIm                 = contentPanelAx.Children;

            if hObject == hIm
                coor            = uint16(get(contentPanelAx,'CurrentPoint')); % returns [col row]
                coor            = coor(1,[2 1]);
                coor            = VTools.rotateCoordinates( coor, gui.annotations.region.rotationAdditional90Idx, gui.annotations.region.regionSize); % in case image was shown with additional region rotation, will need to convert coor
                
                if mouseButtonType(1)=='n' % normal = left mouse button
                    disp(['Clicked mouse : left -> select cellNr, click at @ ' num2str(coor)]);
%                     gui.annotations.editByJoiningCells( gui.prevClickCoor, coor, gui.annotations.frames(gui.currentFrameIdx));
                    [cellNr, distance] = gui.annotations.findClosestCellNr( coor );
                    if isempty(cellNr) || distance > gui.annotations.get('ann_minPixelSpacing')
                        disp(['              : no cellNr nearby']);
                    else
                        gui.currentCellNrIdx = find( cellNr == gui.annotations.cellNrs );
                    end

                elseif mouseButtonType(1)=='a' % alternate = ctrl+left button or right mouse button
                    disp(['Clicked mouse : right -> add cellNr @ ' num2str(coor)]);
                    cellNr = gui.annotations.addCellNr( coor );
                    if ~isempty(cellNr)
                        gui.currentCellNrIdx    = find( cellNr == gui.annotations.cellNrs );
                        frame                   = gui.annotations.frames( gui.currentFrameIdx );
                        initAnnotationIdx       = gui.annotations.get('ann_initAnnotationIdx');
                        gui.annotations.editAnnotation( cellNr, frame, initAnnotationIdx); 
                    end
                    if isempty( gui.currentCellNrIdx ), gui.currentCellNrIdx = 1; end

                elseif mouseButtonType(1)=='e' % extend = shift+left button
                    disp(['Clicked mouse : shift+left -> delete cellNr @ ' num2str(coor)]);
                    currentCellNr = gui.annotations.cellNrs( gui.currentCellNrIdx );
                    [cellNr, distance] = gui.annotations.findClosestCellNr( coor );
                    if isempty(cellNr) || distance > gui.annotations.get('ann_minPixelSpacing')
                        disp(['              : no cellNr nearby']);
                    else
                        gui.annotations.deleteCellNr( cellNr );
                        gui.currentCellNrIdx = find( currentCellNr == gui.annotations.cellNrs );
                        if isempty( gui.currentCellNrIdx ), gui.currentCellNrIdx = 1; end
                    end
                end
            end
            
            gui.guiUpdate();
        end

        
        %% ? %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function cellNr = getCurrentCellNr( gui )
            cellNr = [];
            cellNrs = gui.annotations.cellNrs;
            
            % if no cellNrs return empty
            if isempty( cellNrs ), return; end
            
            % if currentCellNrIdx is out of range, set to 1
            if gui.currentCellNrIdx > numel( cellNrs ), gui.currentCellNrIdx = 1; end
            
            cellNr = cellNrs( gui.currentCellNrIdx );
        end
        
        
        %% Actions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionChangeFrame(gui, hObject, eventdata)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            if hObject == gui.uiEdits(1)
                if ~isequal( eventdata.Key, 'return'), return; end
                drawnow; % makes sure that uiEdits(1) is up to date
                frame = str2double( gui.uiEdits(1).String );
                if ~isnan(frame)
                    idx = find(gui.annotations.frames==frame);
                    if ~isempty(idx)
                        gui.currentFrameIdx =idx(1);
                    end
                end
            elseif hObject == gui.uiButtons(1) & gui.currentFrameIdx > 1
                gui.currentFrameIdx = gui.currentFrameIdx - 1;
            elseif hObject == gui.uiButtons(2) & gui.currentFrameIdx < length(gui.annotations.frames)
                gui.currentFrameIdx = gui.currentFrameIdx + 1;
            end
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from edit box / button
            gui.guiUpdate();
        end        
        
        function actionSaveRegion(gui, ~, ~)
            gui.annotations.region.save();
            gui.guiUpdate();
        end

        function actionDeleteCellNr(gui, hObject, ~)
            cellNr = gui.getCurrentCellNr();
            tf = gui.annotations.deleteCellNr( cellNr );
            if tf
                gui.currentCellNrIdx = 1;
            end
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from button
            gui.guiUpdate();
        end

        function actionNextCellNr(gui, hObject, ~)
            gui.currentCellNrIdx = gui.currentCellNrIdx + 1;
            if gui.currentCellNrIdx > numel( gui.annotations.cellNrs )
                gui.currentCellNrIdx = 1;
            end
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from button
            gui.guiUpdate();
        end

        function actionNextAnnotationType(gui, hObject, ~)
            gui.currentAnnIdx = gui.currentAnnIdx + 1;
            if gui.currentAnnIdx > numel( gui.annotations.annotationTypes )
                gui.currentAnnIdx = 1;
            end
            gui.guiPositionUpdate();
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from button
            gui.guiUpdate();
        end
        
        function actionChangeAnnotationType(gui, hObject, ~)
            for i = 1:numel( gui.annotations.annotationTypes )
                if hObject == gui.uiButtons(20+i)
                    gui.currentAnnIdx = i;
                end
            end
            gui.guiPositionUpdate();
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from button
            gui.guiUpdate();
        end

        function actionAddAnnotation(gui, hObject, ~)
            cellNr = gui.getCurrentCellNr();
            frame = gui.annotations.frames( gui.currentFrameIdx );
            gui.annotations.editAnnotation(cellNr, frame, gui.currentAnnIdx);
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from button
            gui.guiUpdate();
        end

        function actionRemoveAnnotation(gui, hObject, ~)
            cellNr = gui.getCurrentCellNr();
            frame = gui.annotations.frames( gui.currentFrameIdx );
            gui.annotations.editAnnotation(cellNr, frame, 0);
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from button
            gui.guiUpdate();
        end
        
        function editAnnotationCellNr(gui, annIdx)
            cellNr = gui.getCurrentCellNr();
            frame = gui.annotations.frames( gui.currentFrameIdx );
            gui.annotations.editAnnotation(cellNr, frame, annIdx);
            gui.guiUpdate();
        end
        
        function actionTogglePicture(gui, hObject, ~)
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from button
            gui.guiUpdate();
        end        
        
        function actionTogglePlot(gui, hObject, ~)
            if gui.uiButtons(8).Value
                gui.sidePanel.Visible           = 'on';
            else
                gui.sidePanel.Visible           = 'off';
            end
            gui.vanellusGUI.guiPositionUpdate();
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from button
            gui.vanellusGUI.guiUpdate();
        end        
        
        
    end
end