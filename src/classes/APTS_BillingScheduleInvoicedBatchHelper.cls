/************************************************************
Apex Class: APTS_BillingScheduleInvoicedBatchHelper
@Author: Sai Sagar
@CreateDate: 26-05-2018
Description: Common Batch helper for Billing Schedule Invoiced
*************************************************************/
global class APTS_BillingScheduleInvoicedBatchHelper implements APTS_CommonBatchHandler {
    
    // 10 Records
    global void processBatchRecords(Database.BatchableContext context, List<Apttus_Billing__BillingSchedule__c> lstBillingSchedule,boolean control){
        System.debug('control_____________________----'+control);       
        // Get Current Batch Execution State
        List<APTS_Batch_Job_Execution__c> currentBatch = [Select id,APTS_Total_Records__c,APTS_Total_Records_Failed__c from APTS_Batch_Job_Execution__c where APTS_Job_ID__c =: context.getJobId()];
        integer processedRecords = lstBillingSchedule.size();
        processedRecords = currentBatch[currentBatch.size() - 1].APTS_Total_Records__c == null? processedRecords: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records__c+processedRecords);
        integer totalRecordsFailed =  currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c == null? 0: Integer.valueOf(currentBatch[currentBatch.size() - 1].APTS_Total_Records_Failed__c);
        //Variables declaration
        List<APTS_Batch_Error__c> lstErrorLogs = new List<APTS_Batch_Error__c>();
        Boolean pricingResult;
        //For each Order line item reprice
        if(lstBillingSchedule.size() > 0 && currentBatch.size() > 0){
        List<Apttus_Billing__BillingSchedule__c> lstBillingSchedules =new List <Apttus_Billing__BillingSchedule__c>(); 
        List<Database.SaveResult> srList = new List<Database.SaveResult>(); 
            for(Apttus_Billing__BillingSchedule__c bs:lstBillingSchedule){
                Apttus_Billing__BillingSchedule__c billingsch = new Apttus_Billing__BillingSchedule__c();
                if(bs.Apttus_Billing__AssetLineItemId__c != null){
                    if(bs.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c == 'One Time'){ 
                        billingsch.Apttus_Billing__Status__c = 'Invoiced';
                        billingsch.Apttus_Billing__HideInvoiceDisplay__c = True;
                        billingsch.Id = bs.Id;
                        lstBillingSchedules.add(billingsch);
                    }else{
                        integer frequencyinMonth = getBillingFrequencyinMonth(bs.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillingFrequency__c); 
                        if(frequencyinMonth != 0){
                            Date dt = bs.Apttus_Billing__AssetLineItemId__r.Apttus_Config2__BillThroughDate__c.addMonths(-frequencyinMonth);
                            if(bs.Apttus_Billing__ReadyForInvoiceDate__c <= dt){ 
                                billingsch.Apttus_Billing__Status__c = 'Invoiced';
                                billingsch.Apttus_Billing__HideInvoiceDisplay__c = True;
                                billingsch.Id = bs.Id;
                                lstBillingSchedules.add(billingsch);
                            }    
                        }
                    }                   
                } 
            }       
          
            
            if(lstBillingSchedules.size()>0){
                if(Test.isRunningTest()) {
                     Apttus_Billing__BillingSchedule__c billingschtest = new Apttus_Billing__BillingSchedule__c();
                    lstBillingSchedules.add(billingschtest); 
                }
               srList = Database.update(lstBillingSchedules, false); 
              
            }
                  // Iterate through each returned result
                for (Database.SaveResult sr : srList) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully Updated' + sr.getId());
                    }
                    else {
                        // Operation failed, so get all errors                
                        for(Database.Error e : sr.getErrors()) { 
                            System.debug('The following error has occurred.');                    
                            System.debug(e.getStatusCode() + ': ' + e.getMessage()); 
                            totalRecordsFailed = totalRecordsFailed+1; 
                            String errorMessage = e.getMessage();                   
                            lstErrorLogs.add(APTS_CommonBatch_Helper.createBatchErrorObject(
                                                                            currentBatch[0].Id,
                                                                            errorMessage, 
                                                                            sr.getId(), 
                                                                            'Apttus_Billing__BillingSchedule__c',
                                                                            'Error Occured During Parallel Batch Processing',
                                                                            'APTS_BillingScheduleInvoicedBatchHelper'));
                        }
                    }
                }
            }  
        //Log errors
        if(lstErrorLogs.size() > 0){
            APTS_CommonBatch_Helper.createBatchErrorLogs(lstErrorLogs);             
        }    
        if(currentBatch.size() > 0){                                    
            APTS_CommonBatch_Helper.updateExecutionLog(context.getJobId(),'In Progress',processedRecords,totalRecordsFailed );
        }       
    } 
    
    global Integer getBillingFrequencyinMonth(String Frequency){
     integer billingFreq = 0;
        if(Frequency =='Monthly'){
            billingFreq = 1;
        }
        if(Frequency =='Quarterly'){
            billingFreq = 3;
        }
        if(Frequency =='Half Yearly'){
            billingFreq = 6;
        }
        if(Frequency =='Yearly'){
            billingFreq = 12;
        }
        return billingFreq;
    }
}