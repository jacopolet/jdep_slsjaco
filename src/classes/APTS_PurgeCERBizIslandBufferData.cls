/**********************************************************************************
 * @Author: Keerthana
 * @Company: Accenture
 * @Description: Batch to Delete CER BizIsland Temporary Table Records
 * @Created Date: March 25, 2019
 * @History:
 *      <Name>              <Date>          <Description>
 *      Keerthana           25.03.2019       Created
 **********************************************************************************/



global class APTS_PurgeCERBizIslandBufferData implements Database.Batchable<sObject>{
    global APTS_PurgeCERBizIslandBufferData(){
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        if(!Test.isRunningTest()){
            return Database.getQueryLocator([Select Id from CER_Bizisland__c where CreatedDate < TODAY AND isExecuted__c = true AND isDeleted = false]);
        }
        else { return Database.getQueryLocator([Select Id from CER_Bizisland__c]); }
    }

    global void execute(Database.BatchableContext BC, List<CER_Bizisland__c> scope){       
                    
        Database.delete(scope, false);        

    }

    global void finish(Database.BatchableContext BC){
    }
}