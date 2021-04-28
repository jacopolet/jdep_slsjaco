/*************************************************************
@Name: APTS_MovementOrderUtilsTest
@Author: Nikita Modi
@CreateDate: 12-03-2019
@Description: APTS_MovementOrderUtils Test
@UsedBy: APTS_MovementOrderUtils
******************************************************************/
//v100 12-03-2019 Nikita Modi: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
@isTest
private class APTS_MovementOrderUtilsTest {
    @isTest
    public static void testMovementOrderPass(){
        
        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        oPhysicalAsset.SerialNumber__c = 'Test123';
        insert oPhysicalAsset;
        
        Apttus__APTS_Agreement__c oAggr = new Apttus__APTS_Agreement__c();
        oAggr.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
        insert oAggr;

        Account acc = APTS_TestDataFactory.createAccount('Movement Order Account');
        insert acc;

        Apttus_Config2__AssetLineItem__c oALI = new Apttus_Config2__AssetLineItem__c();
        oALI.APTS_Physical_Asset__c = oPhysicalAsset.Id;
        oALI.Apttus_Config2__LineType__c = 'Product/Service';   
        oALI.Apttus_Config2__IsPrimaryLine__c = true;
        oAlI.Apttus_Config2__AssetStatus__c = 'Activated';
        oAlI.Apttus_CMConfig__AgreementId__c = oAggr.id;
        oALI.Apttus_Config2__AccountId__c=acc.id;
        insert oALI;       

        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = acc.Id;
        loc.Account_Location_Status__c  = 'Valid';
        insert loc;
        
        APTS_Order_LSP_Details__c oLSPdetail = new APTS_Order_LSP_Details__c();
        oLSPdetail.APTS_Area__c = 'Test Area';
        oLSPdetail.APTS_Building__c = 'Test Building';
        oLSPdetail.APTS_Floor__c = 'Test Floor';
        oLSPdetail.APTS_SmokingArea__c = true;
        oLSPdetail.APTS_StairClimber__c = true;
        insert oLSPdetail;
        
        Test.startTest();
        Date deInstallDate = system.today().addDays(math.abs(math.mod(Date.newInstance(1900, 1, 8).daysBetween(system.today()),7)-7));
        Date InstallDate = system.today().addDays(math.abs(math.mod(Date.newInstance(1900, 1, 8).daysBetween(system.today()),7)-7));
        APTS_MovementOrderUtils.validate(oALI.id,oAggr.id,acc.id,oLSPdetail,loc.id,InstallDate,true);
        
        //Apttus_Config2__Order__c order = [select id from Apttus_Config2__Order__c limit 1];    
        APTS_MovementOrderUtils.saveCart(null,null);
        APTS_MovementOrderUtils move = new APTS_MovementOrderUtils();
        move.goToPricing(false,null);      
        APTS_MovementOrderUtils.createCart(null);
        APTS_MovementOrderUtils.getHistoricalPriceChange(null);
        Test.stopTest();

    }
   @isTest
    public static void testMovementOrderFail(){
        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        oPhysicalAsset.SerialNumber__c = 'Test123';
        insert oPhysicalAsset;
        
        Apttus__APTS_Agreement__c oAggr = new Apttus__APTS_Agreement__c();
        oAggr.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId();
        insert oAggr;
        
        Apttus__APTS_Agreement__c oAggr1 = new Apttus__APTS_Agreement__c();
        oAggr1.recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId();
 
        insert oAggr1;

        Apttus_Config2__AssetLineItem__c oALI = new Apttus_Config2__AssetLineItem__c();
        oALI.Apttus_Config2__LineType__c = 'Product/Service';   
        oALI.Apttus_Config2__IsPrimaryLine__c = true;
        oAlI.Apttus_Config2__AssetStatus__c = 'New';
        oAlI.Apttus_CMConfig__AgreementId__c = oAggr1.id;
        insert oALI;
        
        Account acc = APTS_TestDataFactory.createAccount('Movement Order Account');
        insert acc;
        
        Date deInstallDate = system.today().addDays(math.abs(math.mod(Date.newInstance(1900, 1, 8).daysBetween(system.today()),7)-7));
        Date InstallDate = system.today().addDays(math.abs(math.mod(Date.newInstance(1900, 1, 8).daysBetween(system.today()),7)-7));

        Apttus_Config2__AccountLocation__c loc = new Apttus_Config2__AccountLocation__c();
        loc.Apttus_Config2__AccountId__c = acc.Id;
        loc.Account_Location_Status__c  = 'Valid';
        insert loc;
        
        APTS_Order_LSP_Details__c oLSPdetail = new APTS_Order_LSP_Details__c();
        oLSPdetail.APTS_Area__c = 'Test Area';
        oLSPdetail.APTS_Building__c = 'Test Building';
        oLSPdetail.APTS_Floor__c = 'Test Floor';
        oLSPdetail.APTS_SmokingArea__c = true;
        oLSPdetail.APTS_StairClimber__c = true;
        insert oLSPdetail;
       
        Test.startTest();
        APTS_MovementOrderUtils.validate(oALI.id,oAggr.id,acc.id,oLSPdetail,loc.id,system.today(),false);
        APTS_MovementOrderUtils.getAccount(acc.id);
        APTS_MovementOrderUtils.getAssetL1(oALI);
        APTS_MovementOrderUtils.changeAssets(null,null,null, null);
        APTS_MovementOrderUtils.addMovementProductToCart(null, null, APTS_OrderConstants.INTERNAL_MOVEMENT);
        APTS_MovementOrderUtils.createMovementOrder(oALI,oAggr1,acc.id,oLSPdetail,loc.id,InstallDate,'Standard Order',false);
        APTS_MovementOrderUtils.createOrder(oALI,oAggr1,acc,loc.id,InstallDate,'Standard Order',false);
        Test.stopTest();

    }

}