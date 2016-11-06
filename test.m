r.client_id = '202:OSU API Test';
r.client_secret = 'f05ce749579e354046d3fcb5d271a600e7ba7afa29762787842806ac87fca131';
r.grant_type = 'client_credentials';
%...display the body
disp(savejson('',r));

%...make the request
options = weboptions('MediaType','application/json','RequestMethod','post');
tokenRequestResponse = webwrite('http://tqa.imageowl.com/api/rest/oauth',r,options);
%display the authorization
disp(savejson('',tokenRequestResponse));

%% setup the options to do the various gets
options = weboptions('RequestMethod','get',...
    'ContentType','json',...
    'KeyName','Authorization',...
    'KeyValue',['Bearer ',tokenRequestResponse.access_token]);

%% get the users
users = webread(...
    'http://tqa.imageowl.com/api/rest/users',...
    'Accept','application/json',...
    options);

disp(savejson('',users));