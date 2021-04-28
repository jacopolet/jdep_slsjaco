/*************************************************************
@Name: APTS_LaeTransactionHandlerTest
@Author: Shahul
@CreateDate: 11-08-2020
@Description: Test class for laetransaction trigger handler
@UsedBy: APTS_LaeTransactionHandler
******************************************************************/
@isTest
public class APTS_LaeTransactionHandlerTest{

    public static testMethod void insertTransactionRecord()
    {
    TriggerSettings__c settings = new TriggerSettings__c();
        settings.LAETransaction__c = true;
        Database.insert(settings, false);
        List<RTR_LAE_Transaction_Data__c> lstlaecount =new List<RTR_LAE_Transaction_Data__c>();
        List<RTR_LAE_Transaction_Data__c> lstlaecountupdate =new List<RTR_LAE_Transaction_Data__c>();
        Map<Id, RTR_LAE_Transaction_Data__c > newItems =new Map<Id, RTR_LAE_Transaction_Data__c >();
        List<RTR_LAE_Transaction_Data__c > oldList =new List<RTR_LAE_Transaction_Data__c >();
        Map<Id, RTR_LAE_Transaction_Data__c > oldItems =new Map<Id, RTR_LAE_Transaction_Data__c >();
        List<Apttus__APTS_Agreement__c> agrlst = new List<Apttus__APTS_Agreement__c>();
        Apttus__APTS_Agreement__c aggr = new Apttus__APTS_Agreement__c();
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr);
        Apttus__APTS_Agreement__c aggr1 = new Apttus__APTS_Agreement__c();
        aggr1.Apttus__Status__c = 'In Effect';
        aggr1.Apttus__Status_Category__c = 'Activated';
        agrlst.add(aggr1);
        Database.insert(agrlst,false);
        
        List<Apttus_Config2__AssetLineItem__c> assetLI = new List<Apttus_Config2__AssetLineItem__c>();
        Apttus_Config2__AssetLineItem__c tstAsset= new Apttus_Config2__AssetLineItem__c();
        tstAsset.Apttus_Config2__BillingStartDate__c = Date.today().addDays(1);
        tstAsset.Name = 'tstAsset';
        tstAsset.Apttus_Config2__NetPrice__c = 100;
        tstAsset.Apttus_Config2__NetUnitPrice__c=10;
        tstAsset.Apttus_Config2__AssetStatus__c = 'Activated';
        tstAsset.APTS_Manual_Activation_Date__c = Date.today();
        tstAsset.Apttus_Config2__HasOptions__c = true;
        tstAsset.Apttus_CMConfig__AgreementId__c =  agrlst[0].Id;
        tstAsset.Apttus_Config2__LineType__c = 'Product/Service';
        tstAsset.APTS_Is_Primary_L1_Line__c = true;
        tstAsset.APTS_Type_Of_Contract__c = 'Sales';
        tstAsset.Apttus_Config2__ChargeType__c = 'Service Fee';
        insert tstAsset;
        
        RTR_LAE_Transaction_Data__c lae=new RTR_LAE_Transaction_Data__c();
        lae.APTS_Asset_Line_Item__c=tstAsset.Id;
        lae.APTS_Business_Transaction_Type__c='0001';
        lae.APTS_Contract_Effective_Date__c=system.today();
        lstlaecount.add(lae);
        
        RTR_LAE_Transaction_Data__c lae1=new RTR_LAE_Transaction_Data__c();
        lae1.APTS_Asset_Line_Item__c=tstAsset.Id;
        lae1.APTS_Business_Transaction_Type__c='0001';
        lae1.APTS_Contract_Effective_Date__c=system.today();
        lstlaecount.add(lae1);
        
        RTR_LAE_Transaction_Data__c lae2=new RTR_LAE_Transaction_Data__c();
        lae2.APTS_Asset_Line_Item__c=tstAsset.Id;
        lae2.APTS_Business_Transaction_Type__c='A005';
        lae2.APTS_Contract_Effective_Date__c=system.today();
        lstlaecount.add(lae2);
        
        RTR_LAE_Transaction_Data__c lae3=new RTR_LAE_Transaction_Data__c();
        lae3.APTS_Asset_Line_Item__c=tstAsset.Id;
        lae3.APTS_Business_Transaction_Type__c='A005';
        lae3.APTS_Contract_Effective_Date__c=null;
        lstlaecount.add(lae3); 
        if(lstlaecount.size()>0){
        Database.insert(lstlaecount,false);}
        
    //APTS_LaeTransactionHandler laeins=new APTS_LaeTransactionHandler();
    // laeins.BeforeInsert(lstlaecount);
    
    RTR_LAE_Transaction_Data__c laaupdate1=[select id,APTS_Contract_Effective_Date__c,APTS_Business_Transaction_Type__c,APTS_Asset_Line_Item__c from RTR_LAE_Transaction_Data__c where APTS_Contract_Effective_Date__c=null];
    system.debug('++++laaupdate1+++++'+laaupdate1);
    laaupdate1.APTS_Contract_Effective_Date__c=Date.today().addDays(1);
    lstlaecountupdate.add(laaupdate1);
    if(lstlaecountupdate.size()>0){
    Database.update(lstlaecountupdate,false);}
    //laeins.BeforeUpdate(lstlaecountupdate,newItems,oldList,oldItems);
    RTR_LAE_Transaction_Data__c lae4=new RTR_LAE_Transaction_Data__c();
    lae4.APTS_Asset_Line_Item__c=tstAsset.Id;
    lae4.APTS_Business_Transaction_Type__c='0001';
    lae4.APTS_Contract_Effective_Date__c=system.today();
    insert lae4;
    delete lae4;
    RTR_LAE_Transaction_Data__c lae5=new RTR_LAE_Transaction_Data__c();
    lae5.APTS_Asset_Line_Item__c=tstAsset.Id;
    lae5.APTS_Business_Transaction_Type__c='0004';
    lae5.APTS_Asset_Processed__c=false;
    lae5.APTS_Contract_Effective_Date__c=system.today();
    insert lae5;
    System.assert(lae5.APTS_Asset_Processed__c!=null);
    }
}