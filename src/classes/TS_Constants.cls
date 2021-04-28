/**
* @author        Paul Jarred Aguiling
* @date          3.17.2017           
* @description   Class responsible for Technical Services Workstream constant value 
* @revision(s)
*/
@isTest
public without sharing class TS_Constants {

    //FD 853 values
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_INPROGRESS= 'In Progress';
    public static final String STATUS_OPEN = 'Open';
    public static final String STATUS_CLOSE = 'Close';
    public static final String STATUS_CLOSED = 'Closed';
    public static final String STATUS_COMPLETE = 'Complete';
    public static final String STATUS_INCOMPLETE = 'Incomplete';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_CANCELED = 'Canceled';
    public static final String WOLI_STATUS_REVIEW = 'Review Needed';
    public static final String WOLI_STATUS_RETURN = 'Return Needed';
    public static final String WOLI_STATUS_OPEN = 'Open';
    public static final String WOLI_STATUS_SCHEDULED = 'Scheduled';
    public static final String WOLI_STATUS_DISPATCHED = 'Dispatched';
    public static final String WOLI_STATUS_RECEIVED = 'Received';
    public static final String WOLI_STATUS_TRAVELLING = 'Travelling';
    public static final String WOLI_STATUS_ONSITE = 'On Site';
    public static final String WOLI_STATUS_STARTWORK = 'Start Work';
    public static final String WO_STATUS_SENTFIELD = 'Sent to Field';
    public static final String WO_STATUS_SENTPLANNING = 'Sent To Planning';
    public static final String CASE_SUBSTATUS_SENTFIELD = 'Order Sent to Field';
    public static final String CASE_SUBSTATUS_SENTPLANNING = 'Order Sent to Planning';
    public static final String TYPE_QUEUE = 'Queue';
    public static final String TYPE_TASK = 'Task';
    public static final String TYPE_COUNTER = 'Counter';
    public static final String WOLI_STATUS_MISSING = 'MissingSpareParts';
    public static final String WOLI_STATUS_REQUIRED = 'RequiredSpareParts';

    public static final String PA_STATUS_ACTIVATED = 'Activated';
    public static final String PA_STATUS_PENDINGCANCELATION = 'Pending Cancellation';
    public static final String PA_STATUS_PENDINGACTIVATION = 'Pending Activation';

    public static final String CASE_TYPE_FIELDSERVICE = 'Field Service';
    public static final String CASE_TYPE_COMPLAINT = 'Complaint';
    public static final String CASE_TYPE_CUSTOMERCARE = 'Customer Care';
    public static final String TYPE_SERVICE = 'Service Materials';
    public static final String TYPE_API_USEDPARTS = 'UsedSpareParts';

    public static final String CASE_PRIORITY_MEDIUM = 'Medium';
    public static final String CASE_SOURCE = 'Sales';

    public static final String CASE_SUBTYPE_REPLACEMENT = 'Replacement';
    public static final String CASE_SUBTYPE_CONFIGCHANGE = 'Configuration Change';
    public static final String CASE_SUBTYPE_CORRECTMAINT = 'Corrective Maintenance';
    public static final String CASE_SUBTYPE_CORRECTMAINTAPI = 'S10';
    public static final String CASE_SUBTYPE_1STLINECORRECTMAINT = '1st Line Corrective Maintenance';
    public static final String CASE_SUBTYPE_1STLINECORRECTMAINTAPI = 'S15';
    public static final String CASE_SUBTYPE_SWAP = 'Swap';
    public static final String CASE_SUBTYPE_INSTALLATION = 'Installation';
    public static final String CASE_SUBTYPE_DEINSTALLATION = 'De-Installation';
    public static final String CASE_SUBTYPE_GENERICQUESTION = 'Generic question';
    public static final String CASE_SUBSTATUS_ORDEROPEN = 'Order Open';


    public static final String SUBJECT_ADD = 'Add';
    public static final String SUBJECT_REMOVE = 'Remove';
    public static final String ASSET_SERVICEWINDOW_WEEKEND = 'Weekends: 09:00 - 22:00';
    public static final String ASSET_SERVICEWINDOW_WEEKDAY = 'Working Days: 09:00 - 17:00';
    public static final String ASSET_SERVICEWINDOW_24 = '24 hour services: 00:00 - 24:00';

    public static final String CASE_ORIGIN_MANUAL = 'Manual';
    public static final String CASE_ORIGIN_EMAIL = 'E-mail';
    public static final String CASE_ORIGIN_PHONE = 'Telefoon';    
    public static final String CASE_ORIGIN_ROUTESALESREQUEST = 'Routesales Request';
    public static final String CASE_ORIGIN_DR = 'Disaster Recovery';
    public static final String CASE_ORIGIN_EF = 'Engineer Feedback';
    public static final String CASE_ORIGIN_SALESORDER = 'Sales Order';
    public static final String CASE_ORIGIN_CONTRACTORDER = 'Contract Order';
    public static final String CASE_ORIGIN_WEB = 'Web';
    public static final String CASE_ORIGIN_IOT = 'IOT';
    public static final String CASE_ORIGIN_OPERATINGORDER = 'Operating Order';

    public static final String ENTITLEMENT_QUALIFYEMAIL = 'Qualify Email';

    public static final String WO_TYPE_S20_MACHINECARE = 'S20';
    public static final String WO_TYPE_S21_COUNTERREADING = 'S21';
    public static final String WO_TYPE_S22_COUNTERREADINGFUP = 'S22';
    public static final String WO_TYPE_S15_1STLINECM = 'S15';
    public static final String TYPE_S25_ROUTESALES = 'S25';
    public static final String TYPE_S32_WATERFILTER = 'S32';
    public static final String TYPE_S30_PREVMAINTENANCE = 'S30';
    public static final String TYPE_S31_PRECHECK = 'S31';
    public static final String TYPE_S60_MODIFICATION = 'S60';
    public static final String TYPE_S42_MOVEMENT = 'S42';
    public static final String TYPE_S43_CONFIGCHANGE = 'S43';

    public static final String FIELDSET_API_FIELDSERVICE_CLOSEDVALIDATION = 'FieldServiceClosedValidation';
    public static final String FIELDSET_API_CUSTOMERCARE_CLOSEDVALIDATION = 'CustomerCareClosedValidation';
    public static final String FIELDSET_API_COMPLAINT_CLOSEDVALIDATION = 'ComplaintClosedValidation';
    public static final String ERRORMSG_CASECLOSEDVALIDATION = 'You cannot update the Case anymore once the task is closed.';
    public static final String ERRORMSG_CASEROUTESALESVALIDATION = 'You can not create a task after 12h00 mid-day for the next business day.';
    public static final String ERRORMSG_RELATEDINVOICEVALIDATION = 'It is not allowed to delete a related invoice if dunning block is set to true.';
    public static final String ERRORMSG_ROUTELINEITEMVALIDATION = 'Only 1 Route Line Item per machine is allowed.';
    
    //Test Constants
    //Salesforce user Default profile
    public static final string DEFAULT_USER_PROFILE = 'System Administrator';
    public static final string PRIORITY_LOW = 'Low';
    
    //Record Type Names
    public static final string TS_WOLI_RECORDTYPE = 'TS Work Order Line Item';
    public static final string TS_WOLI_RECORDTYPE_MISC = 'TS Work Order Line Item Miscellaneous';  
    public static final String TS_WOLI_RECORDTYPE_REGTASK = 'Register Task';
    public static final String TS_WOLI_RECORDTYPE_ADDSERVICE = 'Add Service Job';
    public static final String TS_WOLI_RECORDTYPE_REGMAC = 'Register Machine Actions';
    public static final String TS_WOLI_RECORDTYPE_REGMISPART = 'Register Missing Part';
    public static final String TS_WOLI_RECORDTYPE_REGSERVMAT = 'Register Service Material';
    public static final String TS_WOLI_RECORDTYPE_REGUSEDPART = 'Register Used Part';
    public static final String TS_WOLI_RECORDTYPE_REGREQPART = 'Register Required Part';
    public static final String TS_WOLI_RECORDTYPE_COUNTERREADING = 'Counter Reading';
    public static final String TS_WOLI_RECORDTYPE_COUNTERREADINGTASK = 'Counter Reading Task';
    public static final String TS_WOLI_RECORDTYPE_OPERATINGTASK = 'Operating Task';

    public static final String TS_CASE_RECORDTYPE_FIELDSERVICE = 'Field Service';
    public static final String TS_CASE_RECORDTYPE_FIELDSERVICE_DEFAULT = 'Field Service Default';
    public static final String TS_CASE_RECORDTYPE_FIELDSERVICE_SALES = 'Field Service Sales';
    public static final String TS_CASE_RECORDTYPE_FIELDSERVICE_CONTRACT = 'Field Service Contract';
    public static final String TS_CASE_RECORDTYPE_ROUTESALES = 'Routesales';
    public static final String TS_CASE_RECORDTYPE_COMPLAINT = 'Complaint';
    public static final String TS_CASE_RECORDTYPE_CUSTOMERCARE = 'Customer Care';
    public static final String TS_CASE_RECORDTYPE_QUALIFYCASE = 'Qualify Case';
    public static final String TS_CASE_RECORDTYPE_CASEREG = 'Case Registration';
    public static final String TS_CASE_RECORDTYPE_MOD = 'Modification';
    public static final String TS_TASK_RECORDTYPE_AUTOMATED = 'Automated';

    public static final String TS_COUNTRYSETTING_RECORDTYPE_DEFAULT = 'Country Default Business Hours';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_CURRENCYCODE = 'Currency Code Mappings';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_RESPONSEPROFILE = 'CountryResponseProfile';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_DEFAULTCASEOWNER = 'Country_Default_Case_Owner_Rules';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_COUNTRYEMAIL = 'Country_Email_Rules';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_COUNTRYPURCHASING = 'Country Purchasing Settings';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_COUNTRYSLADERIVATION = 'Country SLA Derivation';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_MOBILEPROFILETEMPLATE = 'Mobile Profile Template';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_MCO_PM_RULES = 'Machine Clean Operating PM Rules';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_DEFAULT_CALENDAR = 'Country Default Operating Calendar';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_CONTRACTTRIGGERSETTING = 'Contract Trigger Setting';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_MERGEWTSWITHPM = 'Merge WTS with Preventive Maintenance';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_DEFAULTSAPINTERNALORDER = 'Default SAP Internal Order';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_COUNTRY_UNKNOWN_CONTACT = 'Country_Unknown_Contact_To_Account_Mapping';

    public static final String TS_COUNTRYSETTING_RECORDTYPE_COUNTRYEMAIL_NAME = 'Country Email Rules';
    public static final String TS_COUNTRYSETTING_RECORDTYPE_DEFAULTCASEOWNER_NAME = 'Country Default Case Owner Rules';

    public static final String TS_WO_RECORDTYPE_COUNTERREADING = 'Counter Reading';
    public static final String TS_WO_RECORDTYPE_OPERATINGWO = 'Operating Work Order';
    public static final String TS_WO_RECORDTYPE_OPERATINGROUTEWO = 'Operating (Route) Work Order';

    public static final String TS_WOT_TYPE_CONVERSION = 'Conversion';

    public static final String TS_WOT_RECORDTYPE_LINEITEM = 'Line Item';

    public static final String TS_CONTACT_RECORDTYPE_OPERATIONALCONTACT = 'Operational Contact';

    //APTS
    public static final String PENDING = 'Pending';
    public static final String SUBMITTED = 'Submitted';
    
    //Object Api Names
    public static final string OBJ_API_NAME_WOLI = 'WorkOrderLineItem'; 
    public static final String OBJ_APINAME_CASE = 'Case';
    public static final String OBJ_APINAME_WO = 'WorkOrder';
    public static final String OBJ_APINAME_CONTACT = 'Contact';

    //Order record constants
    public static final String ORDER_TYPE_NEW = 'New';
    public static final String ORDER_TYPE_RETURN = 'Return';
    public static final String ORDER_TYPE_REPLACE = 'Replace';
    public static final String ORDER_TYPE_ADDON = 'Add On';
    public static final String ORDER_FAMILY_MACHINES = 'Machines';
    public static final String ORDER_FAMILY_SPAREPARTS = 'Spare Parts';
    public static final String ORDER_INSTYPE_INSTALLATION = 'Installation';
    public static final String ORDER_INSTYPE_DEINSTALLATION = 'De-Installation';
    public static final String ORDER_INSTYPE_DEINSTALL = 'De-install';
    public static final String ORDER_INSTYPE_MOVEMENT = 'Movement';
    public static final String ORDER_EQTYPE_STAIR = 'Stair';
    public static final String ORDER_CANCELED = 'Cancelled';
    public static final String ORDER_S40 = 'S40';
    public static final String ORDER_S41 = 'S41';
    public static final String ORDER_S43 = 'S43';
    public static final String PRODUCT_BUNDLE = 'Bundle';
    public static final String ORDER_STATUS_SUBMITTED = 'Submitted';
    public static final String ASSETLINITEM_PREVMAIN = 'Preventive Maintenance';
    public static final String ASSETLINITEM_WATERFILTER = 'Water-Filter Change';
    
    //Agreement Value
    public static final String AGREE_STATUS_ACTIVATED = 'Activated';    
    public static final String AGREE_STATUS_AMEND = 'Being Amended';
    public static final String AGREE_STATUS_RENEW = 'Being Renewed';
    public static final String AGREE_STATUSCAT_EFFECT = 'In Effect';

    //SLA Value
    public static final String SLA_RESPONSE = 'Response Time';
    public static final String SLA_EXTENDEDDAYS = 'Extended Weekdays';
    public static final String SLA_STANDARDDAYS = 'Standard Weekdays';
    public static final String SLA_SATURDAY = 'Saturday';
    public static final String SLA_SUNDAY = 'Sunday';

    //Contract Trigger Cases
    public static final String PREVMAIN_NORMAL = 'Normal';
    public static final String PREVMAIN_CONTRACT = 'Contract';
    public static final String PREVMAIN_PERFORM = 'Perform preventive maintenance.';
    public static final String WATERFILTER_PERFORM = 'Perform a water-filter change';
    public static final String WFS_COVERAGE = 'Waterfilter Coverage';
    public static final String WFS_OPERATOR = 'Operator';
    public static final String WFS_ENGINEER = 'Engineer';
    public static final String CASE_MODIFICATION = 'Modification';
    public static final String TASK_SUBJ_ACCOUNTBLOCKED = 'Can Account Block be lifted';
    public static final String TASK_DESC_ACCOUNTBLOCKED = 'Please verify if the Account Block can be lifted and provide feedback.';
    public static final String WOLI_LOADID_INSTALL = 'INSTALL-';
    public static final String WOLI_LOADID_DEINSTALL = 'DEINSTALL-';
    public static final String WOLI_LOADID_PICKUP = 'PICKUP-';
    public static final String WOLI_LOADID_DROPOFF = 'DROPOFF-';
    public static final String WOLI_SBJDESC_DROPOFF = 'Drop-Off Machine';
    public static final String WOLI_SBJDESC_PICKUP = 'Pick-Up Machine';
    public static final String WOLI_SBJDESC_DEINSTALLATION = 'DeInstallation';
    public static final String WOLI_SBJDESC_INSTALLATION = 'Installation';
    public static final String LOADID_TEXT_CASE = 'CASE';
    public static final String LOADID_TEXT_WO = 'WO';
    public static final String TASKSOURCE_SC = 'SC';
    public static final String TASK_SUBJ_ACCOUNTRELEASE = 'Account Block Release Request';
    public static final String TASK_TOUCHPOINT_ACCOUNTRELEASE = 'ACCOUNT BLOCK RELEASE REQUEST';
    public static final String TASK_TYPE_CASE = 'Case';
    public static final String TASK_SUBJ_DONOTCHANGE = 'Do not change.';
    public static final String TASKGUIDANCE_ACCBLOCK = 'Preventive maintenance request on Account with Account Block';
    public static final String TASKGUIDANCE_ACCBLOCK_WATER = 'Waterfilter Change request on Account with Account Block';

    //WOLI Values
    public static final String WO_BILLING = 'Work Order SAP -Billing Interface';

    //Route Sales Values
    public static final String ROUTESALES_DESCSUBJ = 'Routesales Batch';
    public static final String TS_WOLI_RECTYPE_ROUTESALES = 'Routesales Task';
    public static final String PA_RECTYPE_MACHINE = 'Machine';
    public static final String PA_RECTYPE_OPTION = 'Option';

    //Error Messages
    public static final String ERRBATCH_MSG_01 = '### The following error has occurred: ';
    public static final String ERRBATCH_MSG_02 = '### Total number of failed records: ';
    public static final String ERRBATCH_MSG_03 = '### BATCH ERROR: Business hours not properly setup for country settings with account location Id: ';
    public static final String ERRBATCH_MSG_04 = 'Force to throw an exception';

    //Resource object constants
    public static final String EMPSTAT_3 = '3';
    public static final String EMPSTAT_0 = '0';
    public static final String CLICK_USERCREATE = 'Click - Request to Create User';
    public static final String CLICK_USERDELETE = 'Click - Request to Deactivate User';
    public static final String PROFILE_PORTALUSER = 'JDE - END USER - STC COMMUNITY EXTERNAL';
    public static final String PROFILE_MOBILEUSER = 'JDE - END USER - STC MOBILE EXTERNAL';

    //Error Msgs
    public static final String ERRORMSG_EXECUTEENGR = 'You cannot assign two different third parties under the same work order';
    public static final String ERRORMSG_SURVEYINT_01 = 'You cannot submit a survey without all interviewee details.';
    public static final String ERRORMSG_SURVEYINT_02 = 'You cannot submit a survey with an interviewee but without an email';
    public static final String ERRORMSG_SURVEYINT_03 = 'The interviewee lookup and interviewee email fields should be populated';
    public static final String PREFIX_SAP = 'SAP_';

    public static final String FIRST_RESPONSE = 'First Response';
    public static final String CATSCODE_JDEP = 'JDEP';
    public static final String WOLI_LINENUMBER_00000001 = '00000001';
    public static final String INTERNALCOMPLETION_INTERNALORDERMISSING = 'SAP internal order is missing. Please check. ';
    public static final String INTERNALCOMPLETION_TIMETHRESHHOLDEXCEED = 'Validate dates and times.';

    public static final String RESOURCE_USERPROFILE_THIRDPARTY = 'Third Party Capacity';
    public static final String RESOURCE_USERPROFILE_TSRESOURCE = 'TS Resource';

    public static final String SHARING_ACCESSLEVEL_EDIT = 'Edit';
    public static final String SHARING_ACCESSLEVEL_READ = 'Read';
    public static final String SHARING_ACCESSLEVEL_NONE = 'None';
    public static final String SHARING_ROWCAUSE_MANUAL = 'Manual';

    public static final String ERRORMESSAGE_ONLYONEACTIVEJOB = 'You are not allowed to create the same type of job under this work order without closing the existing one.';
    public static final String FORCE_EXCEPTION = 'Force to throw an exception';
    
    public static final String ERRORMESSAGE_NOPBENTRY = 'This product is not in your country’s price list. Please contact your administrator.';
    public static final String ERRORMESSAGE_NOCOUNTRYSETTING = 'Please contact your administrator to activate the purchasing settings for your company.';
    public static final String ERRORMESSAGE_NOTRELEVANT = 'You are not allowed to order part that is not relevant in your country.';
    
    public static final String ACTIVE = 'Active';

    //Account Location Values
    public static final String ACLOC_ROUTESALES_FLUSHINGVALUES = 'RouteSales_Flush_Account_Location_Field';

    //Physical Asset Values
    public static final String PA_SERVICESFIELDVALUES = 'ServicesFieldValues';
    public static final String PA_OPERATIONALDATAFIELDVALUES = 'OperationalDataFieldValues';
    public static final String ERROR_MESSAGE_UNABLE_TO_UPDATE_SERIALNUMBER = 'Serial number change is not allowed when there is an open order for the machine.';

    //Meter Reading Data
    public static final String METERREADING_WORKORDERCREATED = '2';
    public static final String METERREADING_YES = 'Yes';
    public static final String METERREADING_NO = 'No';
    public static final String METERREADING_ASSETTHRESHOLD_ERROR = 'Unable to process more than 10 distinct physical assets.';

    //FIELD SETS
    public static final String CONST_WOLITASK_FIELDSET= 'ClickWOLIFieldSet';
    public static final String CONST_WOLI_OP_TASK_FIELDSET= 'OperatingTask';
    public static final String CONST_WOLI_ROUTESALES_FIELDSET= 'RouteSales';

    //COUNTRY SETTING STRING
    public static final String NO_CONTRACT = 'No Contract'; 
    public static final String NA = 'N/A';

    //Routesales batch string
    public static final String CONST_THROW = 'Force to throw an exception';
    public static final String CONST_EEEE = 'EEEE';
    public static final String CONST_SUNDAY = 'Sunday';
    public static final String CONST_MONDAY = 'Monday';
    public static final String CONST_SATURDAY = 'Saturday';
    public static final String CONST_EEEEE = 'EEEEE';
    public static final String CONST_BATCH = 'TS_RouteSalesBatch';
    public static final String CONST_SAP_0333 = 'SAP_0333';
    public static final String CONST_SAP_6712 = 'SAP_6712';
    
    public static final String TS_CountrySettingRecType_RouteSales = 'RouteSalesSetting';
    public static final String TS_CountrySettingRecType_CountryDefBusHrs = 'CountryDefaultBusinessHours';
    public static final String TS_Status_Open = 'Open';
    public static final String TS_Type_Task = 'Task';
    public static final String TS_Case_SubType_S25 = 'S25';
    public static final String TS_Status_New = 'New';
    public static final String TS_Case_Type_RouteSales = 'Routesales';
    public static final String TS_CaseOrigin_RouteSalesBatch = 'Routesales Batch';
    public static final String TS_SLA_Monday = 'Monday';
    public static final String TS_SLA_Friday = 'Friday';
    public static final String TS_SalesOrg_Netherlands = 'SAP_0111';
    public static final String TS_SalesOrg_Denmark = 'SAP_0975';
    public static final String TS_SLA_Saturday = 'Saturday';
    public static final String TS_SLA_Sunday = 'Sunday';
    public static final String TS_ConFunction_ServiceContact = 'Service Contact';

    public static final String CONST_START = 'start';
    public static final String CONST_EXECUTE = 'execute';
    public static final String CONST_FINISH = 'finish';
    public static final String CONST_CREATEWOLI = 'createWorkOrderLineItem';
    public static final String CONST_CREATECASE = 'createCaseRecords';
    public static final String CONST_STARTENDDATES = 'getStartAndEndDates';
    public static final String CONST_GETCOUNTRY = 'getCountrySettings';
    public static final String CONST_GETCONDATE ='getConfirmationDate';
    public static final String CONST_GETACCLOC = 'getAccLocContactList';

    //Prev Maintenance batch strings
    public static final String TS_Order_Type_New = 'New';
    public static final String TS_CountrySettingRecType_ConTriggerSet = 'ContractTriggerSetting';  
    public static final String TS_Case_SubType_PrevMain = 'S30';
    public static final String TS_Case_Type_FieldService = 'Field Service';    
    public static final String TS_Assetlinitem_PrevMain = 'Preventive Maintenance';
    public static final String TS_Case_Origin_ContractOrder = 'Contract Order';
    public static final String TS_Status_InProgress = 'In Progress';
    public static final String CONST_PREVCON = 'PrevMaintenanceConTriggerBatch';
    public static final String CONST_GETPA = 'getPAsContactList';
    public static final String CONST_CREATEREC = 'createCaseRecords';   
    public static final String CONST_2345 = '23:45';

    //WaterFilterBatch Strings
    public static final String TS_Activity_Type_S32 = 'S32';
    public static final String TS_Assetlinitem_WaterFilter = 'Water-Filter Change';
    public static final String CONST_WATERFILTER = 'WaterFilterChangeConTriggerBatch';
    public static final String TS_RECORDTYPENAME_COUNTRYSETTING_MERGEWTS = 'MergeWTSwithPreventiveMaintenance';
    
    //Task creation
    public static final Boolean ORDER_TRUE = true;
    public static final String TASK_TT_AFTINSTAL = 'AFT INSTAL';
    public static final String TASK_TYPE_OUTBOUNDNONCOMMERCIAL = 'Outbound Non-commercial';
    public static final String TASK_TASKSOURCE_SFDC = 'SFDC';
    public static final String TASK_AFTERINSTALLATION = ' AFTER INSTALLATION ';
    public static final String TASK_SPACE = ' ';

    //Custom Logging (Batch)
    public static final String PREVMAIN_BATCH = 'PrevMaintenanceConTriggerBatch: Update Physical Asset';
    public static final String WATERFILTER_BATCH = 'WaterFilterChangeConTriggerBatch: Update Physical Asset';
    public static final String ROUTESALES_BATCH = 'TS_RouteSalesBatch: Update Account Location';
    public static final String OPERATING_WEEKLY_BATCH = 'TS_CreateTask_Batch: Update Operating Schedule';
    public static final String FAILEDRECORDS = 'Failed Records: ';
    public static final String DATABASE_ERROR = 'Database.Error';

    //Day short format
    public static final String FRI = 'Fri';
    public static final String SAT = 'Sat';
    
    //Schedule Type
    public static final String REGULAR = 'Regular';
    
    //Asset Status
	public static final String CANCELLED = 'Cancelled';
    
    //Machine Care
    public static final String FULL_OPERATING = 'Full Operating';
    public static final String COMFORT_OPERATING = 'Comfort Operating';
    public static final String MACHINE_CLEAN_OPERATING = 'Machine Clean Operating';
    public static final String EOD_BATCH = 'EoD Batch';

    //Case Cancelation Reason
    public static final String WTS_PERFORMED = 'WTS already performed.';

    //Woli Cancelation Reason
    public static final String MACHINE_TO_BE_DEINSTALLED = 'Machine to be de-installed';
    public static final String MACHINE_DEINSTALLED = 'Machine de-installed';

    //Operating MTTO
    public static final String RECALCULATE_SUCCESS = 'Success';
    public static final String RECALCULATE_SUCCESS_MESSAGE = 'Recalculation has been successfully queued. Please check again later for the latest report.';
    public static final String RECALCULATE_ERROR = 'Error';
    public static final String RECALCULATE_ERROR_MESSAGE = 'Recalculation for another region is in progress or the queue is full. Please try again later.';
    public static final String GENERAL_ERROR = 'ERROR';
    public static final String GENERAL_SUCCESS = 'SUCCESS';
    public static final String ERROR_MESSAGE_NOACCOUNTLOCATIONFOUND = 'No account location assigned to this team found.';
    public static final String ERROR_MESSAGE_ALLMACHINEOPERATINGSCHED = 'All machines on this region have an Operating Schedule.';
    public static final String ERROR_MESSAGE_ALLMACHINEASSIGNED = 'All machines on this region are assigned to a route accordingly.';
    public static final String ERROR_MESSAGE_NOROUTES = 'All customers on this region has designated route/s.';

    //Knowledge article
    public static final String KAV_TYPE_TROUBLESHOOTING = 'Troubleshooting';
    public static final String KAV_TYPE_TECHNICALINFORMATION = 'Technical';
    public static final String KAV_TYPE_GENERICREQUESTS = 'Generic Requests';

    //Activity Type Strings
    public static final String ACTIVITY_LARGE = 'Large';
    public static final String ACTIVITY_BOTTLE = 'Bottle';
    public static final String ACTIVITY_PM = 'Preventive Maintenance';
    public static final String ACTIVITY_WATERFILTER = 'Waterfilter';
    public static final String ACTIVITY_DESCALING = 'Descaling';
    public static final String ACTIVITY_INGREDIENTS = 'Ingredients'; 
    public static final String ACTIVITY_CUPS = 'Cups';
    public static final String ACTIVITY_SMALL = 'Small';
    public static final String ACTIVITY_RINSE = 'Rinse';
    public static final String ACTIVITY_PW = 'PW';
    public static final String ACTIVITY_REFILL = 'Refill';
    
    //Operating Schedule Frequency
    public static final String FREQUENCY_DAILY = 'Daily';
    public static final String FREQUENCY_WEEKLY = 'Weekly';
    public static final String FREQUENCY_MONTHLY = 'Monthly';
    public static final String ERROR_MESSAGE_STARTDATE = 'Please use the Monday one week earlier or later.';
    public static final Date SYSTEM_START_DATE = Date.newInstance(2019,1,28);

    //Rule Type Strings
    public static final String RULE_MODIFY_EARLY_START = 'Modify Early Start';

    //Material Status
    public static final String SAP_01 = 'SAP_01';
    public static final String SAP_03 = 'SAP_03';
    public static final String SAP_04 = 'SAP_04';
    public static final String SAP_05 = 'SAP_05';
    public static final String SAP_07 = 'SAP_07';

    //Material Warranty
    public static final String WARRANTY_NONE = 'None';
    public static final String WARRANTY_K1 = 'K1'; //Under Warranty
    public static final String WARRANTY_YR = 'YR'; //Covered by Contract
    public static final String WARRANTY_Z1 = 'Z1'; //Coulance (Goodwill)
    public static final String WARRANTY_C1 = 'C1'; //To be paid by Customer
    public static final String WARRANTY_DEFAULT = 'Default';

    //Sales Org Strings
    public static final String SAP_6864 = 'SAP_6864';
    public static final String SAP_0975 = 'SAP_0975';    

    //Operating Hours
    public static final String EXCEPTIONAL_OH = 'Exceptional Operating Hours';
    public static final String REGULAR_OH = 'Regular Operating Hours';

    //Object API Names
    public static final String OBJ_PHYSICALASSET = 'PhysicalAsset__c';

    //Waterfilter Suggestion Strings
    public static final String SUGGESTION_1 = 'Allowed to change WF ';
    public static final String SUGGESTION_2 = 'Change WF ';
    public static final String SUGGESTION_3 = 'WF normally changed during PM ';

    //Journey Trigger Types
    public static final String CASE_CREATE = 'Case Create';
    public static final String CASE_CANCELATION = 'Case Cancelation';
    public static final String CASE_CLOSURE_FIXED_BY_PHONE = 'Case Closure - Fixed by Phone';

    //Journey Trigger Subtypes
    public static final String CASE_CLOSURE_NOTIF_STAKEHOLDER = 'Case Closure Notification to Stakeholder';
    public static final String CASE_CANCEL_NOTIF_STAKEHOLDER = 'Case Cancelation Notification to Stakeholder';
    public static final String CASE_CREATION_NOTIF_STAKEHOLDER = 'Case Creation Notification to Stakeholder';
    public static final String CASE_CLOSURE_NOTIF_KNOWN_CUSTOMER = 'Case Closure Notification to Known Customer';
    public static final String CASE_CANCEL_NOTIF_KNOWN_CUSTOMER = 'Case Cancelation Notification to Known Customer';
    public static final String CASE_CREATION_NOTIF_UNKNOWN_CUSTOMER = 'Case Creation Notification to Unknown Customer';
    public static final String CASE_CREATION_NOTIF_KNOWN_CUSTOMER = 'Case Creation Notification to Known Customer';

    //Sending Methods
    public static final String SEND_VIA_MC = 'Send via MC';
    public static final String SEND_VIA_SF_PLATFORM = 'Send via Salesforce Platform';

    //Contact Communication Preference
    public static final String EMAIL = 'Email';

    //Email Template Name
    public static final String STAKEHOLDER_NOTIF_OPEN = 'TS_Stakeholder_Notification_Case_Open';
    public static final String CASE_CREATION_UNKNOWN_CUSTOMER = 'TS_CaseCreationForAnUnknownCustomer';
    public static final String CASE_CREATION_KNOWN_CUSTOMER = 'TS_CaseCreationForAKnownCustomer';

    //Email Template Type
    public static final String ACKNOWLEDGEMENT = 'Acknowledgement';
    public static final String STAKEHOLDER = 'Stakeholder';

    //Contact creation field value
    public static final String UNKNOWN_CONTACT = 'Unknown Contact';
	public static final String PORTALUSER_PROFILE = 'Customer Portal User';
    public static final String PARTNERCOMMUNITY_LICENSE = 'Partner Community';
    public static final String CUSTOMERCOMMUNITY_LICENSE = 'Customer Community';
    
    //Feed Types
    public static final String TEXTPOST = 'TextPost';
    public static final String CASECOMMENTPOST = 'CaseCommentPost';
}