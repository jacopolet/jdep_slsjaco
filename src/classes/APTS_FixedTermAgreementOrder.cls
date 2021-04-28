/*
    @Author: Amit 
    @Calss : APTS_FixedTermAgreementOrder
    @Description : Calss created to activate Admin order for Fixed term, to create billing schedule. 
                   This class will be invoked from button on Agreement header - 'Active Fixed Term Order'
*/
public with sharing class APTS_FixedTermAgreementOrder{
    private static final string ORDERTYPE='Admin Order';
    private static final string ACTIVATED='Activated';
    private static final string AGRMTID = 'agrmentId';
    public Apttus__APTS_Agreement__c agrmnt{ get; set;}

    //constructor to get the Case record    
    public APTS_FixedTermAgreementOrder(ApexPages.StandardController controller){
    
    }
    //Method to activate admin order 
    public void activeFixedTermOrder(){
        try{    
            String agreementID='';
            agreementID= ApexPages.currentPage().getParameters().get(AGRMTID);
            
            List<Apttus_Config2__Order__c> ordlst = new List<Apttus_Config2__Order__c>();
            for(Apttus_Config2__Order__c ordup : [select Id,Apttus_Config2__Status__c from Apttus_Config2__Order__c where Apttus_CMConfig__AgreementId__c=:agreementID and APTS_Order_Type__c=:ORDERTYPE and APTS_Name__c =: System.Label.APTS_BIR_FixedTerm_Dummy]){
                ordup.Apttus_Config2__Status__c = ACTIVATED;
                ordlst.add(ordup);
            }
            
            if(ordlst.size()>1){
                APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = true;
                update ordlst[1];
                update ordlst[0];
                APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = false;
                }else{
                APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = true;
                update ordlst;
                APTS_AssetLineItemTriggerHandler.isSkipAssetlineitemTrigger = false;
                }
        }
        catch(Exception ex){
            Database.INSERT(APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', string.valueOf(ex),'Order', '','BIR',False, False,'', False));
        }
    }
    
}