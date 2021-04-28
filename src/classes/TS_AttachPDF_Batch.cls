/**
 * @author        Karen Hung
 * @date          9/13/2018
 * @description   Apex batch class for generating PDF File, updating IsReadyToSummarize__c of task and deleting dummy service material
 * @revision(s)
 */
global with sharing class TS_AttachPDF_Batch implements Database.Batchable <sObject> {
    
    public Boolean SOQL_OVERRIDE = false;
    public String NEW_SOQL_STRING;
    private Exception[] errors = new Exception[0];

  public class TS_AttachPDF_BatchException extends Exception {}
    
    global TS_AttachPDF_Batch() {
        
    }
    
    /* query to start job*/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('start', 'TS_AttachPDF_Batch');    
        CustomLogging.pop();  
        return Database.getQueryLocator(query());
    }
    
    /*actions during job execution*/
    global void execute(Database.BatchableContext BC, List<WorkOrderLineItem> dummyWolis) {
        CustomLogging.push('execute', 'TS_AttachPDF_Batch'); 

        //XEN REYES Jan. 9, 2019
        WorkOrderLineItemTriggerHandler.isAttachPDFBatch = true;

        //get parentIDs
        Map<Id,Boolean> requireEstimateMap = new Map<Id,Boolean>();  

        List<WorkOrderLineItem> woList = new List<WorkOrderLineItem>(); //wolis that meet if conditions        
        List<Attachment> attachmentList = new List<Attachment>();   
        List<WorkOrderLineItem> woliToUpdateList = new List<WorkOrderLineItem>();  

        Set<Id> parentWOLI = new Set<Id>();
        Set<Id> caseIds = new Set<Id>(); //case id's for attachment
        //Set<String> taskTypes = new Set<String>{'S10','S15','S30','S31','S32','S40','S41','S42','S60'};

        Boolean hasSignature = false;

        for(WorkOrderLineItem woli : dummyWolis){
                
            //if(taskTypes.contains(woli.CaseSubType__c) || woli.TS_CaseOrigin__c == 'Sales Order'){
            woList.add(woli);
            requireEstimateMap.put(woli.id,woli.ParentWorkOrderLineItem.QuotingSignature__c != null ? true : false);   
            
            /*another scenario from createSignatureAttachments of wolitriggerhandler*/
            if(Boolean.valueOf(System.Label.TS_AttachPDFEnableSignature) || Test.isRunningTest()){
                if (!String.isBlank(woli.ParentWorkOrderLineItem.QuotingSignature__c)) {
                    attachmentList.add(generateAttachment('Quote Signature', new WorkOrderLineItem(id = woli.ParentWorkOrderLineItemId), woli.ParentWorkOrderLineItem.QuotingSignature__c));
                    hasSignature = true;                   
                }
                if (!String.isBlank(woli.ParentWorkOrderLineItem.Signature__c)) {
                    attachmentList.add(generateAttachment('Signature', new WorkOrderLineItem(id = woli.ParentWorkOrderLineItemid), woli.ParentWorkOrderLineItem.Signature__c));
                    hasSignature = true;
                }

                //XEN REYES Jan 9, 2019 - To avoid duplicate               
                if(hasSignature == true) {
                    if(!parentWoli.contains(woli.ParentWorkOrderLineItemid)){
                        woliToUpdateList.add(new WorkOrderLineItem(Id = woli.ParentWorkOrderLineItemid, HasSignature__c = true));
                    }
                }
            }
            
            parentWoli.add(woli.ParentWorkOrderLineItemId);
            //}
        }
               
        /*generate work order summary*/
        if(woList != null || caseIds !=null){
            TS_CreateCaseReportFile_2 createPDF = new TS_CreateCaseReportFile_2();
            createPDF.newList = woList;
            createPDF.parentWOLI = parentWOLI; 
            createPDF.requireEstimateMap = requireEstimateMap;
            createPDF.isSalesOrder = false;
            createPDF.caseIdSet = caseIds; //for sales order
            System.enqueueJob(createPDF);
        }

        /*create signature attachment*/
        if(!attachmentList.isEmpty()) {
            try {
                
                if(Schema.sObjectType.Attachment.isCreateable()){                
                    database.insert(attachmentList);
                }              
                
                if(Boolean.valueOf(System.Label.TS_AttachPDFEnableSignature)){
                    if(Schema.sObjectType.WorkOrderLineItem.isUpdateable()) {
                        database.update(woliToUpdateList);
                    }
                }

            } catch(Exception ex) {
                CustomLogging.debugException(ex);
                CustomLogging.pop();
            }            
        }
        

        CustomLogging.pop();            
    }

    /*after execution actions*/
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TS_AttachPDF_Batch');   
        CustomLogging.pop();           
    }

    /*query*/
    String query(){
        CustomLogging.push('query', 'TS_AttachPDF_Batch');

        DescribeSObjectResult woli = WorkOrderLineItem.getSObjectType().getDescribe();
        List<String> fields = new List<String>(woli.fields.getMap().keySet());
        String SERVICE_MATERIAL = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Service Material').getRecordTypeId();

        //XEN REYES July 29, 2019
        String STR_COUNTRIES;
        if(Test.isRunningTest()){
            STR_COUNTRIES = ' \'SAP_0333\', \'SAP_6712\' ';
        } else {
            STR_COUNTRIES = System.Label.TS_AttachPDFCountries;
        }

        //XEN REYES August 8, 2019
        String STR_TASKTYPES;
        if(Test.isRunningTest()){
            STR_TASKTYPES = ' \'S10\',\'S15\',\'S30\',\'S31\',\'S32\',\'S40\',\'S41\',\'S42\',\'S60\' ';
        } else {
            STR_TASKTYPES = System.Label.TS_AttachPDFTaskType;
        }
        
        Boolean getOnlyToday = Boolean.valueOf(System.Label.TS_AttachPDFGetToday);

        CustomLogging.pop(); 

        String DEFAULT_SOQL = 'SELECT ' + String.join(fields, ',') + ', Case__r.Status, ' +
                    ' ParentWorkOrderLineItem.Case__c, ParentWorkOrderLineItem.TS_CaseOrigin__c, ParentWorkOrderLineItem.JDELineItemNumber__c, ParentWorkOrderLineItem.Case__r.Status, ParentWorkOrderLineItem.Signature__c, ParentWorkOrderLineItem.QuotingSignature__c, WorkOrder.SalesOrganization__c ' +
                    ' FROM WorkOrderLineItem ' +
                    ' WHERE ParentWorkOrderLineItem.PhysicalAsset__c != null AND Recordtypeid= ' + '\'' + SERVICE_MATERIAL + '\'' + 
                    ' AND WorkOrder.SalesOrganization__c IN (' + STR_COUNTRIES + ')' +
                    ' AND CaseSubType__c IN (' + STR_TASKTYPES + ')' +
                      (getOnlyToday ? ' AND CreatedDate = TODAY ' : ' ') +
                    ' AND IsReadyToSummarize__c = true AND ParentWorkOrderLineItemId != null AND ParentWorkOrderLineItem.Status = \'Completed\' AND ParentWorkOrderLineItem.ExecutingEngineer__r.UserProfile__c != \'Third Party Capacity\'';
        
        System.debug(DEFAULT_SOQL);
        System.debug(STR_COUNTRIES);
        System.debug(STR_TASKTYPES);

        if(SOQL_OVERRIDE){
            return NEW_SOQL_STRING;
        } else {
            return DEFAULT_SOQL;
        }

    }
    
    public Attachment generateAttachment(String attachmentName, WorkOrderLineItem woli, String blobString) {
        Attachment attachmentImage = new Attachment();
        attachmentImage.parentId = woli.id;
        attachmentImage.name = attachmentName.replace(' ','') + '_'+woli.JDELineItemNumber__c+'.png';
        attachmentImage.description = attachmentName;
        blob fileContent = EncodingUtil.base64Decode(blobString);
        attachmentImage.body = fileContent;
        
        System.debug('XEN 11/7 attachmentImage: ' + attachmentImage);
        return attachmentImage;
    }
    

}