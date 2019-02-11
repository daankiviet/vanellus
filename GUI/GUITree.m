classdef GUITree < GUITogglePanel
% GUITree

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant = true)
        SEG_DIVIDER_HEIGHT      = 10;
        NR_DISPLAY_LABELS       = {'No #', 'Seg #', 'Cell #', 'Birth #', 'Feature Value'};
        COLORMAP_TYPE           = @cool;
    end
    
    properties (Transient) % not stored
        vanellusGUI
        tree

        contentPanel
        controlPanel
%         sidePanel
        
        uiTogglePanels
        uiTexts
        uiButtons
        uiEdits
        uiTables
        uiListboxes
        uiPopups
        
        currentFrameIdx
        currentCellNr
        
        colorTable
    end  
    
    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUITree(vanellusGUI, tree)
            if nargin < 1, error('Need VanellusGUI as argument'); end
            if nargin < 2, error('Need tree as argument'); end

            gui.vanellusGUI         = vanellusGUI;
            gui.tree                = tree;
            gui.currentFrameIdx     = 1;
            
            gui.guiUpdateColorTable();
            gui.guiBuild();
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
            gui.uiTogglePanels(1).BorderType        = 'beveledin'; % 'etchedin' (default) | 'etchedout' | 'beveledin' | 'beveledout' | 'line' | 'none'
            gui.uiTogglePanels(1).BorderWidth       = 2; % 1 (default)
            gui.uiTogglePanels(1).Units             = 'pixels';
            
%             gui.uiTogglePanels(2)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
%             gui.uiTogglePanels(2).BackgroundColor   = gui.vanellusGUI.EDITPANEL_BGCOLOR;
%             gui.uiTogglePanels(2).Title             = 'Edit';
%             
%             gui.uiTogglePanels(3)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
%             gui.uiTogglePanels(3).BackgroundColor   = gui.vanellusGUI.ANALYSISPANEL_BGCOLOR;
%             gui.uiTogglePanels(3).Title             = 'Analysis';
% 
%             gui.uiTogglePanels(4)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
%             gui.uiTogglePanels(4).Title             = 'Click behavior';

            gui.uiTogglePanels(5)                   = copyobj(gui.uiTogglePanels(1), gui.controlPanel);
            gui.uiTogglePanels(5).Title             = 'Relevant settings';
            
            %% Display Panel
            gui.uiTexts                             = uicontrol(gui.uiTogglePanels(1));
            gui.uiTexts(1).Style                    = 'text';
            gui.uiTexts(1).String                   = 'Frame';
            gui.uiTexts(1).BackgroundColor          = gui.controlPanel.BackgroundColor;
            gui.uiTexts(1).HorizontalAlignment      = 'left';

            gui.uiButtons                           = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(1).Style                  = 'pushbutton';
            gui.uiButtons(1).String                 = 'Prev';
            gui.uiButtons(1).Callback               = @gui.actionChangeFrame;
            
            gui.uiEdits                             = uicontrol(gui.uiTogglePanels(1));
            gui.uiEdits(1).Style                    = 'edit';
            gui.uiEdits(1).String                   = '';
            gui.uiEdits(1).KeyPressFcn              = @gui.actionChangeFrame;
            
            gui.uiButtons(2)                        = copyobj(gui.uiButtons(1), gui.uiTogglePanels(1));
            gui.uiButtons(2).String                 = 'Next';
            gui.uiButtons(2).Callback               = @gui.actionChangeFrame;                                  

            gui.uiPopups                            = uicontrol(gui.uiTogglePanels(1));
            gui.uiPopups(1).Style                   = 'popup';
            gui.uiPopups(1).String                  = gui.tree.featureList;
%             gui.uiPopups(1).KeyPressFcn             = @gui.actionChangeSelectedFeature;
            gui.uiPopups(1).Callback                = @gui.actionChangeSelectedFeature;
%             gui.uiPopups(1).BackgroundColor         = gui.controlPanel.BackgroundColor;
            
            gui.uiButtons(3)                        = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(3).Style                  = 'togglebutton';
            gui.uiButtons(3).Min                    = 0;
            gui.uiButtons(3).Max                    = 1;
            gui.uiButtons(3).Value                  = 1;
            gui.uiButtons(3).String                 = 'Feature Color';
            gui.uiButtons(3).Callback               = @gui.guiUpdate;

            gui.uiButtons(4)                        = copyobj(gui.uiButtons(3), gui.uiTogglePanels(1));
            gui.uiButtons(4).String                 = 'Feature Value';
            gui.uiButtons(4).Callback               = @gui.guiUpdate;

            gui.uiButtons(6)                        = copyobj(gui.uiButtons(3), gui.uiTogglePanels(1));
            gui.uiButtons(6).String                 = 'Phase';
            gui.uiButtons(6).Callback               = @gui.guiUpdate;
            
            gui.uiButtons(7)                        = uicontrol(gui.uiTogglePanels(1));
            gui.uiButtons(7).Style                  = 'pushbutton';
            gui.uiButtons(7).String                 = gui.NR_DISPLAY_LABELS{1};
            gui.uiButtons(7).Callback               = @gui.actionChangeNrDisplay;
            
%             %% Edit Panel
%             gui.uiButtons(11)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(2));
%             gui.uiButtons(11).String                = 'Recolor';
%             gui.uiButtons(11).Callback              = @gui.actionRecolorButtonPressed;                                  
% 
%             %% Analysis Panel
%             gui.uiButtons(21)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
%             gui.uiButtons(21).String                = 'Recalculate';
%             gui.uiButtons(21).Callback              = @gui.actionRecalculateButtonPressed;                                  
% 
%             gui.uiButtons(22)                       = copyobj(gui.uiButtons(3), gui.uiTogglePanels(3));
%             gui.uiButtons(22).String                = 'Analyze';
%             gui.uiButtons(22).Value                 = 0;
%             gui.uiButtons(22).Callback              = @gui.actionToggleAnalyze;                                  
% 
%             gui.uiButtons(23)                       = copyobj(gui.uiButtons(1), gui.uiTogglePanels(3));
%             gui.uiButtons(23).String                = 'Compile';
%             gui.uiButtons(23).Callback              = @gui.actionCompileButtonPressed;                                  
%             
%             %% Click Behavior Panel
%             gui.uiTexts(31)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
%             gui.uiTexts(31).String                  = 'Left click : connect cells';
%             
%             gui.uiTexts(32)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
%             gui.uiTexts(32).String                  = 'Right click: disconnect cell';
%             
%             gui.uiTexts(33)                         = copyobj(gui.uiTexts(1), gui.uiTogglePanels(4));
%             gui.uiTexts(33).String                  = 'Shift + left click: ';
            
            %% Relevant Settings Panel
            gui.uiTables                            = uitable(gui.uiTogglePanels(5));
            gui.uiTables(1).ColumnName              = [];
            gui.uiTables(1).ColumnWidth             = {130 125};
            gui.uiTables(1).ColumnEditable          = [false true];
            gui.uiTables(1).Enable                  = 'on';
            gui.uiTables(1).RowStriping             = 'off';
            gui.uiTables(1).CellEditCallback        = @gui.actionEditedTable;            
            
%             % SET TOOLTIPS
%             gui.uiEdits(1).TooltipString            = 'keyboard shortcut = g';
%             gui.uiButtons(1).TooltipString          = 'keyboard shortcut = < or ,';
%             gui.uiButtons(2).TooltipString          = 'keyboard shortcut = > or ,';
%             gui.uiButtons(11).TooltipString         = 'keyboard shortcut = r';
% %             gui.uiButtons(XX).TooltipString     = 'keyboard shortcut = u';
%             gui.uiButtons(7).TooltipString          = 'keyboard shortcut = BACKQUOTE';
%             gui.uiButtons(3).TooltipString          = 'keyboard shortcut = 1';
%             gui.uiButtons(4).TooltipString          = 'keyboard shortcut = 2';
%             gui.uiButtons(5).TooltipString          = 'keyboard shortcut = 3';
%             gui.uiButtons(6).TooltipString          = 'keyboard shortcut = 4';
            
            % SET CONTENTPANEL
            gui.contentPanel = ScrollPanel(gui.vanellusGUI.fig);
        end

        function guiPositionUpdate(gui, ~, ~)
            % SET CONTROLPANEL BUTTONS
            % Position coordinates: [left bottom width height]
            
            gui.uiTogglePanels(1).Position  = [ 10 200 280 120]; % Display
            gui.uiTexts(1).Position         = [ 58  90  60  15];
            gui.uiButtons(1).Position       = [ 10  70  40  20];
            gui.uiEdits(1).Position         = [ 55  70  40  20];
            gui.uiButtons(2).Position       = [100  70  40  20];
            gui.uiPopups(1).Position        = [ 10  40 160  20];
            gui.uiButtons(3).Position       = [180  85  80  20];
            gui.uiButtons(4).Position       = [180  60  80  20];
            gui.uiButtons(6).Position       = [180  10  80  20];            
            gui.uiButtons(7).Position       = [ 80  10  80  20];            

%             gui.uiTogglePanels(2).Position  = [ 10 200 280  50]; % Edit
%             gui.uiButtons(11).Position      = [ 10  10  80  20];
%             
%             gui.uiTogglePanels(3).Position  = [ 10 200 280  50];% Analysis
%             gui.uiButtons(21).Position      = [ 10  10  80  20];
%             gui.uiButtons(22).Position      = [100  10  80  20];
%             gui.uiButtons(23).Position      = [190  10  80  20];
%             
%             gui.uiTogglePanels(4).Position  = [ 10 200 280 100];% Click Behavior
%             gui.uiTexts(31).Position        = [ 10  65 160  15];
%             gui.uiTexts(32).Position        = [ 10  40 160  15];
%             gui.uiTexts(33).Position        = [ 10  15 160  15];

            gui.uiTogglePanels(5).Position  = [ 10 200 280 280];    % Relevant Settings Panel        
            gui.uiTables(1).Position        = [ 10  10 260 250];
            
            % INITIALIZE TOGGLE PANELS
            gui.guiInitializeTogglePanels();            
        end

        function guiUpdate(gui, ~, ~)

            % UPDATE CONTROLPANEL
            if isempty(gui.tree.frames)
                gui.uiEdits(1).String = '-';
            else
                gui.uiEdits(1).String = gui.tree.frames(gui.currentFrameIdx);
            end                

            % update settings Table
            [~, ~, combined]            = gui.getSettingsData();
            gui.uiTables(1).RowName     = {};  % settingsList
            gui.uiTables(1).Data        = combined; % data;
            if gui.uiTables(1).Extent(3) < gui.uiTables(1).Position(3), gui.uiTables(1).Position(3) = gui.uiTables(1).Extent(3); end            
            
            % UPDATE CONTENTPANEL (=SCROLLPANEL)
            rgb = gui.getTreeImage();
            hIm = gui.contentPanel.showImage(rgb, gui.vanellusGUI.currentMagnification);
            set(hIm, 'ButtonDownFcn', @gui.actionImageClicked);
            
            % UPDATE NAVPANEL
            gui.vanellusGUI.guiUpdateNavPanel();
        end
        
        
        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function rgb = getTreeImage(gui)
 
            segSize     = gui.tree.region.regionSize;
            frame      = gui.tree.frames(gui.currentFrameIdx);

            % Setup output
            rgb = repmat(reshape(GUISegmentations.COLOR_BACKGROUND, [1 1 3]), segSize);

            % add feature
            featureName = gui.uiPopups(1).String{ gui.uiPopups(1).Value };
            if gui.uiButtons(3).Value
                seg         = gui.tree.region.getSeg( frame );
                segNrs      = unique(seg);
                segNrs(segNrs==0) = [];
                
                seg2value   = [];
                
                for segNr = segNrs'
                    cellNr  = gui.tree.seg2cell{frame}(segNr);
                    value   = gui.tree.getValuesCellNr(featureName, cellNr, frame);
                    seg2value( segNr ) = value;
                end
                range       = [min( seg2value(segNrs) ) max( seg2value(segNrs) )];

                features    = zeros( segSize );
                for segNr = segNrs'
                    colorNr     = round( VTools.scaleRange(seg2value( segNr ), range, [2 GUISegmentations.DIFFERENT_COLORS+1]) );
                    features( seg==segNr ) = colorNr;
%                     disp(['seg' num2str(segNr) ' - cell' num2str(gui.tree.seg2cell{frame}(segNr)) ' : ' featureName ' = ' num2str(seg2value( segNr )) ' -> colorNr=' num2str(colorNr) ' with range = ' num2str(range)]);
                end
                featureRGB  = ind2rgb(features, gui.colorTable);
                idx         = repmat( logical(seg), [1 1 3]);
                rgb(idx)    = featureRGB(idx);
                
            end

            % add phase
            if gui.uiButtons(6).Value
                segImage   = gui.tree.region.segmentations.getSegImage( frame );
                rgb = VTools.addPhaseOverlayToRGB(rgb, segImage);
            end

            % add seg numbers
            nrDisplayIdx = find( strcmp(gui.NR_DISPLAY_LABELS, gui.uiButtons(7).String) );
            if nrDisplayIdx > 1 
                % get rotated seg
                seg        = gui.tree.region.getSeg( frame );
                seg        = rot90( seg, gui.tree.region.rotationAdditional90Idx);
            end
            if nrDisplayIdx == 3
                % convert segnrs into cellnrs
                seg        = gui.convertSegToCell(seg, frame);
            elseif nrDisplayIdx == 4
                % convert segnrs into cellnrs in first frame
                seg        = gui.convertSegToCellWithDivision2(seg, frame);
            elseif nrDisplayIdx == 5
                % convert segnrs into feature value
                segNrs      = unique(seg);
                segNrs(segNrs==0) = [];
                seg        = double(seg);
                for segNr = segNrs'
                    cellNr  = gui.tree.seg2cell{frame}(segNr);
                    value   = gui.tree.getValuesCellNr(featureName, cellNr, frame);
                    seg( seg==segNr ) = value;
                end
            end
            if nrDisplayIdx > 1
                % get nr image and rotate back
                segNrs     = GUISegmentations.getSegNrsImFromSeg( seg );
                segNrs     = rot90( segNrs, -gui.tree.region.rotationAdditional90Idx);

                segNrsRGB  = repmat(reshape(GUISegmentations.COLOR_EDGE, [1 1 3]), segSize);
                idx         = repmat( segNrs, [1 1 3]);
                rgb( idx ) = segNrsRGB( idx );
            end

            % apply additional region rotation (only for visualization)
            rotationAdditional90Idx = gui.tree.region.rotationAdditional90Idx;
            if rotationAdditional90Idx ~= 4
                rgb = VTools.rot90_3D(rgb, rotationAdditional90Idx);
            end
            
            % add feature value
            if gui.uiButtons(4).Value
                % get rotated seg
                seg        = gui.tree.region.getSeg( frame );
                seg        = rot90( seg, gui.tree.region.rotationAdditional90Idx);
                segNrs     = VTools.uniqueExcluding(seg, [0]);
                for segNr = segNrs'
                    cellNr  = gui.tree.seg2cell{frame}(segNr);
                    value   = gui.tree.getValuesCellNr(featureName, cellNr, frame);
                    [r, c]  = find(seg == segNr);
                    rgb = insertText( rgb, [mean(c) mean(r)], num2str(value), ...
                                        'AnchorPoint', 'Center', ...
                                        'FontSize', 10, ...
                                        'BoxColor', [1 1 1], ...
                                        'BoxOpacity', 0.5);
                end 
            end            
            
        end
        
        function guiUpdateColorTable(gui)
            % note that ind2rgb on uint16 will set 0->1 and 1->2 in colorMap
            
            % get segColormap
            gui.colorTable = gui.COLORMAP_TYPE( GUISegmentations.DIFFERENT_COLORS );
            
            % randomize segColorMap
            gui.colorTable(2:end+1,:) = gui.colorTable(:,:);
            
            % add additional color
            gui.colorTable(GUISegmentations.COLORNR_BACKGROUND+1,:)    = GUISegmentations.COLOR_BACKGROUND;
            gui.colorTable(GUISegmentations.COLORNR_OUTLINE+1,:)       = GUISegmentations.COLOR_OUTLINE;
        end        
        
        function [settingsList, data, combined] = getSettingsData(gui) 
            settings        = gui.tree.getCurrentDefaultSettings();
            settingsList    = settings(:,1);
            data            = cell( numel(settingsList), 1);
            combined        = cell( numel(settingsList), 2);
            for i = 1:numel(settingsList)
                text = VTools.convertValueToChar( settings{i,3} );
                data{i,1} = VTools.getHTMLColoredText( text, [0 0 0]);
                text2 = VTools.convertValueToChar( settings{i,1} );
                combined{i,1} = VTools.getHTMLColoredText( text2, [  0   0   0], [0.8 0.8 0.8]);
                combined{i,2} = text;
            end
        end        

        
        %% Key or Image Clicked %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionKeyPressed(gui, ~, eventdata)
            switch upper(eventdata.Key)
                case {'LEFTARROW','COMMA'}
                    gui.actionChangeFrame(gui.uiButtons(1));
                case {'RIGHTARROW','PERIOD'}
                    gui.actionChangeFrame(gui.uiButtons(2));
                    
                case {'BACKQUOTE'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling # in Display']);
                    gui.actionChangeNrDisplay();
                case {'1'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Feature in Display']);
                    gui.uiButtons(3).Value = ~gui.uiButtons(3).Value;
                    gui.guiUpdate();
                case {'4'}
                    disp(['Clicked key: ' eventdata.Key ' -> toggling Phase in Display']);
                    gui.uiButtons(6).Value = ~gui.uiButtons(6).Value;
                    gui.guiUpdate();                    
                case {'G'}
                    disp(['Clicked key: ' eventdata.Key ' -> Goto frame']);
                    uicontrol( gui.uiEdits(1) );
            end
        end        
        
        function actionImageClicked(gui, hObject, ~)
            mouseButtonType     = get(gui.vanellusGUI.fig, 'SelectionType');
            contentPanelAx      = findall(gui.contentPanel.contentPanel, 'type', 'axes');
            hIm                 = contentPanelAx.Children;

            if hObject == hIm
                coor = uint16(get(contentPanelAx,'CurrentPoint')); % returns [col row]
                coor = coor(1,[2 1]); % disp(['Screen coordinates             : (' num2str(coor(1)) ',' num2str(coor(2)) ') [ T, L ] ']);

                % in case image was shown with additional region rotation, will need to convert coor
                coor = VTools.rotateCoordinates( coor, gui.tree.region.rotationAdditional90Idx, gui.tree.region.regionSize); 
            
                if mouseButtonType(1)=='n' % normal = left mouse button
                    disp(['Clicked mouse : left -> not doing anything for the moment @ ' num2str(coor)]);

                elseif mouseButtonType(1)=='a' % alternate = ctrl+left button or right mouse button
                    disp(['Clicked mouse : right  -> not doing anything for the moment @ ' num2str(coor)]);
                    
                elseif mouseButtonType(1)=='e' % extend = shift+left button
                    disp(['Clicked mouse : shift+left -> not doing anything for the moment @ ' num2str(coor)]);
                end
            end

            gui.guiUpdate();
        end
        
        
        %% Actions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionChangeFrame(gui, hObject, eventdata)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            if hObject == gui.uiEdits(1)
                if ~isequal( eventdata.Key, 'return'), return; end
                drawnow; % makes sure that uiEdits(1) is up to date
                frame = str2double(get(gui.uiEdits(1), 'String'));
                if ~isnan(frame)
                    idx = find(gui.tree.frames==frame);
                    if ~isempty(idx)
                        gui.currentFrameIdx =idx(1);
                    end
                end
            elseif hObject == gui.uiButtons(1) && gui.currentFrameIdx > 1
                gui.currentFrameIdx = gui.currentFrameIdx - 1;
            elseif hObject == gui.uiButtons(2) && gui.currentFrameIdx < length(gui.tree.frames) - 1
                gui.currentFrameIdx = gui.currentFrameIdx + 1;
            end
            gui.vanellusGUI.removeFocusFromObject(hObject); % remove focus from edit box / button
            gui.guiUpdate();
        end        
        
        function actionEditedTable(gui, ~, eventdata)
            if isempty(eventdata.Indices), return; end % avoid error when changing display while cell is selected
            
            if eventdata.Indices(2) == 2 % only respond to clicks in 2nd column
                [settingsList, ~, ~] = gui.getSettingsData(); 
                settingName = settingsList{eventdata.Indices(1)};
                
                if isempty(settingName), return; end % avoid empty row error
                
                try
                    oldValue = gui.tree.get(settingName);
                    newValue = eventdata.NewData;
                    
                    if ischar(oldValue), newValue = ['''' newValue '''']; end
                    if isnumeric(oldValue), newValue = ['[' newValue ']']; end
                    eval(['gui.tree.set(''' settingName ''', ' newValue ');']);
                    disp([ settingName ' changed']);
                catch
                    warning(['GUITree: something went wrong while trying to change a setting.']);
                end
            end
            gui.guiUpdate();
        end
        
        function actionChangeNrDisplay(gui, ~, ~)
            idx = find( strcmp(gui.NR_DISPLAY_LABELS, gui.uiButtons(7).String) );
            if isempty(idx), idx = 1; end
            idx = idx + 1;
            if idx > numel(gui.NR_DISPLAY_LABELS), idx = 1; end
            gui.uiButtons(7).String             = gui.NR_DISPLAY_LABELS{idx};
            gui.guiUpdate();
        end        
        
        function actionShowCell(gui, hObject, ~)
            idx = get(hObject,'Value');
            if isempty(idx), return; end % no line selected
            idx = idx(1); % avoid error when multiple lines are selected
            if idx > length(gui.treeAnalysis.problems), return; end % should not happen
            
            % extract frame
            frame = str2double(regexpi(gui.treeAnalysis.problems{idx},'Fr (\d+).*','tokens','once'));
            
            % tell parent to go to frame
            idx = find( gui.tree.frames==frame );
            if ~isempty(idx)
                gui.currentFrameIdx =idx(1);
                gui.guiUpdate();
            end            
        end        
        
        function actionChangeSelectedFeature(gui, ~, ~)
            gui.guiUpdate();
        end        
        
        
        %% Tree coloring %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function seg_out = convertSegToCell(gui, seg, frame)
            % seg2cell        { frame }  ( segno )  = cellno
            seg_out = seg;
            us = setdiff(unique(seg),[0]);
            for u = reshape(us,1,length(us))
                if frame <= numel(gui.tree.seg2cell) && u <= numel( gui.tree.seg2cell{frame} )
                    seg_out(seg==u) = gui.tree.seg2cell{frame}(u);
                end
            end
        end
        
        function seg_out = convertSegToCellWithDivision(gui, seg, frame)
            % seg2parent      { frame }  ( segno )  = cellno (with cellno = parent_cellno in first frame)
            seg_out = seg;
            us = setdiff(unique(seg),[0]);
            for u = reshape(us,1,length(us))
                if frame <= numel(gui.tree.seg2parent) && u <= numel( gui.tree.seg2parent{frame} )
                    seg_out(seg==u) = gui.tree.seg2parent{frame}(u);
                end
            end
        end        
        
        function seg_out = convertSegToCellWithDivision2(gui, seg, frame)
            % seg2cell        { frame }  ( segno )  = cellno
            % seg2parent      { frame }  ( segno )  = cellno (with cellno = parent_cellno in first frame)
            seg_out = zeros(size(seg));
            us = setdiff(unique(seg),[0]);
            for u = reshape(us,1,length(us))
                if frame <= numel(gui.tree.seg2cell) && u <= numel( gui.tree.seg2cell{frame} ) && frame <= numel(gui.tree.seg2parent) && u <= numel( gui.tree.seg2parent{frame} )
                    if gui.tree.seg2cell{frame}(u) ~= gui.tree.seg2parent{frame}(u)
                        seg_out(seg==u) = gui.tree.seg2cell{frame}(u);
                    end
                end
            end
        end        
        
        
    end
end



%         function calcTree(gui)
%             gui.tree.region.tree.updateTree();
%             gui.seg2cell = gui.tree.region.tree.seg2cell;
%             gui.seg2parent = gui.tree.region.tree.seg2parent;
%             
% %            [gui.seg2cell, gui.seg2parent] = gui.tree.calcColorTools();
% %            [~, gui.segToCell] = gui.tree.calcTree();
% %            gui.segToCellWithDivision = gui.tree.calcSegToCellWithDivision();
%         end
%         

%         function actionCompileButtonPressed(gui, ~, ~)
%             % indicate that GUI is working
%             gui.vanellusGUI.fig.Pointer = 'watch';
%             drawnow;
%             
%             gui.tree.region.tree.compile();
% 
%             gui.guiUpdate();
% 
%             % indicate that GUI is finished
%             gui.vanellusGUI.fig.Pointer = 'arrow';            
%         end
%         
%         function actionRecolorButtonPressed(gui, ~, ~)
%             gui.guiUpdateColorTable();
%             gui.guiUpdate();
%         end   

%         function actionSaveRegion(gui, ~, ~)
%             gui.tree.region.save();
%             gui.guiUpdate();
%         end

%         function actionRecalculateButtonPressed(gui, ~, ~)
%             frame      = gui.tree.frames(gui.currentFrameIdx);
%             frame2      = gui.tree.frames(gui.currentFrameIdx+1);
% 
%             gui.tree.calcAndSetData( [frame frame2] );
%             gui.calcTree();
%             gui.guiUpdateColorTable();
%             gui.guiUpdate();
%         end 