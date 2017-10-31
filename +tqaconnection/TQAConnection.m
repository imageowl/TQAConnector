classdef TQAConnection <matlab.mixin.SetGet
    %TQACONNECTION Wrapper for the Total QA REST API 
    %  The TQAConnection provides methods for each of the REST API calls
    %  to the Total QA service
    %  Several external libraries need to be installed and available on the
    %  MATLAB path
    % <a href="matlab:
    % web('https://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files?s_tid=srchtitle')">JSONLab-encoding/decoding JSON</a>.
    % <a href="matlab:
    % web('https://www.mathworks.com/matlabcentral/fileexchange/35693-urlread2')">urlread2-improved web reading over built in matlab functionality</a>.
    % <a href="matlab:
    % web('http://square.github.io/okhttp/')">OkHttp-to handle PATCH calls</a>.
    % okhttp-3.4.1.jar and okio-1.10.0.jar must be on the MATLAB path
    %
    %General Notes on response and status returns from te TQA service:
    %Each call returns two variables , a response and a status. The reponse
    %contains any data being retrieved or in the case of an error any
    %details returned from the service. The status is a structure
    %containing information on the headers, the final formed URL, the
    %return codes and the overall status (isGood)
    %The default format for the responses is a matlab structure. The
    %response may be formatted as a JSON string or a MATLAB rable by
    %passing the P-V pair 'format',{'struct'}|'json','table'
    
  
    properties(Dependent)
        %Credentials A tqaconnection.TQACredentials object handling
        %retriving  the access token from the TQA service
        Credentials;
        %Base URL: Base url of te TQA API service.
        BaseURL;
    end %dependent properties
    
    properties(Access = private)
        Credentials_ = tqaconnection.TQACredentials();
        BaseURL_;
        GetRequest = tqaconnection.requests.TQAGetRequest();
        PostRequest = tqaconnection.requests.TQAPostRequest();
        PatchRequest = tqaconnection.requests.TQAPatchRequest();
        DeleteRequest = tqaconnection.requests.TQADeleteRequest();
        PostImageRequest = tqaconnection.requests.TQAPostImageRequest();
    end %privateproperties
    
    properties (Hidden)
        UseOKHTTP = false;
        UseProxy = false;
        Proxy = [];
    end 
    
    methods
        function obj = TQAConnection(varargin)
            if ~isempty(varargin)
                set(obj,varargin{:});
            end %if
        end %TQAConnection
        
        function set.UseOKHTTP(obj,val)
            validateattributes(val,{'logical'},{'scalar'});
            obj.UseOKHTTP = val;           
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
        
        function val = get.Credentials(obj)
            val = obj.Credentials_;
        end %getCredentials
        
        function set.Credentials(obj,val)
            validateattributes(val,{'tqaconnection.TQACredentials'},...
                {'scalar'});
            obj.Credentials_ = val;           
        end %setCredential
        
        function val = get.BaseURL(obj)
            val = obj.BaseURL_;
        end %getbaseURL
        
        function set.BaseURL(obj,val)
            validateattributes(val,{'char'},{'row'});
            obj.BaseURL_ = val;
        end %setBaseURL
               
        function [sites,status] = getSites(obj,varargin)
            %getSites Return the sites associated with the account
            format = obj.parseSiteInputArgs(varargin{:});
            urlExt = '/sites';
            [sites,status] = obj.executeGetRequest(urlExt,format);
        end %if
        
        function [response,status] = modifySiteFields(obj,siteId,varargin)
            %modifySiteFields Modifies names and comments on sites.
            %Inputs:
            %siteId: integer site id
            %Paramter Value Pairs
            %'name' : name of the site (char row vector)
            %'notes': notes associated with site (char)
            %
            [format,siteId,data] = obj.parseModifySiteInput(siteId,varargin{:});
            urlExt = ['/sites/',int2str(siteId)];
            [response,status] = obj.executePatchRequest(urlExt,data,format);
        end %modifySiteFields
        
        function [response,status] = requestNewSite(obj,varargin)
            %requestNewSite - generates a new site request to IO support
            format = obj.parseSiteMachineRequestInput(varargin{:});
            urlExt = '/sites';
            [response, status] = obj.executePostRequest(urlExt,[],format);
        end %requestNewSite        
        
        function [users,status] = getUsers(obj,varargin)
            %getUsers Return users and their info (sans PW) associated
            %with the account. To get information on a particular user pass
            %the parameter-value pair 'userId',integer with user id
            [format,userId] = obj.parseUserInputArgs(varargin{:});            
            if ~isempty(userId)
                urlExt = ['/users/',int2str(userId)];
            else             
                urlExt = '/users';
            end %if

            [users,status] = obj.executeGetRequest(urlExt,format);            
        end %getUsers
        
        function [response,status] = createNewUser(obj,varargin)
            %createNewUser  creates a new user for the account
            [format,data] = obj.parseCreateNewUserInput(varargin{:});
            urlExt = '/users';
            [response,status] =obj.executePostRequest(urlExt,data,format);
        end %createNewUser
        
        function [response,status] = modifyUserFields(obj,userId,varargin)
            %modifyUserFields modify user characteristics and role
            [format,userId,data] = obj.parseModifyUserInput(userId,varargin{:});
            urlExt = ['/users/',int2str(userId)];
            [response,status] = obj.executePatchRequest(urlExt,data,format);
        end %modifyUserFields
        
        function [machines,status] = getMachines(obj,varargin)
            %get machines list machines mayfilter by site, active,
            %deviceType.
            [format,filter] = obj.parseMachineInputArgs(varargin{:});            
            urlExt = ['/machines',filter];
            [machines,status] = obj.executeGetRequest(urlExt,format);            
        end %getMachines
        
        function [machineIdx,status] = getMachineIDFromString(obj,sMachine)
            %get the ID for a machine from its name
            [machines,status] = obj.getMachines();
            if ischar(sMachine)
                sMachine = {sMachine};
            end %if

            [inList,idx] = ismember(sMachine,{machines.machines.name});
            if all(~inList)
                    machineIdx = [];
                    status.isGood = false;
                    status.status.msg = 'Machines specified cannot be found in the account';
                    return;                
            end %if
            idx(idx==0) = 1;
            machineIdx = [machines.machines(idx).id];
            machineIdx(~inList) = NaN;
        end %getMachineIDFromString
        
        function [response,status] = requestNewMachine(obj,varargin)
            %requestNewMachine sends a new machine request to IO support
            format = obj.parseSiteMachineRequestInput(varargin{:});
            urlExt = '/machines';
            [response, status] = obj.executePostRequest(urlExt,[],format);
        end %requestNewSite
        
        function [response,status] = modifyMachineFields(obj,machineId,varargin)
             %modifyMachineFields modify machine name , notes, type
             %and status
            [format,machineId,data] = obj.parseModifyMachineInput(machineId,varargin{:});
            urlExt = ['/machines/',int2str(machineId)];
            [response,status] = obj.executePatchRequest(urlExt,data,format);
        end %modifyMachineFields        
        
        function [reports, status] = getReports(obj,varargin)
            %get Reports return reports  may filter by schedule,machine,
            %status, toleranceStatus,,deviceType, frequency
            [format,filter,verbose] = obj.parseReportInputArgs(varargin{:});
                        
            if verbose
                reportPage = 1;
                reportMsg = ['Retrieving reports page ',int2str(reportPage)];
                disp(reportMsg);
            end %if
            [reportResp,status] = obj.executeCustomGetCall('urlExtension',['/reports',filter]);
            
            %basically here we want to loop through all the pages until we
            %have no more pages 
            if isfield(reportResp,'reports') && ~isempty(reportResp.reports)
                reports = reportResp.reports;
                while isfield(reportResp,'x0x5F_metadata') && ...
                        isfield(reportResp.x0x5F_metadata,'Links') &&...
                        isfield(reportResp.x0x5F_metadata.Links,'next') &&...
                        ~isempty(reportResp.x0x5F_metadata.Links.next) &&...
                        status.isGood
                    C = strsplit(reportResp.x0x5F_metadata.Links.next,'/reports');
                    C{end} = strrep(C{end},'\u0026','&');
                    if verbose
                        reportPage = reportPage+1;
                        reportMsg = ['Retrieving reports page ',int2str(reportPage)];
                        disp(reportMsg);
                    end %if
                    [reportResp,status] = obj.executeCustomGetCall(...
                        'urlExtension',['/reports',C{end}]);
                    if isfield(reportResp,'reports') && ~isempty(reportResp.reports)
                        reports = [reports,reportResp.reports]; %#ok<AGROW>
                    end %if
                end %if  
            else
                reports = [];
            end %if
            if verbose
                disp('Finished retrieving reports');
            end %if
            reports = tqaconnection.requests.TQARequest.formatResponse(...
                reports,status,format);
            if verbose
                disp('Finished formatting reports');
            end %if
        end %getReportData
        
        function [reportData,status] = getReportData(obj,reportId,varargin)
            %getReportData returns results for a particular reportId
            [format,reportId] = obj.parseReportDataInputArgs(reportId,varargin{:});  
            urlExt = ['/report-data/',int2str(reportId)];
            
            %get the data in a struct first
            [reportData,status] = obj.executeGetRequest(urlExt,'struct');
            
            reportData = obj.postprocessReportData(reportData,status,format);

        end %getReportData
        
        function [logData,status] = getLongitudinalData(obj,scheduleId,varargin)
            [format,scheduleId,filter] = ...
                obj.parseLongitudinalDataInputArgs(scheduleId, varargin{:});

            urlExt =['/schedules/',int2str(scheduleId),'/trends',filter];
            [logData,status] = obj.executeGetRequest(urlExt,format);
            
        end %getLongitudinalData
        
        function [variableData,status] = getReportVariableData(obj,reportId,...
                variableId,varargin)
            %getReportVariableData get data for a particlar report and
            %variable.
            [format,reportId,variableId] = obj.parseReportVariableDataInputArgs(...
                reportId,variableId,varargin{:}); 
            urlExt = ['/report-data/',int2str(reportId),...
                '/variables/',int2str(variableId)];
            [variableData,status] = obj.executeGetRequest(urlExt,'struct');   
            variableData = obj.postprocessReportData(variableData,status,format);
        end %getReportVariableData
        
        function [response,status] = executeCustomGetCall(obj,varargin)
            %executeCustomGetCall execute any arbitrary GET call to the API
            [format,urlExtension] = obj.parseCustomGetInputArgs(varargin{:});
            [response,status] = obj.executeGetRequest(urlExtension,format);  
        end %executeCustomGetCall
        
        function [response,status] = executeCustomPostCall(obj,varargin)
             %executeCustomPostCall execute any arbitrary POST call to the API
            [format,urlExtension,data] = obj.parseCustomPostInputArgs(varargin{:});
            [response,status]  = obj.executePostRequest(urlExtension,data,format); 
        end %executeCustomPostCall
        
        function [response,status] = executeCustomPatchCall(obj,varargin)
             %executeCustomPatchCall execute any arbitrary PATCH call to the API
            [format,urlExtension,data] = obj.parseCustomPostInputArgs(varargin{:});
            [response,status]  = obj.executePatchRequest(urlExtension,data,format); 
        end %executeCustomPatchCall
        
        function [schedules,status] = getSchedules(obj,varargin)
            %getSchedules return schedule data
            [format,scheduleId] = obj.parseScheduleInputArgs(varargin{:});
            if ~isempty(scheduleId)
                urlExt = ['/schedules/',int2str(scheduleId)];
            else             
                urlExt = '/schedules';
            end %if
            [schedules,status] = obj.executeGetRequest(urlExt,format);
        end %getScgedules
        
        function [scheduleIdx,status] = getScheduleIDFromString(...
                obj,sSchedule,machineIdx)
            %get the ID for a schedule from its name
            
            %having a machine idx will reduce ambiguities
            if nargin == 2
                machineIdx = [];
                warning('TQAConnector:PossibleAmbiguousResults',...
                    'Not specifying a machine id may result in ambiguous results');
            end %if
            
            %...get all the schedules for the account
            [schedules,status] = obj.getSchedules();
            
            if ischar(sSchedule)
                sSchedule = {sSchedule};
            end %if
            
            %...filter to just the schedules for the selected machine
            if isempty(machineIdx)
                machineSchedules = schedules.schedules;
            else                
                machineSchedules = schedules.schedules([schedules.schedules.machineId]==machineIdx);
            end%if
            
            if isempty(machineSchedules)
                scheduleIdx = [];
                status.isGood = false;
                status.status.msg = 'The list of machines is empty';
                return;
            end %if
            
            %...and  now get the schedule we are looking for
            [inList,idx] = ismember(sSchedule,{machineSchedules.name});
            if all(~inList)
                scheduleIdx = [];
                status.isGood = false;
                status.status.msg = 'Schedules specified cannot be found in the list of schedules';
                return;
            end %if
            idx(idx==0) = 1;
            scheduleIdx = [machineSchedules(idx).id];       
            scheduleIdx(~inList) = NaN;
        end %getScheduleIDFromString
        
        function [response,status] = createSchedule(obj,machineId,templateId,...
                varargin)
            %createSchedule create a new schedule
            [format,data] = obj.parseCreateScheduleInput(machineId,templateId,...
                varargin{:});
            urlExt = '/schedules';
            [response,status] = obj.executePostRequest(urlExt,data,format);
        end %createSchedule
        
        function [templates,status] = getTemplates(obj,varargin)
            %getTemplates return template data
            [format,templateId] = obj.parseTemplateInputArgs(varargin{:});
            if ~isempty(templateId)
                urlExt = ['/templates/',int2str(templateId)];
            else             
                urlExt = '/templates';
            end %if
            [templates,status] = obj.executeGetRequest(urlExt,format);
        end %getTemplates  
        
        function [response,status] = addTemplate(obj,varargin)
            %addTemplate create a new template
            [format,data] = obj.parseAddTemplateInput(varargin{:});
            urlExt = '/templates';
            [response,status] = obj.executePostRequest(urlExt,data,format);
        end %addTemplate
        
        function [response,status] = modifyTemplate(obj,templateId,varargin)
            %modifyTemplate modify template fields
            [format,templateId,data] = obj.parseModifyTemplateInputs(...
                templateId,varargin{:});
            urlExt = ['/templates/',int2str(templateId)];
            [response,status] =obj.executePatchRequest(urlExt,data,format);
            
        end 
        
        
        function [response,status] = deleteTemplate(obj,templateId,varargin)
            %deleteTemplate delete a template
            [format,templateId] = obj.parseDeleteTemplateInputArgs(...
                templateId,varargin{:});
            urlExt = ['/templates/',int2str(templateId)];
            [response,status] = obj.executeDeleteRequest(urlExt,format);
        end %deleteTemplate
        
        function [equipment,status] = getEquipment(obj,varargin)
            %getEquipment get QA equipment information
            [format,equipmentId] = obj.parseEquipmentInputArgs(varargin{:});
            if ~isempty(equipmentId)
                urlExt = ['/equipment/',int2str(equipmentId)];
            else             
                urlExt = '/equipment';
            end %if
            [equipment,status] = obj.executeGetRequest(urlExt,format);
        end %getEquipment  
        
        function [response,queryStatus] = addEquipment(obj,name,type,status,varargin)
            %addEquipment add new QA equipment
            [format,data] = obj.parseAddEquipmentInput(name,type,status,varargin{:});
            urlExt = '/equipment';
            [response,queryStatus] = obj.executePostRequest(urlExt,data,format);
        end %addEquipment
        
        function [response,status]= modifyEquipment(obj,equipmentId,varargin)
            %modifyEquipment modify Qa equipment fields
            [format,equipmentId,data] = obj.parseModifyEquipmentInput(...
                equipmentId,varargin{:});
            urlExt = ['/equipment/',int2str(equipmentId)];
            [response,status] = obj.executePatchRequest(urlExt,data,format);
        end %modifyEquipment
        
        function [response,status] = deleteEquipment(obj,equipmentId,varargin)
            %deleteEquipment delete QA equipment fields
            [format,equipmentId] = obj.parseDeleteEquipmentInput(equipmentId,...
                varargin{:});
            urlExt = ['/equipment/',int2str(equipmentId)];
            [response,status] = obj.executeDeleteRequest(urlExt,format);
        end %deleteEqupment
        
        function [baselines,status] = getBaselinesAndTolerances(obj,scheduleId,varargin)
            %getBaselinesAndTolerances get baseline and tolerance
            %information for a schedule
            [format,scheduleId] = obj.parseBaselinesInput(scheduleId,varargin{:});         
            urlExt = ['/schedules/',int2str(scheduleId),'/tolerances'];           
            [baselines,status] = obj.executeGetRequest(urlExt,format);
        end %getBaselinesAndTolerances
        
        function [qaSettings,status] = getQASettings(obj,scheduleId,varargin)
            %getQASettings get QA settings information for a schedule
            [format,scheduleId] = obj.parseQASettingsInput(scheduleId,varargin{:});         
            urlExt = ['/schedules/',int2str(scheduleId),'/qa-settings'];           
            [qaSettings,status] = obj.executeGetRequest(urlExt,format);
        end %getBaselinesAndTolerances  
        
        function [sources,status] = getRadioactiveSources(obj,varargin)
            %getRadioactiveSources get the radioactive source information
            %for the account
            [format,sourceId] = obj.parseSourceInputArgs(varargin{:});
            if ~isempty(sourceId)
                urlExt = ['/radioactive-sources/',int2str(sourceId)];
            else             
                urlExt = '/radioactive-sources';
            end %if
            [sources,status] = obj.executeGetRequest(urlExt,format);            
        end %getRadioactiveSources
        
        function [response,status] = shipRadioactiveSource(obj,sourceId,...
                shipOutDate,varargin)
            %shipRadioactiveSource ship out a radioactive source
            [format,sourceId,shipOutDate] = obj.parseShipSourceInput(sourceId,...
                shipOutDate,varargin{:});
            urlExt = ['/ship-radioactive-sources/',int2str(sourceId)];
            data.shipOutDate = shipOutDate;
            [response,status] = obj.executePatchRequest(urlExt,data,format);
        end %shiupRadioactiveSource
        
        function [energies,status] = getMachineEnergies(obj,varargin)
            %getMachineEnergies return the machine energies in the acocunt
            format = obj.parseEnergyInputArgs(varargin{:});
            urlExt = '/machine-energies';
            [energies,status] = obj.executeGetRequest(urlExt,format);            
        end %getMachineenergies
        
        function [response,status] = setMachineEnergy(obj,varargin)
            %setMachineEnergy set new machine energy
            [format,data] = obj.parseSetMachineEnergyInput(varargin{:});
            [response,status]= obj.executePostRequest('/machine-energies',...
                data,format);
        end %setMachineEnergy
        
        function [documents,status]= getDocuments(obj,varargin)
            %geDocuments get the documents associated with the account
            [format, filter, documentId] = obj.parseDocumentInputArgs(varargin{:});
            if ~isempty(documentId)
                urlExt = ['/documents/',int2str(documentId)];
            else
                urlExt = '/documents';
            end %if
            urlExt = [urlExt,filter];
            [documents,status] = obj.executeGetRequest(urlExt,format); 
            
            %fix the links in the returns to get correct ampersand and other stuff in there
            switch format
                case 'struct'
                    if isstruct(documents) &&...
                            isfield(documents,'documents')
                        for d = 1:numel(documents.documents)
                            documents.documents(d).temporaryLink.path =...
                                strrep(documents.documents(d).temporaryLink.path,...
                                '\u0026','&');                    
                        end %for
                    end %if
                        
                case 'json'
                    documents = strrep(documents,'\u0026','&'); 
                    documents = strrep(documents,'\/','/'); 
                case 'table'
                    for r = 1:size(documents,1)
                        tempLink = documents{r,'temporaryLink'};
                        tempLink.path = strrep(tempLink.path,...
                                '\u0026','&');
                       documents{r,'temporaryLink'} = tempLink;    
                    end %for
            end 
        end %getDocuments
        
        function [calibrationFactors,status] = getCalibrationFactors(obj,equipmentId,varargin)
            %getCalibrationFactors returns the calibration factors
            %associated with a piece of QA equipment
            [format,equipmentId,machineId] = obj.parseCalibrationFactorsInput(equipmentId,varargin{:});
            urlExt = ['/equipment/',int2str(equipmentId)];
            if ~isempty(machineId)
                urlExt = [urlExt,'/machines/',int2str(machineId)];
            end %if
            urlExt = [urlExt,'/calibration-factors'];
            [calibrationFactors,status] = obj.executeGetRequest(urlExt,format);
        end %getCalibrationFactors        
                      
        function [response,status] = setUserAssignments(obj,siteId,...
                userIds,varargin)
            %setUserAssignments set user assignments for a site
            [format,siteId,data] = obj.parseUserAssigmentInputs(siteId,...
                userIds,varargin{:});
            
            urlExt = ['/sites/',int2str(siteId)];
            [response,status]  = obj.executePatchRequest(urlExt,data,format); 
        end %setUserAssignements
        
        function [customTests,status] = getCustomTests(obj,varargin)
            %getCustomTests return the custom tests associated with the
            %account
            format = obj.parseGetCustomTestsInput(varargin{:});
            urlExt = '/custom-tests';
            [customTests,status] = obj.executeGetRequest(urlExt,format);
        end %getCustomTests
        
        function [response,status] = deactivateCustomerEnergy(obj,...
                energyId,varargin)
            %deactivateCustomerEnergy turn off an existing customer defined
            %energy
            [format,energyId] = obj.parseDeativateEnergyInput(energyId,...
                varargin{:});
            urlExt = ['/machine-energies/',int2str(energyId)];
            [response,status] = obj.executeDeleteRequest(urlExt,format);
        end %deactivateCustomerEnergy
        
        function [scheduleVariables,status] = getScheduleVariables(obj,...
                scheduleId,varargin)
            %getScheduleVariables return variable info for a schedule
            [format,scheduleId] = obj.parseScheduleVariablesInput(...
                scheduleId,varargin{:});
            urlExt = ['/schedules/',int2str(scheduleId),'/variables'];
            [scheduleVariables,status] = obj.executeGetRequest(urlExt,...
                format);
        end %getScheduleVariables
        
        function [varIdx,status] = getVariableIDFromString(obj,sVar,scheduleIdx)
            %Get the ID for schedule variable by its name
            if ischar(sVar)
                sVar = {sVar};
            end %if
            [scheduleVar,status] = obj.getScheduleVariables(scheduleIdx);
            
            if isempty(scheduleVar)
                varIdx = [];
                status.isGood = false;
                status.status.msg = 'The list of variables is empty';
                return;
            end %if
            
            [inList,idx] = ismember(sVar,{scheduleVar.variables.name});
            if all(~inList)
                varIdx = [];
                status.isGood = false;
                status.status.msg = 'Variables specified cannot be found in the schedule';
                return;
            end %if
            
           idx(idx==0) = 1;
           varIdx = [scheduleVar.variables(idx).id];       
           varIdx(~inList) = NaN;
                       
        end %getVariableIDFromString
        
        
        function [response,status] =uploadTestResults(obj,scheduleId,...
                variableData,varargin)
            %uploadTestResults upload test results to a schedule
            [format,scheduleId,outputData] =obj.parseUploadSimpleDataInput(...
                scheduleId,variableData,varargin{:});
            
            urlExt = ['/schedules/',int2str(scheduleId),'/add-results'];
            opt.SingletCell = 1;
            jsonData = savejson('',outputData,opt);
            [response,status] = obj.executePostRequest(urlExt,jsonData,format);
        end %uploadTestResults
        
        function [response,status] =finalizeReport(obj,scheduleId,varargin)
            %finalizeReport finalize an in progress report
            [format,scheduleId] = obj.parseFinalizeReportInputs(scheduleId,...
                varargin{:});
            
            urlExt = ['/schedules/',int2str(scheduleId),'/finalize-results'];
            [response,status] = obj.executePostRequest(urlExt,[],format);
        end %finalize report
        
        function [uploadSet,uploadStatus] = getUploadImageSetStatus(obj,...
                scheduleId,varargin)
            %getUploadImageSetStatus get the status of any uploaded images
            [format,scheduleId] = obj.parseFinalizeReportInputs(scheduleId,...
                varargin{:});
            urlExt = ['/schedules/',int2str(scheduleId),'/upload-images'];
            [uploadSet,uploadStatus]  = obj.executeGetRequest(...
                urlExt,format);            
        end %getUploadImageSetStatus
        
        function [response,status] = startImageProcessing(obj,scheduleId,varargin)
            %startImageProcessing start the image processing on uploaded
            %images
            [format,scheduleId] = obj.parseFinalizeReportInputs(scheduleId,...
                varargin{:});
            
            urlExt = ['/schedules/',int2str(scheduleId),'/start-processing'];
            [response,status] = obj.executePostRequest(urlExt,[],format);            
        end %startImageProcessing
        
        function [response,status] = getUploadImageStatus(obj,scheduleId,varargin)
            %getUploadImageStatus  Note that once schedules are finalized
            %it appears that the upload images cannot be accessed even if
            %they are still processing.
            [format,scheduleId] = obj.parseGetUploadStatusInputs(...
                scheduleId,varargin{:});
            urlExt = ['/schedules/',int2str(scheduleId),'/upload-images'];
            [response,status] = obj.executeGetRequest(urlExt,format); 
        end %getUploadScheduleStatus
        
        function [response,status] = uploadImages(obj,scheduleId,fileList,...
                varargin)
            %uploadImages upload images for image processing
            [format,scheduleId,fileList,startProcessing,finalizeQA,...
                verbose] = obj.parseUploadImage(scheduleId,fileList,...
                varargin{:});
            urlExt = ['/schedules/',int2str(scheduleId),'/upload-images'];
            response = cell(1,numel(fileList));
            status = cell(1,numel(fileList));
            for f = 1:numel(fileList)
                if verbose
                    disp(['Uploading: ',fileList{f}]);
                end %if
                [response{f},status{f}] = obj.executePostImageRequest(urlExt,...
                    fileList{f},format); 
            end %for
            
            %confirm that the image set is up.
            [response{end+1},status{end+1}] = obj.getUploadImageSetStatus(...
                scheduleId,'format','struct');

            
            if startProcessing
                if verbose
                    disp('Starting Processing...');
                end %if
                [response{end+1},status{end+1}] = obj.startImageProcessing(scheduleId,...
                    'format',format);
            end %if
            
            if finalizeQA
                if verbose
                    disp('Finalizing QA...');
                end %if
                [response{end+1},status{end+1}] =obj.finalizeReport(...
                    scheduleId,'format',format);
            end %if
                        
        end 
        
        function [tests,status] = getTests(obj,varargin)
            %getTests listing of measurements in database
            format= obj.parseGetTestsInput(varargin{:});
            urlExt = '/tests';
            [tests,status] = obj.executeGetRequest(urlExt,format);
        end %getTests
        
        function [response,status] = createCustomGroup(obj,varargin)
            %createCustomGroup create a new custom group
            [format,group] = obj.parseAddCustomGroupInput(varargin{:});
            
            data = savejson(group);
            urlExt = '/custom-tests';
            [response,status] = obj.executePostRequest(urlExt,data,format);
        end %createCustomGroup
        
        function [response,status] = createCustomSectionGroup(obj,groupId,varargin)
            %createCustomSectionGroup create a new custom section group
            [format,data] = obj.parseAddCustomSectionGroupInput(groupId,varargin{:});
            urlExt = '/custom-tests';
            [response,status] = obj.executePostRequest(urlExt,data,format);
        end %createCustomSectionGroup
        
        function[response,status] = createCustomTest(obj,sectionGroupId,...
                varargin)
            %createCustomTest create a custom test
            [format,data] = obj.parseAddCustomTestInput(sectionGroupId,...
                varargin{:});
            urlExt = '/custom-tests';
            [response,status] = obj.executePostRequest(urlExt,data,format);
        end %createCustomTest
        
        function [response,status] = createCustomTestMetaData(obj,testId,...
                metaItems,varargin)
            %createCustomTestMetaData create metadata fields for a custom
            %test
            [format,data] = obj.parseAddMetaItemsInput(testId,metaItems,...
                varargin{:});
            %data = savejson(data);
            urlExt = '/custom-tests';
            [response,status] = obj.executePostRequest(urlExt,data,format);            
        end %createCustomTestMetaData
        
        function [response,status] = createCompleteCustomTest(obj,...
                customTestData,varargin)
            %createCompleteCustomTest create a new group, sectiongroup and
            %test
            [format,data]= obj.parseAddCompleteCustomTestInput(customTestData,...
                varargin{:});
            
            urlExt = '/custom-tests';
            [response,status] = obj.executePostRequest(urlExt,data,format); 
        end %   
        
        function encodedFileAttachment= encodeFileAttachmentForUpload(~,fileName,variableId)
            import java.io.File;
            javaFile = java.io.File(java.lang.String(fileName));
            
            import java.nio.file.Files;
            import java.nio.file.Path;
            import java.nio.file.Paths;
            source = java.nio.file.Paths.get(javaFile.toURI());
            type = char(Files.probeContentType(source));
            
            encodedFileAttachment.id = variableId;
            encodedFileAttachment.filename = fileName;
            
            %read in the file and encode as base 64
            fid = fopen(fileName);
            bytes = fread(fid,'int8=>int8');
            fclose(fid);
            
            import org.apache.commons.codec.binary.Base64;
            encodedBytes = char(java.lang.String(Base64.encodeBase64(bytes)));
            
            encodedFileAttachment.value = ['data:',type,';base64,',encodedBytes];
            
        end %encodeFileAttachmentForUpload
    end %methods
    
    methods (Access = private)
        function [response,status] = executeGetRequest(obj,urlExt,format)
            if nargin <= 2 || isempty(format)
                format = 'struct';
            end %if
            
            %make sure we are synced
            obj.Credentials.BaseURL = obj.BaseURL;
            obj.GetRequest.BaseURL = obj.BaseURL;
            obj.GetRequest.Credentials = obj.Credentials;
            obj.GetRequest.URLExtension = urlExt;
            obj.GetRequest.UseOKHTTP = obj.UseOKHTTP;
            obj.GetRequest.UseProxy = obj.UseProxy;
            obj.GetRequest.Proxy = obj.Proxy;
            [response,status] = obj.GetRequest.execute(format);
        end %executeGetRequest
        
        function [response,status] = executeDeleteRequest(obj,urlExt,format)
            if nargin <= 2 || isempty(format)
                format = 'struct';
            end %if
            
            %make sure we are synced
            obj.Credentials.BaseURL = obj.BaseURL;
            obj.DeleteRequest.BaseURL = obj.BaseURL;
            obj.DeleteRequest.Credentials = obj.Credentials;
            obj.DeleteRequest.URLExtension = urlExt;
            [response,status] = obj.DeleteRequest.execute(format);            
        end %executeDeleteRequest
        
        
        function [response,status]= executePostRequest(obj,urlExt,data,format)
            if nargin <= 3 || isempty(format)
                format = 'struct';
            end %if    
            %make sure we are synced
            obj.Credentials.BaseURL = obj.BaseURL;
            obj.PostRequest.BaseURL = obj.BaseURL;
            obj.PostRequest.Credentials = obj.Credentials;
            obj.PostRequest.URLExtension = urlExt;            
            obj.PostRequest.PostData = data;
            
            [response, status] = obj.PostRequest.execute(format);
        end %executePostRequest
        
        function [response,status] = executePostImageRequest(obj,urlExt,filename,format)
            if nargin <= 3 || isempty(format)
                format = 'struct';
            end %if    
            %make sure we are synced            
            obj.Credentials.BaseURL = obj.BaseURL;
            obj.PostImageRequest.BaseURL = obj.BaseURL;
            obj.PostImageRequest.Credentials = obj.Credentials;
            obj.PostImageRequest.URLExtension = urlExt;
            obj.PostImageRequest.FileName  = filename;
            
            [response, status] = obj.PostImageRequest.execute(format);
        end %executePostImageRequest
        
        function [response,status] = executePatchRequest(obj,urlExt,data,format)
            if nargin <= 3 || isempty(format)
                format = 'struct';
            end %if    
            %make sure we are synced
            obj.Credentials.BaseURL = obj.BaseURL;
            obj.PatchRequest.BaseURL = obj.BaseURL;
            obj.PatchRequest.Credentials = obj.Credentials;
            obj.PatchRequest.URLExtension = urlExt;            
            obj.PatchRequest.PostData = data;
            obj.PatchRequest.UseProxy = obj.UseProxy;
            obj.PatchRequest.Proxy = obj.Proxy;
            
            [response, status] = obj.PatchRequest.execute(format);            
        end %executePtachRequest
        
        function [format,filter] = parseMachineInputArgs(~,varargin)
            p = getTQAInputParser();
            p.addOptional('active',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','>=',0,'<=',1,'scalar'}));
            p.addOptional('site',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));
            p.addOptional('deviceType',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));          
            p.parse(varargin{:});
            r = p.Results;
            filter = '';
            if any(~(cellfun(@isempty,{r.active,r.site,r.deviceType},...
                    'UniformOutput',true)))
                filter = '?';
                first = true;
                if ~isempty(r.active)
                    filter = [filter,'active=',int2str(r.active)];
                    first = false;
                end %if
                
                if ~isempty(r.site)
                    if ~first
                        filter = [filter,'&'];
                    end %if
                    filter = [filter,'site=',int2str(r.site)];
                    first = false;
                end %if
                
                if ~isempty(r.deviceType)
                    if ~first
                        filter = [filter,'&'];
                    end %if
                    filter = [filter,'deviceType=',int2str(r.deviceType)];
                end %ifparseMachineInputArgs
            end %if
            format = r.format;
        end %parseMachineInputArgs
        
        function format = parseSiteInputArgs(~,varargin)
            p = getTQAInputParser();
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
        end %parseSiteInputArgs
        
        function [format,userId] = parseUserInputArgs(~,varargin)
            p = getTQAInputParser();
            p.addOptional('userId',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}))
            p.parse(varargin{:});
            
            r = p.Results;
            format = r.format;
            userId = r.userId;
        end %parseUserInputArgs
        
        function [format,reportId] = parseReportDataInputArgs(~,reportId,varargin)
            p = getTQAInputParser();
            p.addRequired('reportId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));              
            p.parse(reportId,varargin{:});
            r = p.Results;
            format = r.format;
            reportId = r.reportId;            
        end 
        
        function [format,scheduleId,filter] = ...
                parseLongitudinalDataInputArgs(~,scheduleId, varargin)
            
            p = getTQAInputParser();
            p.addRequired('scheduleId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));
            p.addOptional('variableId',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','vector'}));
            p.addOptional('dateStart','',...
                @(x)validateattributes(x,{'char'},{'row'}));
            p.addOptional('dateEnd','',...
                @(x)validateattributes(x,{'char'},{'row'}));            
            p.addOptional('dateFormat','',...
                @(x)validateattributes(x,{'char'},{'row'}));
            
            p.parse(scheduleId,varargin{:});
            r = p.Results;
            
            filterFields = {r.variableId,r.dateStart,r.dateEnd,...
                    r.dateFormat};

            if any(~(cellfun(@isempty,filterFields,...
                    'UniformOutput',true)))
                filter = '?';
                
                if ~isempty(r.variableId)
                    filter = [filter,'variables=',sprintf('%i,',r.variableId)];
                    filter= filter(1:end-1); %take off the trailing comma
                end %if
                
                if ~isempty(r.dateStart)
                    if numel(filter) > 1
                        filter(end+1) = '&';
                    end %if
                    
                    dStart = getDateTimeFromString(r.dateStart,r.dateFormat);
                    filter = [filter,'dateFrom=',char(dStart)];
                end %if
                
                if ~isempty(r.dateEnd)
                    if numel(filter) > 1
                        filter(end+1) = '&';
                    end %if
                    
                    dEnd = getDateTimeFromString(r.dateEnd,r.dateFormat);
                    filter = [filter,'dateTo=',char(dEnd)];
                end %if
                                
            else 
                filter = '';
                   
            end %if
            
            format = r.format;
            scheduleId = r.scheduleId;
                                
            function dt = getDateTimeFromString(dtStr,dateFormat)
                if isempty(dtStr)
                    dt = [];
                    return;
                end %if
                
                if isempty(dateFormat)
                    %no format specified- hopefully datetime will figure it out
                    dt = datetime(dtStr);
                else
                    dt = datetime(dtStr,'InputFormat',dateFormat);
                end %if
                dt.Format = 'yyyy-MM-dd''T''HH:mm';
                
            end %getDateTimeFromString
        end 
        
        function [format,reportId,variableId]= parseReportVariableDataInputArgs(~,...
                reportId,variableId,varargin)
            p = getTQAInputParser();
            p.addRequired('reportId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));   
            p.addRequired('variableId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));             
            p.parse(reportId,variableId,varargin{:});
            r = p.Results;
            format = r.format;
            reportId = r.reportId;  
            variableId = r.variableId;
        end 
        
        function [format,urlExtension] = parseCustomGetInputArgs(~,varargin)
            p = getTQAInputParser();
            p.addOptional('urlExtension','',...
                @(x)validateattributes(x,{'char'},{'row'}));              
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
            urlExtension = r.urlExtension;            
            
        end %parseCustomGetInputArgs
        
        function [format,urlExt,data] = parseCustomPostInputArgs(~,varargin)
            p = getTQAInputParser();
            p.addOptional('urlExtension','',...
                @(x)validateattributes(x,{'char'},{'row'}));      
            p.addOptional('data',[]);
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
            urlExt = r.urlExtension; 
            data = r.data;
        end %parseCustomPostInputArgs
        
        function [format,scheduleId] = parseScheduleInputArgs(~,varargin)
            p = getTQAInputParser();
            p.addOptional('scheduleId',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));              
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
            scheduleId = r.scheduleId;            
        end  %parseScheduleInputArgs      
        
        function [format,templateId] = parseTemplateInputArgs(~,varargin)
            p = getTQAInputParser();
            p.addOptional('templateId',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));              
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
            templateId = r.templateId;            
        end %parseTemplateInputArgs    
        
        function [format,templateId] = parseDeleteTemplateInputArgs(~,...
                templateId,varargin)
            p = getTQAInputParser();
            p.addRequired('templateId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));              
            p.parse(templateId,varargin{:});
            r = p.Results;
            format = r.format;
            templateId = r.templateId;            
        end %parseTemplateInputArgs    
                
        
        function [format,equipmentId] = parseEquipmentInputArgs(~,varargin)
            p = getTQAInputParser();
            p.addOptional('equipmentId',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));              
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
            equipmentId = r.equipmentId;            
        end %parseEquipmentInputArgs  
        
        function [format,scheduleId] = parseBaselinesInput(~,scheduleId,varargin)
            p = getTQAInputParser();
            p.addRequired('scheduleId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));   
          
            p.parse(scheduleId,varargin{:});
            r = p.Results;
            format = r.format;
            scheduleId = r.scheduleId;
        end 
        
        function [format,scheduleId] = parseQASettingsInput(~,scheduleId,varargin)
            p = getTQAInputParser();
            p.addRequired('scheduleId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));   
            
            p.parse(scheduleId,varargin{:});
            r = p.Results;
            format = r.format;
            scheduleId = r.scheduleId;
        end %parseQASettingsInput      
        
        function [format,sourceId] = parseSourceInputArgs(~,varargin)
            p = getTQAInputParser();
            p.addOptional('sourceId',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
            sourceId = r.sourceId;
        end %parseSourceInputArgs
        
        function format = parseEnergyInputArgs(~,varargin)
            p = getTQAInputParser();
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
        end %parseSiteInputArgs   
        
        function [format, filter, documentId] = parseDocumentInputArgs(~,varargin)
            p = getTQAInputParser();
            p.addOptional('hidden','',...
                @(x)any(validatestring(x,{'true','false'})))
            p.addOptional('documentId',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));           
            p.parse(varargin{:});
            r = p.Results;
            filter = '';
            if ~isempty(r.hidden)
                filter = ['?hidden=',r.hidden];
            end %if
            format = r.format;
            documentId = r.documentId;
        end %parseDocumentInputArgs
        
        function [format,equipmentId,machineId] = parseCalibrationFactorsInput(~,equipmentId,varargin)
            p = getTQAInputParser();
            p.addRequired('equipmentId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'})); 
            p.addOptional('machineId',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));            
            p.parse(equipmentId,varargin{:});
            r = p.Results;
            format = r.format;
            equipmentId = r.equipmentId;
            machineId = r.machineId;
        end      
        
        function [format,data] = parseSetMachineEnergyInput(~,varargin)
            p = getTQAInputParser();
            p.addOptional('radiationType','',...
                @(x)any(validatestring(x,{'photon','electron'})));
            p.addOptional('energyValue',[],@(x)validateattributes(x,{'numeric'},...
                {'positive','scalar'})); 
            p.addOptional('energyLabel','',@(x)validateattributes(x,{'char'},...
                {}));
            
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
            data =struct(...
                'radiationType',r.radiationType,...
                'energyValue', r.energyValue,...
                'energyLabel',r.energyLabel);                
        end %parse
        
        function format = parseSiteMachineRequestInput(~,varargin)
            p = getTQAInputParser();
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
        end %parseSiteMachineRequestInput
        
        function [format,siteId,data] = parseModifySiteInput(~,siteId,varargin)
            p = getTQAInputParser();
            p.addRequired('siteId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));
            p.addOptional('name','',@(x)validateattributes(x,{'char'},{'row','nonempty'}));
            p.addOptional('notes','**NOT PRESENT**',@(x)ischar(x));
            if ~isempty(varargin)
                p.parse(siteId,varargin{:});
            else
                p.parse(siteId);
            end %if
            r = p.Results;
            format = r.format; 
            siteId = r.siteId;
            data = struct('name',r.name,'notes',r.notes);
            if isempty(data.name)
                data = rmfield(data,'name');
            end %if
            
            if strcmp(data.notes,'**NOT PRESENT**')
                data = rmfield(data,'notes');
            end %if
        end %parseModifySiteInput
        
        function [format,machineId,data] = parseModifyMachineInput(~,machineId,varargin)
            p = getTQAInputParser();
            p.addRequired('machineId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));
            p.addOptional('name','',@(x)validateattributes(x,{'char'},{'row','nonempty'}));
            p.addOptional('phoneNumber','**NOT PRESENT**',@(x)ischar(x));
            p.addOptional('serialNumber','**NOT PRESENT**',@(x)ischar(x));
            p.addOptional('internalNumber','**NOT PRESENT**',@(x)ischar(x));
            if ~isempty(varargin)
                p.parse(machineId,varargin{:});
            else
                p.parse(machineId);
            end %if
            r = p.Results;
            format = r.format; 
            machineId = r.machineId;
            data = struct('name',r.name,'phoneNumber',...
                r.phoneNumber,'serialNumber',r.serialNumber,...
                'internalNumber',r.internalNumber);
            if isempty(data.name)
                data = rmfield(data,'name');
            end %if
            
            optionalFields = {'phoneNumber','serialNumber','internalNumber'};
            for f = 1:numel(optionalFields)
                if strcmp(data.(optionalFields{f}),'**NOT PRESENT**')
                    data = rmfield(data,optionalFields{f});
                end %if
            end %for
        
        end %parseModifySiteInput    
                
        function [format,filter,verbose] = parseReportInputArgs(~,varargin)
            p = getTQAInputParser();
            p.addOptional('verbose',false,...
                @(x)validateattributes(x,{'logical'},{'scalar'}));
            p.addOptional('machine',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));            
            p.addOptional('site',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));  
            p.addOptional('schedule',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));       
            p.addOptional('status',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','nonnegative','scalar'}));    
            p.addOptional('toleranceStatus',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','nonnegative','scalar'}));
            p.addOptional('deviceType',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','nonnegative','scalar'}));             
            p.addOptional('frequency',[],@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));             
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
            verbose = r.verbose;
            
            %build the filter string
            filter = '';
            filterFields = {r.machine,r.site,r.schedule,...
                    r.status,r.toleranceStatus,r.deviceType,r.frequency};
            filterNames = {'machine','site','schedule','status',...
                'toleranceStatus','deviceType','frequency'};
            if any(~(cellfun(@isempty,filterFields,...
                    'UniformOutput',true)))
                filter = '?';
                first = true;
                for f = 1:numel(filterFields)
                    if ~isempty(filterFields{f})
                        if ~first
                            filter = [filter,'&']; %#ok<AGROW>
                        end %if
                        filter = [filter,filterNames{f},'=',int2str(filterFields{f})]; %#ok<AGROW>
                        first = false;
                    end %if
                end %for
                   
            end %if
            
        end %parseReportInputArgs
        
        function [format,siteId,data] = parseUserAssigmentInputs(~,siteId,userIds,varargin)
            p = getTQAInputParser();
            p.addRequired('siteId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'}));
            p.addRequired('userIds',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','vector'}));
            
            p.parse(siteId,userIds,varargin{:});
            r = p.Results;
            format = r.format;
            siteId = r.siteId;
            data.userIds = r.userIds;
        end %parseUserAssigmentInputs
        
        function format = parseGetCustomTestsInput(~,varargin)
            p = getTQAInputParser();            
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;            
            
        end %getCustom
        
        function [format,data] = parseCreateNewUserInput(~,varargin)
            p = getTQAInputParser();           
            p.addOptional('name','',@(x)validateattributes(x,{'char'},...
                {'row','nonempty'}));
            p.addOptional('emailAddress','',@(x)validateattributes(x,{'char'},...
                {'row','nonempty'}));
            p.addOptional('active',1,@(x)validateattributes(x,{'numeric'},...
                {'scalar','integer','>=',0,'<=',1}));
            p.addOptional('role','',...
                @(x)any(validatestring(x,{'therapist','physicist',...
                'administrator','physicist_administrator'})));
            p.addOptional('notes','',@(x)ischar(x));
            p.addOptional('phoneNumber','',@(x)ischar(x));
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
            data = struct('name',r.name,...
                          'emailAddress',r.emailAddress,...
                          'active',r.active,...
                          'role',r.role,...
                          'notes',r.notes,...
                          'phoneNumber',r.phoneNumber);
        end %parseCreateNewUser
        
        function [format,userId,data] = parseModifyUserInput(~,userId,varargin)
            p = getTQAInputParser();
            p.addRequired('userId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'}));
            p.addOptional('name','**NOT PRESENT**',@(x)validateattributes(x,{'char'},...
                {'row','nonempty'}));
            p.addOptional('emailAddress','**NOT PRESENT**',@(x)validateattributes(x,{'char'},...
                {'row','nonempty'}));
            p.addOptional('active',-1,@(x)validateattributes(x,{'numeric'},...
                {'scalar','integer','>=',0,'<=',1}));
            p.addOptional('role','**NOT PRESENT**',...
                @(x)any(validatestring(x,{'therapist','physicist',...
                'administrator','physicist_administrator'})));
            p.addOptional('notes','**NOT PRESENT**',@(x)ischar(x));
            p.addOptional('phoneNumber','**NOT PRESENT**',@(x)ischar(x));
            p.parse(userId,varargin{:});
            r = p.Results;
            format = r.format;
            data = struct('name',r.name,...
                          'emailAddress',r.emailAddress,...
                          'active',r.active,...
                          'role',r.role,...
                          'notes',r.notes,...
                          'phoneNumber',r.phoneNumber);  
                      
            charFields = {'name','emailAddress','role','notes','phoneNumber'};
            for f = 1:numel(charFields)
                if strcmp(data.(charFields{f}),'**NOT PRESENT**')
                    data = rmfield(data,charFields{f});                   
                end %if
            end %for
            
            if data.active == -1
                data = rmfield(data,'active');
            end %if
                
        end %parseModifyUserInput
        
        function [format,energyId] = parseDeativateEnergyInput(~,energyId,varargin)
            p = getTQAInputParser();
            p.addRequired('energyId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'}));
            p.parse(energyId,varargin{:});
            r = p.Results;
            format = r.format;
            energyId = r.energyId;
            
        end %parseDeativateEnergyInput
        
        function [format,scheduleId] = parseScheduleVariablesInput(~,...
                scheduleId,varargin)
            p = getTQAInputParser();
            p.addRequired('scheduleId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'})); 
            
            p.parse(scheduleId,varargin{:});
            r = p.Results;
            format = r.format;
            scheduleId = r.scheduleId;                        
        end %parseScheduleVariablesInput
        
        function [format,scheduleId,outputData] =...
                parseUploadSimpleDataInput(~,scheduleId,variableData,...
                varargin)
            if isstruct(variableData) %then assume its a single measurement
                variableData = {variableData};
               
            end %if
            
            if isempty(variableData)
                variableData = {'EMPTY'};
            end %if
                               
            p = getTQAInputParser();
            p.addRequired('scheduleId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'})); 
            p.addRequired('variableData',@(x)validateattributes(x,{'cell'},{'vector'}));
            p.addOptional('date',datestr(now,'YYYY-mm-dd HH:MM'),...
                @(x)validateattributes(x,{'char'},{'row'}));
            p.addOptional('dateFormat','',... 
                @(x)validateattributes(x,{'char'},{'row'}));
            p.addOptional('finalize',0,@(x)validateattributes(x,...
                {'numeric'},{'scalar','integer','>=',0,'<=',1}));
            p.addOptional('comment','',@(x)ischar(x));
            p.parse(scheduleId,variableData,varargin{:});
            r= p.Results;
            format = r.format;
            scheduleId = r.scheduleId;
            %now let's make sure the date format is correct
            if isempty(r.dateFormat)
                %no format specified- hopefully datetime will figure it out
                d = datetime(r.date); 
            else
                d = datetime(r.date,'InputFormat',r.dateFormat);
            end %if
            %...put it back out as string in correct format
            d.Format = 'yyyy-MM-dd HH:mm'; %seriously Chet... 
            %I have to do the format string different from above. WTF?
            outputData.date = char(d);
            outputData.comment = r.comment;
            outputData.finalize = r.finalize;
            
            %do a more detailed look at the variable data
            %each array member should be a structure
            
            if isequal(r.variableData,{'EMPTY'})
                outputData.variables =[];
                return;
            end %if
            
            varIsStruct = cellfun(@isstruct,r.variableData,...
                'UniformOutput',true);
            if ~all(varIsStruct)
                error('TQAConnection:parseUploadSimpleDataInput',...
                    'variable data must a cell array of structs');
            end %if
            
            %now we need to check each struct to see if it has the right
            %fields
            
            ...must have at least id and value
            for v = 1:numel(r.variableData)
                reqFieldsPresent = isfield(r.variableData{v},{'id','value'});
                if ~all(reqFieldsPresent)
                    error('TQAConnection:parseUploadSimpleDataInput',...
                        'each element of the variable data must have id and value fields');
                end %if
                
                %they MAY have a metaItems field in which case each
                %metaitem must have an id and value
                
                if isfield(r.variableData{v},'metaItems')                   
                    if isstruct(r.variableData{v}.metaItems)
                        reqMetaItemFieldsPresent = ...
                            isfield(r.variableData{v}.metaItems,{'id','value'});
                        
                        if ~all(reqMetaItemFieldsPresent)
                            error('TQAConnection:parseUploadSimpleDataInput',...
                                'metaItem datadata must have id and value fields');
                        end %if
                        if numel(r.variableData{v}.metaItems)== 1
                            %becuase we need it in an array even if its
                            %singular we need to change it to a cell
                            c = r.variableData{v}.metaItems;
                            r.variableData{v}.metaItems = {c};
                        end %if
                        
                    elseif iscell(r.variableData{v}.metaItems)
                        for m = 1:numel(r.variableData{v}.metaItems)
                            reqMetaItemFieldsPresent = ...
                                isfield(r.variableData{v}.metaItems{m},{'id','value'});
                            if ~all(reqMetaItemFieldsPresent)
                                error('TQAConnection:parseUploadSimpleDataInput',...
                                    'metaItem datadata must have id and value fields');
                            end %if
                        end %for
                    end %if
                    
                end %if
                
            end %for
            
            outputData.variables = r.variableData;
        end %parseUploadSimpleDataInput
        
        function [format,scheduleId] = parseFinalizeReportInputs(~,...
                scheduleId,varargin)
            p = getTQAInputParser();
            p.addRequired('scheduleId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'})); 
            p.parse(scheduleId,varargin{:});
            r = p.Results;
            format = r.format;
            scheduleId = r.scheduleId;
        end %parseFinalizedReportinputs
        
        function [format,scheduleId] = parseGetUploadStatusInputs(~,scheduleId,varargin)
            p = getTQAInputParser();
            p.addRequired('scheduleId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'})); 
            p.parse(scheduleId,varargin{:});
            r = p.Results;
            format = r.format;
            scheduleId = r.scheduleId;
            
        end %
        
        function [format,scheduleId,fileList,startProcessing,finalizeQA,...
                verbose] = parseUploadImage(~,scheduleId,fileList,varargin)
            if ischar(fileList)
                fileList = {fileList};
            end %if
            
            p = getTQAInputParser();
            p.addRequired('scheduleId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'}));
            p.addRequired('fileList',@(x)iscellstr(x));
            p.addOptional('startProcessing',false,@(x)validateattributes(...
                x,{'logical'},{'scalar'}));
            p.addOptional('finalizeQA',false,@(x)validateattributes(...
                x,{'logical'},{'scalar'}));
            p.addOptional('verbose',false,@(x)validateattributes(...
                x,{'logical'},{'scalar'}));
            
            p.parse(scheduleId,fileList,varargin{:});
            r = p.Results;
            format = r.format;
            scheduleId = r.scheduleId;
            fileList = r.fileList;
            startProcessing = r.startProcessing;
            finalizeQA = r.finalizeQA;
            verbose = r.verbose;
        end %parseUploadImage
        
        function format = parseGetTestsInput(~,varargin)
            p = getTQAInputParser();
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;            
        end %parseGetTestsInput
        
        function [format,sourceId,shipOutDate] = parseShipSourceInput(~,sourceId,shipOutDate,varargin)
            p = getTQAInputParser();
            p.addRequired('sourceId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'}));
            p.addRequired('shipOutDate',@(x)validateattributes(x,{'char'},...
                {'row'}));
            p.addOptional('dateFormat','',@(x)validateattributes(x,{'char'},...
                {'row'}));
            
            p.parse(sourceId,shipOutDate,varargin{:});
            r = p.Results;
            format = r.format;
            sourceId = r.sourceId;
            shipOutDate = r.shipOutDate;
            
            %now make sure date is in correct format
            if isempty(r.dateFormat)
                %no format specified- hopefully datetime will figure it out
                d = datetime(shipOutDate);
            else
                d = datetime(shipOutDate,'InputFormat',r.dateFormat);
            end %if
            d.Format = 'yyyy-MM-dd HH:mm';
            shipOutDate = char(d);
            
        end %parseShipSourceInput
        
        function [format,data] = parseAddEquipmentInput(~,name,type,status,varargin)
            p = getTQAInputParser();
            p.addRequired('name',@(x)validateattributes(x,{'char'},{'row'}));
            p.addRequired('type',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'})); 
            p.addRequired('status',@(x)validateattributes(x,{'numeric'},...
                {'>=',0,'<=',1,'scalar','integer'}));
            p.addOptional('description','',@(x)ischar(x));
            p.addOptional('serialNumber','',@(x)ischar(x));
            p.parse(name,type,status,varargin{:});
            r = p.Results;
            format = r.format;
            data = r;
            data = rmfield(data,'format');
        end %parseAddEquipmentInput
      
        
        function [format,equipmentId,data] = parseModifyEquipmentInput(~,equipmentId,varargin)
            p = getTQAInputParser();
            p.addRequired('equipmentId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'})); 
            p.addOptional('name','**NOT PRESENT**',...
                @(x)validateattributes(x,{'char'},{'row'}));
            p.addOptional('type',-1,@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'})); 
            p.addOptional('status',-1,@(x)validateattributes(x,{'numeric'},...
                {'>=',0,'<=',1}));
            p.addOptional('description','**NOT PRESENT**',@(x)ischar(x));
            p.addOptional('serialNumber','**NOT PRESENT**',@(x)ischar(x));
            p.parse(equipmentId,varargin{:});
            r = p.Results;
            format = r.format;
            equipmentId = r.equipmentId;
            data = r;
            data = rmfield(data,{'format','equipmentId'});  
            
            %remove non-present fields
            checkFields = {'name','type','status','description','serialNumber'};
            for n = 1:numel(checkFields)
                if ischar(data.(checkFields{n})) && ...
                        strcmp(data.(checkFields{n}),'**NOT PRESENT**')
                    data = rmfield(data,checkFields{n});
                elseif isnumeric(data.(checkFields{n})) && ...
                        data.(checkFields{n}) == -1
                    data = rmfield(data,checkFields{n});
                end %if
            end %if
        end %parseModifyEquipmentInput
        
        function [format,equipmentId] = parseDeleteEquipmentInput(~,...
                equipmentId,varargin)
            p = getTQAInputParser();
            p.addRequired('equipmentId',@(x)validateattributes(x,{'numeric'},...
                {'integer','positive','scalar'})); 
            p.parse(equipmentId,varargin{:});
            r = p.Results;
            format = r.format;
            equipmentId = r.equipmentId;
        end %parseDeleteEquipmentInput
        
        function [format,data] = parseAddTemplateInput(~,varargin)
            p = getTQAInputParser();
            p.addOptional('name','',@(x)validateattributes(x,{'char'},...
                {'row'}));
            p.addOptional('description','',@(x)ischar(x));
            p.addOptional('active',0,@(x)validateattributes(x,{'numeric'},...
                {'scalar','integer','>=',0,'<=',1}));
            p.addOptional('deviceTypes',4,@(x)validateattributes(x,...
                {'numeric'},{'positive','nonempty','integer','vector'}));
            p.addOptional('tests',[],@(x)validateattributes(x,...
                {'numeric'},{'positive','nonempty','integer','vector'}));
            p.StructExpand = true;
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
            data = r;
            data.deviceTypes = num2cell(data.deviceTypes);
            data.tests = num2cell(data.tests);
            data = rmfield(data,'format');            
        end %parseAddTemplate
        
        function [format,templateId,data] = parseModifyTemplateInputs(~,templateId,varargin)
            p = getTQAInputParser();
            p.addRequired('templateId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'}));
            p.addOptional('name','**NOT PRESENT**',@(x)validateattributes(x,{'char'},...
                {'row'}));
            p.addOptional('description','**NOT PRESENT**',@(x)ischar(x));
            p.addOptional('active',-1,@(x)validateattributes(x,{'numeric'},...
                {'scalar','integer','>=',0,'<=',1}));
            p.addOptional('deviceTypes',-1,@(x)validateattributes(x,...
                {'numeric'},{'positive','nonempty','integer','vector'}));
            p.addOptional('addTests',-1,@(x)validateattributes(x,...
                {'numeric'},{'positive','nonempty','integer','vector'}));
            p.addOptional('removeTests',-1,@(x)validateattributes(x,...
                {'numeric'},{'positive','nonempty','integer','vector'}));
            p.parse(templateId,varargin{:});
            r = p.Results;
            format = r.format;
            templateId = r.templateId;
            data = r;
            data = rmfield(data,{'format','templateId'});
            
            %remove non-present fields
            checkFields = {'name','deviceTypes','active','description',...
                'addTests','removeTests'};
            for n = 1:numel(checkFields)
                if ischar(data.(checkFields{n})) && ...
                        strcmp(data.(checkFields{n}),'**NOT PRESENT**')
                    data = rmfield(data,checkFields{n});
                elseif isnumeric(data.(checkFields{n})) && ...
                        isscalar(data.(checkFields{n}))&&...
                        data.(checkFields{n}) == -1
                    data = rmfield(data,checkFields{n});
                end %if
            end %if            
            
            %this is to ensure that scalars are encoded as arrays in the
            %input JSON string
            if isfield(data,'addTests') && isscalar(data.addTests)
                data.addTests = {data.addTests};
            end %if
            
            if isfield(data,'removeTests') && isscalar(data.removeTests)
                data.removeTests = {data.removeTests};
            end %if        
            
            if isfield(data,'deviceTypes') && isscalar(data.deviceTypes)
                data.deviceTypes = {data.deviceTypes};
            end %if
        end %parseModifyTemplateInputs
        
        function [format,group] = parseAddCustomGroupInput(~,varargin)
            p = getTQAInputParser();           
            p.addOptional('label','',@(x)validateattributes(x,{'char'},...
                {'nonempty','row'}));
            p.addOptional('description','',@(x)ischar(x));

            p.addOptional('deviceTypes',[],@(x)validateattributes(x,...
                {'numeric'},{'positive','integer','vector','nonempty'}));
            
            p.parse(varargin{:});
            r = p.Results;
            format = r.format;
            group.label = r.label;
            group.description = r.description;
            group.deviceTypes = num2cell(r.deviceTypes);
            
        end %parseAddCustomTestGroup
        
        function [format,data] = parseAddCustomSectionGroupInput(~,groupId,varargin)
            p = getTQAInputParser();
            p.addRequired('groupId',@(x)validateattributes(x,{'numeric'},...
                {'nonempty','positive','scalar'}));
            p.addOptional('label','',@(x)validateattributes(x,{'char'},...
                {'nonempty','row'}));
            p.addOptional('description','',@(x)ischar(x));
                       
            p.parse(groupId,varargin{:});
            r = p.Results;
            format = r.format;
            data.group = r.groupId;
            data.sectionGroup.label = r.label;
            data.sectionGroup.description = r.description;           
        end %parseAddCustomTestGroup
        
        function [format,data] = parseAddCustomTestInput(~,sectionGroupId,...
                varargin)
            p = getTQAInputParser();
            p.addRequired('sectionGroupId',@(x)validateattributes(x,{'numeric'},...
                {'nonempty','positive','scalar'}));
            p.addOptional('name','',@(x)validateattributes(x,{'char'},...
                {'nonempty','row'}));
            p.addOptional('description','',@(x)ischar(x));
            p.addOptional('type','numeric',...
                @(x)any(validatestring(x,{'numeric','energydependencyphoton',...
                'energydependencyelectron','deviation','passfail',...
                'passfailwarning','binary','text'})));
            p.addOptional('multipleValues',0,@(x)validateattributes(x,...
                {'numeric'},{'scalar','nonempty','integer','>=',0,'<=',1}));
               
            p.parse(sectionGroupId,varargin{:});
            r = p.Results;
            format = r.format;
            data.sectionGroup = r.sectionGroupId;
            data.test.name = r.name;
            data.test.description = r.description;    
            data.test.type = r.type;
            data.test.multipleValues = r.multipleValues;
        end %parseAddCustomTestInput
        
                    
        function [format,data] = parseAddMetaItemsInput(~,testId,metaItems,...
                varargin)     
            
            if isstruct(metaItems) %then assume its a single item
                metaItems = {metaItems};
            end %if
            
            p = getTQAInputParser();            
            p.addRequired('testId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'}));     
          
            p.addRequired('metaItems',@(x)validateattributes(x,{'cell'},...
                {'vector'}));
            p.parse(testId,metaItems,varargin{:});
            r= p.Results;
            format = r.format;         
            data.test = r.testId;
            data.metaItems = r.metaItems;
            %do a more detailed look at the metaitem data
            %each array member should be a structure
            metaitemsAreStruct = cellfun(@isstruct,r.metaItems,...
                'UniformOutput',true);
            if ~all(metaitemsAreStruct)
                error('TQAConnection:parseAddMetaItemsInput',...
                    'metaitem data must a cell array of structs');
            end %if  
            
            %now we need to check each struct to see if it has the right
            %fields
            
            ...must have at least name and type
            for v = 1:numel(r.metaItems)
                reqFieldsPresent = isfield(r.metaItems{v},{'name','type'});
                if ~all(reqFieldsPresent)
                    error('TQAConnection:parseAddMetaItemsInput',...
                        'each element of the metaitem data must have name and type fields');
                end %if
                
                validateattributes(r.metaItems{v}.name,{'char'},{'row'});
                validatestring(r.metaItems{v}.type,{'list','text','numeric'});

                switch r.metaItems{v}.type
                    case 'list'
                       %it will need an options list
                       optionsPresent = isfield(r.metaItems{v},'options');
                       if ~optionsPresent
                           error('TQAConnection:parseAddMetaItemsInput',...
                               'list type meta items must specify options');
                       end %if
                       validateattributes(r.metaItems{v}.options,{'struct'},{});
                       labelPresent = isfield(r.metaItems{v}.options,'label');
                       if ~labelPresent
                           error('TQAConnection:parseAddMetaItemsInput',...
                               'list type meta items must specify options with a label field');
                       end %if
                    case 'text'
                        %no options to be present
                    case 'numeric'
                        unitsPresent = isfield(r.metaItems{v},'units');
                        if unitsPresent
                            validateattributes(r.metaItems{v}.units,{'char'},...
                                {'row'});
                        end %if
                end 
            end %for
            
        end %parseAddMetaItemsInput
        
        function [format,data] = parseAddCompleteCustomTestInput(obj,customTestData,varargin)
            p = getTQAInputParser();      
            
            reqFields = {'group','sectionGroup','test'};
            if ~all(isfield(customTestData,reqFields))
                error('TQAConnection:MissingCustomTestFields',...
                    'A complete custom test needs group, sectionGroup and test fields');
            end %if
            
            [~,groupData] = obj.parseAddCustomGroupInput(customTestData.group);
            [~,sectionData] = obj.parseAddCustomSectionGroupInput(1,customTestData.sectionGroup);
            sectionData = rmfield(sectionData,'group');
            [~,testData] = obj.parseAddCustomTestInput(1,customTestData.test);
            testData = rmfield(testData,'sectionGroup');
            if isfield(customTestData,'metaItems')
                [~,metaItemData] = obj.parseAddMetaItemsInput(1,customTestData.metaItems);
                metaItemData = rmfield(metaItemData,'test');
            else               
                metaItemData = struct([]);
            end %if
            
            p.parse(varargin{:});
            format = p.Results.format;
            data.group = groupData;
            data.sectionGroup = sectionData.sectionGroup;
            data.test = testData.test;
            if ~isempty(metaItemData)
                data.metaItems = metaItemData.metaItems;
            end %if
            
        end %parseAddCompleteCustomTestInput
        
        function [format,data] = parseCreateScheduleInput(~,machineId,templateId,...
                varargin)
            p = getTQAInputParser();  
            p.addRequired('machineId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'}));
            p.addRequired('templateId',@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'}));
            p.addOptional('allowedGroups',{},@(x)iscellstr(x));
            p.addOptional('status',1,@(x)validateattributes(x,{'numeric'},...
                {'scalar','integer','>=',0,'<=',1}));            
            p.addOptional('name','',@(x)validateattributes(x,{'char'},...
                {'row','nonempty'}));
            p.addOptional('starts',datestr(now,'YYYY-mm-dd'),...
                @(x)validateattributes(x,{'char'},{'row'}));  
            p.addOptional('ends','**NOT PRESENT**',...
                @(x)validateattributes(x,{'char'},{'row'})); 
            p.addOptional('frequency','ad-hoc',@(x)any(validatestring(...
                x,{'ad-hoc','daily','weekly','monthly','yearly'})));
            p.addOptional('dueDays',1,@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'}));
            p.addOptional('overdueDays',1,@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'}));        
            p.addOptional('repeat',1,@(x)validateattributes(x,{'numeric'},...
                {'scalar','positive','integer'}));
            p.addOptional('repeatBy','day',@(x)any(validatestring(...
                x,{'day','weekday'})));   
            p.addOptional('repeatOn','**NOT PRESENT**',@(x)iscellstr(x));
            
            p.parse(machineId,templateId,varargin{:});
            data= p.Results;
            format = data.format;     
            data = rmfield(data,'format');
            
            %now remove unecessary or missing fields
            if isequal(data.ends,'**NOT PRESENT**')
                data = rmfield(data,'ends');
            end %if
            
            if isequal(data.repeatOn,'**NOT PRESENT**')
                data = rmfield(data,'repeatOn');
            end %if
            
            if isequal(data.frequency,'ad-hoc')
                data = rmfield(data,{'dueDays','overdueDays','repeat'});
            end %if
            
            if ~isequal(data.frequency,'monthly')
                data = rmfield(data,'repeatBy');
            end %if
            
            if ~isequal(data.frequency,'weekly') && isfield(data,'repeatOn')
                data = rmfield(data,'repeatOn');
            end %if
            
            %do some furtherparsing of date fields 
            data.machine = data.machineId;
            data.template = templateId;
            data = rmfield(data,{'machineId','templateId'});

            %no format specified- hopefully datetime will figure it out
            d = datetime(data.starts);
            %...put it back out as string in correct format
            d.Format = 'yyyy-MM-dd'; %seriously Chet... 
            %I have to do the format string different from above. WTF?
            data.starts = char(d);
            
            if isfield(data,'ends')
                %no format specified- hopefully datetime will figure it out
                d = datetime(data.ends);
                %...put it back out as string in correct format
                d.Format = 'yyyy-MM-dd';
                data.ends = char(d);                
            end %if
            
            
        end %parseCreateScheduleInput
        
        function reportData = postprocessReportData(~,reportData,status,format)
            %putting report data into a more friendly forma                       
            valStruct = reportData.reportData.values;
            
            if isempty(valStruct)
                reportData.reportData.values = [];
            else
                varValueField = fieldnames(valStruct);
                valField = cell(numel(varValueField),1);
                nVar = 0;
                for v =1:numel(varValueField)
                    valField{v} = fieldnames(valStruct.(varValueField{v}));
                    thisValFields = valField{v};
                    for f = 1:numel(thisValFields);
                        nVar = nVar+1;
                        dataStruct(nVar) = valStruct.(varValueField{v}).(thisValFields{f}); %#ok<AGROW>
                    end %for
                    
                end %for
                reportData.reportData.values =dataStruct;
            end %if
            
            %now reformat into originall requested format
            reportData = tqaconnection.requests.TQARequest.formatResponse(...
                reportData,status,format);
         
            %fix links in the reportdata
            switch format
                case 'struct'
                    if isstruct(reportData) && ...
                            isfield(reportData,'reportData') &&...
                            numel(reportData.reportData.values) >0
                        
                        types = {reportData.reportData.values.type};
                        for r = 1:numel(reportData.reportData.values)
                            if isequal(types{r},'binary') % fix the &
                                v = reportData.reportData.values(r).value;
                                reportData.reportData.values(r).value =...
                                    strrep(v, '\u0026','&'); 
                            end %if
                        end %for
                    end %if
                case 'json'
                    reportData = strrep(reportData,'\u0026','&');
                    reportData = strrep(reportData,'\/','/');
                case 'table'
                    reportVariables = reportData.Properties.VariableNames;
                    if ismember('values',reportVariables)
                        values = reportData.values;
                        types = {values.type};
                        for v = 1:numel(values)
                            if isequal(types{v},'binary')
                                binaryVal = values(v).value;
                                values(v).value = strrep(binaryVal, '\u0026','&'); 
                            end %if
                            reportData.values = values;
                        end %for
                            
                    end %if
                                     
            end %switch
        end %
    end %private methods
    
end

function parser = getTQAInputParser
parser = inputParser;
parser.addOptional('format','struct',...
    @(x)any(validatestring(x,{'struct','json','table'})));
end 
