classdef Proxy < matlab.mixin.SetGet
    %PROXY Sores proxy server data for use with okhttp
    %   Detailed explanation goes here
    
    properties
        ProxyServer = '';
        ProxyPort = 80;
        ProxyMethod = 'HTTP';
    end %properties
    
    methods
        function obj = Proxy(varargin)
            if ~isempty(varargin)
                set(obj,varargin{:});
            end %if
        end %Proxy
        
        function set.ProxyServer(obj,val)
            validateattributes(val,{'char'},{'row'});
            obj.ProxyServer = val;
        end %setProxyServer
        
        function set.ProxyPort(obj,val)
            validateattributes(val,{'numeric'},{'positive','integer','scalar'});
            obj.ProxyPort = val;
        end %set.ProxyPort
        
        function set.ProxyMethod(obj,val)
            val = validatestring(val,{'DIRECT','HTTP','SOCKS'});
            obj.ProxyMethod = val;
        end %setProxyMethod
        
        function javaProxy = getJavaProxy(obj)
            import java.net.*;
            socket = java.net.InetSocketAddress(...
                obj.ProxyServer,obj.ProxyPort);
            
            proxyMethod = javaMethod('valueOf','java.net.Proxy$Type',...
                obj.ProxyMethod); 
            
           javaProxy = java.net.Proxy(proxyMethod,socket); 

        end %getJavaProxy
            
        
    end
    
end

