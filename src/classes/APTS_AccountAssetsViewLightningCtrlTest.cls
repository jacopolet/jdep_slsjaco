/*************************************************************
@Name: APTS_AccountAssetsViewLightningCtrlTest
@Author: Wendy Kelley
@CreateDate: 31/01/2018
@Description: Test class for APTS_AccountAssetsViewLightningCtrl
@UsedBy:
******************************************************************/
@isTest
public with sharing class APTS_AccountAssetsViewLightningCtrlTest {
    private final static string STR_ASSET_STATUS_ACTIVATED = 'Activated';
    private final static string STR_LINETYPE_PROD_SERVICE = 'Product/Service';
    private final static string STR_LINETYPE_OPTION = 'Option';

    /**
     * setup test data
     */
    @TestSetup
    public static void buildTestData(){

        User usr = APTS_TestUtils.createUser();
        usr.Username += '.' + Integer.valueOf(math.rint(math.random()*1000000));
        Database.insert(usr);

        Account acc = APTS_TestUtils.createOrganisationproduct();
        acc.Name = 'Test Asset Acct';
        Database.insert(acc);

        List<Apttus_Config2__AssetLineItem__c> assetLineItemHeaderList = new List<Apttus_Config2__AssetLineItem__c>();

        Product2 prod = APTS_TestUtils.createProduct('Test Product', 'PRD001', 'Machines');
        Database.insert(prod);

        Apttus_Config2__AssetLineItem__c assetLineItemHeader = new Apttus_Config2__AssetLineItem__c();
        assetLineItemHeader.Name = 'Test Asset 1';
        assetLineItemHeader.Apttus_Config2__AccountId__c = acc.Id;
        assetLineItemHeader.Apttus_Config2__AssetStatus__c = STR_ASSET_STATUS_ACTIVATED;
        assetLineItemHeader.Apttus_Config2__IsInactive__c = false;
        assetLineItemHeader.Apttus_Config2__LineType__c = STR_LINETYPE_PROD_SERVICE ;
        assetLineItemHeader.Apttus_Config2__ProductId__c = prod.Id;
        assetLineItemHeader.Apttus_Config2__HasOptions__c = true;
        assetLineItemHeader.Apttus_Config2__IsPrimaryLine__c = true;
        assetLineItemHeaderList.add(assetLineItemHeader);

        assetLineItemHeader = new Apttus_Config2__AssetLineItem__c();
        assetLineItemHeader.Name = 'Test Asset 2';
        assetLineItemHeader.Apttus_Config2__ProductId__c = prod.Id;
        assetLineItemHeader.Apttus_Config2__AccountId__c = acc.Id;
        assetLineItemHeader.Apttus_Config2__AssetStatus__c = STR_ASSET_STATUS_ACTIVATED;
        assetLineItemHeader.Apttus_Config2__IsInactive__c = false;
        assetLineItemHeader.Apttus_Config2__LineType__c = STR_LINETYPE_PROD_SERVICE ;
        assetLineItemHeader.Apttus_Config2__HasOptions__c = false;
        assetLineItemHeaderList.add(assetLineItemHeader);

        Database.insert(assetLineItemHeaderList);

    }

    /**
     * positive test - test account with active assets
     */
    @isTest
    static void testAssetLineItemViewPage(){
        List<Account> accountList = [SELECT Id FROM Account WHERE Name LIKE '%Test Asset Acct%' LIMIT 1];

        List<Apttus_Config2__AssetLineItem__c> aliList = new List<Apttus_Config2__AssetLineItem__c>();
        Test.startTest();
        APTS_AccountAssetsViewLightningCtrl.activeAssetQueryMdt  = (List<APTS_Batch_Queries__mdt>) JSON.deserialize( '[{"Id ":"dummyValue","APTS_Query_String__c":"Select id from Apttus_Config2__AssetLineItem__c"}]', List<APTS_Batch_Queries__mdt>.class );
        aliList = APTS_AccountAssetsViewLightningCtrl.getBundleAssetLineItems(accountList[0].Id);
        Test.stopTest(); 

        //System.assertEquals(1, aliList.size());
    }

    /**
     * negative test - test account with no active assets
     */
    @isTest
    static void testAssetLineItemViewPageNoRecord(){
        User usr = [SELECT Id FROM User WHERE LastName LIKE '%123Smith%' LIMIT 1];
        Account acct = APTS_TestUtils.createOrganisationproduct();
        acct.Name = 'Test Account 1';
        Database.insert(acct);

        List<Apttus_Config2__AssetLineItem__c> aliList = new List<Apttus_Config2__AssetLineItem__c>();
        Test.startTest();
            System.runAs(usr) {
        APTS_AccountAssetsViewLightningCtrl.activeAssetQueryMdt  = (List<APTS_Batch_Queries__mdt>) JSON.deserialize( '[{"Id ":"dummyValue","APTS_Query_String__c":"Select id from Apttus_Config2__AssetLineItem__c"}]', List<APTS_Batch_Queries__mdt>.class );
                aliList = APTS_AccountAssetsViewLightningCtrl.getBundleAssetLineItems(acct.Id);
            }
        Test.stopTest();
    }

    static testMethod void testadminorder() {

        List<Apttus_Config2__AssetLineItem__c> aliList = new List<Apttus_Config2__AssetLineItem__c>();
        List<Account> accountList = [SELECT Id FROM Account WHERE Name LIKE '%Test Asset Acct%' LIMIT 1];
        
        Product2 oproduct = [select id,name,ProductCode from Product2 limit 1];
        Apttus_Config2__AccountLocation__c testAcclocation = APTS_TestUtils.createAccountLocation(accountList[0].Id);
        insert testAcclocation;

        PhysicalAsset__c testphAsset = APTS_TestUtils.createPhysicalAsset();
        insert testphAsset;

        Apttus_Config2__PriceList__c oTestPricelist = APTS_TestUtils.createPriceList();
        insert oTestPricelist;

        Apttus_Config2__PriceListItem__c opriceListItem = APTS_TestUtils.createPriceListItem(oTestPricelist.id,oproduct.id);
        insert opriceListItem;

        Apttus_Config2__BillingPreference__c obillpref = APTS_TestUtils.createBillingPrefrence('April');
        insert obillpref;

        Contact oTestContact = APTS_TestUtils.createContact();
        insert oTestContact;

        Apttus_Config2__AccountLocation__c location = APTS_TestUtils.createAccountLocation(accountList[0].ID);
        insert location;

        Apttus__APTS_Agreement__c oAggreement = APTS_TestUtils.createAgreement(oTestContact.Id, null, oTestPricelist.Id, accountList[0].Id);
        oAggreement.Apttus__Status_Category__c = 'In Effect';
        oAggreement.Apttus__Status__c = 'Activated';
        oAggreement.Apttus__Contract_End_Date__c = Date.today().addYears(3);
        insert oAggreement;

        APTS_Order_LSP_Details__c oLSPdetail = new APTS_Order_LSP_Details__c();
        oLSPdetail.APTS_Area__c = 'Test Area';
        oLSPdetail.APTS_Building__c = 'Test Building';
        oLSPdetail.APTS_Floor__c = 'Test Floor';
        oLSPdetail.APTS_SmokingArea__c = true;
        oLSPdetail.APTS_StairClimber__c = true;

        Apttus_Config2__AssetLineItem__c oAssetLItem = APTS_TestUtils.createAssetLineItem(accountList[0].Id, oproduct.Id, oTestPricelist.Id, opriceListItem.Id, obillpref.Id, null);
        oAssetLItem.Apttus_CMConfig__AgreementId__c = oAggreement.Id;
        oAssetLItem.APTS_Option_Group_Text__c = 'Technical Service';
        oAssetLItem.APTS_Physical_Asset__c = testphAsset.Id; 
        oAssetLItem.APTS_Sub_Status__c = 'Temporary Deactivated';
        insert oAssetLItem;
        APTS_AccountAssetsViewLightningCtrl.activeAssetQueryMdt  = (List<APTS_Batch_Queries__mdt>) JSON.deserialize( '[{"Id ":"dummyValue","APTS_Query_String__c":"Select id from Apttus_Config2__AssetLineItem__c"}]', List<APTS_Batch_Queries__mdt>.class );

        Test.startTest();
        APTS_AccountAssetsViewLightningCtrl.getAccountLocations(accountList[0].ID);
        APTS_AccountAssetsViewLightningCtrl.getRelatedAgreements(accountList[0].ID);
        aliList = APTS_AccountAssetsViewLightningCtrl.getDeactivatedAssetLineItems(accountList[0].Id);
        aliList = APTS_AccountAssetsViewLightningCtrl.getALIsBySerialNo(accountList[0].Id,'01232345');
        APTS_AccountAssetsViewLightningCtrl.updateAssets(new List<String>{oAssetLItem.Id},'Installation');
        APTS_AccountAssetsViewLightningCtrl.updateAssets(new List<String>{oAssetLItem.Id},'De-installation');
        APTS_AccountAssetsViewLightningCtrl.getKeyPrefixes();
        String result = APTS_AccountAssetsViewLightningCtrl.createAdminOrder(new List<string>{String.valueof(oAssetLItem.Id)},accountList[0].Id,oAggreement.Id,oLSPdetail,String.Valueof(testAcclocation.Id),false);
        String movementUtilResult = APTS_AccountAssetsViewLightningCtrl.invokeMovementUtil(oAssetLItem.Id, accountList[0].Id, oAggreement.Id, oLSPdetail, testAcclocation.Id, System.today(),TRUE);
        list<APTS_Error_Object__c>error = [select id,APTS_Error_Name__c,APTS_Error_Type__c,APTS_Description_Of_Error__c, APTS_Error_Description__c from APTS_Error_Object__c limit 1];
    

        Test.stopTest();
    }
}