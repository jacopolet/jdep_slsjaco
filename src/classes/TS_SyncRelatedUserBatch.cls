/**
* @author        Paul Jarred Aguiling
* @date          07.10.2018          
* @description   [KTS-1932]: Batch class that synchronize related user to resource records 
* @revision(s)   
*/
global without sharing class TS_SyncRelatedUserBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private String queryStr = null;
    private List<String> exception_List = new List<String>();
    public static Boolean hasException = false;
    String COMMUNITY_PROFILEID;
    /**
    * @author         Paul Jarred Aguiling
    * @date           07.10.2018
    * @description    Method responsible for throwing an exception
    * @revision(s)
    */ 
    public class TS_SyncRelatedUserBatchException extends Exception {}
    public TS_SyncRelatedUserBatch(){
        List<Profile> Comm_Profile = [SELECT Id FROM Profile WHERE Name = 'JDE - END USER - STC MOBILE INTERNAL' LIMIT 1];
        If(Comm_Profile != null && Comm_Profile.size() > 0){
        	COMMUNITY_PROFILEID = Comm_Profile[0].Id;     
        }       
    }
    /**
    * @author         Paul Jarred Aguiling
    * @date           07.10.2018
    * @description    This method is the start of the batch job
    * @revision(s)
    */ 
    global Database.QueryLocator start(Database.BatchableContext BC) {
        CustomLogging.push('execute', 'TS_SyncRelatedUserBatch');

        queryStr = 'SELECT Id, Name, NickName__c '
                    + 'FROM Resource__c WHERE Click__c = false '
                    + 'AND RelatedUser__c = NULL ';

        System.debug('queryStr >>> ' + queryStr);
                        
        CustomLogging.pop();

        return Database.getQueryLocator(queryStr);

    }

    /**
    * @author         Paul Jarred Aguiling
    * @date           07.10.2018
    * @description    Method responsible executing the main logic
    * @revision(s)
    */ 
    global void execute(Database.BatchableContext BC, List<Resource__c> resourceList) {
        CustomLogging.push('execute', 'TS_SyncRelatedUserBatch');
        Set<String> resNameSet = new Set<String>();
        Map<String, Id> usrResMap = new Map<String, Id>();
        List<Resource__c> resourceToUpdate = new List<Resource__c>();

        try {

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_SyncRelatedUserBatchException('Force to throw an exception');
            }

            for (Resource__c res : resourceList) {
                //resNameSet.add(res.Name);
                resNameSet.add(res.Name); //XEN REYES Dec. 17, 2018
            }

            if (!resNameSet.isEmpty()) {
                for (User usr : [SELECT Id, CommunityNickname,EmployeeNumber FROM User WHERE EmployeeNumber IN :resNameSet AND Isactive = true AND ProfileId =: COMMUNITY_PROFILEID]) {
                    usrResMap.put(usr.EmployeeNumber, usr.Id);
                }

                for (Resource__c res : resourceList) {
                    if(usrResMap.get(res.Name) != null){
                    	res.RelatedUser__c = usrResMap.get(res.Name);
                    	//res.RelatedUser__c = usrResMap.get(res.NickName__c); //XEN REYES Dec. 17, 2018
                    	resourceToUpdate.add(res);    
                    }
                }
            }

            //Update resource records
            if (Schema.sObjectType.Resource__c.isUpdateable() && !resourceToUpdate.isEmpty()) {
                Database.SaveResult[] saveResultList = Database.update(resourceToUpdate, false);
                
                for (Database.SaveResult sr: saveResultList) {
                    if (!sr.isSuccess()) {
                        //Operation failed. Get error details               
                        for(Database.Error err : sr.getErrors()) {
                            String msg = TS_Constants.ERRBATCH_MSG_01 + err.getStatusCode() + ': ' + err.getMessage() + ': ' + err.getFields();
                            exception_List.add(msg);
                        }
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

    /**
    * @author         Paul Jarred Aguiling
    * @date           07.10.2018
    * @description    Method responsible for final changes or updates whitin the batch of records
    * @revision(s)
    */ 
    global void finish(Database.BatchableContext BC) {
        CustomLogging.push('finish', 'TS_RouteSalesBatch');

        //Display summary of failed records
        if (!exception_List.isEmpty()) {
            System.debug(TS_Constants.ERRBATCH_MSG_02 + exception_List.size());

            //Detailed log of errors
            for (String err : exception_List) {
                System.debug(err);
            }
        }

        CustomLogging.pop();
    }

}