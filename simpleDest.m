classdef simpleTest < matlab.unittest.TestCase

    methods (Test)
        % list of all tests to run (this should be out-sourced)
        function isEqualTest(testCase)
                testCase.assertEqual('11','11');
                disp('tested 11')
        end
    end
    
end