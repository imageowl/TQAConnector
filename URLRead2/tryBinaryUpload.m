BASE_URL = 'http://tqadev.imageowl.com/api/rest';


tqaCred = tqaconnection.TQACredentials(...
    'ClientID','141:API_Test',...
    'APIKey','7d5974d5060db868fca98482617355ec782ff323adf9fdd1387467d566a205ea',...
    'BaseURL',BASE_URL);

fname = {'Rad light 3.dcm','radLight 2.dcm'};

headers(1).name = 'Authorization';
headers(1).value = tqaCred.AccessToken;
headers(2).name = 'Accept';
headers(2).value = 'application/json';


%read the file in


URL = [BASE_URL,'/schedules/619/upload-images'];
[output1,status1] = postIOmages(URL,headers,fname{1});
[output2,status2] = postIOmages(URL,headers,fname{2});

tqa = tqaconnection.TQAConnection(...
    'BaseURL',BASE_URL,...
    'Credentials',tqaCred);

[response,status]= tqa.executeCustomGetCall('format','json','urlExtension',...
    '/schedules/619/upload-images');

[variables, varStatus] = tqa.executeCustomGetCall('format','json','urlExtension','/schedules/619/variables');