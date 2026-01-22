%% Using the new file
%
file = 'finland1.nc';

min_file = ncread(file, 'min');
max_file = ncread(file, 'max');
lat_file = ncread(file, 'lat');
lon_file = ncread(file, 'lon');

read = true;


%% Getting GDD for all years
lat_n = 98;
lon_n = 53;

GDD_full = zeros(lat_n, lon_n, 95);
CU_full = zeros(lat_n, lon_n, 95);

yr_length = 365;

GDD_table = make_container(lat_file, lon_file, 2006, 2100);


%% Main Loop

current_index = 1;

for latitude = 1:lat_n
    for longitude = 1:lon_n
        % Calculating the actual coordinates
        lat = lat_file(latitude, longitude);
        lon = lon_file(latitude, longitude);

        % Setting the initial conditions
        CU_init = 0;

        for year = 2006:2100
           [GDD, CU, CU_extra] = accumulate(year, min_file, max_file, ...
               lat, latitude, longitude, CU_init);
    
            GDD_full(latitude, longitude, year-2005) = GDD;
            CU_full(latitude, longitude, year-2005) = CU;
            CU_init = CU_extra;

            yr_str = int2str(year);
            GDD_table.(yr_str)(current_index) = GDD;

        end

        current_index = current_index + 1;
    end
    progress = latitude/lat_n
end


%% Checking output
%heatmap(CU_full(:, :, 80))

x = linspace(1, 95, 95);
y = squeeze(GDD_full(20, 30, :));
scatter(x,y)

%% Saving table as CSV
filename = "GDD2006-2100.csv";
writetable(GDD_table, filename);


%% Functions

function GDD_table = make_container(lat_file, lon_file, start_year, end_year)
    var_names = ["lat", "lon"];

    n_years = end_year - start_year + 1;

    for year = start_year:end_year
        yr_str = int2str(year);
        var_names(end+1) = yr_str;
    end

    vartypes = repelem("double", n_years + 2);

    GDD_table = table('Size', [5194 (n_years + 2)],...
        'VariableNames', var_names, 'VariableTypes', vartypes);

    current_index = 1;

    for latitude = 1:98
        for longitude = 1:53
            lat = lat_file(latitude, longitude);
            lon = lon_file(latitude, longitude);

            GDD_table.lat(current_index) = lat;
            GDD_table.lon(current_index) = lon;

            current_index = current_index + 1;
        end
    end
end


function [GDD, CU, CU_extra] = accumulate(year, min_file, max_file, ...
    lat, latitude, longitude, CU_init)
    % This function accumulates GDD and CU for a year in a single location.
    % The outputs are as follows:
    % GDD: GDD accumulated from chilling completion to end of year
    % CU: Total CU accumulated between last minimum chill and current one
    % CU_extra: CU accumulated after the minimum chill

    [yr_start, yr_end] = get_yr_bounds(year);
    yr_length = yr_end - yr_start + 1;

    % Starting storing variables
    GDD_acc = 0;
    accumulate_heat = false;
    CU_acc = CU_init;

    GDD_per_day = zeros(yr_length, 1);
    CU_per_day = zeros(yr_length, 1);


    % Calculating CU & GDD for the year
    for day = yr_start:yr_end
    
        % Getting the day of the year
        date = day - yr_start + 1;

        % We retrieve the temperatures for that day
        tmin = min_file(latitude, longitude, day);
        tmax = max_file(latitude, longitude, day);
    
        % We calculate the chilling and heating
        [CU_day, GDD_day] = daily_acc(date, lat, tmin, tmax);

        CU_acc = CU_acc + CU_day;

        % We only accumulate GDD if chilling was fulfilled
        if CU_acc > 650
            accumulate_heat = true;
        end

        % Even if CU goes below 650 later on, accumulation continues
        if accumulate_heat
            GDD_acc = GDD_acc + GDD_day;
        end
        
        GDD_per_day(date) = GDD_acc;
        CU_per_day(date) = CU_acc;
    end

    % Calculating the ending points of the seasons
    [min_chill, min_chill_day] = min(CU_per_day(274:end));
    min_chill_day = min_chill_day + 274;
    
    % Calculating the outputs
    GDD = GDD_per_day(yr_length);
    CU = CU_per_day(min_chill_day);

    CU_extra = CU_per_day(yr_length) - CU_per_day(min_chill_day);

end


% Year bounds calculator (in days from 1/1/2006)
function [yr_start, yr_end] = get_yr_bounds(year)
    % Number of years from the beginning year
    yrs_from_start = year - 2006;

    % Number of leap years from 2006 to the start of the year of interest
    leaps = floor((yrs_from_start + 1)/4);
    
    % Days to year's beginning (+1 because index starts at 1)
    yr_start = 365*yrs_from_start + leaps +1;

    % Days to year's end (-1 because of the index starting position)
    yr_end = yr_start + 365 - 1;

    % Accounting for leap years (2100 is not a leap year)
    if (mod(year, 4)==0) && (year ~= 2100)
        yr_end = yr_end + 1;
    end
end


% Daytime temperature calculator (hours after sunrise)
function td = tday(hr, tmin, tmax, daylen)
    td = tmin + (tmax-tmin) * sin( (pi*hr) / (daylen+4) );
end

% Nighttime temperature calculator (hours after sunset)
function tn = tnight(hr, tsunset, tmin, daylen)
    tn = tsunset - log(hr-daylen) * ( (tsunset - tmin) / (log(24 - daylen)) );
end


% Logarithmic temperature interpolation function
function temps = get_hour_temps(day, lat, tmin, tmax)
    % Container for the temperatures
    temps = zeros(24,1);
    
    % Setting all the constants that we need
    latitude = lat*pi/180;
    gamma = (2*pi/365)*(day-1);
    delta = 0.006918 - 0.3999*cos(gamma) + 0.070257*sin(gamma) ...
        - 0.006758*cos(2*gamma) + 0.000907*sin(2*gamma) ...
        - 0.002697*cos(3*gamma) + 0.00148*sin(3*gamma);
    tans = -tan(latitude)*tan(delta);

    if tans <= -1
        dl = 24;
    elseif tans >= 1
        dl = 0;
    else
        dl = (180/pi)*(2/15)*acos(tans);
    end
    
    % Linear interpolation function if daylength is 0
    if dl == 0
        for h = 0:23
            temps(h+1) = tmin + h*((tmax-tmin)/24);
        end
        return
    end 
    
    % Logarithmic interpolation
    for h = 0:23
        % Daylight curve
        if h < (dl + 1)
            temps(h+1) = tday(h, tmin, tmax, dl);
        % Nighttime curve
        else
            temp_sunset = tday(dl, tmin, tmax, dl);
            temps(h+1) = tnight(h, temp_sunset, tmin, dl);
        end
    end
end


% Modified Utah Model to calculate daily CU accumulation
function CU = dailyCU(temps)
    % We start with 0 CU
    CU = 0;
    
    % MODIFIED UTAH
    % We add CU depending on the temperature
    for hour = 1:24
        if temps(hour) > 21
            CU = CU - 1;
        elseif temps(hour) > 0
            CU = CU + (sin(2*pi*temps(hour)/28));
        end
    end


    % ORIGINAL UTAH
    %for hour = 1:24
    %    if temps(hour) > 18
    %        CU = CU - 1;
    %    elseif temps(hour) > 15.9
    %        CU = CU - 0.5;
    %    elseif temps(hour) > 12.4
    %        CU = CU;
    %    elseif temps(hour) > 9.1
    %        CU = CU + 0.5;
    %    elseif temps(hour) > 2.4
    %        CU = CU + 1;
    %    elseif temps(hour) > 1.4
    %        CU = CU + 0.5;
    %    end
    %end
    % We add nothing if the temperature <= 0
end


% GDD calculation function
function GDD = dailyGDD(meantemp)
    GDD = 0;
    if meantemp > 20
        GDD = 5;
    elseif meantemp > 5
        GDD = meantemp - 5;
    end
end


% Function to get CU and GDD accumulated for a day
function [CU, GDD] = daily_acc(day, lat, tmin, tmax)
    daily_temps = get_hour_temps(day, lat, tmin, tmax);
    mean_temp = mean(daily_temps);

    CU = dailyCU(daily_temps);
    GDD = dailyGDD(mean_temp);
end



