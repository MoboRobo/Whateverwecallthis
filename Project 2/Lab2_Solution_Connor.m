function Lab2_Solution_Connor(robot_id)
    global rob_type laser_data_avail person
    rob_type = 'sim';
    %% SETUP ROBOT
    rasp = raspbot(robot_id, [0.25; 0; pi/2])
    rob = P2_Robot(rasp);
    if(~strcmp(robot_id,'sim'))
        rob_type = 'raspbot';
        rob.core.togglePlot(); %Turn on map plotting for non-simulated robots
    end

    %% SETUP MAPPING
    bounds = 4*[0.5 0; 0.5 1; -0.5 1; -0.5 0]; % Inverted U-Shaped Container
    person_lines = ShapeGen.rect(0.1,0.05);
    wm = WorldMap(rob, bounds);
        person = wm.addObstacle(person_lines); % Person to Follow.
        person.pose = [0 0.5 0]; % Move to Center Screen
    wm.createMap();
    pause(1) % Wait for World to Initialize
    
    %% TASK PARAMETERS
    FOLLOWING_DIST = 0.5;   % m, Distance to stay away from target.
    PROP_GAIN = 1;          % Proportional gain for positioning
    
    %% SETUP SENSING
    rob.core.startLaser();
    rob.core.laser.NewMessageFcn=@new_rangeData; % Setup Callback to Process New Data
    laser_data_avail = 0; % Flag for New Unprocessed Laser Data 
    
    %% INITIALIZE DATA PLOTTING
    % Plotting of Solo-Plot of the Nearest Object in the Robot's Reference
    % Frame.
    fig_target = figure();
    plot_target = scatter([],[]);
        plot_target.Marker = 'x';
        plot_target.MarkerEdgeColor = 'r';
        axis(1.5*[-1 1 -1 1]);
    
    %% MAIN LOOP
    last_plot = tic; % Time of last plotting of laser data.
    hz = 3; % [Hz] Maximum Number of Times to Update LIDAR Display per Second.
    sct_overlay = 0; % Scatter Plot of Nearest Object for Overlay onto the LIDAR Data. 
    done = 0;
    while(~done)
        
        %% ALGORITHM
        rs = rob.core.laser.LatestMessage.Ranges; % Store so all functions use same data set (lest there be an interim interrupt update)
        rs = RangeImage.cleanImage(rs, 0.06, 1.5);
        
        [l_near, i_near, ~] = dist2nearestObject(rs, -pi/2, pi/2);
        [x_near, y_near, th_near] = RangeImage.irToXy(i_near, l_near);
        set(plot_target, 'XData', -y_near, 'YData', x_near);
        
        prntsrc = l_near
        
        if 1 %(l_near ~= Inf) % Is there a valid point?
            rob.trajectory_goTo(0.05, l_near-FOLLOWING_DIST, th_near);
        else
            % Spin in place until nearest object to robot is within field
            % of view (i.e. robot is pointing to nearest object; this 
            % solves the "step-over" problem):
            OOR = 1; % Is Out of Range?
            while(OOR) %sub-loop
                rs = rob.core.laser.LatestMessage.Ranges; % Store so all functions use same data set (lest there be an interim interrupt update)
                rs = RangeImage.cleanImage(rs, 0.06, 1.5);
                [l_n, ~, th_n] = dist2nearestObject(rs); % Nearest Distance
                [l_nir, ~, ~] = dist2nearestObject(rs, -pi/2, pi/2); % Nearest In Range
                
                if(l_nir > l_n || th_n < pi/3 && th_n > -pi/3)
                % If nearest object in range is farther than the nearest object
                % or the nearest point is not within the center of the
                % field of view
                    dir = -sign(th_n); % Spin direction of nearest object
                    rob.moveAt( 0, dir*(pi/2) ); %spin into the direction of nearest object
                else
                    OOR = 0; %done
                end % l_nir > l_n?
                
                pause(0.05); % CPU Relief
            end % while OOR
        end % l_near~=Inf?
        
        
        %% Plot Laser Data
        if( (isempty(last_plot) || toc(last_plot)>1/hz) && laser_data_avail)
            last_plot = tic;
            
            fig = RangeImage.plot_rangeData(rob.core.laser.LatestMessage.Ranges, 0); % Plot Range Data
            %Plot nearest point on top of range data:
            figure(fig);
            set(0,'CurrentFigure',fig)
                if(sct_overlay == 0) %Overlay has not yet been performed.
                    hold on
                    sct_overlay =  scatter(-y_near,x_near, 'Marker', 'x', 'MarkerEdgeColor', 'r');
                    legend('LIDAR Readings', 'Nearest Object')
                    hold off
                else
                    set(sct_overlay, 'XData', -y_near, 'YData', x_near);
                end% sct_overlay==0
            
            laser_data_avail = 0; % Flag Laser Data as Processed.
            
        end  % last_time > 1/hz
            
        pause(0.05); % CPU Relief
    end % while ~done

    %% RESET ROBOTS & CLEAR MEMORY
    pause % Wait for instruction before closing

    rob.core.stopLaser();
    clear rob
    clear rasp
    clear robot
    close all
end % #Lab2_Solution_Connor

%% Distance to Nearest Object
% Returns distance, l,  to the nearest object with non-zero distance from the
% given range data, its index in the range data, idx, and its bearing, th
% in radians.
% Optional: th_min, th_max - boundaries (in radians) of the angular range 
% to constrain the search for the nearest point to.
function [l, idx, th] = dist2nearestObject(ranges, th_min, th_max)
    l = Inf;
    idx = 0;
    in_range = 1; % - [bool] Whether the pt being tested is within the 
                  %   valid angular range, if specified by th_min, th_max
    
    for i=(1:length(ranges))
        th_i = deg2rad(RangeImage.index2bearing(i));
        
        if(nargin >= 3 && (th_i < th_min || th_i > th_max))
            in_range = 0;
        end
        
        if(in_range && abs(ranges(i)) < abs(l) && ranges(i)~=0)
            l = ranges(i);
            idx = i;
        end % ranges<l
        
        in_range = 1;
    end % for ranges
    
    th = deg2rad(RangeImage.index2bearing(idx));
end % 

% Callback Function on New Laser Range Data
%%DEPRECATED%%
function new_rangeData(~, event)
    global person laser_data_avail
    persistent last_time last_call person_initPos
    persistent dp vp om
    
    laser_data_avail = 1; % Flag new Laser Data as Available
    
    if isempty(last_call)
        last_call = tic; % time of last call to this function
    else

        % Move Person Up and Down from init a Maximum of dp Distance at with
        % vertical velocity vp with rotational velocity om.
        if isempty(person_initPos) % Provide Initial States
            person_initPos = person.pose;
            dp = 0.5; vp = 0.04; om = 0;
        end
        if (person.pose(2) > person_initPos(2)+dp && vp>0 ...
         || person.pose(2) < person_initPos(2)-dp && vp<0)
            vp = -vp; % turn around if out of bounds (if haven't turned around already)
        end % if out of bounds
        person.pose = person.pose + [0 vp*toc(last_call) om*toc(last_call)]; % Move
        
        last_call = tic;
    end % isempty(last_call)?
    
%     hz = 5; % [Hz] Maximum Number of Times to Update LIDAR Display per Second.
%     if(isempty(last_time) || toc(last_time)>1/hz )
%         last_time = tic;
%         plot_rangeData(event.Ranges);
%     end % last_time > 1/hz?
end % #new_rangeData