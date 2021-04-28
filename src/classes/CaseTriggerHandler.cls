/**
* @author        Anna Gonzales
* @date          5.1.2017           
* @description   Class responsible for the trigger business logic of Case object
* @revision(s)   11.08.2017 Paul Aguiling: KTS-365 Added closeFieldServiceFirstResponse methods
*                11.15.2017 Paul Aguiling: KTS-363 Added updateCaseStatusViaFirstResp methods  
*                12.04.2017 Paul Aguiling: Updated getFromAddressAndDefaultOwner(), updateCaseWOStatus(), 
*                                          and updateWOLIScheduleDate()
*                1 December 2017 Archi Delphinanto: added calculateFSdowntime() and  calculate_BI_Time()
*                2.27.2018  Paul Aguiling: KTS-1477 and KTS-1472 Added caseCancellation and assignRecordType method
*                3.21.2018  Paul Aguiling: Added validateClosedAndConvertedCases method
*                3.26.2018  Marvin Gatchailan: Enhancement, moved logic of TS_Change Work Order Owner to Case Owner 
*                3.27.2018  Marvin Gatchailan: Enhancement, moved logic of TS_Case Routing Settings in Before Insert/Update
*                4.6.2018   Archi Delphinanto: Update method calculate_BI_Time in calculating business hours to use --> TS_BusinessHour_Calculation.calculateBusinessHourBetweenDatesBr 
*                4.25.2018  Paul Aguiling: KTS-1684 Added updateSalesOrganization() and commented updateCaseRecord()
*                5.16.2018  Paul Aguiling: KTS-1472 Updated assignRecordType()
*                9.18.2018  Karen Hung : comment out sendWorkOrderSummarySalesOrder in after update
*/
public with sharing class CaseTriggerHandler implements ITriggerHandler {

    private static Boolean beforeUpdateRunOnce = true;
    private static Boolean afterUpdateRunOnce = true;
    public static Boolean isTriggerDisabled = true;
    public static Boolean caseEntitlementRunOnce = true;
    public static Boolean hasException = false;
    public static Boolean emailToCase = false;
    public static Integer processedEmail = 0;
    public static List<Entitlement> list_Entitlements = new List<Entitlement>();
    public static List<CountrySetting__c> list_CountrySettings = new List<CountrySetting__c>();
    private Id caseRecTypeId = null;
    public static Map<Id, SObject> dummysObjectMap = new Map<Id, SObject>();
    User CURRENTUSER = null;
    //private static user CURRENTUSER;

    //XEN REYES Nov. 13, 2018 - Method muting static variable for batches (Waterfilter, Prev. Maintenance)
    public static Boolean isNotBatchExecution = true;

    //XEN REYES Static Record Type Variables
    public static Id CASE_FIELDSERVICE_DEFAULT_RECORDTYPEID = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_FIELDSERVICE_DEFAULT);
    public static Id CASE_FIELDSERVICE_CONTRACT_RECORDTYPEID = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_FIELDSERVICE_CONTRACT);
    public static Id CASE_FIELDSERVICE_SALES_RECORDTYPEID = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_FIELDSERVICE_SALES);
    public static Id CASE_CUSTOMERCARE_RECORDTYPEID = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_CUSTOMERCARE);
    public static Id CASE_COMPLAINT_RECORDTYPEID = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_COMPLAINT);
    public static Id CASE_QUALIFYCASE_RECORDTYPEID = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_QUALIFYCASE);
    public static Id CASE_CASEREG_RECORDTYPEID = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_CASEREG);
    public static Id CASE_MODIFICATION_RECORDTYPEID = TS_UtilityClass.getRecordTypeIdByName(TS_Constants.OBJ_APINAME_CASE, TS_Constants.TS_CASE_RECORDTYPE_MOD);

    //Xen Reyes June 26, 2019
    public static Boolean IS_RETURN_NEEDED = false;
    
    //Francis Allen Alindogan DOO-4676 09/04/2020
    public static Boolean IGNORE_CASEOWNER_CSETTING = false;

    public static Boolean CASE_CONVERTED = false;
    public static Boolean ASSIGNMENT_RULE_FIRED = false;
    
    /******************************************************************************
    * @author         Paul Jarred Aguiling
    * @date           07.06.2017
    * @description    Method responsible for throwing an exception
    * @revision(s)
    ******************************************************************************/ 
    public class TS_CaseTriggerHandlerException extends Exception {  }

    public void BeforeInsert(List<SObject> newItems) {      
        CustomLogging.push('BeforeInsert', 'CaseTriggerHandler');
        TS_UpdateRelatedCase relatedCase = new TS_UpdateRelatedCase();
        
        try {  
            if (CURRENTUSER == null)
                   CURRENTUSER = getUsers();

            if (caseRecTypeId == null)
                caseRecTypeId = CASE_MODIFICATION_RECORDTYPEID;
            
            updateSalesOrganization(newItems);
            getFromAddressAndDefaultOwner(newItems, dummysObjectMap);
            validateTasktobeCreated(newItems); //Karen Hung 3/19/2019 KTS-2664 

            //Logic for TS_Case Routing Settings. From process builder to Trigger
            relatedCase.caseRoutingSettingsForInsertedCase (newItems); 
    
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_CaseTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
        CustomLogging.pop();   
    }
     
    public void BeforeUpdate(List<SObject> newList, Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems) {  
        CustomLogging.push('BeforeUpdate', 'CaseTriggerHandler');
        TS_UpdateRelatedCase relatedCase = new TS_UpdateRelatedCase();
        
        try { 
                        
            //Logic for TS_Case Routing Settings. From process builder to Trigger
            relatedCase.caseRoutingSettingsForUpdatedCase (newList, oldMapItems); 
            
            getFromAddressAndDefaultOwner(newList, oldMapItems);
            
            if(isNotBatchExecution){ 
                updateCaseStatusViaFirstResp(newList, oldMapItems);  
                calculate_BI_Time(newList,  newMapItems, oldMapItems);
            }
                        
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_CaseTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
    }   
    
    public void BeforeDelete(List<SObject> oldList, Map<Id, SObject> oldItems){ }
    
    public void AfterInsert(List<SObject> newList, Map<Id, SObject> newMapItems){
        CustomLogging.push('AfterInsert', 'CaseTriggerHandler');
        
        try {
            
            if (CURRENTUSER == null) CURRENTUSER = getUsers();
            
            if(TS_UtilityClass.isSObjectAccessible(new String[]{TS_Constants.OBJ_APINAME_CASE}))
                TS_CaseAssignmentRuleToggle.fireAssignmentRuleBulkUpdate(newList, false, null);
            
            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_CaseTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
            }        

            List<Case> caseListBulk = new List<Case>();
            for (Case cseRec: (List<Case>) newList) {
                if (cseRec.Type == TS_Constants.CASE_TYPE_FIELDSERVICE && cseRec.PhysicalAsset__c != null) {
                    caseListBulk.add(cseRec); 
                }
            }

            if (!caseListBulk.isEmpty()) {
                Map<String, Object> flowMap = new Map<String, Object>();
                flowMap.put('CaseCollection',caseListBulk);

                Flow.Interview.TS_RepeatVisist myFlow = new Flow.Interview.TS_RepeatVisist(flowMap);
                myFlow.start();  
                List<Case> listCase = (List<Case>) myFlow.getVariableValue('SetCaseCollection');
            }
            
            if(TS_UtilityClass.isSObjectAccessible(new String[]{TS_Constants.OBJ_APINAME_CASE})){
                updateCaseEntitlement(newList, null);
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
    }
    
    public void AfterUpdate(List<SObject> newList , Map<Id, SObject> newMapItems, List<SObject> oldList, Map<Id, SObject> oldMapItems){
        CustomLogging.push('AfterUpdate', 'CaseTriggerHandler');

        //Please use the class and add action method specific to WorkOrder object, return the list and update here.
        TS_UpdateRelatedWorkOrder relatedWorkOrder = new TS_UpdateRelatedWorkOrder();
        List<WorkOrder> allWorkOrderToBeUpdated = new  List<WorkOrder>();        

        try {  

            if (afterUpdateRunOnce) {
                afterUpdateRunOnce = false;  
            }
            
            if(!ASSIGNMENT_RULE_FIRED && TS_UtilityClass.isSObjectAccessible(new String[]{TS_Constants.OBJ_APINAME_CASE})){
                TS_CaseAssignmentRuleToggle.fireAssignmentRuleBulkUpdate(newList, true, oldMapItems); //Includes the criteria for Case Qualification Routing
            }

            if(isNotBatchExecution){
                if(!CASE_CONVERTED) CONVERT_ORDER(newList, newMapItems, oldMapItems);
                updateCaseWOStatus(newList, oldMapItems);
                updateWOLIScheduleDate(newList, oldMapItems);//added by Archi 15 sep 2017 
                validateClosedAndConvertedCases(newList, oldMapItems);                
            }

            updateOrderLSPDates(newList, oldMapItems);

            //Karen Hung Oct 12, 2020 DOO-4969 invoke email sending  
            /*if(Boolean.valueOf(Label.TS_SendEmailCaseApex) == true /*&& processedEmail < 4){
                sendEmailFromCase(newList, oldMapItems);
            }*/  
           
            //need to have a seperate static variable because the email message trigger will run after the case is executed
            //if combine with other static variable, the case entitlement will not be stamp if the case is created via email
            if(caseEntitlementRunOnce) {
                caseEntitlementRunOnce = false;

                if (CURRENTUSER == null)
                CURRENTUSER = getUsers();
                
                if(TS_UtilityClass.isSObjectAccessible(new String[]{TS_Constants.OBJ_APINAME_CASE}))
                    updateCaseEntitlement(newList, oldMapItems);
                
                closeFieldServiceFirstResponse(newList, oldMapItems);
            }
            
            List<TS_Feature_Flag__mdt > ffList = [SELECT Id, QualifiedApiName, Enable__c FROM TS_Feature_Flag__mdt WHERE QualifiedApiName = 'DOO_4969' LIMIT 1];
            if((!ffList.isEmpty() && ffList[0].Enable__c) || Test.isRunningTest()){
                sendEmailFromCase(newList, oldMapItems);
            }           
            
            //Below class/method is the implementation of TS_Change Work Order Owner to Case Owner process builder
            //The logic has been moved in CaseTrigger after insert and update.
            //Please use the class and add action method specific to WorkOrder object, return the list and update here.
            List <WorkOrder> workOrderToBeUpdated = relatedWorkOrder.actionsForUpdatedCases (newList, newMapItems, oldMapItems);
            allWorkOrderToBeUpdated.addAll(workOrderToBeUpdated);
            if (!allWorkOrderToBeUpdated.isEmpty() && Schema.sObjectType.WorkOrder.isUpdateable()){
                update allWorkOrderToBeUpdated;           
            }

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();   
    }
    
    public void AfterDelete(List<SObject> oldList, Map<Id, SObject> oldMapItems){}
    
    public void AfterUndelete(List<SObject> newList, Map<Id, SObject> newMapItems){}

    /**
    * @author        Paul Jarred Aguiling
    * @date          3.20.2018           
    * @description   Method responsible for retrieving active entitlements
    * @revision(s)
    */
    public List<Entitlement> getEntitlements() {
        CustomLogging.push('getEntitlements', 'CaseTriggerHandler');

        if (list_Entitlements.isEmpty()) {
            list_Entitlements = [SELECT SalesOrganization__c, CaseType__c, CountryDefault__c, ServiceWindow__c, BusinessHoursId FROM Entitlement WHERE Status =: TS_Constants.ACTIVE];
        }

        CustomLogging.pop();
        return list_Entitlements;
    }    

    /**
    * @author        Paul Jarred Aguiling
    * @date          3.20.2018           
    * @description   Method responsible for retrieving country settings
    * @revision(s)
    */
    public List<CountrySetting__c> getCountrySetViaRectypeName(String recTypeName) {
        CustomLogging.push('getEntitlements', 'CaseTriggerHandler');
        Map<String, List<CountrySetting__c>> countrySetMap = new Map<String, List<CountrySetting__c>>();
        List<CountrySetting__c> countrySettingsList = new List<CountrySetting__c>();

        if (list_CountrySettings.isEmpty()) {
            list_CountrySettings = [SELECT Country__c, toLabel(Country__c) countryLabel, Priority__c, 
                                           RecordType.DeveloperName, 
                                           ResponseProfile__c, Email__c, 
                                           CaseType__c, RecordTypeId, 
                                           RecordType.Name, Default_Owner__c, 
                                           Signature_Title__c,
                                         Coffee_is_Running__c, //Karen Hung DOO-677
                                           AssetResponseProfile__c  //Karen Hung 03.09.2018
                                    FROM CountrySetting__c WHERE Active__c = true];
        }

        //Construct list of record from SOQL result
        for (CountrySetting__c ctrySet: list_CountrySettings) {
            if (countrySetMap.containsKey(ctrySet.RecordType.DeveloperName)) {
                countrySetMap.get(ctrySet.RecordType.DeveloperName).add(ctrySet);
            } else {
                countrySetMap.put(ctrySet.RecordType.DeveloperName, new List<CountrySetting__c>{ctrySet});
            }
        }

        //Return Result
        if(countrySetMap.containsKey(recTypeName)){
            countrySettingsList = countrySetMap.get(recTypeName);
        }
        
        CustomLogging.pop();
        return countrySettingsList;
    }       

    /**
    * @author        Archi Delphinanto
    * @date          30 nov 2017           
    * @description   KTS-934: Method used to calculate coffee down time, corrective maintenance response time, complaint response time, and complaint resolution time. 
    *                The related field updates are used for BI 
    * @revision(s)
    */
    public void calculate_BI_Time(List<SObject> newList, Map<Id, SObject> newMapItems, Map<Id, SObject> oldRecordMap) {
        
        CustomLogging.push('calculate_BI_Time', 'CaseTriggerHandler');
        
        Map<Id, Case> newCase = (Map<Id, Case>) newMapItems;
        Map<Id, Case> oldCase = (Map<Id, Case>) oldRecordMap;
        Map<Id, CaseMilestone> firstMSList = new Map<Id, CaseMilestone> ();
        Map<Id, CaseMilestone> ClosureMSList = new Map<Id, CaseMilestone> ();
        List<Id> caseComplaintIdList = new List<Id>();
        List<Id> caseWOLIIdList = new List<Id>();
        List<CaseMilestone> cseMilestoneList = new List<CaseMilestone>();
        List<Case> toupdatecaselist = new List<case>();
        String activityS10 = TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI;
        String activityS15 = TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI;
        String activityS30 = TS_Constants.TYPE_S30_PREVMAINTENANCE;
        String activityS31 = TS_Constants.TYPE_S31_PRECHECK;
        String activityS32 = TS_Constants.TYPE_S32_WATERFILTER;
        String activityS60 = TS_Constants.TYPE_S60_MODIFICATION;
        String activityS43 = TS_Constants.TYPE_S43_CONFIGCHANGE;

        // preparing related WOLIs for down time calculation
        List<WorkOrderLineItem> downtimewolilist = new List <WorkOrderLineItem> ();
        List<ID> caseIDlist = new List<ID>();

        for (Case jCase: (List<Case>) newList) {
          if (oldCase.get(jCase.Id).Status != jCase.Status 
                && jcase.status == TS_Constants.STATUS_CLOSED
                && jCase.Type == TS_Constants.CASE_TYPE_FIELDSERVICE &&
                (   (jcase.SubType__c==activityS10)
                    || (jcase.SubType__c==activityS15)
                    || (jcase.SubType__c==activityS30)
                    || (jcase.SubType__c==activityS31)
                    || (jcase.SubType__c==activityS32)
                    || (jcase.SubType__c==activityS60)
                    || (jcase.SubType__c==activityS43) 
                )                           
            ){
                caseIDlist.add(jCase.id);
           }
        } 

        if ( !caseIDlist.isEmpty()) {
            //Karen Hung 28.11.2019 DOO-2651 added WorkOrderLineItemType__c filter
            downtimewolilist = [SELECT Id, WorkOrderType__c, IsFirstTask__c, Case__r.Id, CreatedDate, CoffeeRunsAfterVisit__c, CoffeeRunsUponArrival__c, StartDate__c, EndDate__c
                                FROM WorkOrderLineItem WHERE (Status =: TS_Constants.STATUS_COMPLETED AND Case__r.Id In :caseIdList) AND WorkOrderLineItemType__c = :TS_Constants.TYPE_TASK ORDER BY Case__r.Id, CreatedDate ASC ] ;
        }
        
        for (Case icase: (List<Case>) newList) {

            //Scenario 1 (Case type Complaint) : filter case type complaint, should only happen on case update
            if((oldCase.get(icase.Id) != null) && iCase.Type == TS_Constants.CASE_TYPE_COMPLAINT){
                // 1.a calculate response time --> when Case First milestone is changed to true/completed (updated by First Response milestone action)
                if (  (icase.CompletedFirstResponse__c != oldcase.get(icase.id).CompletedFirstResponse__c) &&
                      icase.CompletedFirstResponse__c &&
                      (icase.TS_BI_WorkOrder_Start__c !=null) // TS_BI_WorkOrder_Start__c is filled in by First response milestone action.                         
                    ) {

                    icase.TS_BI_Response_Time__c = TS_BusinessHour_Calculation.defaultSFBusinessHourBetweenDates (icase.CreatedDate, icase.TS_BI_WorkOrder_Start__c, icase.BusinessHoursId);                                          
                }
                
                // 1.b calculate resolution time  for case complaint only when case is closed
                if (oldCase.get(icase.Id).TS_BI_WorkOrder_Finish__c != icase.TS_BI_WorkOrder_Finish__c && icase.TS_BI_WorkOrder_Finish__c!=null &&
                      icase.CompletedCaseClosure__c
                    ){                        

                    icase.TS_BI_Resolution_Time__c = TS_BusinessHour_Calculation.defaultSFBusinessHourBetweenDates ( icase.CreatedDate, icase.TS_BI_WorkOrder_Finish__c , icase.BusinessHoursId);
                }
             }

            //filter case type field service used only on case update
            else if ( (oldCase.get(icase.Id) != null)  && iCase.Type == TS_Constants.CASE_TYPE_FIELDSERVICE){

                //filter to subtype corrective maintenance for calculating response time and resolution time only happen on case update
                if (icase.SubType__c.equals(activityS10) 
                    || icase.SubType__c.equals(activityS15) 
                    || icase.SubType__c.equals (activityS30)
                    || icase.SubType__c.equals(activityS31)
                    || icase.SubType__c.equals(activityS43)
                   ){
                    
                    // calculate corrective maintenance response time if the first woli task is changed to completed (i.e. only happen when TS_BI_workorder_start is updated by PB on woli, 
                    if ((oldcase.get(icase.Id).TS_BI_WorkOrder_Start__c != icase.TS_BI_WorkOrder_Start__c )
                        &&  icase.TS_BI_WorkOrder_Start__c !=null) {                             
                            icase.TS_BI_Response_Time__c = TS_BusinessHour_Calculation.defaultSFBusinessHourBetweenDates (icase.CreatedDate, icase.TS_BI_WorkOrder_Start__c, icase.BusinessHoursId);                      
                        }

                    if (icase.status == TS_Constants.STATUS_CLOSED && icase.TS_BI_WorkOrder_Finish__c != null && oldCase.get(icase.Id).TS_BI_WorkOrder_Finish__c != icase.TS_BI_WorkOrder_Finish__c){
                            icase.TS_BI_Resolution_Time__c = TS_BusinessHour_Calculation.defaultSFBusinessHourBetweenDates ( icase.CreatedDate, icase.TS_BI_WorkOrder_Finish__c, icase.BusinessHoursId);
                        }                       
                }

                //calculating downtime only on case status is changed to closed
                if ( (oldCase.get(icase.Id).status!=  icase.status) && icase.status == TS_Constants.STATUS_CLOSED &&
                       ((icase.SubType__c==activityS10) 
                        || (icase.SubType__c==activityS15) 
                        || (icase.SubType__c==activityS30) 
                        || (icase.SubType__c==activityS31) 
                        || (icase.SubType__c==activityS32) 
                        || (icase.SubType__c==activityS60) 
                        || (icase.SubType__c==activityS43)
                       )){
                    
                    //calculate down time (require woli list per case)
                    List <WorkOrderLineItem> iwolilist = new List <WorkOrderLineItem> ();
                    for (WorkOrderLineItem iwoli: downtimewolilist){
                        if (iwoli.Case__r.id==icase.id) iwolilist.add(iwoli);                            
                    }
                    if ( icase.BusinessHoursId !=null && !iwolilist.isempty()) icase.TS_BI_Coffee_Down_Time__c = calculateFSdowntime( iwolilist,  icase);
                  }

            } 
            
            toupdatecaselist.add(icase);
        }

        CustomLogging.pop();
    }

    /**
    * @author        Archi Delphinanto
    * @date          30 nov 2017            
    * @description   Method responsible calculating BI down time
    * @revision(s)
    */
    public Decimal calculateFSdowntime(List<WorkOrderLineItem> awolilist,  Case acase) {
        Decimal totaldowntime = 0.00;
        Decimal idowntime =0.00;
        Decimal responsetime = 0.00;
        Decimal workdelta=0.00;      
        DateTime mylastdate;
        boolean isfirsttask = true;
        String activityS10 = TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI;
        String activityS15 = TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI;

        for (WorkOrderLineItem iwoli : awolilist){
            if (isfirsttask && iwoli.IsFirstTask__c ){
                
                isfirsttask = false;
                if (acase.TS_BI_Response_Time__c == null) {
                    responsetime = TS_BusinessHour_Calculation.defaultSFBusinessHourBetweenDates (acase.CreatedDate, iwoli.startdate__c, acase.BusinessHoursId); 
                } else {
                    responsetime = acase.TS_BI_Response_Time__c;    
                }

                workdelta = TS_BusinessHour_Calculation.defaultSFBusinessHourBetweenDates ( iwoli.startdate__c, iwoli.enddate__c, acase.BusinessHoursId);
                if((iwoli.WorkOrderType__c.equals(activityS10) || iwoli.WorkOrderType__c.equals(activityS15) ) && iwoli.CoffeeRunsUponArrival__c == false){
                    idowntime = responsetime + workdelta;
                } else {
                    idowntime = workdelta;
                }
            } else {
                workdelta = TS_BusinessHour_Calculation.defaultSFBusinessHourBetweenDates ( iwoli.startdate__c, iwoli.enddate__c, acase.BusinessHoursId);
                if (iwoli.CoffeeRunsUponArrival__c) {
                    idowntime = workdelta;
                } else {   

                    if (mylastdate == null) mylastdate = iwoli.startdate__c; 
                    responsetime = TS_BusinessHour_Calculation.defaultSFBusinessHourBetweenDates ( mylastdate, iwoli.startdate__c,  acase.BusinessHoursId);
                    idowntime = responsetime + workdelta;
                }
            }

            mylastdate = iwoli.enddate__C;    
            totaldowntime = totaldowntime + idowntime;

        }            
          return totaldowntime;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          5.15.2017           
    * @description   Method responsible in disabling the function of the trigger if user settings is false
    * @revision(s)
    */
    public Boolean IsDisabled() {
        if (TriggerSettings__c.getInstance().CaseTrigger__c && !IS_RETURN_NEEDED) {
            return false;
        } else {
            return isTriggerDisabled;
        }
    }
    
    /**
    * @author        Paul Jarred Aguiling
    * @date          11.15.2017           
    * @description   KTS 363 - Confirm First Response.
    *                Method responsible in updating case status when first response milestone is completed
    * @revision(s)
    */
    @testVisible
    private void updateCaseStatusViaFirstResp(List<SObject> newList, Map<Id, SObject> oldRecordMap) {
        CustomLogging.push('updateCaseStatusViaFirstResp', 'CaseTriggerHandler');
        Map<Id, Case> oldCase = (Map<Id, Case>) oldRecordMap;
        List<Id> caseIds = new List<Id>();
        List<CaseMilestone> cseMilestoneList = new List<CaseMilestone>();

        //Add case id  with Type = Field Service, Sub-Type = corrective maintenance, and status = completed
        for (Case newCase: (List<Case>) newList) {
            if (oldCase.get(newCase.Id) != null && newCase.IsFirstResponseClosed__c != oldCase.get(newCase.Id).IsFirstResponseClosed__c
                && newCase.Status != TS_Constants.STATUS_CLOSED
                && newCase.IsFirstResponseClosed__c) {
                newCase.Status = TS_Constants.STATUS_INPROGRESS;
            }
        }

        CustomLogging.pop();
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          11.08.2017           
    * @description   KTS 365 - Close First Response for Field Service Cases.
    *                Method responsible in closing first response case milestones
    * @revision(s)
    */
    @testVisible
    private void closeFieldServiceFirstResponse(List<SObject> newList, Map<Id, SObject> oldRecordMap) {
        CustomLogging.push('closeFieldServiceFirstResponse', 'CaseTriggerHandler');
        Map<Id, Case> oldCase = (Map<Id, Case>) oldRecordMap;
        List<Id> caseIds = new List<Id>();
        List<CaseMilestone> cseMilestoneList = new List<CaseMilestone>();

        //Add case id  with Type = Field Service, Sub-Type = corrective maintenance, and status = completed
        for (Case newCase: (List<Case>) newList) {
            if (newCase.Status != oldCase.get(newCase.Id).Status 
                && newCase.Status == TS_Constants.STATUS_CLOSED
                && newCase.Type == TS_Constants.CASE_TYPE_FIELDSERVICE
                && !newCase.CreatedOrderedManually__c
                && (newCase.SubType__c == TS_Constants.CASE_SUBTYPE_CORRECTMAINTAPI
                || newCase.SubType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI)) {
                caseIds.add(newCase.Id);
            }
        }

        //Collect list of related first response case milestones then update completion date using woli actual start date
        if (!caseIds.isEmpty()) {
            for (CaseMilestone cseMilestone: [SELECT CompletionDate, CaseId FROM CaseMilestone 
                                              WHERE MilestoneType.Name =: TS_Constants.FIRST_RESPONSE
                                              AND IsCompleted = false
                                              AND CaseId IN: caseIds]) {
                cseMilestone.CompletionDate = DateTime.now();
                cseMilestoneList.add(cseMilestone);
            }
        }

        if (!cseMilestoneList.isEmpty() && Schema.sObjectType.CaseMilestone.isUpdateable()) {
            update cseMilestoneList;
        }

        CustomLogging.pop();
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          5.15.2017           
    * @description   Method responsible in selecting correct case entitlements
    * @revision(s)   2017-05-26  Rey Austral - Add dynamic computation of SLA
    *                2018-01-05  Adrian Reyes - Replaced Asset Line Item with Physical Asset and simplified code
    *                2018-03-29  Paul Aguiling - KTS-1370: Updates in response time for s10 and s15
    */
    @testVisible
    private void updateCaseEntitlement(List<SObject> newList, Map<Id, SObject> oldRecordMap) {
        CustomLogging.push('updateCaseEntitlement', 'CaseTriggerHandler');
        Set<Id> caseIDs = new Set<Id>();
        
        //Filter cases to process
        for (Case c: (List<Case>) newList) {
            //Insert
            if(oldRecordMap == null){
                caseIDs.add(c.Id);
            }
            //Update
            else{
                Case oldCase = (Case) oldRecordMap.get(c.Id);
                
                //Case type/priority/subtype/sales org/physical asset changed
                if(c.Type != oldCase.Type || 
                   c.Priority != oldCase.Priority || 
                   c.SubType__c != oldCase.SubType__c || 
                   c.SalesOrganization__c != oldCase.SalesOrganization__c || 
                   c.PhysicalAsset__c != oldCase.PhysicalAsset__c ||
                   c.CoffeeIsRunning__c != oldCase.CoffeeIsRunning__c || //DOO-5194 Jan 14 2021          
                   c.SLARecalculation__c //DOO-5274 XEN REYES - Jan. 26, 2020        
                  ){
                    caseIDs.add(c.Id);
                }
                
                //Use when a milestone is completed for customer care or complaint case
                if(c.NumberofCompletedMilestones__c != oldCase.NumberofCompletedMilestones__c && (c.Type == TS_Constants.CASE_TYPE_CUSTOMERCARE || c.Type == TS_Constants.CASE_TYPE_COMPLAINT)){
                    //Creating a Map to pass parameters to the flow
                    Map<String, Object> flowMap = new Map<String, Object>();
                    flowMap.put('CaseId',c.Id);
                    
                    //Launching the flow with the parameters
                    Flow.Interview.TS_UpdateTargetDate myFlow = new Flow.Interview.TS_UpdateTargetDate(flowMap);
                    myFlow.start();
                }
            }
        }
        
        if (!caseIDs.isEmpty()){
            List<Case> cases = [SELECT Id, Type, toLabel(SubType__c) subLabel, SubType__c,  AccountId, Account.BillingCountry, 
                                   Account.Sales_Organization__c,
                                   EarlyStartDate__c,
                                   RecordType.Name, BusinessHoursId, EntitlementId , 
                                   //Asset__r.Apttus_Config2__AttributeValueId__r.Hours__c,
                                   Origin,CaseQualificationDate__c,
                                   //Asset__r.Apttus_Config2__AttributeValueId__r.Service_windows__c,
                                   Service_Hours__c,SLADate__c,Priority,CreatedDate,SalesOrganization__c,
                                   PhysicalAsset__c,PhysicalAsset__r.ServiceWindow__c, toLabel(PhysicalAsset__r.ResponseTime__c),
                                   PhysicalAsset__r.ActiveContract__c, PhysicalAsset__r.ResponseTimeS15__c, CoffeeIsRunning__c, //Karen Hung DOO-677 added coffee is running
                                   PhysicalAsset__r.EndDate__c
                                   FROM Case WHERE Id =: caseIDs];
            
            Map<String,CountrySetting__c> countrySettingMap = new Map<String,CountrySetting__c>();

            //XR KTS-1827 16.8.2018
            List<CountrySetting__c> countryRespProfile =  getCountrySetViaRectypeName(TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_RESPONSEPROFILE);
            if(countryRespProfile != null){
                for(CountrySetting__c countrySetting : countryRespProfile){
                    //Karen Hung 23.07.2019 DOO-859 added coffee is running map and asset response profile
                    countrySettingMap.put(countrySetting.Country__c + '-' + countrySetting.Priority__c + '-' + countrySetting.Coffee_is_Running__c + '-' + (countrySetting.AssetResponseProfile__c == null ? 'null' : countrySetting.AssetResponseProfile__c), countrySetting);

                }  
            }

            Map<String,Entitlement> entitlementMap = new Map<String,Entitlement>();
            Map<String,Entitlement> fieldServiceEntitlementMap = new Map<String,Entitlement>();
            Map<String,Entitlement> defaultEntitlementMap = new Map<String,Entitlement>();
            for(Entitlement entitlement: getEntitlements()){
                entitlementMap.put(entitlement.SalesOrganization__c + '-' + entitlement.CaseType__c, entitlement);
                fieldServiceEntitlementMap.put(entitlement.SalesOrganization__c + '-' + entitlement.CaseType__c + '-' +  entitlement.ServiceWindow__c, entitlement);
                
                //Map for country default when service window is standard weekdays
                if (entitlement.CountryDefault__c != null && entitlement.CountryDefault__c) {
                    defaultEntitlementMap.put(entitlement.SalesOrganization__c + '-' + entitlement.CaseType__c, entitlement);
                }
            }
            
            for(Case c: cases){
                
                //Update Case Qualification Date if origin is email and type changed
                if(oldRecordMap != null){
                    Case oldCase = (Case) oldRecordMap.get(c.Id);
                    
                    //DOO-5288 XEN Reyes APRIL 9, 2021
                    Set<String> supportedOrigins = new Set<String>{TS_Constants.CASE_ORIGIN_EMAIL, TS_Constants.CASE_ORIGIN_EF, TS_Constants.CASE_ORIGIN_WEB, TS_Constants.CASE_ORIGIN_IOT};

                    if(supportedOrigins.contains(c.Origin) && c.Type != oldCase.Type){
                        c.CaseQualificationDate__c = DateTime.now();
                    }
                }
                
                Entitlement entitlement;
                
                //Field Service s10 or s15
                if (c.Type == TS_Constants.CASE_TYPE_FIELDSERVICE && (c.get('subLabel') == TS_Constants.CASE_SUBTYPE_CORRECTMAINT
                    || c.SubType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI)) {              

                    //Medium with Physical Asset
                    if (c.Priority == TS_Constants.CASE_PRIORITY_MEDIUM && c.PhysicalAsset__c != null){
          
                        //Corrective maintenance/S10 scenario with response time AND coffee is NOT running AND Contract is Active
                        if (c.PhysicalAsset__r.ResponseTime__c != null && c.get('subLabel') == TS_Constants.CASE_SUBTYPE_CORRECTMAINT && !c.CoffeeIsRunning__c && c.PhysicalAsset__r.EndDate__c !=null && c.PhysicalAsset__r.EndDate__c >= Date.Today()) { 
                            
                            c.ResponseProfile__c = c.PhysicalAsset__r.ResponseTime__c; //Karen Hung 16.09.2019
                            
                        //1st line corrective maintenance/S15 scenario with response time 15
                        } else if (c.PhysicalAsset__r.ResponseTimeS15__c != null && c.SubType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI) {
                           
                            c.ResponseProfile__c = String.valueOf(c.PhysicalAsset__r.ResponseTimeS15__c);
                       
                       //Karen Hung Dec 9, 2019 If S15 with null response time 15 but with response time 10
                        } else if (c.PhysicalAsset__r.ResponseTimeS15__c == null && c.SubType__c == TS_Constants.CASE_SUBTYPE_1STLINECORRECTMAINTAPI && c.PhysicalAsset__r.ResponseTime__c != null ) {
                           
                            c.ResponseProfile__c = String.valueOf(c.PhysicalAsset__r.ResponseTime__c);
                        //Use country setting response profile when physical assets response time is empty OR coffee is running OR Contract is Inactive - XR 7/24
                        } else {

                            //Map to 'No Contract' if inactive OR blank response profile, if not, map to Physical Asset's reponse time
                            CountrySetting__c countrySetting = countrySettingMap.get(c.SalesOrganization__c + '-' + c.Priority + '-' + c.CoffeeIsRunning__c + '-' + (c.CoffeeIsRunning__c && c.PhysicalAsset__r.ResponseTime__c != null && c.PhysicalAsset__r.EndDate__c >= Date.Today() ? c.PhysicalAsset__r.ResponseTime__c : TS_Constants.NO_CONTRACT)); //Karen Hung DOO-853 added coffee is running
                           
                            //Map to 'No Contract' if active, coffee is running with response profile but without country setting mapping
                            if(c.CoffeeIsRunning__c && c.PhysicalAsset__r.ResponseTime__c != null && countrySetting == null){ 
                                countrySetting =  countrySettingMap.get(c.SalesOrganization__c + '-' + c.Priority + '-' + c.CoffeeIsRunning__c + '-' + TS_Constants.NO_CONTRACT);  
                            }
                             
                            c.ResponseProfile__c = countrySetting != null? countrySetting.ResponseProfile__c : null;                          
                                        
                        }

                    //s10 medium with null PA    
                    } else if (c.Priority == TS_Constants.CASE_PRIORITY_MEDIUM && c.PhysicalAsset__c == null && c.get('subLabel') == TS_Constants.CASE_SUBTYPE_CORRECTMAINT ){ //Karen Hung DOO-853 04.09.2019

                        CountrySetting__c countrySetting = countrySettingMap.get(c.SalesOrganization__c + '-' + c.Priority + '-' + c.CoffeeIsRunning__c + '-' + TS_Constants.NO_CONTRACT); //Karen Hung DOO-853 03.09.2019 added coffee is running and response time
                        c.ResponseProfile__c = countrySetting != null? countrySetting.ResponseProfile__c : null;    
                    
                    } else { //XEN REYES Nov. 27, 2018 Non-medium s10s //Karen Hung 03.09.2019

                        CountrySetting__c countrySetting = countrySettingMap.get(c.SalesOrganization__c + '-' + c.Priority + '-' + c.CoffeeIsRunning__c + '-' + TS_Constants.NA);//Karen Hung DOO-859 added coffee is running, and asset profile 
                        c.ResponseProfile__c = countrySetting != null? countrySetting.ResponseProfile__c : null;                         
       
                    }

                    //Initially stamp the service window from physical asset if not empty
                    c.ServiceWindow__c = c.PhysicalAsset__c != null ? c.PhysicalAsset__r.ServiceWindow__c : null; 

                    //Use country default entitlement if physical asset is not specified and physical asset service window empty //Karen Hung DOO-4908 added contract end date scenario
                    Boolean countryDefault = c.PhysicalAsset__c == null || (c.PhysicalAsset__c != null && (c.PhysicalAsset__r.ServiceWindow__c == null || c.PhysicalAsset__r.EndDate__c == null || (c.PhysicalAsset__r.EndDate__c != null && Date.Today() > c.PhysicalAsset__r.EndDate__c))) ? true : false; 

                    //Stamp the entitlement record
                    if (countryDefault) {    
                        entitlement = defaultEntitlementMap.get(c.SalesOrganization__c + '-' + c.Type);

                        //Set the entitlement service window when physical assets service window is empty //Karen Hung, because this is also applicable if Physical Asset is null 05.10.2018
                        /*if (c.PhysicalAsset__c != null && c.PhysicalAsset__r.ServiceWindow__c == null
                                && c.PhysicalAsset__r.ActiveContract__c == false) {*/
                        c.ServiceWindow__c = entitlement != null? entitlement.ServiceWindow__c : null;
                       // }
                    } else {
                        entitlement = fieldServiceEntitlementMap.get(c.SalesOrganization__c + '-' + c.Type + '-' + c.ServiceWindow__c);
                    }
                }
                
                //Other Case types
                else {
                    entitlement = entitlementMap.get(c.SalesOrganization__c + '-' + c.Type);

                    //XEN REYES Nov. 27, 2018
                    /* CountrySetting__c countrySetting = countrySettingMap.get(c.SalesOrganization__c + '-' + c.Priority);
                    c.ResponseProfile__c = countrySetting != null? countrySetting.ResponseProfile__c : null; */
                }
                
                //Stamp Entitlement and Business Hours on case
                if(entitlement != null){
                    c.EntitlementId = entitlement.Id;
                    c.BusinessHoursId = entitlement.BusinessHoursId;

                    //DOO-5288 XEN Reyes APRIL 9, 2021
                    if(c.CaseQualificationDate__c != null && c.BusinessHoursId != null){
                        c.Qualification_Duration__c = BusinessHours.diff(c.BusinessHoursId, c.CreatedDate, c.CaseQualificationDate__c) / (1000 * 60);
                    }
                }
            }
            
            //Update cases
            if(!cases.isEmpty()){
                try{
                    //Exception for test class purposes
                    if(Test.isRunningTest() && hasException){
                        throw new TS_CaseTriggerHandlerException('Force to throw an exception');
                    }
                    
                    if(Schema.sObjectType.Case.isUpdateable())
                        update cases;
                }
                catch(Exception ex){
                    CustomLogging.debugException(ex);
                    CustomLogging.pop();
                }
            }
        }
        
        CustomLogging.pop();
    }
    
    /**
    * @author        Rey Austral
    * @date          5.29.2017           
    * @description   Method responsible in retrieving information of the user
    * @revision(s)
    */
    private User getUsers() {       
        List<User> userList = [Select Id,Sales_Organization__c from User where id=: Userinfo.getUserid()];       
        return !userList.isEmpty() ? userList.get(0) : null;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          5.24.2017           
    * @description   Method responsible in updating Work Order and Work Order Line Item Status
    * @revision(s)   12.04.2017 Paul Aguiling - Updated condition by adding new and old values comparison
    */
    private void updateCaseWOStatus(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('updateWOLIScheduleDate', 'CaseTriggerHandler');
        List<Id> caseIdList = new List<Id>();
        Map<Id, Case> oldMapItemsCase = (Map<Id, Case>) oldMapItems;
        List<WorkOrderLineItem> woliTOUpdate = new List<WorkOrderLineItem>();
        List<WorkOrder> woTOUpdate = new List<WorkOrder>();

        Id caseRecTypeId = CASE_FIELDSERVICE_DEFAULT_RECORDTYPEID;
        Id caseRecTypeId2 = CASE_FIELDSERVICE_CONTRACT_RECORDTYPEID;
        Id caseRecTypeId3 = CASE_FIELDSERVICE_SALES_RECORDTYPEID;
        
        Map<Id, String> cancelationReasonMap = new Map<Id, String>();

        for (Case cse: (List<Case>) newList) {
            if ((cse.RecordTypeId == caseRecTypeId || cse.RecordTypeId == caseRecTypeId2 || cse.RecordTypeId == caseRecTypeId3)
                && (cse.Status != oldMapItemsCase.get(cse.Id).Status 
                    || cse.CaseSubStatus__c != oldMapItemsCase.get(cse.Id).CaseSubStatus__c)
                && (cse.Status == TS_Constants.STATUS_CANCELED
                    || cse.CaseSubStatus__c == TS_Constants.STATUS_CANCELED
                    || (cse.Status == TS_Constants.STATUS_CLOSED
                        && cse.cancelationreason__c != oldMapItemsCase.get(cse.Id).cancelationreason__c))) {
                caseIdList.add(cse.Id);
                cancelationReasonMap.put(cse.Id, cse.cancelationreason__c);
            }
        }

        //Query all related Work Order and Work Order Line Items
        if (!caseIdList.isEmpty()) {
            for (WorkOrder wo :[SELECT Id, Status,CaseId, (SELECT Id, Status, Case__c FROM WorkOrderLineItems)
                                FROM WorkOrder 
                                WHERE WorkOrder.CaseId IN :caseIdList]) {

                for (WorkOrderLineItem woli: wo.WorkOrderLineItems) {
                    if (woli.Status != TS_Constants.STATUS_COMPLETED && woli.Status != TS_Constants.STATUS_CANCELED) {
                        woli.Status = TS_Constants.STATUS_CANCELED;
                        woli.CancelationReason__c= cancelationReasonMap.get(woli.Case__c);
                    }

                    woliTOUpdate.add(woli);
                }

                if (wo.Status != TS_Constants.STATUS_COMPLETED && wo.Status != TS_Constants.STATUS_COMPLETED) {
                    wo.Status = TS_Constants.STATUS_CANCELED;
                    woTOUpdate.add(wo);
                }
            }
        }

        try {

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_CaseTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
            }

            if (!woTOUpdate.isEmpty() && Schema.sObjectType.WorkOrder.isUpdateable()) {
                update woTOUpdate;
            }
            if (!woliTOUpdate.isEmpty() && Schema.sObjectType.WorkOrderLineItem.isUpdateable()) {
                update woliTOUpdate;
            }
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        CustomLogging.pop();
    }    
    
    /**
    * @author        Archi Delphinanto
    * @date          9.14.2017           
    * @description   Method responsible for updating Woli schedule date when case schedule date is updated, only Case Field Service recordtype
    * @revision(s)   12.04.2017 Paul Aguiling - Added condition before querying case records and old/new criteria for case subtypes
    */
     public void updateWOLIScheduleDate( List<SObject> newList, Map<Id, SObject> oldMapItems) {
       CustomLogging.push('updateWOLIScheduleDate', 'CaseTriggerHandler');
       List<Id> caseIdList = new List<Id>();
       List<WorkOrderLineItem> woliTOUpdatelist = new List<WorkOrderLineItem>();

       //filter the case recordtype field service and case subtype of installation or de installation.
       Id caseRecTypeId = CASE_FIELDSERVICE_DEFAULT_RECORDTYPEID;
        for (Case cse: (List<Case>) newList) {
            Case oldCase = (Case) oldMapItems.get(cse.Id);
            if (cse.RecordTypeId == caseRecTypeId 
                && cse.SubType__c != oldCase.SubType__c
                && (cse.subType__c == TS_Constants.CASE_SUBTYPE_INSTALLATION || cse.subType__c == TS_Constants.ORDER_S40 || cse.subType__c == TS_Constants.CASE_SUBTYPE_DEINSTALLATION || cse.subType__c == TS_Constants.ORDER_S41)) {
                caseIdList.add(cse.Id);
            }
        }

        List<Case> ucaseList = new List<Case>();

        if (!caseIdList.isEmpty()) {
            ucaseList = [SELECT Id, PickingDate__c, (SELECT Id, ScheduledDate__c FROM WorkOrderLineItems__r) FROM Case WHERE Id =:caseIdList]; 
        }

        if (ucaseList!=null || ucaseList.size()!=0){
            for(Case cse: ucaseList) {  
                for ( WorkOrderLineItem woli: cse.WorkOrderLineItems__r  ) {
                            woli.scheduleddate__c = cse.PickingDate__c;
                            woliTOUpdatelist.add(woli); 
                }                
            }

           try {

                //Exception for test class purposes
                if (Test.isRunningTest() && hasException) {
                    throw new TS_CaseTriggerHandlerException(TS_Constants.FORCE_EXCEPTION);
                }

                if (!woliTOUpdatelist.isEmpty() && Schema.sObjectType.WorkOrderLineItem.isUpdateable()) {
                    update woliTOUpdatelist;
                }
           
            } catch (Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            }
       

            
        }
                    
    }
    
    /**
    * @author        Abram Vixen Reyes
    * @date          10.3.2017           
    * @description   Method for assigning Default From Address/Default Owner from Country Setting
    * @revision(s)   12.04.2017 Paul Aguiling - Replaced SOQL for recordtype using TS_Utility class   
    */

    public void getFromAddressAndDefaultOwner(List<SObject> newList, Map<Id, SObject> oldMapItems) {

        Set<String> countriesToQueryList = new Set<String>();
        Set<CountrySetting__c> countrySettingListOld = new Set<CountrySetting__c>();
        List<CountrySetting__c> countrySettingList = new List<CountrySetting__c>();
        List<Case> caseToUpdateList = new List<Case>();
        Map<String, String> labelValueSalesOrgMap = new Map<String, String>();
        Map<String, String> countryDefaultOwnerMap = new Map<String, String>();
        Map<String, Map<String, String>> countryKeyRecordTypeEmailMap = new Map<String, Map<String, String>>();
        Map<String, Map<String, CountrySetting__c>> countryKeyRecordTypeEmailRecordMap = new Map<String, Map<String, CountrySetting__c>>();
        
        Schema.DescribeFieldResult F = Case.SalesOrganization__c.getDescribe();
        List<Schema.PicklistEntry> P = F.getPicklistValues();
        for(Schema.PicklistEntry pl : P){
            labelValueSalesOrgMap.put(pl.getValue(), pl.getLabel());
        }
        
        for (Case cse: (List<Case>) newList) {
            
            if(labelValueSalesOrgMap.containsKey(cse.SalesOrganization__c)){
                countriesToQueryList.add(labelValueSalesOrgMap.get(cse.SalesOrganization__c));
            } 
        }

        if(!countriesToQueryList.isEmpty()){           
            try{
                List<CountrySetting__c> defaultOwners = getCountrySetViaRectypeName(TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_DEFAULTCASEOWNER);
                List<CountrySetting__c> emailRules = getCountrySetViaRectypeName(TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_COUNTRYEMAIL);

                if(!defaultOwners.isEmpty()){
                    countrySettingListOld.addAll(defaultOwners);    
                }
                
                if(!emailRules.isEmpty()){
                    countrySettingListOld.addAll(emailRules);    
                }

                //System.debug(countrySettingListOld);
                
                //Code optimized to get country settings records
                for (CountrySetting__c countSet: countrySettingListOld) {
                    if (countriesToQueryList.contains(labelValueSalesOrgMap.get(countSet.Country__c))) {
                        countrySettingList.add(countSet);
                    }
                }
            } catch (Exception ex){
                CustomLogging.debugException(ex);
                CustomLogging.pop();
                System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            }
        }

        if(!countrySettingList.isEmpty()){
            
            for(CountrySetting__c cs : countrySettingList){
                String country = cs.get('countryLabel') != null? (String) cs.get('countryLabel') : '';

                //DEFAULT FROM ADDRESS
                if(cs.RecordType.Name == TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_COUNTRYEMAIL_NAME){
                    if(!countryKeyRecordTypeEmailMap.containsKey(country)) {
                        countryKeyRecordTypeEmailMap.put(country, new Map<String, String>{cs.CaseType__c => cs.Email__c});
                        countryKeyRecordTypeEmailRecordMap.put(country, new Map<String, CountrySetting__c>{cs.CaseType__c => cs});                                      
                    } else {
                        countryKeyRecordTypeEmailMap.get(country).put(cs.CaseType__c, cs.Email__c);
                        countryKeyRecordTypeEmailRecordMap.get(country).put(cs.CaseType__c, cs);
                    }
                }

                //DEFAULT CASE OWNER 10.11.2017
                else if(cs.RecordType.Name == TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_DEFAULTCASEOWNER_NAME){
                    if(!countryDefaultOwnerMap.containsKey(country)){
                        countryDefaultOwnerMap.put(country, cs.Default_Owner__c);                                            
                    }
                }
            }
        }

        //DEFAULT FROM ADDRESS                
        if(!countryKeyRecordTypeEmailMap.isEmpty()){   
            for (Case cse: (List<Case>) newList) {
                if (cse.origin != 'E-mail'){
                    if (labelValueSalesOrgMap.containsKey(cse.SalesOrganization__c)) {
                        String country = labelValueSalesOrgMap.get(cse.SalesOrganization__c);
                        if (countryKeyRecordTypeEmailMap.containsKey(country)) {
                            if (countryKeyRecordTypeEmailMap.get(country).containsKey(cse.Type)) {

                                if (Trigger.isUpdate && Trigger.isBefore) {
                                    Case getCase = (Case) oldMapItems.get(cse.Id);
                                    if (((getCase.RecordTypeId != cse.RecordTypeId) || String.isBlank(getCase.Default_Owner_by_Country_Setting__c)) &&
                                            (cse.Origin == TS_Constants.CASE_ORIGIN_EMAIL || cse.Origin == TS_Constants.CASE_ORIGIN_EF || cse.Origin == TS_Constants.CASE_ORIGIN_IOT || cse.Origin == TS_Constants.CASE_ORIGIN_WEB || cse.Origin == TS_Constants.CASE_ORIGIN_OPERATINGORDER)) { //Francis Alindogan 12/2/2019 DOO-2689 Added IOT and WEB
                                        cse.Default_From_Address__c = countryKeyRecordTypeEmailMap.get(country).get(cse.Type);
                                        cse.Country_Setting_Signature_Record__c = countryKeyRecordTypeEmailRecordMap.get(country).get(cse.Type).id;
                                    }
                                } else if (Trigger.isInsert && Trigger.isBefore) {
                                    cse.Default_From_Address__c = countryKeyRecordTypeEmailMap.get(country).get(cse.Type);
                                    cse.Country_Setting_Signature_Record__c = countryKeyRecordTypeEmailRecordMap.get(country).get(cse.Type).id;
                                }
                            }
                        }
                    }
                }
                //System.debug(cse);
            }
        }
      


        //DEFAULT CASE OWNER 10.11.2017        
        if(!countryDefaultOwnerMap.isEmpty()){
            for (Case cse: (List<Case>) newList){               
                if(cse.RecordTypeId == CASE_CUSTOMERCARE_RECORDTYPEID || cse.RecordTypeId == CASE_COMPLAINT_RECORDTYPEID || cse.RecordTypeId == CASE_QUALIFYCASE_RECORDTYPEID || cse.RecordTypeId == CASE_CASEREG_RECORDTYPEID){
                    if(labelValueSalesOrgMap.containsKey(cse.SalesOrganization__c)){
                        String country = labelValueSalesOrgMap.get(cse.SalesOrganization__c);
                    
                        if(countryDefaultOwnerMap.containsKey(country) && IGNORE_CASEOWNER_CSETTING == false){
                            if(Trigger.isUpdate && Trigger.isBefore){
                                Case getCase = (Case) oldMapItems.get(cse.Id);
                                if(((getCase.RecordTypeId != cse.RecordTypeId) || String.isBlank(getCase.Default_Owner_by_Country_Setting__c)) && cse.Origin == TS_Constants.CASE_ORIGIN_EMAIL){
                                    
                                    if(cse.Origin != TS_Constants.CASE_ORIGIN_CONTRACTORDER){
                                        cse.Default_Owner_by_Country_Setting__c = countryDefaultOwnerMap.get(country);
                                    }
                                }
                            } else if(Trigger.isInsert && Trigger.isBefore) {

                                if(cse.Origin != TS_Constants.CASE_ORIGIN_CONTRACTORDER){
                                    cse.Default_Owner_by_Country_Setting__c = countryDefaultOwnerMap.get(country);
                                }
                            }
                        } 
                    }
                }
            }
            //Francis Allen Alindogan DOO-4676 09/04/2020
            if(IGNORE_CASEOWNER_CSETTING == true){
                IGNORE_CASEOWNER_CSETTING = false; 
            }
        }
    }
    
    /**
    * @author        Adrian Reyes
    * @date          2/16/2018
    * @description   Method to update order LSP dates when case actual dates are populated
    * @revision(s)
    */
    void updateOrderLSPDates(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        Set<String> orderTypes = new Set<String>{TS_Constants.ORDER_S40, TS_Constants.ORDER_S41, TS_Constants.CASE_SUBTYPE_SWAP, TS_Constants.ORDER_INSTYPE_MOVEMENT, TS_Constants.TS_WOT_TYPE_CONVERSION};
        Set<Id> orderIDs = new Set<Id>();
        List<Case> cases = new List<Case>();

        //JAN 24, 2019 XEN REYES Round Trip Update
        //Set<Id> caseIds = new Set<Id>();

        for(Case c: (List<Case>) newList){
            Case oldCase = (Case) oldMapItems.get(c.Id);
            if(c.Type == TS_Constants.TS_CASE_RECORDTYPE_FIELDSERVICE && orderTypes.contains(c.SubType__c) &&
               ((c.ActualDeliveryDate__c != oldCase.ActualDeliveryDate__c && c.ActualDeliveryDate__c != null) ||
                (c.ActualPickUpDate__c != oldCase.ActualPickUpDate__c && c.ActualPickUpDate__c != null) ||
                (c.ActualMovementDate__c != oldCase.ActualMovementDate__c && c.ActualMovementDate__c != null))){
                orderIDs.add(c.ApptusOrder__c);
                orderIDs.add(c.ChildOrder__c);
                cases.add(c);

                //JAN 24, 2019 XEN REYES Round Trip Update
                //caseIds.add(c.Id);
            }
        }
        

        if(!cases.isEmpty()){
            Map<Id,Apttus_Config2__Order__c> orderMap = new Map<Id,Apttus_Config2__Order__c>([SELECT Id FROM Apttus_Config2__Order__c WHERE Id IN: orderIDs AND (Apttus_Config2__Status__c =: TS_Constants.Pending OR Apttus_Config2__Status__c =: TS_Constants.SUBMITTED)]);

            for(Case c: cases){

                //Swap
                if(c.SubType__c == TS_Constants.CASE_SUBTYPE_SWAP){
                    if(orderMap.containsKey(c.ApptusOrder__c))

                        //orderMap.get(c.ApptusOrder__c).APTS_LSP_Delivery_Date__c = c.ActualDeliveryDate__c; XEN 2/5
                        orderMap.get(c.ApptusOrder__c).APTS_Delivery_Date_Authorized__c = c.ActualDeliveryDate__c;
                    
                    if(orderMap.containsKey(c.ChildOrder__c))
                        
                        //orderMap.get(c.ChildOrder__c).APTS_LSP_Pick_Up_Date__c = c.ActualPickUpDate__c; XEN 2/5
                        orderMap.get(c.ChildOrder__c).APTS_Pick_Up_Date_Authorized__c = c.ActualPickUpDate__c;
                }
                
                //Installation/De-Installation/Movement/Conversion
                else{
                    if(orderMap.containsKey(c.ApptusOrder__c)){
                        Apttus_Config2__Order__c parentOrder = orderMap.get(c.ApptusOrder__c);

                        //parentOrder.APTS_LSP_Delivery_Date__c = c.ActualDeliveryDate__c; XEN 2/5
                        parentOrder.APTS_Delivery_Date_Authorized__c = c.ActualDeliveryDate__c;

                        //parentOrder.APTS_LSP_Pick_Up_Date__c = c.ActualPickUpDate__c; XEN 2/5
                        parentOrder.APTS_Pick_Up_Date_Authorized__c = c.ActualPickUpDate__c;

                        //parentOrder.APTS_LSP_Movement_Date__c = c.ActualMovementDate__c; XEN 2/5
                        parentOrder.APTS_Movement_Date_Authorized__c = c.ActualMovementDate__c;
                    }
                }
            }
            
            if(Schema.sObjectType.Apttus_Config2__Order__c.isUpdateable())
                update orderMap.values();
        }
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          3.21.2018           
    * @description   KTS-761, KTS-762, KTS-763, KTS-764: Method responsible for preventing updates on converted anc closed cases
    * @revision(s)   
    */
    public void validateClosedAndConvertedCases(List<SObject> newList, Map<Id, SObject> oldMapItems) {
        CustomLogging.push('caseCancellation', 'CaseTriggerHandler');

        //Iterate for closed cases
        for (Case cseNew: (List<Case>) newList) {
            Case cseOld = (Case) oldMapItems.get(cseNew.Id);

            //Check if status is closed initially then proceed to validation of each fields using field set
            if (cseOld.Status == TS_Constants.STATUS_CLOSED && cseOld.Origin != TS_Constants.CASE_ORIGIN_DR) {
                //Type Field Service Closed Status
                if (cseOld.Type == TS_Constants.CASE_TYPE_FIELDSERVICE) {
                    //Invoke case field set to validate each case fields
                    for(Schema.FieldSetMember fields :Schema.SObjectType.Case.fieldSets.getMap().get(TS_Constants.FIELDSET_API_FIELDSERVICE_CLOSEDVALIDATION).getFields()) {
                        if(cseNew.get(fields.getFieldPath()) != cseOld.get(fields.getFieldPath())) {
                            //cseNew.addError(Label.TS_ErrorMsg_FieldServiceClosed); //RETURN NEEDED ISSUE 8.31.2018
                        }
                    }
                //Type Complaint Closed Status
                } else if (cseOld.Type == TS_Constants.CASE_TYPE_COMPLAINT) {
                    //Invoke case field set to validate each case fields
                    for(Schema.FieldSetMember fields :Schema.SObjectType.Case.fieldSets.getMap().get(TS_Constants.FIELDSET_API_COMPLAINT_CLOSEDVALIDATION).getFields()) {
                        if(cseNew.get(fields.getFieldPath()) != cseOld.get(fields.getFieldPath())) {
                            cseNew.addError(TS_Constants.ERRORMSG_CASECLOSEDVALIDATION);
                        }
                    }
                //Type Customer Care Closed Status
                } else if (cseOld.Type == TS_Constants.CASE_TYPE_CUSTOMERCARE) {
                    //Invoke case field set to validate each case fields
                    for(Schema.FieldSetMember fields :Schema.SObjectType.Case.fieldSets.getMap().get(TS_Constants.FIELDSET_API_CUSTOMERCARE_CLOSEDVALIDATION).getFields()) {
                        if(cseNew.get(fields.getFieldPath()) != cseOld.get(fields.getFieldPath())) {
                            cseNew.addError(TS_Constants.ERRORMSG_CASECLOSEDVALIDATION);
                        }
                    }
                }
            }

            ////KTS-764: Validation for converted field service cases (cases that generated orders either manual or automatic)
            if (cseOld.Origin != TS_Constants.CASE_ORIGIN_DR && cseOld.Type == TS_Constants.CASE_TYPE_FIELDSERVICE
                && (cseOld.CreatedOrderedManually__c 
                || cseOld.Origin == TS_Constants.CASE_ORIGIN_CONTRACTORDER
                || cseOld.Origin == TS_Constants.CASE_ORIGIN_SALESORDER)) {

                //Invoke case field set to validate each case fields
                for(Schema.FieldSetMember fields :Schema.SObjectType.Case.fieldSets.getMap().get(TS_Constants.FIELDSET_API_FIELDSERVICE_CLOSEDVALIDATION).getFields()) {
                    if(cseNew.get(fields.getFieldPath()) != cseOld.get(fields.getFieldPath())) {
                        //System.debug('fields.getFieldPath() >>> ' + fields.getFieldPath());
                        //System.debug('cseNew.get(fields.getFieldPath()) >>> ' + cseNew.get(fields.getFieldPath()));
                        //System.debug('cseOld.get(fields.getFieldPath()) >>> ' + cseOld.get(fields.getFieldPath()));
                        //System.debug ('Marvin +++ Field has changed: ' + fields);
                        //System.debug ('Marvin +++ old value: ' + cseOld.get(fields.getFieldPath()));
                        //System.debug ('Marvin +++ new value: ' + cseNew.get(fields.getFieldPath()));
                        //cseNew.addError(Label.TS_ErrorMsg_FieldServiceConversion);
                    }
                }
            }
        }

        Customlogging.pop();
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          4.25.2018           
    * @description   KTS-1684 Stamp registed contacts sales organization in complaint and customer care case records
    *                and account locations sales organization in field service cases
    * @revision(s)   
    */
    public void updateSalesOrganization(List<SObject> newList) {
        CustomLogging.push('updateSalesOrganization', 'CaseTriggerHandler');
        Set<Id> caseSetCustComp = new Set<Id>();
        Set<Id> caseSetFieldServ = new Set<Id>();
        Set<Id> phyAssetSet = new Set<Id>();
        Map<Id, Id> accLocPhyAssetMap = new Map<Id, Id>();
        
        //Collect set of contacts in the case records
        for (Case cse : (List<Case>) newList) {
            
            //if manual created case (phone, manual) && customer care or complaint
            //then retrieve sales org from contact
            if ((cse.Type == TS_Constants.CASE_TYPE_COMPLAINT
                || cse.Type == TS_Constants.CASE_TYPE_CUSTOMERCARE)
                && (cse.Origin == TS_Constants.CASE_ORIGIN_MANUAL
                || cse.Origin == TS_Constants.CASE_ORIGIN_PHONE
                || cse.Origin == TS_Constants.CASE_ORIGIN_EMAIL
                || cse.Origin == TS_Constants.CASE_ORIGIN_WEB
                || cse.Origin == TS_Constants.CASE_ORIGIN_IOT //Francis Allen Alindogan 05.20.2020 DOO-4483
                || cse.Origin == TS_Constants.CASE_ORIGIN_OPERATINGORDER) //Karen Hung 7/1/2020 DOO-5030
                && cse.ContactId != null){
                caseSetCustComp.add(cse.ContactId);
            }

            //if manual created case (phone, manual) && field service
            //then retrieve sales org from account location
            if (cse.Type == TS_Constants.CASE_TYPE_FIELDSERVICE
                && (cse.Origin == TS_Constants.CASE_ORIGIN_MANUAL
                || cse.Origin == TS_Constants.CASE_ORIGIN_PHONE
                || cse.Origin == TS_Constants.CASE_ORIGIN_EMAIL
                || cse.Origin == TS_Constants.CASE_ORIGIN_WEB
                || cse.Origin == TS_Constants.CASE_ORIGIN_IOT //Francis Allen Alindogan 05.20.2020 DOO-4483  
                || cse.Origin == TS_Constants.CASE_ORIGIN_OPERATINGORDER) //Karen Hung 7/1/2020 DOO-5030          
                ){

                //Get sales org from account location when manually input in the case record
                if (cse.AccountLocation__c != null) {
                    caseSetFieldServ.add(cse.AccountLocation__c);
                }

                //Get sales org from account location in physical asset when manually input in the case record
                if (cse.PhysicalAsset__c != null) {
                    phyAssetSet.add(cse.PhysicalAsset__c);
                }
            }
        }

        //Get the sales org of the registered contact via query
        if (!caseSetCustComp.isEmpty()) {
            for (Contact con : [SELECT Id, Sales_Organization__c FROM Contact WHERE Id IN :caseSetCustComp]) {
                for (Case cse : (List<Case>) newList) {
                    //Stamp the contacts sales org in the created for complaint and customer care case
                    if (cse.ContactId == con.Id) {
                        cse.SalesOrganization__c = con.Sales_Organization__c;
                    }
                }
            }
        }

        //Get the sales org of the account location in the physical asset via query
        if (!phyAssetSet.isEmpty()) {
            for (PhysicalAsset__c phyAsset : [SELECT Id, AccountLocation__c FROM PhysicalAsset__c WHERE Id IN :phyAssetSet]) {
                if (phyAsset.AccountLocation__c != null) {
                    caseSetFieldServ.add(phyAsset.AccountLocation__c);
                    accLocPhyAssetMap.put(phyAsset.Id, phyAsset.AccountLocation__c);
                }
            }
        }

        //Get the sales org of the account location via query
        if (!caseSetFieldServ.isEmpty()) {
            for (Apttus_Config2__AccountLocation__c accLoc : [SELECT Id, Mini_Sales_Organization__c 
                                                              FROM Apttus_Config2__AccountLocation__c 
                                                              WHERE Id IN :caseSetFieldServ]) {
                for (Case cse : (List<Case>) newList) {
                    //Stamp the account locations sales org in the created field service cases
                    if (cse.AccountLocation__c == accLoc.Id) {
                        cse.SalesOrganization__c = accLoc.Mini_Sales_Organization__c;
                    //Stamp the sales org of physical assets account location in the created field service cases
                    } else if (cse.PhysicalAsset__c != null && accLocPhyAssetMap.get(cse.PhysicalAsset__c) != null 
                        && accLocPhyAssetMap.get(cse.PhysicalAsset__c) == accLoc.Id) {
                        cse.SalesOrganization__c = accLoc.Mini_Sales_Organization__c;
                    }
                }
            }
        }

        CustomLogging.pop();
    }
    
    //Karen Hung 3/18/19 KTS-2664 , to prevent from creating Routesales request
    public void validateTasktobeCreated(List<Case> newList) {
        CustomLogging.push('validateTasktobeCreated', 'CaseTriggerHandler');
        
        try{
            
            Datetime now = Datetime.now();
            Integer offset = UserInfo.getTimezone().getOffset(now);
            Datetime local = now.addSeconds(offset/1000);

            Date localDate = Date.valueOf(local);
            String localStr = local.format();
            String dayofWeek = local.format('E');
            
            for(Case c : newList){
                
                //origin is Routesales Request and Type is Routesales
                if(c.Origin == Ts_Constants.CASE_ORIGIN_ROUTESALESREQUEST && c.Type == TS_Constants.TS_CASE_RECORDTYPE_ROUTESALES){
                 
                    Date earlyStart = Date.newInstance(c.EarlyStartDate__c.year(),c.EarlyStartDate__c.month(), c.EarlyStartDate__c.day());

                    //creating routesales request for weekdays
                    if(((dayOfWeek == Ts_Constants.FRI && earlyStart == date.today().addDays(3)) ||
                        (dayOfWeek == Ts_Constants.SAT && earlyStart == date.today().addDays(2)) ||
                        (dayOfWeek != Ts_Constants.FRI && dayOfWeek != Ts_Constants.SAT && earlyStart == date.today().addDays(1))) &&
                       system.now().time() > Time.newInstance(12,0,0,0) 
                      ){

                          c.addError(TS_Constants.ERRORMSG_CASEROUTESALESVALIDATION);
                     } 
                    
                }
            }
        } catch(Exception e){
            CustomLogging.debugException(e);
            CustomLogging.pop();
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());    
        }
        
        CustomLogging.pop(); 
    }

    /*
    * @author        Abram Vixen Reyes
    * @date          Sept. 14, 2020
    * @description   DOO - 4740 Process builder to trigger: Order Conversion
    * @revision(s)   
    */
    public void CONVERT_ORDER (List<SObject> newList, Map<Id, SObject> newMapItems, Map<Id,SObject> oldMapItems){     
        CustomLogging.push('CONVERT_ORDER', 'CaseTriggerHandler');
        
        try{

            List<Case> forConversion = new List<Case>();
            List<WorkOrder> workOrderToInsert = new List<WorkOrder>();
            List<WorkOrderLineItem> woliToInsert = new List<WorkOrderLineItem>();
            Set<String> supportedCaseOriginsForConversion = new Set<String>{TS_Constants.CASE_ORIGIN_MANUAL, TS_Constants.CASE_ORIGIN_EMAIL, TS_Constants.CASE_ORIGIN_PHONE, TS_Constants.CASE_ORIGIN_WEB, TS_Constants.CASE_ORIGIN_IOT, TS_Constants.CASE_ORIGIN_OPERATINGORDER}; //Karen Hung 7/1/2021 DOO-5030
            Set<String> supportedCaseTypesForConversion = new Set<String>{'S10','S15','S30','S31','S32','S40','S41','S42','S43','S44','S50','S51','S52','S53','S60'};
            Map<Id, Case> newCaseMap = (Map<Id, Case>) newMapItems;

            for(Case cs_var : (List<Case>) newList){
                Case cs_var_old = (Case) oldMapItems.get(cs_var.Id);
                if( cs_var.Status == TS_Constants.STATUS_INPROGRESS && cs_var.Status != cs_var_old.Status
                    && cs_var.CaseSubStatus__c == TS_Constants.CASE_SUBSTATUS_ORDEROPEN && cs_var.CaseSubStatus__c != cs_var_old.CaseSubStatus__c
                    && cs_var.CreatedOrderedManually__c == true && cs_var.CreatedOrderedManually__c != cs_var_old.CreatedOrderedManually__c
                    && cs_var.AddRequiredPartsandMaterials__c == false
                    && supportedCaseOriginsForConversion.contains(cs_var.Origin)
                    && supportedCaseTypesForConversion.contains(cs_var.SubType__c)){

                    //CASE FOR CONVERSION
                    forConversion.add(cs_var);

                }
            }

            if(!forConversion.isEmpty()){

                //GET OTHER INFORMATION FROM CASE
                Map<Id, Case> caseOtherInfo = new Map<Id, Case>([SELECT Id, AccountLocation__r.PreferredEngineer__c, AccountLocation__r.ExcludedEngineer__c FROM Case WHERE Id IN: forConversion]);

                //GET SALES ORGANIZATION FOR PRICEBOOK
                Set<String> salesOrgSet = new Set<String>();
                for(Case cs_var_2 : forConversion){
                    salesOrgSet.add(cs_var_2.SalesOrganization__c);
                }

                //QUERY PRICEBOOK
                Map<String, Pricebook2> pricebookMap = new Map<String, Pricebook2>();
                if(!salesOrgSet.isEmpty()){
                    for(Pricebook2 pb_var : [SELECT Id, Sales_Organization__c FROM Pricebook2 WHERE IsStandard = false AND Sales_Organization__c IN: salesOrgSet]){
                        pricebookMap.put(pb_var.Sales_Organization__c, pb_var);
                    }

                    if(!pricebookMap.isEmpty()){

                        //CREATE WORK ORDERS
                        for(Case cs_var_3 : forConversion){
                            WorkOrder newWorkOrder = new WorkOrder();
                            newWorkOrder.AccountId = cs_var_3.AccountId;
                            newWorkOrder.CaseId = cs_var_3.Id;
                            newWorkOrder.ContactId = cs_var_3.ContactId;
                            newWorkOrder.Created_Manually__c = true;
                            newWorkOrder.Pricebook2Id = pricebookMap.containsKey(cs_var_3.SalesOrganization__c) ? pricebookMap.get(cs_var_3.SalesOrganization__c).Id : null;
                            newWorkOrder.RecordTypeId = Schema.SObjectType.WorkOrder.getRecordTypeInfosByName().get('TS Work Order').getRecordTypeId();
                            newWorkOrder.SalesOrganization__c = cs_var_3.SalesOrganization__c;
                            newWorkOrder.WorkOrderType__c = cs_var_3.SubType__c;
                            newWorkOrder.OwnerId = cs_var_3.OwnerId;
                            newWorkOrder.Has_created_WOLI__c = true;
                            workOrderToInsert.add(newWorkOrder);
                        }

                        insert workOrderToInsert;

                        for(WorkOrder wo_var : workOrderToInsert){
                            WorkOrderLineItem newWoli = new WorkOrderLineItem();
                            
                            Case relatedCase = newCaseMap.get(wo_var.CaseId);
                            Case relatedCaseOtherInfo = caseOtherInfo.get(wo_var.CaseId);

                            newWoli.WorkOrderId = wo_var.Id;
                            newWoli.AccountLocation__c = relatedCase.AccountLocation__c;
                            newWoli.AlternativeMachine__c = relatedCase.AlternativeMachine__c;
                            newWoli.BookAppointmentStart__c = relatedCase.BookingAppointmentStart__c;
                            newWoli.BookAppointmentFinish__c = relatedCase.BookingAppointmentFinish__c;
                            newWoli.Case__c = wo_var.CaseId;
                            newWoli.Created_Manually__c = true;
                            newWoli.Subject = relatedCase.Subject;
                            newWoli.Description = relatedCase.Description;
                            newWoli.EarliestAppointmentTime__c = relatedCase.EarliestAppointmentTime__c;
                            newWoli.LatestAppointmentTime__c = relatedCase.LatestAppointmentDate__c;
                            newWoli.EarlyStart__c = relatedCase.EarlyStartDate__c;
                            newWoli.SLADate__c = relatedCase.SLADate__c;
                            newWoli.FaultConfiguration__c = relatedCase.Fault_Configuration__c;
                            newWoli.IgnoreCalendar__c = relatedCase.IgnoreCalendar__c;
                            newWoli.IsCoffeeRunning__c = relatedCase.CoffeeIsRunning__c;
                            newWoli.RepeatVisit__c = relatedCase.RepeatVisit__c;
                            newWoli.RequiredEngineer__c = relatedCase.RequiredEngineer__c;
                            newWoli.ScheduleManually__c = relatedCase.ScheduleManually__c;
                            newWoli.WorkOrderType__c = relatedCase.SubType__c;

                            //DOO-5018 XEN REYES Nov. 24, 2020
                            newWoli.PhysicalAsset__c = relatedCase.PhysicalAsset__c;

                            newWoli.PreferredEngineer__c = relatedCaseOtherInfo.AccountLocation__r.PreferredEngineer__c;
                            newWoli.ExcludedEngineer__c = relatedCaseOtherInfo.AccountLocation__r.ExcludedEngineer__c;

                            if(relatedCase.SubType__c == 'S10') newWoli.OutsideSLA__c = relatedCase.OutsideSLA__c;
                            if(relatedCase.SubType__c == 'S60') newWoli.Re_active__c = relatedCase.Re_active__c;

                            woliToInsert.add(newWoli);
                        }
                        
                        CaseTriggerHandler.CASE_CONVERTED = true;
                        insert woliToInsert;
                        
                        //INSERT FIXED COST ITEMS
                        /* List<Id> woliIdSet = new List<Id>();
                        for(WorkOrderLineItem woli : woliToInsert){
                            woliIdSet.add(woli.Id);
                        }
                        
                        TS_FlowProcessor.executeFixCostFlow(woliIdSet, null); */
                    }
                }
            }
    
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    
        CustomLogging.pop();        
    }

    /*
    * @author        Karen Mae Hung
    * @date          Oct. 12, 2020
    * @description   DOO - 4969 SF: Journey Trigger Case Rebuilding + Fixed by Phone & Cancellation
    * @revision(s)   
    */
    public void sendEmailFromCase(List<SObject> newList, Map<Id,SObject> oldMapItems){
        CustomLogging.push('sendEmailFromCase', 'CaseTriggerHandler');

        List<Case> caseForProcess = new List<Case>();
        Map<Id, Case> oldCaseMap = (Map<Id, Case>) oldMapItems;

        for(Case cse: (List<Case>) newList){
            //if case is new or status is updated to canceled or closed (fixed by phone)
            if(((cse.Status == TS_Constants.STATUS_OPEN || cse.Status == TS_Constants.STATUS_NEW) && !cse.NoCaseCreationNotification__c && !cse.Sent_Case_Create_Notification_to_Contact__c && !cse.Sent_Case_Create_Notif_to_Stakeholder__c ) ||
               (oldCaseMap.get(cse.Id).Status != cse.Status && 
               ((cse.Status == TS_Constants.STATUS_CANCELED && !cse.NoCaseCreationNotification__c && !cse.Sent_Case_Cancelation_Notif_to_Contact__c && !cse.Sent_Case_Cancel_Notif_to_Stakeholder__c) || 
               (cse.Status == TS_Constants.STATUS_CLOSED && cse.External_Solution__c != null && !cse.NoCaseClosureNotification__c && !cse.Sent_Case_Closure_Notif_to_Stakeholder__c && !cse.Sent_Case_Closure_Notif_to_Contact__c)))){
                
                   if((cse.Status == TS_Constants.STATUS_OPEN || cse.Status == TS_Constants.STATUS_NEW) && cse.Origin != TS_Constants.EMAIL && cse.Type == TS_Constants.CASE_TYPE_FIELDSERVICE){
                       if(processedEmail == 3){
                       	caseForProcess.add(cse);   
                       }
                   }else{
                   		caseForProcess.add(cse);    
                   }
                
            }

        }
		
        processedEmail = processedEmail + 1;
        if(!caseForProcess.isEmpty()){
            //processedEmail = processedEmail + 1;
            //TS_SendEmailQueueable varProcess = new TS_SendEmailQueueable();
           // varProcess.METHOD_SENDEMAILFROMCASE = true;
           // varProcess.casetoProcess = caseForProcess;
           //System.enqueueJob(varProcess);
			
            TS_SendEmail sendEmail = new TS_SendEmail();
            sendEmail.SENDFROMCASE(caseforProcess);
        }        

        CustomLogging.pop();
    }


}