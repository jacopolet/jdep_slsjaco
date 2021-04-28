/************************************************************
Apex Class: APTS_ActivateAgreementBatchHelper
@Author: Rahul Garje
@CreateDate: 29-09-2018
Description: Common Batch helper for Activating Agreement
*************************************************************/
global class APTS_ActivateAgreementBatchHelper implements APTS_CommonBatchHandler {

    global void processBatchRecords(Database.BatchableContext context, List<Apttus__APTS_Agreement__c> lstAgreements,boolean control){
        System.debug('RG: Activate Agreement control_____________________----'+control);       
        // Get Current Batch Execution State
        List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,APTS_Total_Records_Failed__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
        integer processedRecords = lstAgreements.size();
        processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
        integer totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);
        //Variables declaration
        List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();
        List<Attachment> createAttachement= new List<Attachment>();
        List<Attachment> deleteAttachement= new List<Attachment>();
        Map<Id,Id> agreementwithAttachmentId = New Map<Id,Id>();
        List<Id> listActivatedDocIds = new List<Id>();
        List<Id> listRemovableDocIds = new List<Id>();
        Set<Id> agreementIds = new Set<Id>();

        if(lstAgreements.size() > 0 && lstAgreements.size() > 0){
            Blob document = [select id,name,body from StaticResource where name = 'DMAttachment'].body;
            for(Apttus__APTS_Agreement__c agreementlist: lstAgreements){ 
                //Agreements to update
                system.debug('agreementlist:::::' + agreementlist.Id); 

                Attachment atmt = new Attachment();
                atmt.ParentId = agreementlist.Id;
                atmt.Name = 'Migrated Attachment';
                atmt.ContentType = 'application/msword';
                atmt.Body = document;
                createAttachement.add(atmt);
                agreementIds.add(atmt.ParentId);
            }

            if(createAttachement != null && createAttachement.size() > 0){
                insert createAttachement;
            }

            for(Attachment attch : [Select id,Name,ParentId,Body,ContentType from Attachment where ParentId IN : agreementIds and Name ='Migrated Attachment']){
                if(agreementwithAttachmentId.containsKey(attch.ParentId)){ 
                    agreementwithAttachmentId.put(attch.ParentId,attch.Id); 
                }else{
                    agreementwithAttachmentId.put(attch.ParentId,attch.Id);
                }       
            deleteAttachement.add(attch); // List to delete the document from the Notes and Attachment
            }
            System.debug('agreementwithAttachmentId-->'+agreementwithAttachmentId);

            for(Id AgreementId : agreementwithAttachmentId.keySet()){
                try{  
                    //Agreements to update
                    system.debug('agreementlist:::::' + AgreementId); 
                    System.debug('agreementwithAttachmentId.get(AgreementId)-->'+agreementwithAttachmentId.get(AgreementId));
                    listActivatedDocIds.clear();
                    listActivatedDocIds.add(agreementwithAttachmentId.get(AgreementId));
                    System.debug('listActivatedDocIds --->'+listActivatedDocIds);
                    Boolean response = Apttus.AgreementWebService.activateAgreement(AgreementId, listActivatedDocIds, listRemovableDocIds);             
                }Catch(Exception e){
                    totalRecordsFailed = totalRecordsFailed+1;
                    String errorMessage = e.getMessage() + '<>' +  e.getStackTraceString();
                    lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(
                                                                    currentBatch[0].Id,
                                                                    errorMessage, 
                                                                    AgreementId, 
                                                                    'Apttus__APTS_Agreement__c',
                                                                    'Error Occured During Parallel Batch Processing Apttus Activate Agreement API Exception ',
                                                                    'APTS_ActivateAgreementBatchHelper'));  
                }
            }
            
            Database.DeleteResult[] drList = Database.delete(deleteAttachement, false);
            
            // Iterate through each returned result
            for (Database.DeleteResult dr : drList) {
                if (!dr.isSuccess()) {
                // Operation failed, so get all errors                
                    for(Database.Error err : dr.getErrors()) {                   
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        totalRecordsFailed = totalRecordsFailed+1;
                        String errorMessage = err.getStatusCode() + '<>' + err.getMessage();
                        lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(
                                                                        currentBatch[0].Id,
                                                                        errorMessage, 
                                                                        dr.getId(), 
                                                                        'Attachment',
                                                                        'Error Occured During Parallel Batch Processing while Deleting the Attachement',
                                                                        'APTS_ActivateAgreementBatchHelper')); 
                    }
                }
            }
            //Log errors
            if(lstErrorLogs.size() > 0){
                APTS_CommonBatch_Helper.createBatchErrorLogs(lstErrorLogs);             
            }
        }
        if(currentBatch.size() > 0){                                    
            APTS_CommonBatch_Helper.updateExecutionLog(context.getJobId(),'In Progress',processedRecords,totalRecordsFailed );
        }   
    }
}