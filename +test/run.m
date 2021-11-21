import matlab.unittest.TestRunner;
import matlab.unittest.TestSuite;

suite = TestSuite.fromClass(?test.testWriteRead);

runner = TestRunner.withTextOutput('Verbosity', matlab.unittest.Verbosity.Concise);

result = runner.run(suite);
% generate output for the yaml tester
any(result.Failed|result.Incomplete) 