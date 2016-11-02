url = 'http://tqa.imageowl.com/api/rest/oauth';


payload = {'client_id','180:API_Connection',...
          'client_secret','25d3ff7d8c7c805f812a09c7a5309938ff4f6c11c64cd414dc4e403bfa071411',...
          'grant_type','client_credentials'};
      
paramString = http_paramsToString(payload);      

[output,extras] = urlread2(url,'POST',paramString)
accessInfo = loadjson(output);

headers(1).name = 'Authorization';
headers(1).value = ['Bearer ',accessInfo.access_token];
headers(2).name = 'Content-Type';
headers(2).value = 'application/json';
headers(3).name = 'Accept';
headers(3).value = 'application/json';

% url = 'http://tqa.imageowl.com/api/rest/schedules';
% [schedules,extras] = urlread2(url,'GET','',headers);
% scheduleStruct = loadjson(schedules);
% 
% %ok 64000 $ ? do POST properly
data.radiationType  = 'electron';
data.energyValue = 17;
data.energyLabel= 'seventeen created during api testing';
% 
url = 'http://tqa.imageowl.com/api/rest/machine-energies';
opt.Compact = 1;
body = savejson('',data,opt);
[output,extras] = urlread2(url,'POST',body,headers)
