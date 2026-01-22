% This Script extracts the data for Finland from all the files,
% and summarizes it into one file

file = 'tasmax_20060101-20101231.nc'

info = ncinfo(file)

% Constants that we will need
latstart = 296;
latend = 393;
latn = (latend - latstart) + 1;

lonstart = 264;
lonend =  316;
lonn = (lonend - lonstart) + 1;

% Initializing our container
finland_temperatures = zeros(latn, lonn, 34698, 2);


% Initializing our parameters
year = 2006;
daystart = 1;

%% Main loop

while year < 2101
    % Loading the correct files
    st_year = int2str(year)
    en_year = int2str(year+4);

    max_file = strcat('tasmax_', st_year, '0101-', (en_year), '1231.nc');
    min_file = strcat('tasmin_', st_year, '0101-', (en_year), '1231.nc');
    
    % Getting the length of the data
    days = length(ncread(max_file, 'time'));
    
    % this extracts the data for finland for one year
    max1 = ncread(max_file, 'tasmax', [lonstart latstart 1],[lonn latn days]);
    min1 = ncread(min_file, 'tasmin', [lonstart latstart 1],[lonn latn days]);
    
    % getting the temperatures in an array
    year_temps = get_temps(max1, min1, days);

    % updating the main container
    finland_temperatures(:, :, daystart:(daystart+days-1),:) = year_temps;

    % updating variables
    year = year + 5;
    daystart = daystart + days;
end

%% Checking the output

% Checking data per point
%y = squeeze(finland_temperatures(4 , 5, 1:34698, 2));
%x = linspace(1, length(y), length(y));
%scatter(x,y)

% Checking data per day
%y = squeeze(finland_temperatures(:, :, 34698, 2));
%heatmap(y)

%% Saving the data
nccreate("finland1.nc", "min", ...
    "Dimensions", {"rlat", latn, "rlon", lonn, "day", 34698});
nccreate("finland1.nc", "max", ...
    "Dimensions", {"rlat", latn, "rlon", lonn, "day", 34698});

ncwrite("finland1.nc", "min", squeeze(finland_temperatures(:,:,:,1)));
ncwrite("finland1.nc", "max", squeeze(finland_temperatures(:,:,:,2)));

%% Adding latitude and longitude data
longitude = ncread(max_file, 'lon', [lonstart latstart],[lonn latn])';
latitude = flip(ncread(max_file, 'lat', [lonstart latstart],[lonn latn])');

nccreate("finland1.nc", "lon", ...
    "Dimensions", {"rlat", latn, "rlon", lonn});
nccreate("finland1.nc", "lat", ...
    "Dimensions", {"rlat", latn, "rlon", lonn});

ncwrite("finland1.nc", "lon", longitude);
ncwrite("finland1.nc", "lat", latitude);



%% Checking the saved data

%ncdisp("finland1.nc")
% this extracts the data for one year
mintemp = ncread("finland1.nc", 'min', [1 1 1],[latn lonn 1]);
heatmap(mintemp)

%% Functions

function temperatures = get_temps(max_data, min_data, days)
    latn = 98;
    lonn = 53;
    
    % Data in the form:latitude, longitude, days since start, min/max
    temperatures = zeros(latn, lonn, days, 2);

    for i=1:days
        for latf=1:latn
            for lonf=1:lonn
                % Getting the temperatures in Celcius
                max_temp = max_data(lonf, latf, i) - 273.15;
                min_temp = min_data(lonf, latf, i) - 273.15;


                % The latitudes are defined this way because the map is flipped
                temperatures(latn-latf+1, lonf, i, 1) = min_temp;
                temperatures(latn-latf+1, lonf, i, 2) = max_temp;
            end
        end
    end
end

