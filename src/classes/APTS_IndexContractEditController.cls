/*************************************************************
@Name: APTS_IndexContractEditController
@Author: Santosh Kumar
@CreateDate: 7-Feb-2018
@Description: Allow users to change values based on Indexation
@UsedBy: APTS_IndexContractEditPage VF Page
******************************************************************/

public with sharing class APTS_IndexContractEditController {
    
    public APTS_Index_Contract__c indexContract{get;set;}
    public boolean istype{get;set;}
    public String ischanged{get;set;}
    private static final  String CONTRACT = 'APTS_Index_Contract__c';
    
    public APTS_IndexContractEditcontroller(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()) {
            stdController.addFields(new List<String>{'Name','APTS_Indexation_Category__c','APTS_Index_Type__c','APTS_Indexation_Number__c','APTS_Frequency__c','APTS_Communication_Deadline__c',
                'APTS_Start_Date__c','APTS_Maximum_Bandwidth__c','APTS_Communication_Needed__c','APTS_Additional_Conditions__c','APTS_Customer_Approval_Required__c','APTS_Contract__c'});
        }
        
        indexContract = (APTS_Index_Contract__c) stdController.getRecord();
        ischanged = 'false';
        identifytype();
    }
    
    /* Function Called when Index type picklist value is changed */
    public pagereference indextypechange() {
        identifytype();
        return null;
    }
    
    /* Function Called to identify type and dispaly message on screen */
    public void identifytype() {
        if(indexContract.APTS_Index_Type__c != 'Non-Standard Indexation') {
            istype = true;  
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info,'Cannot Edit any value as type is not Non-Standard Indexation'));            
        }else if(indexContract.APTS_Index_Type__c == 'Non-Standard Indexation') {
            istype = false;
        }
        
    }
    
    /* Function Called when clicked on save button on Page */
    public pagereference docontinue() {
        try{
        
           
        
            if(indexContract.APTS_Index_Type__c == 'Non-Standard Indexation' && ischanged == 'false') {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning,'You have defined an indexation without changing any Indexation specific values. Please change back to “Standard Indexation” or change any Indexation specific values'));
                return null;
            }
            if(indexContract.APTS_Index_Type__c == 'Standard Indexation(incl Fixed Prices)' && indexContract.APTS_Indexation_Category__c == 'Products (Ingredients and &More)') {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning,'You cannot save data with Standard Indexation(incl Fixed Prices) and Products (Ingredients and &More). Please change back to “Standard Indexation”'));
                return null;
            }
            
            
            DescribeSObjectResult objResultCON = APTS_OTCUtil.getsObjectAccess(CONTRACT);
            if(objResultCON != null &&  objResultCON.isUpdateable() )
            {
                update indexContract;
            }
            return new PageReference('/' + indexContract.id);
        }catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Warning, ex.getMessage()));
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'IndexContract', indexContract.Id, 'CLM', false, false, null, true);
            return null;
        }
    }
    
    /* Function Called when clicked on Cancel button on Page */
    public pagereference docancel() {
        return new PageReference('/' + indexContract.id);
    } 
    
    /* Function Called by Action function to capture value when any value changed on VF Page when index is Non-standard */
    public void valueupdate(){
        ischanged=Apexpages.currentPage().getParameters().get('valFromVf');
    }
}