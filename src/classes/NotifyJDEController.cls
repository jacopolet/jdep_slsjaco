/**
 * Class Name: NotifyJDEController
 * @author: Alvin Lomod
 * Date: 1-Nov-2017
 * Requirement: KASM-232; KASM-1932
 * @description: Controller for NotifyJDE VF Page
 * Updates : Changed Lead Source to Touchpoint Type
 */

public with sharing class NotifyJDEController {
    
    public Lead ld {get;set;}
    public Boolean diffLeadSource {get;set;}

    public NotifyJDEController(ApexPages.StandardController controller) {
        CustomLogging.push('NotifyJDEController', 'NotifyJDEController');
        try {
            ld = (Lead)controller.getRecord();
            
            if (Schema.sObjectType.Lead.fields.Id.isAccessible() && Schema.sObjectType.Lead.fields.Assign__c.isAccessible() && Schema.sObjectType.Lead.fields.LeadSource.isAccessible() &&
                Schema.sObjectType.Lead.fields.OwnerId.isAccessible() && Schema.sObjectType.Lead.fields.Touchpoint_Type__c.isAccessible()){
                ld = [SELECT Id, Assign__c, LeadSource, OwnerId, Touchpoint_Type__c FROM Lead WHERE Id =: ld.Id];
            }
            diffLeadSource = false;
        
        } catch(Exception e){
                
            CustomLogging.debugException(e);
            CustomLogging.pop();      
            System.debug(e.getMessage() + '\n' + e.getStackTraceString());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, e.getMessage()));
                                 
        }
    }
    
    public PageReference NotifyJDE(){
        CustomLogging.push('NotifyJDE', 'NotifyJDEController');
        PageReference pageRef = null;
        
        //changed from lead source to touchpoint type
        if(ld.Touchpoint_Type__c == 'REFERRAL PARTNER'){
            diffLeadSource = false; 
            
            try{
                if(!ld.Assign__c && Schema.sObjectType.Lead.fields.Assign__c.isUpdateable()) {
                    
                    ld.Assign__c = true;
                    update ld;
                    
                    //After lead is assigned to JDE, redirect back to Lead's List view
                    if(UserInfo.getUserType() == 'PowerPartner'){
                        String newURL = System.URL.getSalesforceBaseUrl().toExternalForm() + '/pocportal/s/recordlist/Lead/Recent'; //pocportal will be changed if implement in production
                        pageRef = new PageReference(newURL);
                    }
                    else{
                        pageRef = new PageReference('/00Q/o');
                    }
                }
                
            } catch(Exception e){
                
                CustomLogging.debugException(e);
                CustomLogging.pop();      
                System.debug(e.getMessage() + '\n' + e.getStackTraceString());
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, e.getMessage()));
                                     
            }
            
        }
        
        else if(ld.Touchpoint_Type__c != 'REFERRAL PARTNER'){
            
            diffLeadSource = true;
        }
        
        
        return pageRef;
    }
    
    public PageReference returnToLead(){
        
        return new ApexPages.StandardController(ld).view();
        
    }

}