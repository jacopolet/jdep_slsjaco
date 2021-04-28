/**
* Class Name : APTS_SearchPhysicalAssetController_Test 
* Description :  Apex Class to test APTS_SearchPhysicalAssetController
* Author : Nirmal Vijaya Kumar
* Date Created : 03/06/2018
**/
@istest
private class APTS_SearchPhysicalAssetController_Test{

    /**Method Name : testPhyAssetController
    * Description : Method to test the search and update methods of APTS_SearchPhysicalAssetController
    */
    static testMethod void testPhyAssetController(){
        Account testAccount = APTS_TestUtils.createaccount();
        Database.insert(testAccount, false);
        
        Product2 testProduct = APTS_TestUtils.createProduct('Test','1234','Test');
        Database.insert(testProduct, false);
        
        Apttus_Config2__PriceList__c testPriceList = APTS_TestUtils.createPriceList();
        Database.insert(testPriceList, false);
        
        Apttus_Config2__PriceListItem__c testPLI = APTS_TestUtils.createPriceListItem(testPriceList.Id, testProduct.Id);
        Database.insert(testPLI, false);
        
        Apttus_Config2__BillingPreference__c testBillingPref = APTS_TestUtils.createBillingPrefrence();
        Database.insert(testBillingPref, false);
        
        Apttus_Config2__Order__c testOrder = APTS_TestUtils.createOrder('Test',testPriceList.Id, testAccount.Id, testBillingPref.Id);
        Database.insert(testOrder, false);
        
        PhysicalAsset__c testPhysicalAsset = APTS_TestUtils.createPhysicalAsset();
        Database.insert(testPhysicalAsset, false);
        
        Apttus_Config2__AssetLineItem__c testALI = APTS_TestUtils.createAssetLineItem(testAccount.Id, testProduct.Id, testPriceList.Id, testPLI.Id, testBillingPref.Id, testOrder.Id);
        testALI.Name='Test';
        //testALI.APTS_Physical_Asset_Id__c = testPhysicalAsset.Id;
        testALI.APTS_Physical_Asset__c= testPhysicalAsset.Id;//Added by Abhishek K to Change Field
        Database.insert(testALI, false);

        APTS_SearchPhysicalAssetController.searchAssetLineItem('01232345');
        APTS_SearchPhysicalAssetController.updateAssetLineItem(testALI.Id,'01232345'); 
        
        PhysicalAsset__c phyAsset= [SELECT Id, Name, SerialNumber__c FROM PhysicalAsset__c 
                                   WHERE SerialNumber__c =: '01232345'  LIMIT 1][0];
         Apttus_Config2__AssetLineItem__c  aliToUpdate =[SELECT Id,APTS_Physical_Asset__c FROM Apttus_Config2__AssetLineItem__c
                                                         WHERE Id=:testALI.Id LIMIT 1][0];

        System.assertEquals(testALI.Id,aliToUpdate.Id);                                              
        System.assertEquals(phyAsset.Id,aliToUpdate.APTS_Physical_Asset__c);
        System.assertEquals('01232345',phyAsset.SerialNumber__c);
    }

}