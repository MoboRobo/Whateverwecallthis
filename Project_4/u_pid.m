function control = u_pid(t, goalDistance, distanceTraveled)
    global rob
    persistent lastError errorIntegral t_last
    if isempty(lastError) %initialize
        lastError = 0;
        errorIntegral = 0;
        t_last = 0;
    end % isEmpty(lastError)?
    
    v_max = 0.3;
    k_p = 3;
    k_d = 0.1;
    k_i = 0;
    maxErrorIntegral = 10;
    error = goalDistance - distanceTraveled;
    dt = t - t_last;
    errorDerivative = (error-lastError)/ dt;
    errorIntegral = errorIntegral + error*dt;
    if abs(errorIntegral) > maxErrorIntegral;
        errorIntegral= (errorIntegral/abs(errorIntegral))*maxErrorIntegral;
    end
    
    
    control = k_p * error + k_d * errorDerivative + k_i * errorIntegral;
    
    if abs(control) > v_max
        control = (control / abs(control)) * v_max;
    end
    
    lastError = error;
    t_last = t;
end