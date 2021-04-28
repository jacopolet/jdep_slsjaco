/**
 * Class Name: SM_AgreementToAccount
 * @author: Alvin Lomod
 * Date: 20-Mar-2018
 * Requirement: KASM-1364
 * @description: Create Integration Log from Agreement and update related Accounts and Account Location
 *
 */

public without sharing class SM_AgreementToAccount {
    
    public void AgreementToAccountMethods(List<Apttus__APTS_Agreement__c> agreeList){
        PromoteAccountAndIntegration(agreeList); 
        createPESurvey(agreeList);    
    }
    
    private static void PromoteAccountAndIntegration(List<Apttus__APTS_Agreement__c> agreeList){
        if (!agreeList.isEmpty()) {
                ID jobID = System.enqueuejob(new PromoteAccountAndIntegrationQueueable(agreeList)); 
               system.debug(jobID);
            
        }   
    }
    
    public static void createPESurvey (List<Apttus__APTS_Agreement__c> agreeList) {
        if (!agreeList.isEmpty()) {
               System.enqueuejob(new PerfectExperienceQueueable(agreeList)); 
            
        }
    }
}