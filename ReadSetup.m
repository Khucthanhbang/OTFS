function Params = ReadSetup(NamePrefix)
%
% ������� ��������� ����� ������, ��� ������� ���������� � NamePrefix �
% ����� ���������� 'm'. ���� ������ ��������� ������������� ���������� (���
% ����� 'Params.'). ����� Setup ������ ���� �������� � ����� ��������������
% �� �������� m-�����. ������������ ������ ������� ���������� ��������
% '% End of Params' (�������������, ��������, ��, ��� �������� � ������
% ����� '% End of Params' ����������� �� �����, ��� ��� ��� �����������).
% ����� ����� �� ����������� ��������� ���������� ����������� ������
% ����������, ������� ������� '% End of Params' � ����� ����� ��
% �����������. ������ ������ ���������� �������������. ��������� � ������
% ������ �� ����������� ��������� �������������� ������ �������. ���� ���
% ����� ����� ������� ��� ������ �� ����� �����, �� ����� �������� ����
% ������ � ������ ������� ����������, �.�. � ����������� �� ���������.
% ���������: ���� ��������� �������� ������ ����� ���������� ��� �������,
% ��� � Setup ���� �� ������ ������, �� ����� ������� ����� ����������, �
% ������� ������� ���� �� �������� �� ���������. ���� NamePrefix ==
% RegressionSetup, �� �� ��� ������ ���������� ������������� �����
% ��������� �������: Common.SaveDirName = 'TestRegressionResults', �
% ��������� ������ �� ���� ������� ���������� ����� ��������� ��������
% ����, ��� Common.SaveDirName �� ����� 'TestRegressionResults' � �� �����
% 'ReferenceRegressionResults' (����� �������� �� �����), ��� ��� ��� �����
% ���������������� ��� ���� ���������.
%
% �������� ���������:
%   Params - cell-������ � ���������� �������� ����������, �������������
%       �������� �����(��) Setup.

    % ������������� ����������
        Params = cell(0);

    % ����������� ����� ����� ��������� Params �������� ������
        global FieldNames
        SFieldNames = FieldNames;
        SFieldNames{end+1} = 'BER';
        SFieldNames{end+1} = 'Common';
   
    % ����� ������
        % ������������� ������� ��� ������
            FileNames = cell(0);
        % ��������� ���������� ������� ����������
            Listing = dir;
        % ���� �� ���������� ���������, ������������ � ����������
            for k = 1:length(Listing)
                % ������������� ������ �����
                if ~Listing(k).isdir
                    % ��������, ����� ��� ����� ���������� �� NamePrefix �
                    % ����� ���������� 'm'
                    if length(Listing(k).name) >= length([NamePrefix, ...
                            '.m'])
                        if strcmp(Listing(k).name(1 : length( ...
                                NamePrefix)), NamePrefix) && strcmp( ...
                                Listing(k).name(end-1 : end), '.m')
                            FileNames{end+1} = Listing(k).name; %#ok<AGROW>
                        end
                    end
                end
            end

    % ��������� ������� ���������� �����
        for k = 1:length(FileNames)
            % �������� ������� ���������� ������� ����������
                NumParams = length(Params);

            % ��������� ������� ���� � �����������
                try
                    fid = fopen(FileNames{k});
                catch
                    error('Failed to open setup file %s!\n', FileNames{k});
                end
                
            % ������������� ���������� ������ ����������
                BufParams = [];
                
            % ���������� ���������� ����� �� �����
                tline = fgetl(fid);
                isFindEndOfParams = false; % ��� ���������� ���������� ��
                    % ������, ���� ���� ������
                while ischar(tline)
                    % ������� 'BufParams.' ����� ������ ����� ��������
                    % ������
                        for n = 1:length(SFieldNames)
                            OldStr = [SFieldNames{n}, '.'];
                            NewStr = ['BufParams.', OldStr];
                            tline = strrep(tline, OldStr, NewStr);
                        end

                    % ��������� ��������� ������
                        try
                            eval(tline);
                        catch
                            error(['Failed to evaluate ''%s'' in ', ...
                                'file %s!\n'], tline, FileNames{k});
                        end

                    % ���������, ���� �� � ���� ������ ���� ���������
                    % ������ ����������
                        isFindEndOfParams = contains(tline, ...
                            '% End of Params');
                    
                    % ���� ��� ������ ���� ��������� ������ ���������� �
                    % ������� ����� ���������� �� ������, �� ����� ��������
                    % ������� ����� ���������� � �������� ������ ������ �
                    % ���������������� ���������� ������ ������ ����������
                        if isFindEndOfParams
                            if ~isempty(BufParams)
                                Params{end+1} = BufParams; %#ok<AGROW>
                                BufParams = [];
                            end
                        end
                    
                    % ��������� ��������� ������ �����
                        tline = fgetl(fid);
                end

            % ���� ���� ����������, � ������� ����� ���������� �� ������,
            % �� ���� �������� ��� � �������� ������ ������ ����������
                if ~isFindEndOfParams
                    if ~isempty(BufParams)
                        Params{end+1} = BufParams; %#ok<AGROW>
                    end
                end

            % ������� ����
                fclose(fid);

            % ����� ���������� �� �����
                fprintf(['%s %d parameter sets are parsed from ', ...
                    'file %s.\n'], datestr(now), length(Params) - ...
                    NumParams, FileNames{k});
                fprintf('\n');
        end
        
    % ���� �� ������� ������� �� ���� ����� ����������, �� �������� ������
    % ��� ���������� �������� � ����������� �� ���������
        if isempty(Params)
            Params = cell(1);
            % ����� ���������� �� �����
                fprintf(['%s No parameters were found thus one ', ...
                    'calculation with default parameters will be ', ...
                    'performed.\n'], datestr(now));
                fprintf('\n');
        end
        
		
	% �������/�������� ��� ���������� ��� ���������� �����������
        if strcmp(NamePrefix, 'RegressionSetup')
            % ������������� ������������� ��� ���������� ��� ����������
            % �����������!
            for k = 1:length(Params)
                Params{k}.Common.SaveDirName = 'TestRegressionResults';
            end
        else
            % ���� ����������� ��� ���������� ��� ���������� �����������
            % TestRegressionResults ��� ReferenceRegressionResults, ��
            % ������� ������
            for k = 1:length(Params)
                if isfield(Params{k}, 'Common')
                if isfield(Params{k}.Common, 'SaveDirName')
                if strcmpi(Params{k}.Common.SaveDirName, ...
                        'TestRegressionResults') || ...
                        strcmpi(Params{k}.Common.SaveDirName, ...
                        'ReferenceRegressionResults')
                    error(['It is prohibited to name save directory ', ...
                        'as TestRegressionResults or ', ...
                        'ReferenceRegressionResults']);
                end
                end
                end
            end
        end

    % ������� ��� ���������� ���������� ������� ������� ���������� � path
        AddSubFolders2Path(cd);
end

function AddSubFolders2Path(CurPath)
    % ����� ������� ���:
    %   addpath(genpath(CurPath));
    % ��, ��������, � ������ ������ � ����� GitHub ��� ������� � ���������
    % �������� '.git', ��� ����� �������� � ����������� ������������!
    % ������� ������� �� � ������, ��������� �������� � ������, ��� ���
    % ����� ������ ���������� � �����.
    
    % ��������� ���������� ������� ����������
        FolderInfo = dir(CurPath);

    % ���������� �� ����� �����������, ������� ����������
    for k = 1:length(FolderInfo)
        if FolderInfo(k).isdir == 1
            if isletter(FolderInfo(k).name(1))
                NewPath = [CurPath, '\', FolderInfo(k).name];
                path(NewPath, path);
                AddSubFolders2Path(NewPath);
            end
        end
    end
end
