/**
 * @description       : APTS_ConversionOrderPhaUtilsTest
 * @author            : Karan Khatri
 * @group             : 
 * @last modified on  : 16-02-2021
 * @last modified by  : Karan Khatri
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   16-02-2021   Karan Khatri   Initial Version
**/
@isTest
public with sharing class APTS_ConversionOrderPhaUtilsTest {
    @testSetup
    static void dataSetup() {

        
        TriggerSettings__c oTriggerSettings = new TriggerSettings__c();
        oTriggerSettings.AccountTrigger__c=false;
        insert oTriggerSettings;

        List<Apttus_Config2__AssetLineItem__c> InsertList = new List<Apttus_Config2__AssetLineItem__c>();
        Account acc = APTS_TestUtils.createaccount();
        acc.Sales_Organization__c = 'SAP_0111';
         Database.insert(acc,false);

         PhysicalAssetResponseTimeMapping__c physicalassetMapping = new PhysicalAssetResponseTimeMapping__c();
         physicalassetMapping.name='SAP_0111_12';
         physicalassetMapping.Option_Product_Value__c='12';
         physicalassetMapping.Sales_Org__c='SAP_0111';
         physicalassetMapping.New_Value__c='91';
         insert physicalassetMapping; 
         
         Contact con = APTS_TestUtils.createContact();
         Database.insert(con,false);
 
         Account acc2 = APTS_TestUtils.createaccount();
         Database.insert(acc2,false);
      
         Product2 prd = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
         prd.Name = 'Product Name';
         prd.Description = 'Product Description';
         prd.ProductCode = '23456789';
         Database.insert(prd,false);
 
         Apttus_Config2__PriceList__c  plist = APTS_TestUtils.createPriceList();
         Database.insert(plist,false);
         
         Apttus__APTS_Agreement__c aggr = APTS_TestUtils.createAgreement(con.Id, null, plist.Id, acc.Id);
         aggr.Apttus__Status__c = 'In Effect';
         aggr.Apttus__Status_Category__c = 'Activated';
         Database.insert(aggr,false);
 
         Apttus_Config2__PriceListItem__c pli = APTS_TestUtils.createPriceListItem(plist.Id,prd.Id);
         Database.insert(pli,false);
 
         Apttus_Config2__BillingPreference__c billpre = APTS_TestUtils.createBillingPrefrence();
         Database.insert(billpre,false);
 
 
         Apttus_Config2__Order__c order = APTS_TestUtils.createOrder('test',plist.Id,acc.Id,billpre.Id);
         order.APTS_Order_Type__c='Admin order';
         order.APTS_Order_Sub_Type__c='Conversion Order';
         order.APTS_Contract_Change__c = 'No';
         insert order;

        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__OrderId__c = order.id;
        oOLI.Apttus_Config2__Status__c='Activated';
        insert oOLI;

        Apttus_Config2__OrderLineItem__c oOLI1 = new Apttus_Config2__OrderLineItem__c();
        oOLI1.Apttus_Config2__OrderId__c = order.id;
        oOLI1.Apttus_Config2__Status__c='Activated';
        insert oOLI1;
         
        PhysicalAsset__c oPhysicalAsset = APTS_TestDataFactory.createPhysicalAsset();
        oPhysicalAsset.SerialNumber__c = 'Test123';
        insert oPhysicalAsset;
         
         Apttus_Config2__AssetLineItem__c ali1 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali1.APTS_relatedlist_agreement__c = aggr.Id;
         ali1.Apttus_Config2__AccountId__c = acc.Id;
         ali1.APTS_Physical_Asset__c = oPhysicalAsset.Id;
         ali1.APTS_RefurbishedMachine__c = true;
         ali1.Apttus_Config2__StartDate__c = system.today();
         ali1.Apttus_Config2__EndDate__c = system.today().adddays(1);
         ali1.Apttus_Config2__BusinessLineItemId__c=oOLI.id;
         ali1.APTS_latest_order_type__c='Admin order';
         ali1.APTS_latest_order_type__c='Conversion order';
         // ali1.APTS_Serial_Number__c = '123';
         ali1.APTS_RefurbishedMachine__c = true;
         ali1.Apttus_Config2__AssetStatus__c = 'Activated';
         ali1.APTS_Is_Primary_L1_Line__c=true;
         ali1.Apttus_Config2__LineType__c = 'Product/Service';
         ali1.APTS_OwnedByCustomer__c=false;
         insert ali1;

         PhysicalAsset__c oPhysicalAsset1 = APTS_TestDataFactory.createPhysicalAsset();
         oPhysicalAsset1.SerialNumber__c = 'Test1234';
         oPhysicalAsset1.ParentPhysicalAsset__c=oPhysicalAsset.id;
         insert oPhysicalAsset1;

         Product2 option1 = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
         option1.Name = 'Product Name';
         option1.Description = 'Product Description';
         option1.ProductCode = '23456';
         option1.APTS_Option_Group_Indicator__c = '0102';
         insert option1;

         Apttus_Config2__AssetLineItem__c ali2 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali2.APTS_relatedlist_agreement__c = aggr.Id;
         ali2.Apttus_Config2__AccountId__c = acc.Id;
         //ali2.APTS_Physical_Asset__c = oPhysicalAsset1.Id;
         ali2.APTS_RefurbishedMachine__c = true;
         ali2.Apttus_Config2__StartDate__c = system.today();
         ali2.Apttus_Config2__EndDate__c = system.today().adddays(1);
         // ali1.APTS_Serial_Number__c = '123';
         ali2.APTS_latest_order_type__c='Admin order';
         ali2.APTS_latest_order_type__c='Conversion order';
         ali2.APTS_RefurbishedMachine__c = true;
         ali2.Apttus_Config2__AssetStatus__c = 'Activated';
         ali2.Apttus_Config2__LineType__c = 'Option';
         ali2.Apttus_Config2__OptionId__c = option1.id;
         ali2.APTS_Option_Group_Text__c='Full Operating';
         ali2.APTS_Is_Primary_L1_Asset__c=ali1.id;
         ali2.Apttus_Config2__BundleAssetId__c=ali1.id;
         ali2.Apttus_Config2__BusinessLineItemId__c=oOLI1.id;
         ali2.APTS_OwnedByCustomer__c=false;
         Insert ali2;

         Product2 option2 = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
         option2.Name = 'Product Name';
         option2.Description = 'Product Description';
         option2.ProductCode = '234567';
         option2.APTS_Option_Group_Indicator__c = '0102';
         insert option2;

         Apttus_Config2__AssetLineItem__c ali3 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali3.APTS_relatedlist_agreement__c = aggr.Id;
         ali3.Apttus_Config2__AccountId__c = acc.Id;
         ali3.APTS_Physical_Asset__c = oPhysicalAsset1.Id;
         ali3.APTS_RefurbishedMachine__c = true;
         ali3.Apttus_Config2__StartDate__c = system.today();
         ali3.Apttus_Config2__EndDate__c = system.today().adddays(1);
         // ali1.APTS_Serial_Number__c = '123';
         ali3.APTS_latest_order_type__c='Admin order';
         ali3.APTS_latest_order_type__c='Conversion order';
         ali3.APTS_RefurbishedMachine__c = true;
         ali3.Apttus_Config2__AssetStatus__c = 'Activated';
         ali3.Apttus_Config2__LineType__c = 'Option';
         ali2.Apttus_Config2__OptionId__c = option2.id;
         ali3.APTS_Option_Group_Text__c='Connectivity System';
         ali3.APTS_Is_Primary_L1_Asset__c=ali1.id;
         ali3.Apttus_Config2__BundleAssetId__c=ali1.id;
         ali3.Apttus_Config2__BusinessLineItemId__c=oOLI1.id;
         ali3.APTS_OwnedByCustomer__c=false;
         Insert ali3;
         
         Apttus_Config2__AssetLineItem__c ali4 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali4.APTS_relatedlist_agreement__c = aggr.Id;
         ali4.Apttus_Config2__AccountId__c = acc.Id;
         ali4.APTS_RefurbishedMachine__c = true;
         ali4.Apttus_Config2__StartDate__c = system.today();
         ali4.Apttus_Config2__EndDate__c = system.today().adddays(1);
         // ali1.APTS_Serial_Number__c = '123';
         ali4.APTS_latest_order_type__c='Admin order';
         ali4.APTS_latest_order_type__c='Conversion order';
         ali4.APTS_RefurbishedMachine__c = true;
         ali4.Apttus_Config2__AssetStatus__c = 'Activated';
         ali4.Apttus_Config2__LineType__c = 'Option';
         ali4.APTS_Option_Group_Text__c='Technical Service';
         ali4.Apttus_Config2__BundleAssetId__c=ali1.id;
         ali4.APTS_Is_Primary_L1_Asset__c=ali1.id;
         ali4.Apttus_Config2__BusinessLineItemId__c=oOLI1.id;
         ali4.APTS_OwnedByCustomer__c=false;
         Insert ali4;
         
         Apttus_Config2__AssetLineItem__c ali5 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali5.APTS_relatedlist_agreement__c = aggr.Id;
         ali5.Apttus_Config2__AccountId__c = acc.Id;
         ali5.APTS_RefurbishedMachine__c = true;
         ali5.Apttus_Config2__StartDate__c = system.today();
         ali5.Apttus_Config2__EndDate__c = system.today().adddays(1);
         // ali1.APTS_Serial_Number__c = '123';
         ali5.APTS_latest_order_type__c='Admin order';
         ali5.APTS_latest_order_type__c='Conversion order';
         ali5.APTS_RefurbishedMachine__c = true;
         ali5.Apttus_Config2__AssetStatus__c = 'Activated';
         ali5.Apttus_Config2__LineType__c = 'Option';
         ali5.Apttus_Config2__Description__c='Standard Weekdays';
         ali5.Apttus_Config2__BundleAssetId__c=ali1.id;
         ali5.APTS_Is_Primary_L1_Asset__c=ali1.id;
         ali5.Apttus_Config2__BusinessLineItemId__c=oOLI1.id;
         ali5.APTS_OwnedByCustomer__c=false;
         Insert ali5;

         Apttus_Config2__AssetLineItem__c ali6 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali6.APTS_relatedlist_agreement__c = aggr.Id;
         ali6.Apttus_Config2__AccountId__c = acc.Id;
         ali6.APTS_RefurbishedMachine__c = true;
         ali6.Apttus_Config2__StartDate__c = system.today();
         ali6.Apttus_Config2__EndDate__c = system.today().adddays(1);
         ali6.APTS_OwnedByCustomer__c=false;
         // ali1.APTS_Serial_Number__c = '123';
         ali6.APTS_latest_order_type__c='Admin order';
         ali6.APTS_latest_order_type__c='Conversion order';
         ali6.APTS_RefurbishedMachine__c = true;
         ali6.Apttus_Config2__AssetStatus__c = 'Activated';
         ali6.Apttus_Config2__LineType__c = 'Option';
         ali6.APTS_Option_Group_Text__c='Response Time';
         ali6.Apttus_Config2__BundleAssetId__c=ali1.id;
         ali6.APTS_Is_Primary_L1_Asset__c=ali1.id;
         ali6.Apttus_Config2__BusinessLineItemId__c=oOLI1.id;
         Insert ali6;

         Product2 option3 = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
         option3.Name = 'Product Name';
         option3.Description = 'Product Description';
         option3.ProductCode = '2345678';
         option3.APTS_Option_Group_Indicator__c = '0102';
         option3.APTS_Response_Time_Hours__c = 4;
         insert option3;

         Apttus_Config2__AssetLineItem__c ali7 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali7.APTS_relatedlist_agreement__c = aggr.Id;
         ali7.Apttus_Config2__AccountId__c = acc.Id;
        // ali7.APTS_Physical_Asset__c = oPhysicalAsset1.Id;
         ali7.APTS_RefurbishedMachine__c = true;
         ali7.Apttus_Config2__StartDate__c = system.today();
         ali7.Apttus_Config2__EndDate__c = system.today().adddays(1);
         // ali1.APTS_Serial_Number__c = '123';
         ali7.APTS_latest_order_type__c='Admin order';
         ali7.APTS_latest_order_type__c='Conversion order';
         ali7.APTS_RefurbishedMachine__c = true;
         ali7.Apttus_Config2__AssetStatus__c = 'Activated';
         ali7.Apttus_Config2__LineType__c = 'Option';
         ali7.APTS_Option_Group_Text__c='Response Time';
         ali7.APTS_Is_Primary_L1_Asset__c=ali1.id;
         ali7.Apttus_Config2__BundleAssetId__c=ali1.id;
         ali7.Apttus_Config2__BusinessLineItemId__c=oOLI1.id;
         ali7.Apttus_Config2__OptionId__c=option3.id;
         ali7.APTS_OwnedByCustomer__c=false;
         Insert ali7;

         Apttus_Config2__AssetAttributeValue__c attrib2 = new Apttus_Config2__AssetAttributeValue__c();
         attrib2.APTS_First_Line_Response_Time__c=10;
         attrib2.Apttus_Config2__AssetLineItemId__c=ali7.id;
         insert attrib2;

         ali7.Apttus_Config2__AttributeValueId__c =attrib2.id;
         update ali7;

         Apttus_Config2__AssetAttributeValue__c attrib1 = new Apttus_Config2__AssetAttributeValue__c();
         attrib1.APTS_Type_Of_Contract__c='Rent';
         attrib1.APTS_Consumer_Price__c=10;
         attrib1.APTS_Cup_Size__c='Small';
         attrib1.APTS_Taste_Pallet__c='Value';
         attrib1.APTS_Number_of_months__c='12';
         attrib1.APTS_Merchant__c='Customer';
         attrib1.APTS_WTS_Changed_By__c='Customer';
         attrib1.Apttus_Config2__AssetLineItemId__c=ali1.id;
         insert attrib1;

         ali1.Apttus_Config2__AttributeValueId__c =attrib1.id;
         update ali1;

         Product2 option4 = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
         option4.Name = 'Product Name';
         option4.Description = 'Product Description';
         option4.ProductCode = '23456779';
         option4.APTS_Option_Group_Indicator__c = '0102';
         option4.APTS_Response_Time_Hours__c = 12;
         insert option4;

         Product2 option5 = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
         option5.Name = 'Product Name';
         option5.Description = 'Product Description';
         option5.ProductCode = '2345996';
         option5.APTS_Option_Group_Indicator__c = '0102';
         option5.APTS_Response_Time_Hours__c = 12;
         insert option5;

         Product2 option6 = APTS_TestUtils.createProduct('test High Tax', '26940998', 'Coffee');
         option6.Name = 'Product Name';
         option6.Description = 'Product Description';
         option6.ProductCode = '99876543';
         option6.APTS_Option_Group_Indicator__c = '0102';
         option6.APTS_Response_Time_Hours__c = 12;
         insert option6;

         Apttus_Config2__AssetLineItem__c ali8 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali8.APTS_relatedlist_agreement__c = aggr.Id;
         ali8.Apttus_Config2__AccountId__c = acc.Id;
         //ali8.APTS_Physical_Asset__c = oPhysicalAsset1.Id;
         ali8.APTS_RefurbishedMachine__c = true;
         ali8.Apttus_Config2__StartDate__c = system.today();
         ali8.Apttus_Config2__EndDate__c = system.today().adddays(1);
         // ali1.APTS_Serial_Number__c = '123';
         ali8.APTS_latest_order_type__c='Admin order';
         ali8.APTS_latest_order_type__c='Conversion order';
         ali8.APTS_RefurbishedMachine__c = true;
         ali8.Apttus_Config2__AssetStatus__c = 'Activated';
         ali8.Apttus_Config2__LineType__c = 'Option';
         ali8.Apttus_Config2__OptionId__c = option4.id;
         ali8.Apttus_Config2__Description__c='Full Operating xyz';
         ali8.APTS_Is_Primary_L1_Asset__c=ali1.id;
         ali8.Apttus_Config2__BundleAssetId__c=ali1.id;
         ali8.Apttus_Config2__BusinessLineItemId__c=oOLI1.id;
         ali8.APTS_OwnedByCustomer__c=false;
         Insert ali8;

         Apttus_Config2__AssetLineItem__c ali9 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali9.APTS_relatedlist_agreement__c = aggr.Id;
         ali9.Apttus_Config2__AccountId__c = acc.Id;
         //ali8.APTS_Physical_Asset__c = oPhysicalAsset1.Id;
         ali9.APTS_RefurbishedMachine__c = true;
         ali9.Apttus_Config2__StartDate__c = system.today();
         ali9.Apttus_Config2__EndDate__c = system.today().adddays(1);
         // ali1.APTS_Serial_Number__c = '123';
         ali9.APTS_latest_order_type__c='Admin order';
         ali9.APTS_latest_order_type__c='Conversion order';
         ali9.APTS_RefurbishedMachine__c = true;
         ali9.Apttus_Config2__AssetStatus__c = 'Activated';
         ali9.Apttus_Config2__LineType__c = 'Option';
         ali9.Apttus_Config2__OptionId__c = option5.id;
         ali9.Apttus_Config2__Description__c='WATERFILTER REPLACEMENT';
         ali9.APTS_Option_Group_Text__c='Value Added Service';
         ali9.APTS_Is_Primary_L1_Asset__c=ali1.id;
         ali9.Apttus_Config2__BundleAssetId__c=ali1.id;
         ali9.Apttus_Config2__BusinessLineItemId__c=oOLI1.id;
         ali9.APTS_OwnedByCustomer__c=false;
         Insert ali9;

         Apttus_Config2__AssetAttributeValue__c attrib = new Apttus_Config2__AssetAttributeValue__c();
         attrib.APTS_Number_of_hours_per_month__c=10;
         attrib.Apttus_Config2__AssetLineItemId__c=ali8.id;
         insert attrib;

         ali8.Apttus_Config2__AttributeValueId__c =attrib.id;
         update ali8;

         Apttus_Config2__AssetLineItem__c ali10 =APTS_TestUtils.createAssetLineItem(acc.Id,prd.Id,plist.Id, pli.Id ,billpre.Id ,order.Id);
         ali10.APTS_relatedlist_agreement__c = aggr.Id;
         ali10.Apttus_Config2__AccountId__c = acc.Id;
         //ali8.APTS_Physical_Asset__c = oPhysicalAsset1.Id;
         ali10.APTS_RefurbishedMachine__c = true;
         ali10.Apttus_Config2__StartDate__c = system.today();
         ali10.Apttus_Config2__EndDate__c = system.today().adddays(1);
         // ali1.APTS_Serial_Number__c = '123';
         ali10.APTS_latest_order_type__c='Admin order';
         ali10.APTS_latest_order_type__c='Conversion order';
         ali10.APTS_RefurbishedMachine__c = true;
         ali10.Apttus_Config2__AssetStatus__c = 'Activated';
         ali10.Apttus_Config2__LineType__c = 'Option';
         ali10.Apttus_Config2__OptionId__c = option6.id;
         //ali9.Apttus_Config2__Description__c='WATERFILTER REPLACEMENT';
         ali10.APTS_Option_Group_Text__c='Preventive Maintenance';
         ali10.APTS_Is_Primary_L1_Asset__c=ali1.id;
         ali10.Apttus_Config2__BundleAssetId__c=ali1.id;
         ali10.Apttus_Config2__BusinessLineItemId__c=oOLI1.id;
         ali10.APTS_OwnedByCustomer__c=false;
         Insert ali10;

         APTS_Agreement_PO_Details__c podetails1 = new APTS_Agreement_PO_Details__c();
         podetails1.APTS_PO_Number_Type__c='Fixed';
         podetails1.APTS_PO_Number_Required__c='Yes';
         podetails1.APTS_PO_Number__c='123';
         podetails1.APTS_PO_Category__c='Machine';
         podetails1.APTS_Agreement__c = aggr.Id;
         insert podetails1;

         APTS_Agreement_PO_Details__c podetails2 = new APTS_Agreement_PO_Details__c();
         podetails2.APTS_PO_Number_Type__c='Fixed';
         podetails2.APTS_PO_Number_Required__c='Yes';
         podetails2.APTS_PO_Number__c='123';
         podetails2.APTS_PO_Category__c='Services';
         podetails2.APTS_Agreement__c = aggr.Id;
         insert podetails2;

    }
    static testMethod void validateIfHasChange() {
        Set<Id> assetidSet = new Set<Id>();
        For(Apttus_Config2__AssetLineItem__c assObj : [select id from Apttus_Config2__AssetLineItem__c where Apttus_Config2__AssetStatus__c='Activated']){
            assetidSet.add(assObj.id);
        }   
        System.debug('assetidSet++++++++++'+assetidSet);
        APTS_ConversionOrderPhaUtils.updatePhysicalAssetFieldsABO(assetidSet);
    }
}