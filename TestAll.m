tic

import matlab.unittest.TestRunner;
import matlab.unittest.TestSuite;

% get folder of this file
thisScriptPath = mfilename('fullpath');
[thisScriptFolder, ~, ~] = fileparts(thisScriptPath);

suite = TestSuite.fromFolder(fullfile(thisScriptFolder));
%suite = TestSuite.fromFile(fullfile(thisScriptFolder, 'data','propMode.m'));
% suite = suite.selectIf(matlab.unittest.selectors.HasParameter);

runner = TestRunner.withTextOutput('Verbosity', matlab.unittest.Verbosity.Concise);
%runner = TestRunner.withTextOutput('OutputDetail',0);


result = runner.run(suite);

toc

