classdef TQARequest < matlab.mixin.SetGet
    %TQAREQUEST Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Credentials = [];
        BaseURL = '';
        URLExtension = '';
        Accept = 'application/json';
    end
    
    properties (Access = protected)
        RequestMethod = '';
        ContentType = 'application/json';
        ValidFormats = {'struct','json','table'};
    end % protected properties
        
    
    methods (Abstract)
        [response,status] = execute(obj,format);        
    end %abstract nethods
    
    
    methods
        function obj = TQARequest(varargin)
            if ~isempty(varargin)
                set(obj,varargin{:});
            end %if
        end %TQARequest
        
        function set.Credentials(obj,val)
            if isempty(val)
                obj.Credentials = [];
            else
                validateattributes(val,{'tqaconnection.TQACredentials'},...
                    {'scalar'});
                obj.Credentials = val;
            end %if            
            
        end %setCredentials
        
        function set.BaseURL(obj,val)
            validateattributes(val,{'char'},{'row'});
            obj.BaseURL = val;
        end %setBaseURL     
        
        function set.URLExtension(obj,val)
            validateattributes(val,{'char'},{'row'});
            obj.URLExtension = val;
        end %setURLExtension
        
        function set.Accept(obj,val)
            validateattributes(val,{'char'},{'row'});
            obj.Accept = val;            
        end %setAccept
        
        function set.RequestMethod(obj,val)
            validateattributes(val,{'char'},{'row'});
            obj.RequestMethod = val;
        end %setRequestMethod
        
        function set.ContentType(obj,val)
            validateattributes(val,{'char'},{'row'});
            obj.ContentType = val;
        end %setContentType
        
    end %methods
    
    methods (Access = protected)
        function executableQuery =isQueryExecutable(obj)
            executableQuery = true;
            %check credentials
            if isempty(obj.Credentials)
                warning('RQAGetRequest:EmptyCredentials',...
                    'Credentials are empty. Query cannot be executed');
                executableQuery = false;
                return;
            end %if
            
            %check access
            if isempty(obj.Credentials.AccessToken)
                warning('RQAGetRequest:EmptyAccessToken',...
                    'Access Token is empty. Query cannot be executed');
                executableQuery = false;   
                return;
            end %if
            
            %check base URL
            if isempty(obj.BaseURL)
                warning('RQAGetRequest:EmptyBaseURL',...
                    'BaseURL is empty. Query cannot be executed');
                executableQuery = false;   
                return;
            end %if
            
            %check extension
            if isempty(obj.URLExtension)
                warning('RQAGetRequest:EmptyURLExtension',...
                    'URLExtension is empty. Query cannot be executed');
                executableQuery = false;   
                return;
            end %if             
        end %isQueryExecutable
        
        function headers = getStandardHeaders(obj)
            headers(1).name = 'Authorization';
            headers(1).value = obj.Credentials.AccessToken;
            headers(2).name = 'Content-Type';
            headers(2).value = obj.ContentType;
            headers(3).name = 'Accept';
            headers(3).value = obj.Accept;
        end %getStandardHeaders
        
        function formatStr = validateFormat(obj,format)
            formatStr = validatestring(format,obj.ValidFormats);
        end %validateFormat
            
        
        function [response,status] = doRequest(obj,url,data,headers)
            try
                [response,status] = urlread2(...
                    url,...
                    upper(obj.RequestMethod),...
                    data,...
                    headers);
            catch getError
                disp(getError.message)
                response = [];
                status = getError.message;
                return;
                
            end %catch
        end %doRequest
    end % prptected
    
    methods(Static)
        function response = formatResponse(response,status,formatStr)
            if isempty(response)
                s = struct([]);
            else
                if ischar(response)
                    opt.SimplifyCell = 1;
                    s = loadjson(response,opt);
                elseif isstruct(response)
                    s = response;
                end %if
            end %if
            switch formatStr
                case 'struct'
                    response = s;
                    return;
                case 'json'
                    %pretty print it
                    if isempty(s)
                        response = '';
                    else
                        response = savejson('',s);
                    end %if
                case 'table'
                    %not sure if tis is best method for long run
                    if isempty(s)
                        response = table;
                        return;
                    end %if
                    
                    if status.isGood
                        fields = fieldnames(s);
                        if ~isempty(fields) &&  isscalar(s) && isstruct(s.(fields{1}))
                            structForTable = ...
                                checkAndReplaceKeywordStructureFields(...
                                s.(fields{1}));
                            response = struct2table(structForTable,...
                                'AsArray',true);
                        else
                            s = checkAndReplaceKeywordStructureFields(s);
                            response = struct2table(s,...
                                'AsArray',true);
                        end %if
                    else
                        s = checkAndReplaceKeywordStructureFields(s);
                        response = struct2table(s,...
                            'AsArray',true);
                    end %if
            end %switch
            
            
            function sOut = checkAndReplaceKeywordStructureFields(s)
                sOut = s;
                fNames = fieldnames(s);
                for f = 1:numel(fNames)
                    if iskeyword(fNames{f})
                        sOut.([fNames{f},'_']) = sOut.(fNames{f});
                        sOut = rmfield(sOut,fNames{f});
                    end %if
                end %for
            end %for
        end %formatResponse
    end %end static methods
end

