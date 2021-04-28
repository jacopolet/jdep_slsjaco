@isTest
public class APTS_ProcessUsageInputBatchTest {
    
    static testMethod void testProcessUsageInput(){
        
        test.startTest();
        Account acc = APTS_TestUtils.createaccount();
        Database.insert(acc,false);
        Blob blobKey = crypto.generateAesKey(192);
        String key = EncodingUtil.base64encode(blobKey);
        key = key.substring(0,8);
        Product2 prd = APTS_TestUtils.createProduct(key, key, 'Coffee');
        Database.insert(prd,false);
        Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
        Database.insert(plist,false);
        
        Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id,prd.Id);
        Database.insert(pli,false);
        
        Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
        Database.insert(billpre,false);
        
        Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',acc.Id,plist.Id,billpre.Id);
        Database.insert(order,false);

        Contact con = APTS_TestUtils.createContact();
        Database.insert(con,false);
        
        Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
        aggr.Apttus__Status__c = 'In Effect';
        aggr.Apttus__Status_Category__c = 'Being Amended';
        Database.insert(aggr,false);
        test.stopTest();
        
        List<Apttus_Config2__AssetLineItem__c> aliInsertList = new List<Apttus_Config2__AssetLineItem__c>();
        
        Apttus_Config2__AssetLineItem__c ali =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id , order.Id);
        ali.Apttus_CMConfig__AgreementId__c = aggr.Id;
        ali.Apttus_Config2__AssetStatus__c = 'Activated';
        aliInsertList.add(ali);
        
        Database.insert(aliInsertList,False);
        
        ali.Apttus_Config2__AssetNumber__c = ali.Id;
        ali.Apttus_Config2__AssetCode__c =  ali.Id;   
        
        Database.update(ali,False);
        
        Apttus_Billing__UsageInput__c uI =  new Apttus_Billing__UsageInput__c(
                                            Apttus_Billing__AssetNumber__c = ali.Id,
                                            APTS_Price_Type__c = 'Paid'); 
        Insert uI;
        
        Set<ID> usageInputIDs = new Set<ID>();
        usageInputIDs.add(uI.Id);

        Database.executeBatch(new APTS_ProcessUsageInputBatch());

    }
}