/*************************************************************
@Name: APTS_StagingDataJobScheduler
@Author: Shahul
@CreateDate: 17-11-2020
@Description: 
@UsedBy: 
******************************************************************/

global without sharing class APTS_cerCachcleanJobScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
    
    APTS_cerCachceleanupBatch cc=new APTS_cerCachceleanupBatch();
    database.executebatch(cc,20);
    }
    }