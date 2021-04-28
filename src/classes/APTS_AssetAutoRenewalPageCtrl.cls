/*************************************************************
@Name: APTS_AssetAutoRenewalPageCtrl
@Author: Karan Khatri
@CreateDate: 15-07-2019
@Description: Batch class to display live batch progress, initiate Auto renewal job and rollback job
@Reference JIRA : DFT2C-58
*****************************************************************/
global without sharing class APTS_AssetAutoRenewalPageCtrl{
    public Transient  Integer numberOfJobs {get; set;}
    public Transient String batchComponentLabel {get; set;}
    public final String SYS_ADMIN = 'System Administrator';
 
    /*******************************************************************************************************
    * @description query for the current batch job progress
    */  
    global List<BatchJob> getBatchJobs() {
        //Create new list of BatchJobs, a wrapper class that includes the job and percent complete.
        List<BatchJob> batchJobs = new List<BatchJob>();
        List<AsyncApexJob> jobsToExecuteList = new List<AsyncApexJob>();
        //If number of jobs was not defined, default to 20
        if(numberOfJobs== null || numberofJobs <= 0) {
            numberofJobs = 10;
        }
        IF(batchComponentLabel!='Rollback Batch Progress:'){ 
            //Query the Batch apex jobs for Auto renewal batch
            jobsToExecuteList = [select TotalJobItems, Status, NumberOfErrors,JobItemsProcessed, Id, 
                                        CreatedDate, CreatedById, CompletedDate, ApexClass.Name 
                                        From AsyncApexJob where (ApexClass.name like '%AssetRenewalBatch_Phase%' or ApexClass.name like '%AssetRenewalRollbackBatch%') and JobType = 'BatchApex'
                                        order by CreatedDate desc limit :numberOfJobs];
        }
        if(!jobsToExecuteList.isEmpty()){
           for(AsyncApexJob a : jobsToExecuteList){
                BatchJob j = new BatchJob();
                j.job = a;
                j.percentComplete = getJobPercentage(a.JobItemsProcessed,a.TotalJobItems,a.status);
                batchJobs.add(j);
            }
        }
        return batchJobs;
    }
 
    /* @description wrapper class includes the job itself and a value for the percent complete
    */  
    global Class BatchJob{
        global AsyncApexJob job {get; set;}
        global boolean isChecked{get;set;}
        global Integer percentComplete {get; set;}
        global boolean status{get;set;}
    }
   
   //Method to Run Auto renewal page
   global void initiateAutoRenewalBatch() {
        Set<String> pendingJobStatus = new Set<String>{'Preparing','Processing','Queued','Holding'};
        List<AsyncApexJob> pendingJobs = [select Status from AsyncApexJob where (ApexClass.name like '%AssetRenewalBatch%' or ApexClass.name like '%AssetRenewalRollbackBatch%') and Status IN : pendingJobStatus and ParentJobId =null];
        System.debug('*****pendingJobs=====>'+pendingJobs);
        if(pendingJobs.isEmpty()){
            //Database.executeBatch(new APTS_AssetRenewalBatch_Phase1(),Integer.valueOf(System.Label.APTS_AutoAssetRenewalBatchSize));
            Database.executeBatch(new APTS_AssetRenewalRollbackBatch(),Integer.valueOf(System.Label.APTS_AutoAssetRenewalBatchSize));
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'There are already running jobs for Auto renewal batch. Please run the jobs once completed !'));
        }
   }
    
    public Integer getJobPercentage(Double ItemsProcessed, Double totalItems,String status){
        Integer percentComplete;
        //Determine the pecent complete based on the number of batches complete
        if(status == 'Completed') {
            percentComplete = 100;
        //Determine the pecent complete based on the number of batches complete
        } else if (totalItems == 0) {
            //A little check here as we don't want to divide by 0.
            percentComplete = 0;
        } else {
            percentComplete = ((itemsProcessed  / totalItems) * 100.0).intValue();
        }
        return percentComplete;
    }
}