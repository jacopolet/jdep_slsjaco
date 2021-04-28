/**********************************************************************************
 * @Author: Jason Mactal
 * @Company: Accenture
 * @Description: Controller for APTS_RegenerateDiscounts Page
 * @Created Date: March 05 2019
 * @History:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      03.05.2019       Created
 *********************************************************************************/
public with sharing class APTS_RegenerateDiscountsController{
    
    public Id agreementId {get;set;}
    public Apttus__APTS_Agreement__c oAgreement {get;set;}
    
    public APTS_RegenerateDiscountsController(ApexPages.StandardController stdController){
        agreementId = ApexPages.currentPage().getParameters().get('id');
        oAgreement = [SELECT ID, Apttus__Status__c, Apttus__Status_Category__c, Apttus__Account__c, Apttus__FF_Agreement_Number__c, (SELECT Id FROM Contract_Entitlement_Repositories1__r) FROM Apttus__APTS_Agreement__c WHERE ID=:agreementId];
    }
    
    public PageReference regenerateDiscounts(){
        PageReference pg = new PageReference('/' + agreementId);
        try{
            integer versionNumber = integer.valueof(oAgreement.Apttus__FF_Agreement_Number__c.right(1));
            List<APTS_Contract_Entitlement_Repository__c> cerList = oAgreement.Contract_Entitlement_Repositories1__r;
            //Check if there are existing CER Records

                if(oAgreement.Apttus__Status_Category__c=='In Effect'){
                    APTS_ManageCER.manageCERRecords(new List<Apttus__APTS_Agreement__c>{oAgreement},'Agreement',APTS_CPQConstants.CER_UPDATE);
                }
                if(oAgreement.Apttus__Status__c=='Terminated' ||oAgreement.Apttus__Status__c=='Expired'||oAgreement.Apttus__Status__c=='Superseded'||oAgreement.Apttus__Status__c=='Cancelled Request'||oAgreement.Apttus__Status__c=='Cancelled'){
                    APTS_ManageCER.manageCERRecords(new List<Apttus__APTS_Agreement__c>{oAgreement},'Agreement',APTS_CPQConstants.CER_DELETE);
                }

        }catch(exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Agreement', ApexPages.currentPage().getParameters().get('businessObjectId'),'CPQ',false,true,'cpqerror@accenture.com',true); return pg;
        }
        return pg;
    }
    
    public PageReference doCancel(){
         PageReference pg = new PageReference('/' + agreementId);
         return pg;
    }
    
}