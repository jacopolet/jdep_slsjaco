/*****************************************************************************
@Name: APTS_AgreementNew
@Author: V. Shankaranarayanan
@CreateDate: 08-09-2018
@Description: Controller to remove the intermediary page on Agreement creation
@UsedBy: APTS_AgreementNew VF page
*****************************************************************************/
public without sharing class APTS_AgreementNew{
    
    private static String AGREEMENT = 'Apttus__APTS_Agreement__c';
    private static String RECORDTYPE = 'RecordType';
    private static String CLM = 'CLM';
    private static String ERRORTYPE = 'Apex';
    private static String AGREEMENTERROR = 'Error during Agreement creation: ';
    private static String AGREEMENTCREATIONERROR = 'Please create Agreement from Opportunity or Account';
    
    public Boolean isError {get; set;}
    
    //Constructor
    public APTS_AgreementNew(ApexPages.StandardController controller) {
        isError = false;
    }

    /*
    @Name: createAgreement
    @Description: Method to create an Agreement and redirects to the Agreement detail page
    @Parameters: None
    @Returns: PageReference
    */
    public PageReference createAgreement(){
        try{
            Apttus__APTS_Agreement__c oAgreement;
            String recTypeName;
            
            String recTypeId = ApexPages.currentPage().getParameters().get(RECORDTYPE);
            String oppId = ApexPages.currentPage().getParameters().get(Label.APTS_RelatedOpportunity);
            //String oppId = (ApexPages.currentPage().getParameters().get('retURL')).substringAfter('/');
            String accId = ApexPages.currentPage().getParameters().get('accountId');

            if(String.IsBlank(oppId) && String.IsBlank(accId)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, AGREEMENTCREATIONERROR));
                isError = true;
                return null;
            }else{
                if(recTypeId != null){
                    recTypeName = Schema.getGlobalDescribe().get(AGREEMENT).getDescribe().getRecordTypeInfosById().get(recTypeId).getName();
                }else{
                    recTypeId = Schema.getGlobalDescribe().get(AGREEMENT).getDescribe().getRecordTypeInfosByName().get('Registration Form').getRecordTypeId();
                    recTypeName = 'Registration Form';
                }
                if(recTypeName != null){
                    oAgreement = new Apttus__APTS_Agreement__c();
                    oAgreement.Name = recTypeName;
                    oAgreement.RecordTypeId = recTypeId;
                    if(oppId != null && oppId.startsWith(Opportunity.sObjectType.getDescribe().getkeyPrefix())){
                        oAgreement.Apttus__Related_Opportunity__c = oppId;
                    }
                    if(accId != null){
                        oAgreement.Apttus__Account__c = accId;
                    }
                    insert oAgreement;
                }
                return new PageReference('/' + oAgreement.Id);
            }
        }catch(Exception ex){
            /*** PI fix # 190442 ****/
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, AGREEMENTERROR +ex.getMessage()));
            isError = true;
            return null;
        }
    }
    
}