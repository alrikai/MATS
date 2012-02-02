function out = readHDF5_mcmSpec( h5file )

%
%%
%%% Opens a H5 files and reads out all variables
%%% This M-file is brought to you by Jonathan King
%%
%

file = H5F.open (h5file, 'H5F_ACC_RDONLY', 'H5P_DEFAULT');

%
% Retreive the Platform Time
%
FieldName = 'PlatformTime';
try
    DATASET = '/Platform/Time';
    dset = H5D.open (file, DATASET);
catch
    DATASET = '/PLATFORM/Time';
    dset = H5D.open (file, DATASET);
end
rdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
H5D.close (dset);
if nargout == 1
    out.(FieldName) = rdata;
else
    assignin('caller',FieldName, rdata);
end

%
% Retreive the Platform Navigation
%
FieldName = 'PlatformNavigation';
try
    DATASET = '/Platform/Navigation';
    dset = H5D.open (file, DATASET);
catch
    DATASET = '/PLATFORM/PlatformNavigation';
    dset = H5D.open (file, DATASET);
end
rdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
H5D.close (dset);
if nargout == 1
    out.(FieldName) = rdata;
else
    assignin('caller',FieldName, rdata);
end

%
% Retreive the Data Time
%
FieldName = 'DataTime';
try
    DATASET = '/Sonar/Sensor1/Data1/Time';
    dset = H5D.open (file, DATASET);
catch
    DATASET = '/SONAR/SENSOR1/DATA1/Time';
    dset = H5D.open (file, DATASET);
end
rdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
H5D.close (dset);
if nargout == 1
    out.(FieldName) = rdata;
else
    assignin('caller',FieldName, rdata);
end

%
% Retreive the Data Navigation
%
FieldName = 'DataNavigation';
try
    DATASET = '/Sonar/Sensor1/Data1/Navigation';
    dset = H5D.open (file, DATASET);
catch
    DATASET = '/SONAR/SENSOR1/DATA1/Navigation';
    dset = H5D.open (file, DATASET);
end
rdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
H5D.close (dset);
if nargout == 1
    out.(FieldName) = rdata;
else
    assignin('caller',FieldName, rdata);
end

%
% Retreive the ChannelInfo
%
FieldName = 'ChannelInfo';
try
    DATASET = '/Sonar/Sensor1/Data1/ChannelInfo';
    dset = H5D.open (file, DATASET);
catch
    DATASET = '/SONAR/SENSOR1/DATA1/ChannelInfo';
    dset = H5D.open (file, DATASET);
end
rdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
H5D.close (dset);
if nargout == 1
    out.(FieldName) = rdata;
else
    assignin('caller',FieldName, rdata);
end

%
% Retreive the PingData
%
FieldName = 'PingData';
try
    DATASET = '/Sonar/Sensor1/Data1/PingData';
    dset = H5D.open (file, DATASET);
catch
    DATASET = '/SONAR/SENSOR1/DATA1/PingData';
    dset = H5D.open (file, DATASET);
end
dset = H5D.open (file, DATASET);
rdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
H5D.close (dset);
% Retreive the PingDataPhase if data is not in complex format
try
%     FieldName = 'PingDataPhase';
    try
        DATASET = '/Sonar/Sensor1/Data1/PingDataPhase';
        dset = H5D.open (file, DATASET);
    catch
        DATASET = '/SONAR/SENSOR1/DATA1/PingDataPhase';
        dset = H5D.open (file, DATASET);
    end
    pdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
%     H5D.close (dset);
%     if nargout == 1
%         out.(FieldName) = pdata;
%     else
%         assignin('caller',FieldName, pdata);
%     end
catch
    %disp(['No ',FieldName,' data present']);
end

if exist('pdata','var')
    rdata = rdata.*exp(1i*pdata);
    clear pdata;
else
    if(isfield(rdata,'A'))
        rdata = rdata.A+1i*rdata.B;
    end
end
if nargout == 1
    out.(FieldName) = rdata;
else
    assignin('caller',FieldName, rdata);
end

try
    %
    % Retreive the NERDS
    %
    FieldName = 'NERDS';
    try
        DATASET = '/Sonar/Sensor1/Data1/NERDS';
        dset = H5D.open (file, DATASET);
    catch
        DATASET = '/SONAR/SENSOR1/DATA1/NERDS';
        dset = H5D.open (file, DATASET);
    end
    rdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    H5D.close (dset);
    if nargout == 1
        out.(FieldName) = rdata;
    else
        assignin('caller',FieldName, rdata);
    end
catch
    %disp(['No ',FieldName,' data present']);
end


try
    %
    % Retreive the INS
    %
    FieldName = 'INS';
    try
        DATASET = '/Sonar/Sensor1/Data1/INS';
        dset = H5D.open (file, DATASET);
    catch
        DATASET = '/SONAR/SENSOR1/DATA1/INS';
        dset = H5D.open (file, DATASET);
    end
    rdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    H5D.close (dset);
    if nargout == 1
        out.(FieldName) = rdata;
    else
        assignin('caller',FieldName, rdata);
    end
catch
    %disp(['No ',FieldName,' data present']);
end

try
    %
    % Retreive the tFine
    %
    FieldName = 'TFine';
    try
        DATASET = '/Sonar/Sensor1/Data1/TFine';
        dset = H5D.open (file, DATASET);
    catch
        DATASET = '/SONAR/SENSOR1/DATA1/TFine';
        dset = H5D.open (file, DATASET);
    end
    rdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    H5D.close (dset);
    if nargout == 1
        out.(FieldName) = rdata;
    else
        assignin('caller',FieldName, rdata);
    end
catch
    %disp(['No ',FieldName,' data present']);
end

try
    %
    % Retreive the corrCoef
    %
    FieldName = 'CorrCoef';
    try
        DATASET = '/Sonar/Sensor1/Data1/CorrCoef';
        dset = H5D.open (file, DATASET);
    catch
        DATASET = '/SONAR/SENSOR1/DATA1/CorrCoef';
        dset = H5D.open (file, DATASET);
    end
    rdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
    H5D.close (dset);
    if nargout == 1
        out.(FieldName) = rdata;
    else
        assignin('caller',FieldName, rdata);
    end
catch
    %disp(['No ',FieldName,' data present']);
end

try
%
% Retreive the MotionSolutionDelays
%
FieldName = 'MotionSolutionDelays';
try
    DATASET = '/Sonar/Sensor1/Data1/MotionSolutionDelays';
    dset = H5D.open (file, DATASET);
catch
    DATASET = '/SONAR/SENSOR1/DATA1/MotionSolutionDelays';
    dset = H5D.open (file, DATASET);
end
rdata=H5D.read (dset, H5D.get_type(dset), 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT');
H5D.close (dset);
if nargout == 1
    out.(FieldName) = rdata;
else
    assignin('caller',FieldName, rdata);
end

catch
end


%
% Open group Platform to read attributes
%
try
    GROUP = '/Platform';
    group = H5G.open(file, GROUP);
catch
    GROUP = '/PLATFORM';
    group = H5G.open(file, GROUP);
end

%
% Retreive the UUID
%
ATTRIBUTE = 'UUID';
attr = H5A.open_name (group, ATTRIBUTE);
%rdata=H5A.read (attr, H5A.get_type(attr)); %no matlab datatypes over 64 bits
rdata=H5A.read (attr, 'H5T_NATIVE_UINT64');
H5A.close (attr);
if nargout == 1
    out.(ATTRIBUTE) = rdata;
else
    assignin('caller',ATTRIBUTE, rdata);
end

%
% Retreive the SpecVersionMajor
%
ATTRIBUTE = 'SpecVersionMajor';
attr = H5A.open_name (group, ATTRIBUTE);
rdata=H5A.read (attr, H5A.get_type(attr));
H5A.close (attr);
if nargout == 1
    out.(ATTRIBUTE) = rdata;
else
    assignin('caller',ATTRIBUTE, rdata);
end

%
% Retreive the SpecVersionMinor
%
ATTRIBUTE = 'SpecVersionMinor';
attr = H5A.open_name (group, ATTRIBUTE);
rdata=H5A.read (attr, H5A.get_type(attr));
H5A.close (attr);
if nargout == 1
    out.(ATTRIBUTE) = rdata;
else
    assignin('caller',ATTRIBUTE, rdata);
end

%
% Retreive the PlatformName
%
ATTRIBUTE = 'PlatformName';
attr = H5A.open_name (group, ATTRIBUTE);
rdata = H5A.read (attr, H5A.get_type(attr));
rdata = char(rdata.');
H5A.close (attr);
if nargout == 1
    out.(ATTRIBUTE) = rdata;
else
    assignin('caller',ATTRIBUTE, rdata);
end

%
% Retreive the Classification
%
ATTRIBUTE = 'Classification';
attr = H5A.open_name (group, ATTRIBUTE);
rdata=H5A.read (attr, H5A.get_type(attr));
rdata=H5T.enum_nameof (H5A.get_type(attr), rdata);
H5A.close (attr);
if nargout == 1
    out.(ATTRIBUTE) = rdata;
else
    assignin('caller',ATTRIBUTE, rdata);
end

%
% Retreive the DestructionNotice
%
ATTRIBUTE = 'DestructionNotice';
attr = H5A.open_name (group, ATTRIBUTE);
rdata=H5A.read (attr, H5A.get_type(attr));
rdata = char(rdata.');
H5A.close (attr);
if nargout == 1
    out.(ATTRIBUTE) = rdata;
else
    assignin('caller',ATTRIBUTE, rdata);
end

%
% Retreive the TechnicalPOC
%
ATTRIBUTE = 'TechnicalPOC';
attr = H5A.open_name (group, ATTRIBUTE);
rdata=H5A.read (attr, H5A.get_type(attr));
rdata = char(rdata.');
H5A.close (attr);
if nargout == 1
    out.(ATTRIBUTE) = rdata;
else
    assignin('caller',ATTRIBUTE, rdata);
end

%
% Retreive the DistributionStatement
%
ATTRIBUTE = 'DistributionStatement';
attr = H5A.open_name (group, ATTRIBUTE);
rdata=H5A.read (attr, H5A.get_type(attr));
rdata = char(rdata.');
H5A.close (attr);
if nargout == 1
    out.(ATTRIBUTE) = rdata;
else
    assignin('caller',ATTRIBUTE, rdata);
end

%
% Close group Platform 
%
H5G.close (group);



%
% Open group Data1 to read attributes
%
try
    GROUP = '/Sonar/Sensor1';
    group = H5G.open(file, GROUP);
catch
    GROUP = '/SONAR/SENSOR1';
    group = H5G.open(file, GROUP);
end

%
% Retreive the SensorName
%
ATTRIBUTE = 'SensorName';
attr = H5A.open_name (group, ATTRIBUTE);
rdata=H5A.read (attr, H5A.get_type(attr));
rdata = char(rdata.');
H5A.close (attr);
if nargout == 1
    out.(ATTRIBUTE) = rdata;
else
    assignin('caller',ATTRIBUTE, rdata);
end


%
% Close group Data1 
%
H5G.close (group);


%
% Open group Data1 to read attributes
%
try
    GROUP = '/Sonar/Sensor1/Data1';
    group = H5G.open(file, GROUP);
catch
    GROUP = '/SONAR/SENSOR1/DATA1';
    group = H5G.open(file, GROUP);
end

%
% Retreive the DataStreamName
%
ATTRIBUTE = 'DataStreamName';
attr = H5A.open_name (group, ATTRIBUTE);
rdata=H5A.read (attr, H5A.get_type(attr));
rdata = char(rdata.');
H5A.close (attr);
if nargout == 1
    out.(ATTRIBUTE) = rdata;
else
    assignin('caller',ATTRIBUTE, rdata);
end


%
% Close group Data1 
%
H5G.close (group);


%
% Close hdf5 file
%
H5F.close(file);


end