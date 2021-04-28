/**
 * Class Name: Proposal_NewQuoteWithOppController
 * @author: James Azana
 * Date: 07-Jun-2017
 * Requirement: Automatic creation of Opportunity when creating new quote with oppotunity from account page
 * @description: Controller for Proposal_NewQuoteWithOpportunity VF Page
 * @update: 10-Jul-2017 - Alvin Lomod - if Account blocked is true, validation message will appear return page
 */

 public without sharing class Proposal_NewQuoteWithOppController {
    
    public Account acc {get; set;}
    public Opportunity opp;
    public Apttus_Proposal__Proposal__c proposal {get; set;}
    public string editPageUrl {get; set;}
    public boolean renderform {get;set;}
    
    
    public Proposal_NewQuoteWithOppController(ApexPages.StandardController controller) {
        CustomLogging.push('Proposal_NewQuoteWithOppController', 'Proposal_NewQuoteWithOppController');
        try{
            //get account record
            acc = (Account)controller.getRecord();
            system.debug('rrr' + renderform);
            renderform = true;
            
            if (Schema.sObjectType.Account.fields.Id.isAccessible() && Schema.sObjectType.Account.fields.Segment__c.isAccessible() && Schema.sObjectType.Account.fields.Account_Block__c.isAccessible()){
                //get segment field of the account
                acc = [SELECT Id, Segment__c, Account_Block__c FROM Account WHERE id = :acc.id];
            }
        } catch(Exception ex){
            renderform = false;
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            
        }
    }
    
    public void createOpportunityAndProposal(){
        CustomLogging.push('createOpportunityAndProposal', 'Proposal_NewQuoteWithOppController');
        try{
            //create opportunity record
            opp = new Opportunity();
            opp.AccountId = acc.id;
            opp.CloseDate = System.Today() + 30; 
            opp.CurrencyIsoCode = SM_Constants.CurrencyIsoCodeValue;
            opp.Go_To_Market__c = SM_Constants.GoToMarketValue;
            opp.Name = SM_Constants.NameValue ; //will be auto renamed
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(SM_Constants.RecTypeNameValue).getRecordTypeId();
            opp.StageName = SM_Constants.StageNameValue;
            opp.Type = SM_Constants.TypeValue;
            opp.Segment__c = acc.Segment__c;
            if (Schema.sObjectType.Opportunity.fields.AccountId.isCreateable() && Schema.sObjectType.Opportunity.fields.CloseDate.isCreateable() &&
                Schema.sObjectType.Opportunity.fields.CurrencyIsoCode.isCreateable() && Schema.sObjectType.Opportunity.fields.Go_To_Market__c.isCreateable() &&
                Schema.sObjectType.Opportunity.fields.Name.isCreateable() && Schema.sObjectType.Opportunity.fields.RecordTypeId.isCreateable() &&
                Schema.sObjectType.Opportunity.fields.StageName.isCreateable() && Schema.sObjectType.Opportunity.fields.Type.isCreateable() &&
                Schema.sObjectType.Opportunity.fields.Segment__c.isCreateable()){
                insert opp;
            }
            Opportunity updatedOpp;
            if (Schema.sObjectType.Opportunity.fields.Name.isAccessible()){
                //get updated opportunity name
                updatedOpp = [SELECT Name FROM Opportunity WHERE ID = :opp.id];
            }
            
            //create proposal record
            proposal = new Apttus_Proposal__Proposal__c();
            proposal.Apttus_Proposal__Account__c = acc.id;
            proposal.RecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
            proposal.OwnerId = UserInfo.getUserId();
            proposal.Apttus_Proposal__Opportunity__c = opp.id;
            proposal.Apttus_Proposal__Proposal_Name__c = updatedOpp.name;
            if (Schema.sObjectType.Apttus_Proposal__Proposal__c.fields.Apttus_Proposal__Account__c.isCreateable() && Schema.sObjectType.Apttus_Proposal__Proposal__c.fields.RecordTypeId.isCreateable() &&
                Schema.sObjectType.Apttus_Proposal__Proposal__c.fields.OwnerId.isCreateable() && Schema.sObjectType.Apttus_Proposal__Proposal__c.fields.Apttus_Proposal__Opportunity__c.isCreateable() &&
                Schema.sObjectType.Apttus_Proposal__Proposal__c.fields.Apttus_Proposal__Proposal_Name__c.isCreateable()){
                insert proposal;
            }
            
            //editPageUrl = '/' + proposal.id + '/e?retURL=' + proposal.id + '&cancelURL=' + acc.id;
            
        } catch(Exception ex){
            renderform = false;
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, ex.getMessage().substringAfterLast('FIELD_CUSTOM_VALIDATION_EXCEPTION,')));           
            system.debug(renderform);
            
        }
    }
    
    public pagereference returnToAccount(){
        CustomLogging.push('returnToAccount', 'Proposal_NewQuoteWithOppController');
        try{
            PageReference accPage = new PageReference('/'+acc.id);
            accPage.setRedirect(true);
            return accPage;
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
    }
    
    public pagereference returnToEdit(){
        CustomLogging.push('returnToEdit', 'Proposal_NewQuoteWithOppController');
        try{
            PageReference tskPage = new PageReference('/'+proposal.id+'/e');
            tskPage.setRedirect(true);
            return tskPage;
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
    }
    
    public pagereference returnToNewProposal(){
        CustomLogging.push('returnToNewProposal', 'Proposal_NewQuoteWithOppController');
        try{
            PageReference tskPage = new PageReference('/'+proposal.id);
            tskPage.setRedirect(true);
            return tskPage;
        } catch(Exception ex){
            CustomLogging.debugException(ex);
            CustomLogging.pop();      
            System.debug(ex.getMessage() + '\n' + ex.getStackTraceString());
            return null;
        }
    }

}