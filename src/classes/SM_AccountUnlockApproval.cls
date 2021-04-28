//-------------------------------------------------------------------------------------------//
// Author       :   Catherine Aragon - Accenture
// Created Date :   February 25, 2019
// Usage        :   Unlock approval process after submission
//-------------------------------------------------------------------------------------------//
public without sharing class SM_AccountUnlockApproval {
	@InvocableMethod
    public static void unlockApproval(List<Id> ListID){
        CustomLogging.push('AccountUnlocker', 'AccountTriggerHandler');
        try{
            List<Id> accToUnlock = new List<Id>();
            for(Id accId : ListID){
                system.debug('locked? ' + Approval.isLocked(accId) + '~~');
                if(Approval.isLocked(accId)){
                    accToUnlock.add(accId);                
                }
            }
            
            if(!accToUnlock.isEmpty()){
                Approval.UnlockResult[] urList = Approval.unlock(accToUnlock);
                
                for(Approval.UnlockResult ur : urList) {
                    if (ur.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully unlocked account with ID: ' + ur.getId());
                    }
                }
            }
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
        }
    }
}