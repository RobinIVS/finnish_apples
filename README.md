# Finnish Apples
My master's thesis work. It involved predicting climatically suitable area for growing apples in Finland under climate change between 2025 and 2100.

# Desription
The purpose of this work was to predict where in Finland we could expect to have temperatures suitable for apple farming during the rest of the century. The code files here were created to a) extract the projected temperature data for Finland from a European dataset, b) calculate GDD as the main measure of suitability (using Chilling Units to determine important dates), and c) model the results to quantify uncertainty and make predictions. The output of these files was then further used in GIS software to create maps to visualize and further analyze the data.

# Software/Languages
Data extraction and calculations: MATLAB
Data analysis: R
Mapping/spatial analysis: QGIS

# HOW TO RUN
## 'data_extraction.m'
**Purpose:**

To extract data for a specific country (Finland, with the current settings) from a larger CORDEX domain (Euro-CORDEX, in this case). Transforms the temperatures from Kelvin to Celcius.


**Requirements:** 

This file requires as an input NetCFD data files with CORDEX data. Each file must contain 5 years of data with a daily resolution. Two sets of files are required, containing the minimum (tasmin) and maximum (tasmax) daily near-surface air temperatures. The file names should contain the variable name, starting date, and ending date. The format should match the following example: 'tasmax_20060101-20101231.nc'. This example would be interpreted as containing the data for the daily maximum temperature between 01 Jan 2006 and 31 Dec 2010.

For this analysis, the data used came from the GCM-RCM pair formed by EC_EARTH and RCA  models, under RCP8.5.


**Important info:** 

The variables 'latstart', 'latend', 'lonstart', and 'lonend' are set to the rows and columns in the EURO-CORDEX domain containing Finland, but they could be changed to contain other countries of interest, potentially working for other CORDEX domains, although this has not been tested.

The file includes a commented-out section that allows you to check whether the data was extracted correctly by allowing you to see a scatterplot of the daily temperatures at any given point in the map, or a heatmap of the temperature at any given day.


**Output:** 

Running this code produces the NetCDF file 'finland1.nc', containing daily temperatures for a rectanglular grid encapsulating Finland between 2006 and 2100, as well as the latitude and longitude of each point in the grid.

## 'data_managing.m'
**Purpose**: 

To calculate the total GDD for every year between 2006 and 2100 given daily temperature data. It also calculates Chilling Units accumulated through each year. However, this value is not saved, and is only used to determine the relevant dates for the start and end of the GDD calculations. 


**Requirements:** 

To run, this file takes as input the output of the 'data_extraction.m' file. In this case, it's called 'finland1.nc'. However, with small changes to the code (for example, changing 'lat_n' and 'lon_n', the name of the file, and the number of years of interest as appropriate), this file should work for any single NetCDF file with maximum and minimum daily temperatures, and the appropriate variable names in the file. Note that some functions would need to be modified for files with a different number of columns(lat)/rows(lon), or number of years.


**Important info:** 

The program assumes that the first year in the data is 2006. Some functions (especially 'get_yr_bounds) may need to be modified to account for different start dates, especially given the effect of leap years.

Given that the chilling units calculation requires hourly input, a model that interpolates hourly temperatures is also included as a function. This function takes into account day of the year, latitude, and maximum and minimum temperatures for the day. It has been adapted so it works for  latitudes above the Arctic circle, even when there is no daylight/nighttime.

Given that this process may take long, the variable 'progress' will print out the percentage completion as the main loop runs, so you can be sure that it is working.


**Agricultural values:** 

This program uses a modified form of the Utah model for calculating Chilling Units, although the original form of the Utah model is also included and commented-out in the code. For the purposes of this project, GDD accumulation starts on the first day of the calendar year after 650 Chilling Units have been achieved (in some cases, this amount may be achieved before the start of the calendar year because of the temperatures in the last months of the previous year). Chilling accumulation starts on the day when the previous season's CU reaches its minimum point starting with 1 October.

The base temperature for apples to accumulate GDD was set to 5°C. The minimum requirement for the average variety of apple in Finland to achieve maturity was set to 1194 GDD.


**Output:** 

The resulting output is a csv file 'GDD2006-2010.csv', containing 97 columns. The first two columns contain the latitude and longitude of every point in the grid. The remaining 95 columns correspond to the 95 years of GDD data for each point.
This format was chosen to make it easier to use this file with GIS software.

## 'analysis.R'
**Purpose:**

This file takes a CSV file with yearly GDD data, and creates a simple linear regresssion model for each point in the grid over 94 years of data. It then calculates the following statistics to evaluate the models:
- Coefficient of determination (R^2)
- p-value of the Shapiro-Wilk normality of residuals test
- p-value of the Breusch-Pagan heteroscedasticity of residuals test
- Predicted yearly change (\beta_1)
- Residual standard error (\sigma)
In addition, it saves the fitted GDD values and calculates a more conservative 'Safe Forcing index'.


**Requirements:**

This file takes as an input a CSV file containing yearly GDD values. The first two columns of the file must correspond to the latitude and longitude of the points on the grid, and the remaining columns must each correspond to a year's of data. The rows must each correspond to a point in the grid. 

In this case, the file being used is called 'GDD_2006-2100_fin.csv'. NOTE: this file is in the same format as the output of 'data_managing.m', but it is not the same file. 'GDD_2006-2100.csv' was modified using QGIS to remove all the data points that fell strictly outside of Finland's borders, using Finland's shapefile. However, the aforementioned file can still be used with this program if the number of rows is adjusted where appropriate. However, note that the points removed mostly correspond to the ocean and may greatly affect the analysis and the conclusions that can be drawn from it.


**Important info:**

The model and evaluation take into account only data from 2007 onwards. 2006 was discarded as it was the first year and therefore the critical dates for Chilling and Heating accumulation could not be properly assessed, and therefore only served to initialize the calculations for the following years.

The DATA VIZ section includes code to visualize the distribution of the test statistics as histograms. Note that these histograms do not consider the spatial distribution of the points, and heat maps or other GIS techniques may be more useful to analyze the results.

The CHECKING INDIVIDUAL POINTS section allows you to select individual points in the grid and analyze the model fit more carefully, both analytically or graphically.

Code is also included to adjust p-values of the tests if so desired, although the difference found has no practical significance.


**Output:**

Running the code produces 4 different CSV files:
1. 'r2test.csv', containing all the test statistics for every point in the grid
2. 'GDD_FIN_fitted.csv', containing the fitted values from the model for every year and every point on the grid
3. 'Safe_Forcing_FIN.csv', containing the Safe Forcing values for every year and every point
4. 'probabilities.csv', containing the probability of exceeding 1194 GDD for every point and every year, given the fitted values and assuming a normal distribution centered at the fitted value, with standard deviation equal to the resiudal standard error of the model.





