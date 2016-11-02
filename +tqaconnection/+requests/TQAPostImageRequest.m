classdef TQAPostImageRequest < tqaconnection.requests.TQARequest
    properties
        FileName= '';
    end %properties
    methods
        function obj = TQAPostImageRequest(varargin)
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
                status.isGood = 0;
                status.allheaders = [];
                status.firstheaders = [];
                status.url = [obj.BaseURL,obj.URLExtension];
                status.status.value = 0;
                status.status.msg = 'Missing Required Data';
                return;
            end %if
            
            if isempty(obj.FileName)
                status.isGood = 0;
                status.allheaders = [];
                status.firstheaders = [];
                status.url = [obj.BaseURL,obj.URLExtension];
                status.status.value = 0;
                status.status.msg = 'Missing Filename';
                response = [];
                return;
            end %if
                               
            %do the request
            [response,status] = obj.postIOImage();
            
            response = tqaconnection.requests.TQARequest.formatResponse(...
                response,status,formatStr);
        end
        
    end %methods
    
    methods (Access = private)
        function [response,extras] = postIOImage(obj)
            
            %adaptation of urlread2 to do multipart uploads
            headersIn = obj.getStandardHeaders();
            assert(usejava('jvm'),'Function requires Java')
            
            import com.mathworks.mlwidgets.io.InterruptibleStreamCopier;
            com.mathworks.mlwidgets.html.HTMLPrefs.setProxySettings %Proxy settings need to be set
            
            urlConnection = getURLConnection([obj.BaseURL,obj.URLExtension]);
            urlConnection.setRequestMethod('POST');
            urlConnection.setFollowRedirects(true);
            urlConnection.setReadTimeout(0);
            
            %read in the file
            f = fopen(obj.FileName);
            body = fread(f,Inf,'*uint8');
            fclose(f);
            
            if ~isempty(body)
                %Ensure vector?
                if size(body,1) > 1
                    if size(body,2) > 1
                        error('Input parameter to function: body, must be a vector')
                    else
                        body = body(:)';
                    end
                end
                
                urlConnection.setDoOutput(true);
                urlConnection.setDoOutput(true);
                boundary = '***********************';
                
                for iHeader = 1:length(headersIn)
                    curHeader = headersIn(iHeader);
                    urlConnection.setRequestProperty(curHeader.name,curHeader.value);
                end
                urlConnection.setRequestProperty( ...
                    'Content-Type',['multipart/form-data; boundary=',boundary]);
                printStream = java.io.PrintStream(urlConnection.getOutputStream);
                % also create a binary stream
                dataOutputStream = java.io.DataOutputStream(urlConnection.getOutputStream);
                eol = [char(13),char(10)];
                
                printStream.print(['--',boundary,eol]);
                printStream.print('Content-Disposition: form-data; name="file"');
                % binary data is uploaded as an octet stream
                % Echo Nest API demands a filename in this case
                printStream.print(['; filename="',obj.FileName,'"',eol]);
                printStream.print(['Content-Type: application/octet-stream',eol]);
                printStream.print(eol);
                dataOutputStream.write(body,0,length(body));
                printStream.print(eol);
                
                printStream.print(['--',boundary,'--',eol]);
                printStream.close;
            else
                urlConnection.setRequestProperty('Content-Length','0');
            end
            
            %==========================================================================
            %                   Read the data from the connection.
            %==========================================================================
            %This should be done first because it tells us if things are ok or not
            %NOTE: If there is an error, functions below using urlConnection, notably
            %getResponseCode, will fail as well
            try
                inputStream = urlConnection.getInputStream;
                isGood = true;
            catch ME
                isGood = false;
                %NOTE: HTTP error codes will throw an error here, we'll allow those for now
                %We might also get another error in which case the inputStream will be
                %undefined, those we will throw here
                inputStream = urlConnection.getErrorStream;
                
                if isempty(inputStream)
                    msg = ME.message;
                    I = strfind(msg,char([13 10 9])); %see example by setting timeout to 1
                    %Should remove the barf of the stack, at ... at ... at ... etc
                    %Likely that this could be improved ... (generate link with full msg)
                    if ~isempty(I)
                        msg = msg(1:I(1)-1);
                    end
                    fprintf(2,'Response stream is undefined\n below is a Java Error dump (truncated):\n');
                    error(msg)
                end
            end
            
            %POPULATING HEADERS
            %--------------------------------------------------------------------------
            allHeaders = struct;
            allHeaders.Response = {char(urlConnection.getHeaderField(0))};
            done = false;
            headerIndex = 0;
            
            while ~done
                headerIndex = headerIndex + 1;
                headerValue = char(urlConnection.getHeaderField(headerIndex));
                if ~isempty(headerValue)
                    headerName = char(urlConnection.getHeaderFieldKey(headerIndex));
                    headerName = fixHeaderCasing(headerName); %NOT YET FINISHED
                    
                    %Important, for name safety all hyphens are replace with underscores
                    headerName(headerName == '-') = '_';
                    if isfield(allHeaders,headerName)
                        allHeaders.(headerName) = [allHeaders.(headerName) headerValue];
                    else
                        allHeaders.(headerName) = {headerValue};
                    end
                else
                    done = true;
                end
            end
            
            firstHeaders = struct;
            fn = fieldnames(allHeaders);
            for iHeader = 1:length(fn)
                curField = fn{iHeader};
                firstHeaders.(curField) = allHeaders.(curField){1};
            end
            
            status = struct(...
                'value',    urlConnection.getResponseCode(),...
                'msg',      char(urlConnection.getResponseMessage));
            
            %PROCESSING OF OUTPUT
            %----------------------------------------------------------
            byteArrayOutputStream = java.io.ByteArrayOutputStream;
            % This StreamCopier is unsupported and may change at any time. OH GREAT :/
            isc = InterruptibleStreamCopier.getInterruptibleStreamCopier;
            isc.copyStream(inputStream,byteArrayOutputStream);
            inputStream.close;
            byteArrayOutputStream.close;
            

            charset = '';
            
            %Extraction of character set from Content-Type header if possible
            if isfield(firstHeaders,'Content_Type')
                text = firstHeaders.Content_Type;
                %Always open to regexp improvements
                charset = regexp(text,'(?<=charset=)[^\s]*','match','once');
            end
            
            if ~isempty(charset)
                response = native2unicode(typecast(byteArrayOutputStream.toByteArray','uint8'),charset);
            else
                response = char(typecast(byteArrayOutputStream.toByteArray','uint8'));
            end

            
            extras              = struct;
            extras.allHeaders   = allHeaders;
            extras.firstHeaders = firstHeaders;
            extras.status       = status;
            %Gets eventual url even with redirection
            extras.url          = char(urlConnection.getURL);
            extras.isGood       = isGood;
            
            function headerNameOut = fixHeaderCasing(headerName)
                %fixHeaderCasing Forces standard casing of headers
                %
                %   headerNameOut = fixHeaderCasing(headerName)
                %
                %   This is important for field access in a structure which
                %   is case sensitive
                %
                %   Not yet finished.
                %   I've been adding to this function as problems come along
                
                switch lower(headerName)
                    case 'location'
                        headerNameOut = 'Location';
                    case 'content_type'
                        headerNameOut = 'Content_Type';
                    otherwise
                        headerNameOut = headerName;
                end
            end
            
            function urlConnection = getURLConnection(urlChar)
                %getURLConnection
                %
                %   urlConnection = getURLConnection(urlChar)
                
                % Determine the protocol (before the ":").
                protocol = urlChar(1:find(urlChar==':',1)-1);
                
                
                % Try to use the native handler, not the ice.* classes.
                try
                    switch protocol
                        case 'http'
                            %http://www.docjar.com/docs/api/sun/net/www/protocol/http/HttpURLConnection.html
                            handler = sun.net.www.protocol.http.Handler;
                        case 'https'
                            handler = sun.net.www.protocol.https.Handler;
                    end
                catch ME
                    disp(ME.message);
                    handler = [];
                end
                
                % Create the URL object.
                try
                    if isempty(handler)
                        url = java.net.URL(urlChar);
                    else
                        url = java.net.URL([],urlChar,handler);
                    end
                catch ME
                    error('Failure to parse URL or protocol not supported for:\nURL: %s',urlChar);
                end
                
                % Get the proxy information using MathWorks facilities for unified proxy
                % preference settings.
                mwtcp = com.mathworks.net.transport.MWTransportClientPropertiesFactory.create();
                proxy = mwtcp.getProxy();
                
                % Open a connection to the URL.
                if isempty(proxy)
                    urlConnection = url.openConnection;
                else
                    urlConnection = url.openConnection(proxy);
                end
                
                
            end
        end %postIOImage
    end %privatre methods
end %TQAPostRequest