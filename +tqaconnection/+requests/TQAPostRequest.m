classdef TQAPostRequest < tqaconnection.requests.TQARequest
    properties 
        PostData = [];
    end %properties
    methods
        function obj = TQAPostRequest(varargin)
            obj.RequestMethod = 'post';
            if ~isempty(varargin)
                set(obj,varargin{:});
            end %if
        end %TQAPostRequest
        
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
            
            %do the request
            [response,status] = obj.doRequest(...
                [obj.BaseURL,obj.URLExtension],...
                postData,headers);
            
            response = tqaconnection.requests.TQARequest.formatResponse(...
                response,status,formatStr);
       end
       
    end %methods
end %TQAPostRequest