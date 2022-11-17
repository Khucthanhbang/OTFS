clc; 
clear all; %#ok<CLALL>
close all;

% Running a model with a RegressionSetup
% Attention: all results of RegreesionSetup are saved into directory named
% TestRegressionResults. This is done by forcibly setting the directory
% name in the ReadSetup.
    UserAns = input(['Whether it is necessary to perform a ', ...
        'calculation of the results (i.e. calling Main)? yes/no\n'], 's');
    if sum(strcmpi(UserAns, {'y', 'yes'}))
        Main(1, 1, 1);
    else
    end

% Gathering the results
    TestRes = GetResults('TestRegressionResults');
    RefRes = GetResults('ReferenceRegressionResults');

% Checking for compliance of test results with reference values
    if size(RefRes, 1) > size(TestRes, 1)
        error(['The number of test results obtained is less than the ', ...
            'number of reference results! Check if new reference ', ...
            'results were added without RegressionSetup update!']);
    end

    if size(RefRes, 1) < size(TestRes, 1)
        warning(['The number of test results obtained is greater ', ...
            'than the number of reference results. Check if new ', ...
            'tests have been added!']);
    end

% Comparing the results
    % Initialization of the number of passed comparisons
        Score = 0;
    for k = 1 : size(RefRes, 1)
        % Trying to find the test result with the same name as for
        % reference result
            TestName = RefRes{k, 1};
            n = find(strcmp(TestName, TestRes(:, 1)));
            if numel(n) ~= 1
                fprintf(['%d Test named %s is not found in test ', ...
                    'results!\n'], k, TestName);
                break % go to the next value of k
            end

        % Matching values of isBER
            if RefRes{k, 2}.isBER ~= TestRes{n, 2}.isBER
                fprintf('%d isBER parameters do not match!\n', k);
                break
            end

        % Calculation of BER+PER/ECDF curves
            Ref = GetCurves(RefRes{k, 2});
            Test = GetCurves(TestRes{n, 2});

        % Initialization of the number of passed comparisons in current
        % test
            SubScore = 0;
        if RefRes{k, 2}.isBER
            % Searching for common values in h2dBs
                [Buf, iRef, iTest] = intersect(Ref.h2dBs, Test.h2dBs);
                if length(Buf) < min([length(Ref.h2dBs), ...
                        length(Test.h2dBs)])
                    fprintf('%02d h2dBs - failed.', k);
                    fprintf([' Parameters h2dBs in reference and test ',...
                        'results have too few common points!']);
                else
                    fprintf('%02d h2dBs - ok!', k);
                    SubScore = SubScore + 1;
                end
                fprintf(' length([Common, Ref, Test]) = [%d, %d, %d]\n',...
                    length(Buf), length(Ref.h2dBs), length(Test.h2dBs));
                if SubScore == 0
                    break
                end

            % Checking for BER values (10% margin)
                if sum(1.1*Ref.BER(iRef) < Test.BER(iTest)) > 0
                    fprintf('   BER - failed.');
                    fprintf([' BER in reference is better (smaller) ', ...
                        'than BER in test results!']);
                else
                    fprintf('   BER - ok!');
                    SubScore = SubScore + 1;
                end
                Buf = sprintf(' %f,', Test.BER(iTest) ./ Ref.BER(iRef));
                Buf(1) = '[';
                Buf(end) = ']';
                fprintf(' Test / Ref (should be <= 1.1) = %s\n', Buf);

            % Checking for PER values (10% margin)
                if sum(1.1*Ref.PER(iRef) < Test.PER(iTest)) > 0
                    fprintf('   PER - failed.');
                    fprintf([' PER in reference is better (smaller) ', ...
                        'than PER in test results!']);
                else
                    fprintf('   PER - ok!');
                    SubScore = SubScore + 1;
                end
                Buf = sprintf(' %f,', Test.PER(iTest) ./ Ref.PER(iRef));
                Buf(1) = '[';
                Buf(end) = ']';
                fprintf(' Test / Ref (should be <= 1.1) = %s\n', Buf);

            % Updating common score
                if SubScore == 3
                    Score = Score + 1;
                end
        else
            % Searching for common values in PAPRVals
                [Buf, iRef, iTest] = intersect(Ref.PAPRVals, ...
                    Test.PAPRVals);
                if length(Buf) < min([length(Ref.PAPRVals), ...
                        length(Test.PAPRVals)])
                    fprintf('%02d PAPRVals - failed.', k);
                    fprintf('% Parameters PAPRVals in reference  and ', ...
                        'test results have too few common points!');
                else
                    fprintf('%02d PAPRVals - ok!', k);
                    SubScore = SubScore + 1;
                end
                fprintf(' length([Common, Ref, Test]) = [%d, %d, %d]\n',...
                    length(Buf), length(Ref.PAPRVals), ...
                    length(Test.PAPRVals));
                if SubScore == 0
                    break
                end

            % Checking for ECDF values (10% margin)    
                if sum(1.1*Ref.ECDF(iRef) < Test.ECDF(iTest)) > 0
                    fprintf('   ECDF - failed.');
                    fprintf([' ECDF in reference is better than ECDF ', ...
                        'in test results!']);
                else
                    fprintf('   ECDF - ok!');
                    SubScore = SubScore + 1;
                end
                Buf = sprintf(' %f,', Test.ECDF(iTest) ./ Ref.ECDF(iRef));
                Buf(1) = '[';
                Buf(end) = ']';
                fprintf(' Test / Ref (should be <= 1.1) = %s\n', Buf);

            % Updating common score
                if SubScore == 2
                    Score = Score + 1;
                end
        end
    end

% If all tests pass successfully, we can update the reference results
% folder. In this case, the folder with the old reference results is
% deleted, and the folder with test results (and, possibly, with new added
% results) becomes the ReferenceRegressionResults folder.
    isTestResDeleted = 0;
    if Score == size(RefRes, 1)
        UserAns = input(['All tests passed successfully. Update ', ...
            'reference results? yes/no \n'], 's');
        if sum(strcmpi(UserAns, {'y', 'yes'}))
            % Delete folder and its content
                rmdir(ReferenceRegressionResults, 's');
            % Rename folder
                movefile('TestRegressionResults', ...
                    'ReferenceRegressionResults');
                isTestResDeleted = 1;
            % Printing the status
                fprintf('Reference results update completed.\n')
        end
    else
        fprintf('Only %d tests of %d are passed successfully.\n', ...
            Score, size(RefRes, 1))
    end

    if isTestResDeleted == 0
        UserAns = input(['Do you want to delete all test regression ', ...
            'results? yes/no \n'], 's');
        if sum(strcmpi(UserAns, {'y', 'yes'}))
            rmdir(TestRegressionResults, 's');
        end
    end

function Curves = GetCurves(Res)

    if Res.isBER
        Curves.h2dBs = Res.h2dBs;
        Curves.BER = Res.NumErBits ./ Res.NumTrBits;
        Curves.PER = Res.NumErFrames ./ Res.NumTrFrames;
    else
        Curves.PAPRVals = Res.PAPRVals;
        Curves.ECDF = Res.NumCaptPAPRSamples ./ Res.NumPAPRSamples;
    end

end

function Results = GetResults(DirName)

    if ~isfolder(DirName)
        error('Folder %s is not found!\n', DirName);
    end

    Listing = dir(DirName);
    Results = cell(0);

    n = 0;
    for k = 1:length(Listing)
        if ~Listing(k).isdir
            FName = Listing(k).name;
            if length(FName) > 4
                if isequal(FName(end-3:end), '.mat')
                    load([DirName, '\', FName], 'Res');
                    n = n + 1;
                    Results{n, 1} = FName(1:end-4);
                    Results{n, 2} = Res;
                end
            end
        end
    end

end