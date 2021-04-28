/*
* @author        Xen Reyes
* @date          05.4.2018
* @description   Controller class for TS_BookAppointVisualforce
* @revision(s)
*/
public with sharing class TS_BookAppointmentVisualforceController{
    public String result {get; set;}
    public String lcBaseURL {get; set;}
    Message message;
    AsyncGetAvailableSlots.GetAvailableSlotsResponse_elementFuture availableSlotFuture;
    AsyncGetAvailableSlots.ProcessSlotResponse_elementFuture processSlotResponse;
    
    public class Message {
        public Boolean isRequest {get; set;}
        public Boolean isSelect {get; set;}
        public String recordId {get; set;}
        public String start {get; set;}
        public String finish {get; set;}
        public Integer dateYear {get; set;}
        public Integer dateMonth {get; set;}
        public Integer dateDay {get; set;}
        public Integer startHour {get; set;}
        public Integer startMinute {get; set;}
        public Integer endHour {get; set;}
        public Integer endMinute {get; set;}
        public String woliId {get; set;}
        public String jdeLine {get; set;}
    }
    
    public TS_BookAppointmentVisualforceController(){
         system.debug('BASEURL' + lcBaseURL);
        if(System.Site.getSiteTypeLabel() == 'Community'){
            lcBaseURL = 'https://' + System.URL.getSalesforceBaseUrl().getHost();
        } else {
            String hostURL = System.URL.getSalesforceBaseUrl().getHost().split('\\.')[0].replace('--c','');
            lcBaseURL = 'https://' + hostURL + '.lightning.force.com';
        }

        System.debug(System.Site.getSiteTypeLabel());
        System.debug(lcBaseURL);
    }
    
    public Continuation startRequest(){
        CustomLogging.push('startRequest', 'TS_BookAppointmentVisualforceController');
        message = (Message) JSON.deserialize(ApexPages.currentPage().getParameters().get('message'), Message.class);
        Continuation cont = new Continuation(60);
        cont.continuationMethod = 'processResponse';
        AsyncGetAvailableSlots.AsyncJDEServiceOptimizationPort port =  new AsyncGetAvailableSlots.AsyncJDEServiceOptimizationPort();
        
        //SEARCH SLOTS
        if(message.isRequest){
            GetAvailableSlotResultWrapper results = getAvailableSlotsForWOLI(message.recordId, message.start, message.finish);
            availableSlotFuture = port.beginGetAvailableSlots(cont, results.taskType, '4hr Slots' , results.timeInterval);
            System.debug(availableSlotFuture);
        }
        //SELECT SLOT
        else if(message.isSelect){
            List<GetAvailableSlots.Tasks> tasks = getTasks();
            processSlotResponse = port.beginProcessTask(cont, tasks);
            System.debug(processSlotResponse);
        }
        
        CustomLogging.pop();
        return cont;
    }
    
    public Object processResponse(){
        CustomLogging.push('processResponse', 'TS_BookAppointmentVisualforceController');
        //SEARCH SLOTS
        if(message.isRequest){
            GetAvailableSlots.TimeIntervalTypeList timeintervalList = availableSlotFuture.getValue();
            Integer ctr = 0;
            Map<String, AvailableSlotsWrapper> availableTimeSlotMap = new Map<String, AvailableSlotsWrapper>();
            if (timeintervalList.TimeInterval != null) {
                for (GetAvailableSlots.TimeIntervalType timeInterval1 : timeintervalList.TimeInterval) {
                    ctr++;
                    String[] startTimeSlot = timeInterval1.Start.Split('T');
                    String[] endTimeSlot = timeInterval1.Finish.Split('T');
                    
                    if (availableTimeSlotMap.containsKey(startTimeSlot[0])) {
                        AvailableSlotsWrapper wrap = availableTimeSlotMap.get(startTimeSlot[0]);
                        AvailableTimeWrapper timeWrap = new AvailableTimeWrapper();
                        timeWrap.startTime = startTimeSlot[1];
                        timeWrap.endTime = endTimeSlot[1];
                        wrap.startEndTime.add(timeWrap);
                    } else {
                        AvailableSlotsWrapper wrap = new AvailableSlotsWrapper();
                        wrap.slotDate = startTimeSlot[0];
                        AvailableTimeWrapper timeWrap = new AvailableTimeWrapper();
                        timeWrap.startTime = startTimeSlot[1];
                        timeWrap.endTime = endTimeSlot[1];
                        wrap.startEndTime = new List<AvailableTimeWrapper>();
                        wrap.startEndTime.add(timeWrap);
                        availableTimeSlotMap.put(startTimeSlot[0], wrap);
                    }
                    if (ctr > 20) {
                        break;
                    }            
                }
            }
            
            AvailableSlotsMainWrapper mainResult = new AvailableSlotsMainWrapper();
            mainResult.availableTimeSlotMap = availableTimeSlotMap;
            mainResult.fromRequest = true;
            mainResult.isSelect = false;
            result = JSON.serialize(mainResult);
        }
        //SELECT SLOT
        else if(message.isSelect){

            System.debug(processSlotResponse);
            System.debug(processSlotResponse.getValue());
            Boolean isSuccess = processSlotResponse.getValue();
            SelectResult selectResult = new SelectResult();
            selectResult.result = isSuccess;
            selectResult.fromRequest = false;
            selectResult.isSelect = true;
            result = JSON.serialize(selectResult);
            
            //Update task in salesforce
            if(isSuccess){
                Datetime bookAppointmentStart = Datetime.newInstance(message.dateYear, message.dateMonth, message.dateDay, message.startHour, message.startMinute, 0);
                Datetime bookAppointmentFinish = Datetime.newInstance(message.dateYear, message.dateMonth, message.dateDay, message.endHour, message.endMinute, 0);
                WorkOrderLineItem woli = new WorkOrderLineItem(Id = message.woliId, BookAppointmentStart__c = bookAppointmentStart, BookAppointmentFinish__c = bookAppointmentFinish);
                update woli;
            }
        }
        
        CustomLogging.pop();
        return null;
    }
    
    //================================================== START: SEARCH SLOTS RELATED CLASSES AND METHODS ==================================================
    
    public class AvailableSlotsMainWrapper {
        public Map<String, AvailableSlotsWrapper> availableTimeSlotMap;
        public Boolean fromRequest;
        public Boolean isSelect;
    }
    
    public class AvailableSlotsWrapper {
        public String slotDate;
        public List<AvailableTimeWrapper> startEndTime;
    }
    
    public class AvailableTimeWrapper {
        public String startTime;
        public String endTime;
    }
    

    public static GetAvailableSlotResultWrapper getAvailableSlotsForWOLI(Id StandardId, String startTime, String finishTime) {
        CustomLogging.push('getAvailableSlotsForWOLI', 'TS_BookAppointmentVisualforceController');
        GetAvailableSlotResultWrapper resultSlotWrapper = new GetAvailableSlotResultWrapper();
        WorkOrderLineItem woli = [  SELECT  EarlyStart__c,
                                            WorkOrderLineItemType__c,
                                            JDELineItemNumber__c,
                                            SLADate__c,
                                            WorkOrderType__c,
                                            Case__r.OutsideSLA__c, 
                                            Pricebookentry.Product2.ProductCode,
                                            LatestAppointmentTime__c,
                                            EarliestAppointmentTime__c,
                                            CreatedDate,
                                            ProductCode__c,
                                            SmokingArea__c,
                                            AccountLocation__r.Screening_Required__c,
                                            ScheduleManually__c,
                                            AccountLocation__r.Apttus_Config2__PostalCode__c,
                                            AccountLocation__r.Shipping_Country_ISO__c,
                                            AccountLocation__r.Apttus_Config2__City__c,
                                            AccountLocation__r.Shipping_Street_Only__c,
                                            AccountLocation__r.Shipping_State__c,
                                            ExcludedEngineer__c,
                                            RequiredEngineer__c,
                                            RequiredEngineer__r.Name,
                                            Calendar__c, //added 15 May 2018
                                            AccountLocation__r.SAP_Customer_ID__c, //added 15 May 2018
                                            IgnoreCalendar__c  //added 15 May 2018
                                            
                                    FROM WorkOrderLineItem WHERE Id =: StandardId];
        
        ValidationWrapper valFields = validateRequiredFields(woli);
        if (valFields.result) {
            
            GetAvailableSlots.GetSlotsTaskType taskType = new GetAvailableSlots.GetSlotsTaskType();
            GetAvailableSlots.TimeInterval_element timeInterval = new GetAvailableSlots.TimeInterval_element();

            taskType.CallID =  woli.JDELineItemNumber__c;        
            taskType.OpenDate =  formatDateTime(woli.CreatedDate);

            taskType.EarlyStart = startTime;
            taskType.SLA =  finishTime;
            timeInterval.Start = taskType.EarlyStart;
            timeInterval.Finish = taskType.SLA; 

            taskType.Postcode = woli.AccountLocation__r.Apttus_Config2__PostalCode__c ;
            taskType.Country =  woli.AccountLocation__r.Shipping_Country_ISO__c;     
            taskType.City =    woli.AccountLocation__r.Apttus_Config2__City__c;
            taskType.Street =  woli.AccountLocation__r.Shipping_Street_Only__c;            
            taskType.State =  woli.AccountLocation__r.Shipping_State__c; 
            taskType.TaskType = woli.WorkOrderType__c;
            taskType.ManualSchedule =  woli.ScheduleManually__c;
            taskType.ScreeningRequired = woli.AccountLocation__r.Screening_Required__c;
            taskType.SmokingArea = woli.SmokingArea__c;        
            taskType.Calendar = woli.Calendar__c;
            taskType.CustomerNumber =woli.AccountLocation__r.SAP_Customer_ID__c;
            taskType.NotNeedCalendar=woli.IgnoreCalendar__c;
            taskType.FaultConfiguration = woli.ProductCode__c; //Karen Hung DOO-5420 18/3/2021 get from woli
            
            //Karen Hung DOO-5420 18/3/2021 get from woli
            if (woli.ProductCode__c != null) {
                GetAvailableSlots.MachineList_element MachineList = new GetAvailableSlots.MachineList_element();
                MachineList.Machine = new List<GetAvailableSlots.Machine_element>();
                GetAvailableSlots.Machine_element mac = new GetAvailableSlots.Machine_element();
                mac.MachineType = woli.pricebookentry.product2.ProductCode;
                MachineList.Machine.add(mac);
                taskType.MachineList = MachineList;  
            }

            taskType.SmokingArea = woli.SmokingArea__c;           
            
            if (!String.isBlank(woli.ExcludedEngineer__c)) {
                GetAvailableSlots.ExcludedEngineers_element excludedEngr = new GetAvailableSlots.ExcludedEngineers_element();
                excludedEngr.EngineerID = new List<String>();
                excludedEngr.EngineerID.add(woli.ExcludedEngineer__c);
                taskType.ExcludedEngineers = excludedEngr;
            }
            
            if (!String.isBlank(woli.RequiredEngineer__c)) {
                GetAvailableSlots.RequiredEngineers_element reqEngr = new GetAvailableSlots.RequiredEngineers_element();
                reqEngr.EngineerID = new List<String>();
                reqEngr.EngineerID.add(woli.RequiredEngineer__r.Name);
                taskType.RequiredEngineers = reqEngr;
            }
            
            resultSlotWrapper.taskType = taskType;
            resultSlotWrapper.timeInterval = timeInterval;
            resultSlotWrapper.fieldValidation = valFields;
        } else {
            resultSlotWrapper.fieldValidation = valFields;
        }
		
        CustomLogging.pop();
        return resultSlotWrapper;
    }
    
    public class GetAvailableSlotResultWrapper {
        public GetAvailableSlots.GetSlotsTaskType taskType;
        public GetAvailableSlots.TimeInterval_element timeInterval;
        public ValidationWrapper fieldValidation;
    }
    
    static String formatDateTime(DateTime valueDateTime) {
        CustomLogging.push('formatDateTime', 'TS_BookAppointmentVisualforceController');
        String result = '';
        if (valueDateTime != null) {
            result = valueDateTime.format('YYYY-MM-dd') + 'T' + valueDateTime.format('hh:mm:ss');
        }
        
        CustomLogging.pop();
        return result;
    }
    
    static ValidationWrapper validateRequiredFields(WorkOrderLineItem woli) {
        CustomLogging.push('validateRequiredFields', 'TS_BookAppointmentVisualforceController');
        List<String> errorMessageList = new List<String>();
        ValidationWrapper validationResult = new ValidationWrapper();
        
        if(String.isBlank(woli.AccountLocation__r.Apttus_Config2__PostalCode__c ) )  {
            errorMessageList.add( 'Postal Code in the Account Location' );
        } 
        
        if(String.isBlank(woli.AccountLocation__r.Apttus_Config2__City__c) )  {
            errorMessageList.add( 'City in the Account Location' );
        }            
        
        if(String.isBlank(woli.AccountLocation__r.Shipping_Street_Only__c) )  {
            errorMessageList.add( 'Street in the Account Location' );
        } 
        
        if(String.isBlank(woli.AccountLocation__r.Shipping_Country_ISO__c) )  {
            errorMessageList.add( 'Country in the Account Location' );
        }  
        
        if (String.isBlank(woli.JDELineItemNumber__c)) {
            errorMessageList.add( 'JDE Line Item Number' ); 
        }
        
        if (String.isBlank(woli.WorkOrderLineItemType__c)) {
            errorMessageList.add( 'Activity Type' );
        }
        
        //Karen Hung DOO-5420 18/3/2021 get from woli
        if (woli.ProductCode__c == null) {
            errorMessageList.add( 'Product Code in the Task' );
        }
        
        if (!errorMessageList.isEmpty()) {
            validationResult.errorMessage = 'Error: These fields are missing: ' + String.join(errorMessageList, ', ');
            validationResult.result = false;
        } else {
            validationResult.result = true;
        }
        
        CustomLogging.pop();
        return validationResult;
    }
    
    public class ValidationWrapper {
        public Boolean result;
        public String errorMessage;
    }
    
    //================================================== END: SEARCH SLOTS RELATED CLASSES AND METHODS ==================================================
    
    //================================================== START: SELECT SLOT RELATED CLASSES AND METHODS ==================================================
    
    List<GetAvailableSlots.Tasks> getTasks(){
        CustomLogging.push('getTasks', 'TS_BookAppointmentVisualforceController');
        Datetime myDate1 = Datetime.newInstanceGmt(message.dateYear, message.dateMonth, message.dateDay, message.startHour, message.startMinute, 0);
        Datetime myDate2 = Datetime.newInstanceGmt(message.dateYear, message.dateMonth, message.dateDay, message.endHour, message.endMinute, 0);
        List<GetAvailableSlots.Tasks> listTask = new List<GetAvailableSlots.Tasks>();
        GetAvailableSlots.Tasks taskToCheck = new GetAvailableSlots.Tasks();
        taskToCheck.CallID = message.jdeLine;
        taskToCheck.AppointmentStart = myDate1;
        taskToCheck.AppointmentFinish = myDate2;
        listTask.add(taskToCheck);
        CustomLogging.pop();
        return listTask;
    }
    
    public class SelectResult {
        public Boolean result;
        public Boolean fromRequest;
        public Boolean isSelect;
    }
    
    //================================================== END: SELECT SLOT RELATED CLASSES AND METHODS ==================================================
    
    //================================================== START: LIGHTNING COMPONENT RELATED METHODS =================================================
    
    @AuraEnabled
    public static DateTime getCurrentDateTime(){
        CustomLogging.push('getCurrentDateTime', 'TS_BookAppointmentVisualforceController');
        CustomLogging.pop();
        return System.now();
    }

    @AuraEnabled
    public static List<WorkOrderLineItem> getOpenTasks(String recordId){
        CustomLogging.push('getOpenTasks', 'TS_BookAppointmentVisualforceController');
        Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();
        List<WorkOrderLineItem> jobsList = new List<WorkOrderLineItem>();
        if(recordId != NULL){
            try{
                jobsList = [SELECT Id, Quantity, BookAppointmentStart__c, BookAppointmentFinish__c, WorkOrderLineItemNumber__c, JDELineItemNumber__c, toLabel(WorkOrderType__c), WorkOrderLineItemType__c, PhysicalAsset__c, PhysicalAsset__r.Name, PricebookEntryId, PricebookEntry.Name, Status, ParentWorkOrderLineItemId, ParentWorkOrderLineItem.WorkOrderLineItemNumber__c 
                            FROM WorkOrderLineItem WHERE Case__c =: recordId AND RecordTypeId =: taskId AND (Status = 'Open' OR Status = 'Scheduled')];
                
            } catch(exception e){
                System.debug(e.getMessage());
            }
        }
        
        CustomLogging.pop();
        return jobsList;
    }
    
    //================================================== END: LIGHTNING COMPONENT RELATED METHODS =================================================
}