classdef TQAPatchRequest < tqaconnection.requests.TQARequest
    %TQAPatchRequest Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)       
        JAVA_DEPENDENCIES = {'okio-1.11.0.jar','okhttp-3.4.2.jar'};   %Java JAR files that must be on the path for this claa    
    end
    
    properties
        PostData = [];
    end 
    
    methods
        
        function obj = TQAPatchRequest(varargin)
            obj.addJavaDependencies();
            obj.RequestMethod = 'patch';
            if ~isempty(varargin)
                set(obj,varargin{:});
            end %if
            
        end %TQAPatchRequest
        
        function  [response,status] = execute(obj,format)
            if nargin == 1
                format = 'struct';
            end %if
            
            formatStr = obj.validateFormat(format);
            
            %prepare post data to be a char row vector json string
            if isempty(obj.PostData)
                postData = [];
            elseif isstruct(obj.PostData)
                opt.Compact = 1; %urlread2 can only take vector data
                postData = savejson('',obj.PostData,opt);
            elseif ischar(obj.PostData)
                %assume its JSON
                %we need to make sure its just a vector- no line returns etc
                s = loadjson(obj.PostData);
                opt.Compact = 1;
                postData = savejson('',s,opt);
            end %if      
                     
            if ~isempty(postData)
                mediaType = okhttp3.MediaType.parse('application/json');
                body = okhttp3.RequestBody.create(mediaType,postData);
            else
                mediaType = okhttp3.MediaType.parse('application/json');
                body = okhttp3.RequestBody.create(mediaType,'{}');
            end %if
            
            %create the client
            client = okhttp3.OkHttpClient();
            
            %build the request
            rb = javaObject('okhttp3.Request$Builder');
            
            %...URL
            rb.url([obj.BaseURL,obj.URLExtension]);
            
            %...Setup the body
                rb.patch(body);
            
            %...setup the headers
            headers = obj.getStandardHeaders();
            for n = 1:numel(headers)
                rb.addHeader(headers(n).name,headers(n).value);               
            end %for
            
            %...get the request object
            request= rb.build();
            
            %use the client to execute the request
            okResp =client.newCall(request).execute();
            
            %build the expected status struct
            status.status.value = okResp.code;
            status.status.msg = char(okResp.message);
            status.isGood = okResp.isSuccessful;
            status.url = char(okResp.request.url.toString());
            
            %format the output
          
            response = tqaconnection.requests.TQARequest.formatResponse(...
                char(okResp.body().string()),status,formatStr);
        end %execute
    end
    
    methods(Access = private)
        function addJavaDependencies(obj)
            %in a compiled setting the the jar files would be added to the
            %build script and will automatically be on the class path.
            %There is no harm in repeatedly calling this within MATLAB as
            %ML is smart enough to see if it is already there.
            if ~isdeployed
                for d = 1:numel(obj.JAVA_DEPENDENCIES)
                    %avoid some ugly warnings when java objects exist
                    if ~any(cell2mat(strfind(javaclasspath('-all'),obj.JAVA_DEPENDENCIES{d})))
                        javaaddpath(which(obj.JAVA_DEPENDENCIES{d}));
                    end %if
                end %for
            end %if
        end %addJavaDependencies
    end %private methods
    
end

