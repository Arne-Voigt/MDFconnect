classdef simpleTest < matlab.unittest.TestCase
    properties
        % timeseries
        signal_f64;
        signal_f32;
        signal_bool; 
        signal_uint8;
    end
    
    methods
        function obj = simpleTest()
            % raw signals
            time =       0:0.05:6.28;
            sin_f64 =    double(sin(time));
            sin_f32 =    single(sin(time));
            sin_bool =   logical(sin(time) >= 0);
            ramp_uint8 = uint8(time*20);
            % set timeseries
            obj.signal_f64 =   timeseries(sin_f64, time,    'Name', 'signal_f64');
            obj.signal_f32 =   timeseries(sin_f32, time,    'Name', 'signal_f32');
            obj.signal_bool =  timeseries(sin_bool,   time, 'Name', 'signal_bool');
            obj.signal_uint8 = timeseries(ramp_uint8, time, 'Name', 'signal_uint8');
            
            %squeeze data from three dimentions into one
            obj.signal_f64.Data    = squeeze(obj.signal_f64.Data);
            obj.signal_f32.Data    = squeeze(obj.signal_f32.Data);
            obj.signal_bool.Data   = squeeze(obj.signal_bool.Data);
            obj.signal_uint8.Data  = squeeze(obj.signal_uint8.Data);
        end
    end
        
    methods (Test)
        % list of all tests to run (this should be out-sourced)
        function writeRead(testCase)
            % write new MDF 
            dataBucket = tsBucket();
            dataBucket.add(testCase.signal_f64); 
            dataBucket.add(testCase.signal_f32);
            dataBucket.add(testCase.signal_bool);
            dataBucket.add(testCase.signal_uint8);
            
            MdfObjWrite = MDF_OBJECT();
            MdfObjWrite.importTsBucket(dataBucket); 
            MdfObjWrite.print('testWrite.mdf');
            
            % read newly written MDF
            MdfObjRead = MDF_OBJECT();
            MdfObjRead.read('testWrite.mdf');
            
            cntnr = MdfObjRead.hHD.getContainerOfAllCNsRegEx('.*'); % use regex to filter for desired channels
            for key = cntnr.keys() % step through all channles
                sigData = cntnr(key{1}).getDataAsTimeseries(); % call the "extract-data function" on the channel
                if ~isempty(sigData)
                    %assignin('base', sigData.Name, sigData);
                    eval([sigData.Name, ' = sigData;'])
                end
            end
            
            % compare read value with the original values
            testCase.verifyEqual(testCase.signal_f64,   signal_f64);
            testCase.verifyEqual(testCase.signal_f32,   signal_f32);
            testCase.verifyEqual(testCase.signal_bool,  signal_bool);
            testCase.verifyEqual(testCase.signal_uint8, signal_uint8);
            
        end
    end
    
end