/**
* @author        Paul Aguiling
* @date          7.04.2018           
* @description   Class responsible to asynchronously update resource record due to issue
*				 of Apex does not allow DML operations of a non-setup sObject and a setup sObject 
*				 in a single Apex transaction. (User is the setup sobject)
* @revision(s)   
*/
public without sharing class TS_AsyncResourceUpdate implements Queueable { 
	public List<Resource__c> resSet = new List<Resource__c>();
	public Boolean hasException = false;
    public List<Integration_Log__c> integLogList = new List<Integration_Log__c>();

    /**
    * @author         Paul Jarred Aguiling
    * @date           7.04.2018 
    * @description    Method responsible for throwing an exception
    * @revision(s)
    */ 
    public class TS_AsyncResourceUpdateException extends Exception {}

    /**
    * @author        Paul Jarred Aguiling
    * @date          07.05.2018            
    * @description   [KTS-1933]: Method use to update resource due to issue with setup 
    *                            and non-setup object inserted/updated at the same transaction
    * @revision(s)
    */
    public void execute(QueueableContext context) {
        CustomLogging.push('execute', 'TS_AsyncResourceUpdate');
        
        Set<String> teamNumberSet = new Set<String>();
        Set<Id> userIdSet = new Set<Id>();
        List<Resource__c> resSameTeamList = new List<Resource__c>();
        List<Resource__Share> resourceSharedList = new List<Resource__Share>();

        try {
            if (Test.isRunningTest() && hasException) {
                throw new TS_AsyncResourceUpdateException('Force to throw an exception');
            }

        	System.debug('#### Limits.getQueueableJobs() TS_AsyncResourceUpdate ### :' + Limits.getQueueableJobs());
    		update resSet;

            //Check if user has access to insert integration log records
            if (!integLogList.isEmpty() && Schema.sObjectType.Integration_Log__c.isCreateable()) {
                insert integLogList;
            }

    		for (Resource__c rsrce: resSet) {
    			if (Label.TS_ResourceUsrProf_ThirdParty.equals(rsrce.UserProfile__c)) {
                    
                    //KTS-2100 Xen Reyes 08.24.2018
                    if(rsrce.TeamNumber__c != null){
                        teamNumberSet.add(rsrce.TeamNumber__c);
                    }
    			}
    		}

    		//Scenario for updating resource sharing
    		if (!teamNumberSet.isEmpty()) {
				//Collect all resource with the same team number
				
				//XEN REYES INC0156784 DOO-3885 Feb. 14, 2020
	    		for (Resource__c resSameTeam : [SELECT Id, TeamNumber__c, RelatedUser__c, RelatedUser__r.IsActive
						                        FROM  Resource__c
						                        WHERE TeamNumber__c IN :teamNumberSet]) {

	    			resSameTeamList.add(resSameTeam);

	    			//Get all related users from the resource record
	    			if (resSameTeam.RelatedUser__c != null) {
						if(resSameTeam.RelatedUser__r.IsActive == true){ //XEN REYES INC0156784 DOO-3885 Feb. 14, 2020
							userIdSet.add(resSameTeam.RelatedUser__c);
						}
	    			}
	    		}

	    		//Iterate the result list to give read access to all related 
	    		//users that is on the same resouce team number
				for (Resource__c resSameTeam : resSameTeamList) { 
					for (Id userId : userIdSet) {
			            Resource__Share resShare = new Resource__Share();
			            resShare.ParentId = resSameTeam.Id;
			            resShare.UserOrGroupId = userId;
			            resShare.AccessLevel = 'Read';
			            resShare.RowCause = 'Manual';
			            resourceSharedList.add(resShare);
		        	}
	        	}

	        	System.debug('### resourceSharedList ### ' + resourceSharedList);

	        	//Update resource sharing
	        	if (!resourceSharedList.isEmpty() 
	        		&& Schema.sObjectType.Resource__Share.fields.ParentId.isCreateable()
	        		&& Schema.sObjectType.Resource__Share.fields.UserOrGroupId.isCreateable()
	        		&& Schema.sObjectType.Resource__Share.fields.AccessLevel.isCreateable()
	        		&& Schema.sObjectType.Resource__Share.fields.RowCause.isCreateable()) {
	        		insert resourceSharedList;
	        	}
        	}

        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug('### ' + ex.getMessage() + '\n' + ex.getStackTraceString());
        }

    	System.debug('### resSet ### : ' + resSet);
    	CustomLogging.pop();
    }
}