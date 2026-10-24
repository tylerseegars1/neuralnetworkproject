%readtable reads a file into a table with one row per tile and one column per field
%load masters.json keep ID, tile_is_hab, center_lat, center_lon, data, tile_status, sat_items
% masters.json is one folder back inside of
% data/amfitrite/amfitrite_open_waters_masters.csv

scriptFolder = fileparts(mfilename('fullpath'));
baseFolder = fileparts(scriptFolder);

mastersCsv = fullfile(baseFolder, 'data', 'amfitrite-open-waters-hab-sentinel2', 'amfitrite_open_waters_master.csv');

% we utilize detect import options
importOptions = detectImportOptions(mastersCsv);
importOptions.SelectedVariableNames = {'ID', 'tile_is_hab', 'center_lat', ...
    'center_lon', 'date', 'tile_status', 'sat_item'};
masterTable = readtable(mastersCsv, importOptions);

class(masterTable.sat_item)

temp = groupcounts(masterTable, "sat_item");
[sortedCounts, idx] = sort(temp.GroupCount, "ascend");
sortedtemp = temp(idx, :);

%collect sorted temp, ignores the the blank sat_item from the sortedarray
%and instead of removing it, keeping it in there for later if we use the
%neighboring tiles method of training
busiestSatItem = sortedtemp.sat_item(end-1);
busiestGroupCount = sortedtemp.GroupCount(end-1);

%print out busiest sat_item and its corresponding Group Count
fprintf('Most Frequent Sat_Item: %s \nNumber of Tiles: %d \n', string(busiestSatItem), busiestGroupCount);

%now we reverse search the masterTable for the busiest Sat_item, collect
%all of the rows that pertain to that sat_item
busiestRows = masterTable(strcmp(string(masterTable.sat_item), string(busiestSatItem)), :);
fprintf('Collected %d rows for Sat_Item %s.\n', height(busiestRows), string(busiestSatItem));

