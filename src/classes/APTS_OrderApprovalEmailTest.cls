@IsTest
public with sharing class APTS_OrderApprovalEmailTest
{

public static TestMethod void orderapprovalTest()
{

Account testAccount = APTS_TestUtils.createOrganisationproduct();
        insert testAccount;

     Apttus_Config2__PriceList__c priceList = APTS_TestUtils.createPriceList();
        insert priceList;

 Apttus_Config2__BillingPreference__c billpref = APTS_TestUtils.createBillingPrefrence('January');
        insert billpref;
        
      Apttus_Config2__Order__c  ord = APTS_TestUtils.createOrder('New',priceList.id,testAccount.Id,billpref.id);
        insert ord;
        
        APTS_OrderApprovalEmailController oe = new APTS_OrderApprovalEmailController();
        oe.orderId = ord.id;
        oe.getorder();
        oe.getorderLineItems();
}

}