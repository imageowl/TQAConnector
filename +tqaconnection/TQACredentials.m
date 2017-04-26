classdef TQACredentials < matlab.mixin.SetGet
    %TQACREDENTIALS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ClientID = '';
        APIKey = '';
    end
    
    properties (Dependent)
        BaseURL;
        OauthURL;
    end %dependent 
    
    properties (Dependent, GetAccess = public, SetAccess = protected)
        AccessToken;
        Duration;
        ExpirationTime;
    end 
    
    properties(Dependent, Access = protected)
        WebOptions;
    end %protected , dependent properties
    
    properties (Access = protected)
        GrantType = 'client_credentials';
        WebOptionParam = {'MediaType','application/json',...
                          'RequestMethod','post'} ;
        ExpirationMargin = 0.1;
    end %protectedProperties
    
    properties(Access = private)
        AccessToken_ = '';
        Duration_ = [];
        TokenType_ = '';
        ExpirationTime_ = [];
        BaseURL_ = '';
        OauthURL_ = '/oauth';
    end %
    
    properties (Dependent, SetAccess = private)
        HasValidFormat;
    end %dependent methods
    
    methods
        function obj = TQACredentials(varargin)
            if ~isempty(varargin) 
                set(obj,varargin{:});
            end %if
        end %TQACredentials
        
        function set.ClientID(obj,val)
            validateattributes(val,{'char'},{'row'});
            obj.ClientID = val;
        end %setClientID
        
        function set.APIKey(obj,val)
            if isempty(val)
                obj.APIKey = '';
            else
                validateattributes(val,{'char'},{'row','numel',64});
                obj.APIKey = val;
            end %if
        end %setAPIKey
        
        function val = get.BaseURL(obj)
            val = obj.BaseURL_;
        end %getBaseURL
        
        function set.BaseURL(obj,val)
            if isempty(val)
                obj.BaseURL_ = '';
                obj.getAccessToken();
                return;
            end 
            validateattributes(val,{'char'},{'row'});
            if ~isequal(val, obj.BaseURL)
                obj.BaseURL_ = val;
                obj.getAccessToken();
            end %if
        end %setBaseURL
        
        function val = get.OauthURL(obj)
            val = obj.OauthURL_;
        end %getOauthURL
        
        function set.OauthURL(obj,val)
            if isempty(val)
                obj.OauthURL_ = '';
                obj.getAccessToken();
                return;
            end 
            validateattributes(val,{'char'},{'row'});
            if ~isequal(val, obj.OauthURL)
                obj.OauthURL_ = val;
                obj.getAccessToken();
            end %if           
        end %setOauthURL
        
        function val = get.AccessToken(obj)
            obj.checkAccessToken();
            if ~isempty(obj.AccessToken_)
                val = [obj.TokenType_,' ',obj.AccessToken_];   
            else
                val = '';
            end %if
        end %getAccessToken
        
        function val = get.Duration(obj)
            obj.checkAccessToken();
            val = obj.Duration_;           
        end %GetDuration
        
        function val = get.ExpirationTime(obj)
            obj.checkAccessToken();
            val = obj.ExpirationTime_;
        end %getExpirationTime
        
           
        function val = get.WebOptions(obj)
            val = weboptions(obj.WebOptionParam{:});
        end %getWebOptions
        
        function jsonStr = writeToJSON(obj,jsonFile)
            if nargin > 1
                opt.FileName = jsonFile;
            else
                opt = struct([]);
            end %if
            
            jsonStr = savejson('TQACredentials',obj.toStruct(),opt);
        end %
        
        function credentialStruct = toStruct(obj,encodeKey)
            if nargin == 1
                encodeKey = true;
            end %if
            credentialStruct.ClientID = obj.ClientID;
            if encodeKey
                credentialStruct.APIKey = obj.encodeKey;
            else
                credentialStruct.APIKey = obj.APIKey;
            end %if
            credentialStruct.BaseURL = obj.BaseURL;
            credentialStruct.OauthURL = obj.OauthURL;
        end %toStruct
        
        function val = get.HasValidFormat(obj)
            %no guarantee they are good but at least right format
            if ~isempty(obj.APIKey) && ~isempty(obj.ClientID)...
                    && ~isempty(obj.BaseURL) && ~isempty(obj.OauthURL)
                val = true;
            else
                val = false;
            end %if
        end %get.hasValidFormat
    end %methods
    
    methods(Access = protected)
        function checkAccessToken(obj)
            %do we have one 
            if isempty(obj.AccessToken_) %try to get it.
                obj.getAccessToken();
            end %if
            
            %are we close to expiration
            try
                closeTime = obj.ExpirationTime_...
                    -seconds((1-obj.ExpirationMargin)*obj.Duration_);
                if datetime('now') > closeTime
                    obj.getAccessToken();
                end %
            catch
                obj.AccessToken_ = '';
                obj.Duration_ = [];
                obj.TokenType_ = '';
                obj.ExpirationTime_ = [];
            end %catch
        end 
        
        function getAccessToken(obj)
            if ~obj.HasValidFormat
                obj.AccessToken_ = '';
                obj.Duration_ = [];
                obj.TokenType_ = '';
                obj.ExpirationTime_ = [];
                return;
            end %if
            
            %ok we should have info lets try it
            try
                r.client_id = obj.ClientID;
                r.client_secret = obj.APIKey;
                r.grant_type = obj.GrantType;
                tokenRequestResponse = ...
                    webwrite([obj.BaseURL,obj.OauthURL],r,obj.WebOptions);
                obj.AccessToken_ = tokenRequestResponse.access_token;
                obj.Duration_ = tokenRequestResponse.expires_in;
                obj.TokenType_ = tokenRequestResponse.token_type;
                obj.ExpirationTime_ = datetime('now')+seconds(obj.Duration_);
                
            catch accessErr
                disp(accessErr.message);
                obj.AccessToken_ = '';
                obj.Duration_ = [];
                obj.TokenType_ = '';
                obj.ExpirationTime_ = [];
            end %catch
            
        end %getAccessToken
    end %protected Methods
    
   methods (Access = private)
       function encodedKey = encodeKey(obj)
           import org.apache.commons.codec.binary.Base64;
           keyString = java.lang.String(obj.APIKey);
           encodedBytes = Base64.encodeBase64(keyString.getBytes());
           encodedKey = char(java.lang.String(encodedBytes));
       end %encodeKey
  
   end %private methods
    
    
    methods(Static)
        
        function decodedKey = decodeKey(encodedKey)
            import org.apache.commons.codec.binary.Base64;
            encodedKeyString = java.lang.String(encodedKey);
            encodedBytes = encodedKeyString.getBytes();
            decodedBytes =  Base64.decodeBase64(encodedBytes);
            decodedKey = char(java.lang.String(decodedBytes));
        end %decodeKey
        
        function credentials = loadFromStruct(s,isEncoded)
            if nargin == 1
                isEncoded = true;
            end %if
            credentials = tqaconnection.TQACredentials();
            if isfield(s,'ClientID')
                credentials.ClientID = s.ClientID;
            end %if
            
            if isfield(s,'APIKey')
                if isEncoded
                    credentials.APIKey =...
                        tqaconnection.TQACredentials.decodeKey(s.APIKey);
                else
                    credentials.APIKey = s.APIKey;
                end %if
            end %if
            
            if isfield(s,'BaseURL')
                credentials.BaseURL = s.BaseURL;
            end %if
            
            if isfield(s,'OauthURL')
                credentials.OauthURL= s.OauthURL;
            end %if
        end %load from struct
        
        function credentials = loadJSON(json)
            if ~ischar(json)
                error('TQACredentials:InvalidJSON',...
                    'The JSON string passed must be a string of JSON data or a valid file name of a json file');
            end %if   
            
            credentialsStruct = loadjson(json);
            if ~isfield(credentialsStruct,'TQACredentials')
                error('TQACredentials:JSONHasNoCredentials',...
                    'No credential data could be found in the JSON data');
            end %if            
            credentials = tqaconnection.TQACredentials.loadFromStruct...
                (credentialsStruct.TQACredentials);
        end %loadJSOn
    end %static methods
end

