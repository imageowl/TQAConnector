r.client_id = 'your id';
r.client_secret = 'your key';
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
