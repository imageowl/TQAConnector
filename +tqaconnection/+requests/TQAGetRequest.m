classdef TQAGetRequest < tqaconnection.requests.TQARequest
    %TQAGetRequest Summary of this class goes here
    %   Detailed explanation goes here
    
    properties 
        UseOKHTTP = false;
        UseProxy = false;
        Proxy = [];
    end %Hidden properties
    
    properties (Constant)
        JAVA_DEPENDENCIES = {'okio-1.11.0.jar','okhttp-3.4.2.jar'};   %Java JAR files that must be on the path for this claa
    end
      
    methods 
        function obj = TQAGetRequest(varargin)
            obj.RequestMethod = 'get';
            if ~isempty(varargin)
                set(obj,varargin{:});
            end %if
        end %TQAGetRequest
        
        function set.UseOKHTTP(obj,val)
            validateattributes(val,{'logical'},{'scalar'});
            obj.UseOKHTTP = val;
            if val
                obj.addJavaDependencies();
            end %if
        end %
        
        function set.UseProxy(obj,val)
            validateattributes(val,{'logical'},{'scalar'});
            obj.UseProxy = val;
        end %set.UseProxy
        
        function set.Proxy(obj,val)
            if isempty(val)
                obj.Proxy = [];
                return;
            end %if
            validateattributes(val,{'tqaconnection.requests.Proxy'},{});
            obj.Proxy = val;
        end %set.UseProxy        
        
        function [response,status] = execute(obj,format)
            if nargin == 1
                format = 'struct';
            end %if
            
            formatStr = obj.validateFormat(format);
            
            if ~obj.isQueryExecutable()               
                response = [];
                return;
            end %if
            
            %get the standard headers
            headers = obj.getStandardHeaders();
            
            if obj.UseOKHTTP %use the okhttp java library
                %create the client
                cb = javaObject('okhttp3.OkHttpClient$Builder');
                if obj.UseProxy
                    if ~isempty(obj.Proxy)
                        cb.proxy(obj.Proxy.getJavaProxy());
                    else
                        error('TQAPatchRequest:EmptyProxy',...
                            'The Use Proxy attribute is set to true but the Proxy is empty');
                    end %if
                end %if
                client = cb.build();
 
                %build the request
                rb = javaObject('okhttp3.Request$Builder');
                
                %...URL
                rb.url([obj.BaseURL,obj.URLExtension]);
                
                rb.get();
                
                for n = 1:numel(headers)
                    rb.addHeader(headers(n).name,headers(n).value);
                end %for
                
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
            else
            
                [response,status] = obj.doRequest(...
                    [obj.BaseURL,obj.URLExtension],...
                    '',headers);
                
                response = tqaconnection.requests.TQARequest.formatResponse(...
                    response,status,formatStr);
            end %if

        end %execute
    end %methods
    
    
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
    
end %TQAGetRequest

