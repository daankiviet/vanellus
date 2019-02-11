classdef GUIPicture < handle
% GUIPicture

% Copyright Daan Kiviet 2018-
% Version : 2017-03-07

    properties (Constant = true)
    end
    
    properties (Transient) % not stored
        vanellusGUI
        picture
        
        contentPanel
        controlPanel

%         uiPanels
        uiTexts
        uiEdits
        uiButtons
%         uiTables

        currentFrameIdx
        currentTypeIdx
    end

    properties (Dependent) % calculated on the fly
    end    
    
    methods
        %% loading and gui building / updating %%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function gui = GUIPicture(vanellusGUI, picture)
            if nargin < 1, error('Need VanellusGUI as argument'); end
            if nargin < 2, error('Need VPicture as argument'); end
            
            gui.vanellusGUI     = vanellusGUI;
            gui.picture             = picture;
            gui.currentFrameIdx = 1;
            gui.currentTypeIdx  = 1;
            
            gui.guiBuild();
        end
 
        function guiBuild(gui)
            gui.controlPanel                    = uipanel(gui.vanellusGUI.fig);
            gui.controlPanel.BackgroundColor    = gui.vanellusGUI.CONTROLPANEL_BGCOLOR;
            gui.controlPanel.BorderType         = 'none';
            gui.controlPanel.Units              = 'pixels';

            % SET CONTROLPANEL
            gui.uiTexts                         = uicontrol(gui.controlPanel);
            gui.uiTexts(1).Style                = 'text';
            gui.uiTexts(1).String               = 'Frame';
            gui.uiTexts(1).BackgroundColor      = gui.controlPanel.BackgroundColor;
            gui.uiTexts(1).HorizontalAlignment  = 'left';

            gui.uiButtons                       = uicontrol(gui.controlPanel);
            gui.uiButtons(1).Style              = 'pushbutton';
            gui.uiButtons(1).String             = 'Prev';
            gui.uiButtons(1).Callback           = @gui.actionChangeFrame;
            
            gui.uiEdits                         = uicontrol(gui.controlPanel);
            gui.uiEdits(1).Style                = 'edit';
            gui.uiEdits(1).String              = '';
            gui.uiEdits(1).KeyPressFcn          = @gui.actionChangeFrame;
                                    
            gui.uiButtons(2)                    = copyobj(gui.uiButtons(1), gui.controlPanel);
            gui.uiButtons(2).String             = 'Next';
            gui.uiButtons(2).Callback           = @gui.actionChangeFrame;                                  
            
            % SET CONTENTPANEL
            gui.contentPanel = ScrollPanel(gui.vanellusGUI.fig);
        end

        function guiPositionUpdate(gui)
            % SET CONTROLPANEL BUTTONS
            controlPanelPosition        = gui.controlPanel.Position; %[left bottom width height]
            
            gui.uiTexts(1).Position     = [ 78 controlPanelPosition(4)-15  60 15];
            gui.uiButtons(1).Position   = [ 30 controlPanelPosition(4)-35  40 20];
            gui.uiEdits(1).Position     = [ 75 controlPanelPosition(4)-35  40 20];
            gui.uiButtons(2).Position   = [120 controlPanelPosition(4)-35  40 20];
        end

        function guiUpdate(gui, hObject, eventdata)
            % UPDATE CONTROLPANEL
            if isempty(gui.picture.parent.frames)
                gui.uiEdits(1).String = '-';
            else
                gui.uiEdits(1).String = gui.picture.parent.frames(gui.currentFrameIdx);
            end                
            
            % UPDATE CONTENTPANEL (=SCROLLPANEL)
            gui.picture.set('pic_imageFrame', gui.picture.parent.frames(gui.currentFrameIdx));
            rgb = gui.picture.getRGB();
            gui.contentPanel.showImage(rgb, gui.vanellusGUI.currentMagnification); % hIm = 
        end

        %% Controller %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function actionKeyPressed(gui, hObject, eventdata)
            switch upper(eventdata.Key)
                case {'LEFTARROW','COMMA'}
                    gui.actionChangeFrame(gui.uiButtons(1));
                case {'RIGHTARROW','PERIOD','SPACE'}
                    gui.actionChangeFrame(gui.uiButtons(2));
            end
        end
                
        function actionChangeFrame(gui, hObject, eventdata)
            drawnow limitrate nocallbacks; % was: pause(0.1);
            if hObject == gui.uiEdits(1)
                if ~isequal( eventdata.Key, 'return'), return; end
                drawnow; % makes sure that uiEdits(1) is up to date
                frame = str2double(get(gui.uiEdits(1), 'String'));
                if ~isnan(frame)
                    idx = find(gui.picture.parent.frames==frame);
                    if ~isempty(idx)
                        gui.currentFrameIdx =idx(1);
                    end
                end
            elseif hObject == gui.uiButtons(1) & gui.currentFrameIdx > 1
                gui.currentFrameIdx = gui.currentFrameIdx - 1;
            elseif hObject == gui.uiButtons(2) & gui.currentFrameIdx < length(gui.picture.parent.frames)
                gui.currentFrameIdx = gui.currentFrameIdx + 1;
            end
            gui.guiUpdate();
        end    
        

                    
    end
end