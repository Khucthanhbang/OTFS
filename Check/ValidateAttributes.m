function ValidateAttributes(inp1, inp2, inp3, inp4, inp5, inp6)
%
% ��� ������� ����� ��� ����, ����� � ������ ��������� ������ ��� ��������
% �������� ����������, ����� ����������� ��������� � ���������� �� ������
% ���������� ������� DeleteObjects()

if nargin == 0
    inp1 = [];
end
if nargin <= 1
    inp2 = [];
end
if nargin <= 2
    inp3 = [];
end
if nargin <= 3
    inp4 = [];
end
if nargin <= 4
    inp5 = [];
end
if nargin <= 5
    inp6 = [];
end

try
    validateattributes(inp1, inp2, inp3, inp4, inp5, inp6);
catch ME
    DeleteObjects();
    rethrow(ME)
end