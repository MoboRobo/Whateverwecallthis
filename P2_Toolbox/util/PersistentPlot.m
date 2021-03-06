%% PersistentPlot
% Small wrapper class for a plot which sticks around and can have its x
% and y values updated over time.
classdef PersistentPlot < handle
    properties(GetAccess = public, SetAccess = private)
        fig;            % Figure that this plot is assigned to
        core;           % Core Matlab plot object
        
        on_time;        % s, Time of Instantiation
        
        update_Tlast;   % s, Time of Last Plot Update
        update_xs = []; % Vector to update X-Data to when an update is performed.
        update_ys = []; % Vector to update Y-Data to when an update is performed.
        update_x = [];  % Datum to add to X-Data when an update is performed.
        update_y = [];  % Datum to add to Y-Data when an update is performed.
    end % properties
    
    events 
        UPDATE_PLOT
    end
    
    methods
        %% Constructor
        % f - figure this plot belongs to
        % xs - initial x data
        % ys - initial y data
        function obj = PersistentPlot(f, xs, ys, varargin)
            obj.fig = figure(f);
            hold on
                if nargin > 3
                    obj.core = plot(xs,ys, varargin{:});
                else
                    obj.core = plot(xs,ys);
                end
            hold off
            
            addlistener(obj, 'UPDATE_PLOT', @obj.performUpdate);
            
            obj.on_time = tic;
            obj.update_Tlast = toc(obj.on_time);
        end % #PersistentPlot
        
        %% Add X
        % Adds an entry, x, to the X Data
        function addX(obj, x)
            set(obj.core, 'XData', [get(obj.core, 'XData') x]);
        end % #addX
        %% Add Y
        % Adds an entry, y, to the Y Data
        function addY(obj, y)
            set(obj.core, 'YData', [get(obj.core, 'YData') y]);
        end % #addY
        %% Add XY
        % Adds an entry, x, to the X Data and an entry, y, to the Y Data
        function addXY(obj, x, y)
            set(obj.core, 'XData', [get(obj.core, 'XData') x], ...
                'YData', [get(obj.core, 'YData') y]);
        end % #addXY
        
        %% Replace X
        % Replaces the X Data to the vector xs
        function replaceX(obj, xs)
            set(obj.core, 'XData', xs);
        end % #resetX
        %% Replace Y
        % Replaces the Y Data to the vector ys
        function replaceY(obj, ys)
            set(obj.core, 'YData', ys);
        end % #resetY
        %% Replace XY
        % Replaces the X Data to the vector xs and Y Data to the vector ys
        function replaceXY(obj, xs, ys)
            set(obj.core, 'XData', xs, 'YData', ys);
        end % #resetY
        
        
        %% Update Replace XY
        % Triggers a plot update event during which the X and Y data will
        % be replaced with (set to) xs,ys.
        % *To reset only one of these values, set the value to remain the
        % same to []. Ex: to only update ys, call: obj.update_resetXY([],ys)
        function update_replaceXY(obj,xs,ys)
            obj.update_xs = xs;
            obj.update_ys = ys;
            notify(obj, 'UPDATE_PLOT');
        end % #update_replaceXY
        
        %% Update Add XY
        % **CAUSES ERRONEOUS PERFORMANCE, USE update_replaceXY IF
        % POSSIBLE**
        % Triggers a plot update event during which the X and Y data will
        % have the values x,y added to them (x to XData, y to YData).
        % *To reset only one of these values, set the value to remain the
        % same to []. Ex: to only update y, call: obj.update_addXY([],y)
        function update_addXY(obj,x,y)
            if(~isempty(obj.update_x)) %if there is already data waiting to be added.
                if(isempty(obj.update_xs))% and the XData isn't set to be replaced (or a queue aleady exists)
                	obj.update_xs = [get(obj.core, 'XData') obj.update_x x];
                else % and the XData is set to be replaced
                    obj.update_xs(end+1) = x;
                end
                obj.update_x = [];% empty x
            else
                obj.update_x = x;
            end
            if(~isempty(obj.update_y)) %if there is already data waiting to be added.
                if(isempty(obj.update_ys))% and the YData isn't set to be replaced (or a queue aleady exists)
                	obj.update_ys = [get(obj.core, 'YData') obj.update_y y];
                else % and the YData is set to be replaced
                    obj.update_ys(end+1) = y;
                end
                obj.update_y = [];% empty y
            else
                obj.update_y = y;
            end
            notify(obj, 'UPDATE_PLOT');
        end % #update_addXY
        
        
        %% Set
        % Sets some property (defined by varargin) of the plot core.
        function set(obj, varargin)
            set(obj.core, varargin{:});
        end % #set
    end % PersistentPlot -> methods
    
    methods(Access = private)
        %% Perform Update
        % Event Listener for a Plot Update. Updates plot data to what was
        % given in update_xs,update_ys or update_x,update_y. If the length
        % of either of them is zero, that data set won't be updated.
        function performUpdate(obj, ~,~)
            if ~(isempty(obj.update_xs) || isempty(obj.update_ys))
                obj.replaceXY(obj.update_xs,obj.update_ys);
                obj.update_xs = [];
                obj.update_ys = [];
            else
                if ~isempty(obj.update_xs)
                    obj.replaceX(obj.update_xs);
                    obj.update_xs = [];
                end
                if ~isempty(obj.update_ys)
                    obj.replaceY(obj.update_ys);
                    obj.update_ys = [];
                end
            end
            if ~(isempty(obj.update_x) || isempty(obj.update_y))
                obj.addXY(obj.update_x,obj.update_y);
                obj.update_x = [];
                obj.update_x = [];
            else
                if ~isempty(obj.update_x)
                    obj.addX(obj.update_x);
                    obj.update_x = [];
                end
                if ~isempty(obj.update_y)
                    obj.addY(obj.update_y);
                    obj.update_y = [];
                end
            end
            
            obj.update_Tlast = toc(obj.on_time);
        end % #performUpdate
    end % PersistentPlot -> methods(private)
end % class PersistentPlot