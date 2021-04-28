//-------------------------------------------------------------------------------------------//
// Author       :   Rey Austral
// Created Date :   Sept 8, 2017
// Usage        :   Class to create file in the case
//-------------------------------------------------------------------------------------------//
// 4 May 2018, Archi Delphinanto implemented Object Level (Access) Security, as part of Code Review actions.
public with sharing class TS_CreateCaseReportFile_2 implements Queueable , Database.AllowsCallouts {
    public List<WorkOrderLineItem> newList { get; set; }
    public Map<Id, Boolean> requireEstimateMap = new Map<Id, Boolean>();
    public Set<Id> parentWOLI { get; set; }

    public Boolean isSalesOrder { get; set; }
    public Set<Id> caseIdSet { get; set; }
      
    public void execute(QueueableContext context) {
        System.debug('TS_CreateCaseReportFile_2:Generate work order summary' );
        CustomLogging.push('execute', 'TS_CreateCaseReportFile');
        
        //XEN REYES Jan. 9, 2019
        WorkOrderLineItemTriggerHandler.isAttachPDFBatch = true;

        //MANUAL CASES VARIABLES
        Map<Id, Id> woliParentMap = new Map<Id, Id>();
        List<WorkOrderLineItem> woliToBeProcess = (List<WorkOrderLineItem>) newList; //new List<WorkOrderLineItem>();
        //List<ContentVersion> contentList = new List<ContentVersion>(); //Karen Hung 20.9.2018

        //SALES ORDER VARIABLES

        //ARCHI: ADDED AS PART OF SECUIRTY BEST PRACTICE: CRUD CHECK
        Boolean hasUpdateRightOnCase  = TS_UtilityClass.isSObjectUpdateable(new String[] {'Case'});    
        
        //PDF GENEATION FOR MANUAL FIELD CASES  
        if(!parentWOLI.isEmpty() && hasUpdateRightOnCase && !isSalesOrder){
            System.debug('TS_CreateCaseReportFile_2: GENERATE WORK ORDER SUMMARY STARTS HERE: Manual Cases' );
			List<ContentVersion> contentList = new List<ContentVersion>();//karen Hung 20.9.2018 
            Map<Id,WorkOrderLineItem> parentWOLIMap = new Map<Id,WorkOrderLineItem>(
                        [SELECT Id, JDELineItemNumber__c, TS_Total_Cost_Labor_Price__c, TS_Total_Estimate_Labor_Price__c
                         FROM WorkOrderLineItem WHERE Id IN : parentWOLI]);

            ///5.2018: PREPARE CHILD WOLI DATA         
            Map<Id, List<WorkOrderLineItem>> subWoliMap = getSubWoliMap(parentWOLIMap.keySet());

            //5.22.2018: CALCULATE SUMMARY
            if(Userinfo.getUserType() == 'Standard'){
                    calculateTotalcost(parentWOLIMap.values(), subWoliMap);
            }

            //XEN REYES 8.29.2018
            if(Userinfo.getUserType() == 'Standard'){
                for (WorkOrderLineItem lineItem : woliToBeProcess) {
                    Boolean requireCostEstimate = requireEstimateMap.get(lineItem.Id);

                    Blob b;
                    Blob bSig;

                    //GENERATE PDF FOR WORK COST ESTIMATE, ONLY GENERATE WHEN IT IS REQUIRED BY THE CASE
                    if (requireCostEstimate) {
                        PageReference pdf = Page.CostEstimate;               
                        pdf.getParameters().put('id',lineItem.ParentWorkOrderLineItemId);
                        pdf.setRedirect(true);
                        
                        b = Test.isRunningTest()? Blob.valueOf('UNIT.Test') : pdf.getContent();

                        ContentVersion signatureFile = new ContentVersion();
                        signatureFile.VersionData = b;
                        signatureFile.Title = 'WO Estimate ' + parentWOLIMap.get(lineItem.ParentWorkOrderLineItemId).JDELineItemNumber__c; //woli.JDELineItemNumber__c;
                        signatureFile.PathOnClient = 'WO_Estimate_' + parentWOLIMap.get(lineItem.ParentWorkOrderLineItemId).JDELineItemNumber__c  + '.pdf';
                        signatureFile.ContentLocation='S';
                        signatureFile.Description  = lineItem.Case__c;
                        signatureFile.ObjectReferenceID__c =lineItem.ParentWorkOrderLineItemId ;//
                        contentList.add(signatureFile);
                    }

                    //GENERATE PDF FOR WORK ORDER SUMMARY 
                    PageReference pdfsig = Page.WorkOrderOverview;
                    pdfSig.getParameters().put('id',lineItem.ParentWorkOrderLineItemId); 
                    pdfSig.setRedirect(true);

                    bSig = Test.isRunningTest() ? Blob.valueOf('UNIT.Test') : pdfSig.getContent();

                    ContentVersion summaryFile = new ContentVersion();
                    summaryFile.VersionData = bSig;
                    summaryFile.Title = 'WO Summary ' + parentWOLIMap.get(lineItem.ParentWorkOrderLineItemId).JDELineItemNumber__c;
                    summaryFile.PathOnClient = 'WO_Summary_' + parentWOLIMap.get(lineItem.ParentWorkOrderLineItemId).JDELineItemNumber__c  + '.pdf';
                    summaryFile.ContentLocation='S';
                    summaryFile.Description  = lineItem.Case__c;
                    summaryFile.ObjectReferenceID__c = lineItem.ParentWorkOrderLineItemId;
                    contentList.add(summaryFile);

                }
            }
            
            //XEN REYES DOO-4773
            /* List<WorkOrderLineItem> parentWoliTobeProcess = new List <WorkOrderLineItem> ();
            for (WorkOrderLineItem pwoli : [SELECT Id, ReadytosendEmail__c, TS_Total_Cost_Labor_Price__c, TS_Total_Estimate_Labor_Price__c FROM WorkOrderLineItem WHERE Id IN: parentWOLI]){
                    pwoli.ReadytosendEmail__c =true; //Karen Hung 21.9.2018 changed from IsReadyToSummarize__c
                    parentWoliTobeProcess.add(pwoli);
            } */

            Savepoint sp = Database.setSavepoint();
            try {

                Map<String, ContentDistribution> pathName_contentDistr_map = new Map<String, ContentDistribution>();

                //XEN REYES 8.29.2018
                if(Userinfo.getUserType() == 'Standard'){
                    insert contentList;
                    List<ContentDistribution> cdList = new List<ContentDistribution>();
                    List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();

                    for(ContentVersion cont : [SELECT ContentDocumentId,Description,PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE id =: contentList]) {

                        //ATTACH FILE TO CASE
                        cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.Description, ShareType = 'V'));

                        //ATTACH FILE TO WOLI
                        cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.ObjectReferenceID__c, ShareType = 'V') );

                        ContentDistribution cd = new ContentDistribution();
                        cd.PreferencesAllowPDFDownload = true;
                        cd.Name = cont.PathOnClient;
                        cd.ContentVersionId = cont.Id;
                        cd.RelatedRecordId = cont.Description;
                        cd.PreferencesAllowOriginalDownload = false;
                        //cd.PreferencesAllowPDFDownload = false;
                        cd.PreferencesAllowViewInBrowser = true;
                        cdList.add(cd);
                    }

                    if(!cdlList.isEmpty()) insert cdlList;
                    if(!cdList.isEmpty()) insert cdList;

                    if(!cdList.isEmpty()){
                        List<ContentDistribution> newList_content = [SELECT Id, Name, DistributionPublicUrl, PdfDownloadUrl FROM ContentDistribution WHERE Id =: cdList];
                        for(ContentDistribution cd_var : newList_content){
                            pathName_contentDistr_map.put(cd_var.Name, cd_var);
                        }
                    }
    
                }
                
                //DELETE DUMMY WOLI
                //if(userinfo.getlastName() != 'Gatchalian'){
                delete woliToBeProcess;
                //}

                List<WorkOrderLineItem> parentWoliTobeProcess = new List <WorkOrderLineItem> ();
                for (WorkOrderLineItem pwoli : [SELECT Id, JDELineItemNumber__c, ReadytosendEmail__c, TS_Total_Cost_Labor_Price__c, TS_Total_Estimate_Labor_Price__c FROM WorkOrderLineItem WHERE Id IN: parentWOLI]){

                        String name_summary = 'WO_Summary_' + String.valueOf(pwoli.JDELineItemNumber__c) + '.pdf';
                        String name_estimate = 'WO_Estimate_' + String.valueOf(pwoli.JDELineItemNumber__c) + '.pdf';

                        pwoli.WorkOrderSummaryPDFURL__c = pathName_contentDistr_map.containsKey(name_summary) ? pathName_contentDistr_map.get(name_summary).PdfDownloadUrl : null;
                        pwoli.CostEstimatePDFURL__c = pathName_contentDistr_map.containsKey(name_estimate) ? pathName_contentDistr_map.get(name_estimate).PdfDownloadUrl : null;
                        pwoli.HasQuotingSignature__c = pwoli.CostEstimatePDFURL__c != null ? true : false;
                        pwoli.ReadytosendEmail__c =true; //Karen Hung 21.9.2018 changed from IsReadyToSummarize__c
                        parentWoliTobeProcess.add(pwoli);
                }
                
                //UPDATE PARENT WOLI IsReadyToSummarize__c to TRUE
                update parentWoliTobeProcess;
              
            } catch(Exception ex) {
                Database.rollback(sp);
                CustomLogging.debugException(ex);
                CustomLogging.pop();     
            }
        
        }
		//PDF GENERATION FOR SALES TRIGGERED CASES - XR 6.25.2018 KTS-1767  		
        if(caseIdSet !=null){ //Karen Hung 20.9.2018 separated if condition for sales triggered cases
            System.debug('TS_CreateCaseReportFile_2: GENERATE WORK ORDER SUMMARY STARTS HERE: Sales Triggered Cases' );
			
			List<ContentVersion> contentList1 = new List<ContentVersion>(); //Karen Hung 20.9.2018 separated content List
            Map<Id, List<WorkOrderLineItem>> caseIdparentWOLIListMap = new Map<Id, List<WorkOrderLineItem>>();
            Map<Id, List<WorkOrderLineItem>> caseIdchildWOLIListMap = new Map<Id, List<WorkOrderLineItem>>();
            Map<Id, String> caseIdCaseNumberList = new Map<Id, String>();
            Id taskId = Schema.SObjectType.WorkOrderLineItem.getRecordTypeInfosByName().get('Register Task').getRecordTypeId();
            List<Case> caseToUpdateCost = new List<Case>();

            Map<Id,WorkOrderLineItem> woliMap = new Map<Id,WorkOrderLineItem>(
                        [SELECT Id, ParentWorkOrderLineItemId, RecordTypeId, Case__c, Case__r.CaseNumber, WorkOrderLineItemType__c, IsReadyToSummarize__c, TS_Sub_Total_Cost_Price__c, JDELineItemNumber__c, TS_Total_Cost_Labor_Price__c, TS_Total_Estimate_Labor_Price__c FROM WorkOrderLineItem WHERE Case__c IN : caseIdSet]);

            System.debug('XEN 6.25: woliMap' + woliMap);

            if(!woliMap.isEmpty()){
                //GET ALL PARENT AND CHILD WOLIS
                for(WorkOrderLineItem wo : woliMap.values()){
                    if(wo.ParentWorkOrderLineItemId == null && wo.RecordTypeId == taskId){
                        if(caseIdparentWOLIListMap.containsKey(wo.Case__c)){
                            caseIdparentWOLIListMap.get(wo.Case__c).add(wo);
                        } else {
                            caseIdparentWOLIListMap.put(wo.Case__c, new List<WorkOrderLineItem>{wo});
                        }

                        //CREATE A CASE ID to CASE NUMBER MAP
                        if(!caseIdCaseNumberList.containsKey(wo.Case__c)){
                            caseIdCaseNumberList.put(wo.Case__c, wo.Case__r.CaseNumber);
                        }

                    } else {
                        if(caseIdchildWOLIListMap.containsKey(wo.Case__c)){
                            caseIdchildWOLIListMap.get(wo.Case__c).add(wo);
                        } else {
                            caseIdchildWOLIListMap.put(wo.Case__c, new List<WorkOrderLineItem>{wo});
                        }
                    }
                }

                System.debug('XEN 6.25: caseIdparentWOLIListMap' + caseIdparentWOLIListMap);
                System.debug('XEN 6.25: caseIdchildWOLIListMap' + caseIdchildWOLIListMap);

                //GENERATE SUMMARY FOR EACH CASE
                List<Case> caseToUpdateList = new List<Case>();
                for(Id caseId : caseIdSet){
					system.debug('karen case Id' + caseId);
                    //XEN REYES 8.29.2018
                    if(Userinfo.getUserType() == 'Standard'){
                        Blob b;
                        Blob bSig;

                        //GENERATE PDF FOR WORK ORDER SUMMARY
                        PageReference pdfsig = Page.WorkOrderOverviewSales;
                        pdfSig.getParameters().put('id', caseId); 
                        pdfSig.setRedirect(true);

                        bSig = Test.isRunningTest() ? Blob.valueOf('UNIT.Test') : pdfSig.getContent();

                        ContentVersion summaryFile = new ContentVersion();
                        summaryFile.VersionData = bSig;
                        summaryFile.Title = 'WO Summary ' + caseIdCaseNumberList.get(caseId);
                        summaryFile.PathOnClient = 'WO_Summary_' + caseIdCaseNumberList.get(caseId) + '.pdf';
                        summaryFile.ContentLocation='S';
                        summaryFile.Description  = caseId;
                        summaryFile.ObjectReferenceID__c = caseId;
                        contentList1.add(summaryFile);
                    }

                    //SET CASE TO SEND EMAIL (SALES ORDER CLOSURE EMAIL)
                    Case cs = new Case(Id = caseId, TS_SalesOrderCompleteEmailReady__c = true);
                    caseToUpdateList.add(cs);
                }

                Savepoint sp = Database.setSavepoint();
                try {

                    //XEN REYES 8.29.2018
                    if(Userinfo.getUserType() == 'Standard'){
                        insert contentList1;
                        System.debug('XEN 6.25: contentList1' + contentList1);

                        List<ContentDistribution> cdList = new List<ContentDistribution>();
                        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();

                        for(ContentVersion cont : [SELECT ContentDocumentId,Description,PathOnClient, ObjectReferenceID__c FROM ContentVersion WHERE id =: contentList1]) {

                            //ATTACH FILE TO CASE
                            cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.Description, ShareType = 'V'));

                            //ATTACH FILE TO WOLI
                            //cdlList.add( new ContentDocumentLink(ContentDocumentId = cont.ContentDocumentId, LinkedEntityId = cont.ObjectReferenceID__c, ShareType = 'V') );

                            ContentDistribution cd = new ContentDistribution();
                            cd.PreferencesAllowPDFDownload = true;
                            cd.Name = cont.PathOnClient;
                            cd.ContentVersionId = cont.Id;
                            cd.RelatedRecordId = cont.Description;
                            cd.PreferencesAllowOriginalDownload = false;
                            //cd.PreferencesAllowPDFDownload = false;
                            cd.PreferencesAllowViewInBrowser = true;
                            cdList.add(cd);
                        }

                        if(!cdlList.isEmpty()) insert cdlList;
                        if(!cdList.isEmpty()) insert cdList;

                        System.debug('XEN 6.25: cdlList' + cdlList);
                        System.debug('XEN 6.25: cdList' + cdList);
                    }

                    //UPDATE CASE TO TRIGGER SEND EMAIL CLOSURE (SALES ORDER)
                    update caseToUpdateList;
                    
                    //Karen Hung 19.9.2018 delete dummy wolis for sales triggered cases
                    List<WorkOrderLineItem> dummyforDelete = [SELECT ID from WorkOrderLineItem where ParentWorkOrderLineItemId != null AND Case__c IN :caseIdSet];
                    if(Schema.sObjectType.WorkOrderLineItem.isDeletable()){
                        database.delete(dummyforDelete);
                    }
                    
                  
                } catch(Exception ex) {
                    Database.rollback(sp);
                    CustomLogging.debugException(ex);
                    CustomLogging.pop();     
                }
            }

        }

        CustomLogging.pop();           
    }
    
    //CREATE A MAP WITH PARENTWOLI ID & LIST OF CHILD WOLIS THAT HAS A PARENT WOLI (ParentWOLIId)
    private Map<Id, List<WorkOrderLineItem>> getSubWoliMap(Set<Id> parentWOLIList){

        Map<Id, List<WorkOrderLineItem>>  subwoliMaplocal = new Map<Id, List<WorkOrderLineItem>> ();       
        for(WorkOrderLineItem subwoli : [SELECT Id, ParentWorkOrderLineItemId, TS_Sub_Total_Cost_Price__c, TS_Sub_Total_Estimated_Price__c, WorkOrderLineItemType__c,IsLabour__c, IsReadyToSummarize__c FROM WorkOrderLineItem WHERE ParentWorkOrderLineItemId IN: parentWOLIList]) {
                                            
            if(subwoliMaplocal.containsKey(subwoli.ParentWorkOrderLineItemId)) {
                List<WorkOrderLineItem> subwolilist = subwoliMaplocal.get(subwoli.ParentWorkOrderLineItemId);
                subwolilist.add(subwoli);
                subwoliMaplocal.put(subwoli.ParentWorkOrderLineItemId, subwolilist);
            } else {
                subwoliMaplocal.put(subwoli.ParentWorkOrderLineItemId, new List<WorkOrderLineItem> { subwoli });
            }
        }

        return subwoliMaplocal;
    }
    
    //CALCULATE TOTAL COST FOR ESTIMATE AND WORK ORDER SUMMARY
    private void calculateTotalcost (List<WorkOrderLineItem> parentWolis, Map<Id, List<WorkOrderLineItem>> subWoliMap) {
        
        List<WorkOrderLineItem> parentWolisToUpdate = new List <WorkOrderLineItem>();
        for (WorkOrderLineItem eachParent :parentWolis){
            WorkOrderLineItem updatedParentWoli = new WorkOrderLineItem();
            updatedParentWoli.id = eachParent.id;
            Decimal totalCost = 0;
            Decimal totalEstimateCost = 0;

            List<WorkOrderLineItem> childWolis = subWoliMap.get(eachParent.id);
            for (WorkOrderLineItem eachChild :childWolis) {
                
                if ((eachChild.WorkOrderLineItemType__c == 'UsedSpareParts' || 
                    (eachChild.WorkOrderLineItemType__c == 'Service Materials' && !eachChild.IsLabour__c)) &&
                    !eachChild.IsReadyToSummarize__c  ) {
                        
                    if (eachChild.TS_Sub_Total_Cost_Price__c!=null) totalCost = totalCost + eachChild.TS_Sub_Total_Cost_Price__c;   
                    if (eachChild.TS_Sub_Total_Estimated_Price__c!=null) totalEstimateCost = totalEstimateCost + eachChild.TS_Sub_Total_Estimated_Price__c;
                }
            }
            
            //XR 5.28
            if (eachParent.TS_Total_Cost_Labor_Price__c != null) updatedParentWoli.TotalCost__c = String.valueOf(totalCost + eachParent.TS_Total_Cost_Labor_Price__c); 
            if (eachParent.TS_Total_Estimate_Labor_Price__c != null) updatedParentWoli.EstimateTotalCost__c = String.valueOf(totalEstimateCost + eachParent.TS_Total_Estimate_Labor_Price__c);
            parentWolisToUpdate.add(updatedParentWoli);
        }

        if (!parentWolisToUpdate.isEmpty()) {
            update parentWolisToUpdate;
        }
             
    }
   
}