# TQAConnector
##Matlab Wrapper for Total QA REST API##

The TQAConnection provides methods for each of the REST API calls to the Total QA service
Several external libraries need to be installed and available on the MATLAB path
*[JSONLab-encoding/decoding JSON](https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files?s_tid=srchtitle)
*[urlread2-improved web reading over built in matlab functionality](https://www.mathworks.com/matlabcentral/fileexchange/35693-urlread2)
*[OkHttp-to handle PATCH call](http://square.github.io/okhttp) okhttp-3.4.2.jar and okio-1.11.0.jar must be on the MATLAB path
 
 **General Notes on response and status returns from te TQA service:**
 Each call returns two variables , a response and a status. The reponse contains any data being retrieved or in the case of an error any details returned from the service. The status is a structure containing information on the headers, the final formed URL, the return codes and the overall status (isGood).
The default format for the responses is a matlab structure. The response may be formatted as a JSON string or a MATLAB table by passing the P-V pair 'format',{'struct'}|'json','table

