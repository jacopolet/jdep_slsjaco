/**
* Class Name : APTS_AutoAssetRenewalScheduler
* Description : Daily job for Auto Asset Renewals
* Author : Karan Khatri
* Date Created : 27/08/2019
**/
global without sharing class APTS_AutoAssetRenewalScheduler implements Schedulable{

    /** Method Name : execute
    * Description : execute method of the scheduler class
    **/
    global void execute(SchedulableContext context){
        Database.executeBatch(new APTS_AssetRenewalRollbackBatch(),Integer.valueOf(System.Label.APTS_AutoAssetRenewalBatchSize));
    }
}