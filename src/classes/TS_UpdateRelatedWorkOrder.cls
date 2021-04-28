/*
* @author        Marvin Gatchalian
* @date          3.23.2018          
* @description   Class responsible for updating related WorkOrder. Please use this class for related WorkOrder only. 
* 			     Do not execute DML operation here, just return the list of WorkOrder to be updated. The calling
*				 class should be the one to performed the dml.	 
* @revision(s)   
*/

public with sharing class TS_UpdateRelatedWorkOrder {
	
	/* Not Applicable for this scenario
    public List<WorkOrder> actionsForInsertedCases (List<SObject> newList, Map<Id, SObject> newMapItems) {
		List<WorkOrder> woListToReturn = new List<WorkOrder>();
		woListToReturn = woUpdateOwnerIdSameWithCase (newList, null);
		
		return woListToReturn;
	}
	*/
	
	public List<WorkOrder> actionsForUpdatedCases (List<SObject> newList, Map<Id, SObject> newMapItems, Map<Id, SObject> oldMapItems) {
		List<WorkOrder> woListToReturn = new List<WorkOrder>();
		woListToReturn = woUpdateOwnerIdSameWithCase (newList, oldMapItems);
		
		return woListToReturn;
	}
	
	private List<WorkOrder> woUpdateOwnerIdSameWithCase (List<SObject> recordList, Map<Id, SObject> oldMapItems ) {
		set <Id> caseIds = new set <Id>();
		List <WorkOrder> woToReturn = new List <WorkOrder>();
		
		try {
			for (Case eachCase :(List<Case>) recordList) {
				if (oldMapItems.containsKey(eachCase.id)) {
					Case oldCase = (Case) oldMapItems.get(eachCase.id);
					if (eachCase.OwnerId != oldCase.OwnerId && eachCase.OwnerId != null )
						caseIds.add(eachCase.id);
				}
			}
			
			if (!caseIds.isEmpty()) {
				for (WorkOrder eachWO :[Select id, OwnerId, Case.OwnerId from WorkOrder Where CaseId in :caseIds]) {
					if (eachWO.OwnerId != eachWO.Case.OwnerId){
						eachWO.OwnerId = eachWO.Case.OwnerId;
						woToReturn.add(eachWO);
					}
				}
				
			} 
        } catch (Exception ex) {
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }

		return woToReturn;
	}
    
}