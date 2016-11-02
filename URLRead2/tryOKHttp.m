BASE_URL = 'http://tqadev.imageowl.com/api/rest';


tqaCred = tqaconnection.TQACredentials(...
    'ClientID','141:API_Test',...
    'APIKey','7d5974d5060db868fca98482617355ec782ff323adf9fdd1387467d566a205ea',...
    'BaseURL',BASE_URL);


javaaddpath('okio-1.10.0.jar')
javaaddpath('okhttp-3.4.1.jar')
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.Response;
client = OkHttpClient();
rb = javaObject('okhttp3.Request$Builder');
rb.url([BASE_URL,'/schedules']);
rb.get();
rb.addHeader('authorization', tqaCred.AccessToken);
rb.addHeader('content-type', 'application/json');
rb.addHeader('accept', 'application/json')
request= rb.build();

response = client.newCall(request).execute();