classdef TQAGetRequest < tqaconnection.requests.TQARequest
    %TQAGetRequest Summary of this class goes here
    %   Detailed explanation goes here
      
    methods 
        function obj = TQAGetRequest(varargin)
            obj.RequestMethod = 'get';
            if ~isempty(varargin)
                set(obj,varargin{:});
            end %if
        end %TQAGetRequest
        
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
            
            [response,status] = obj.doRequest(...
                [obj.BaseURL,obj.URLExtension],...
                '',headers);
            
            response = tqaconnection.requests.TQARequest.formatResponse(...
                response,status,formatStr);

        end %execute
    end %methods
    
end %TQAGetRequest

