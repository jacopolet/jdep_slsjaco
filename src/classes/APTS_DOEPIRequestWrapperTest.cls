/*************************************************************
@Name: APTS_DOEPIRequestWrapperTest
@Author: Aarthi Pitchai
@CreateDate: 12-04-2018
@Description: Digital Order EPI Request Wrapper test class
@UsedBy: APTS_DOEPIRequestWrapper
******************************************************************/
//v100 12-04-2018 Aarthi Pitchai: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes

@isTest
private with sharing class APTS_DOEPIRequestWrapperTest {

    @isTest static void test_DOEPIRequestWrapper() {

        test.startTest();

        APTS_DOEPIReqWrapper oDOEPIReqWrapper = new APTS_DOEPIReqWrapper();
        oDOEPIReqWrapper.AdjustmentType = 'Test Adjustment Type';
        /*oDOEPIReqWrapper.BillToCity = 'Test City';
        oDOEPIReqWrapper.BillToCompanyName = 'Test Company Name';
        oDOEPIReqWrapper.BillToContactName = 'Contact Name';
        oDOEPIReqWrapper.BillToCountry = 'Test Country';
        oDOEPIReqWrapper.BillToEmail = 'Test Email';
        oDOEPIReqWrapper.BillToOverride = 'Yes';
        oDOEPIReqWrapper.BillToPostalCode = '123545';
        oDOEPIReqWrapper.BillToStreet = 'Test Street';*/
        oDOEPIReqWrapper.CurrencyCode = 'Test Currency code';
        oDOEPIReqWrapper.OneTimeContactName = 'Test OneTime Contact';
        oDOEPIReqWrapper.OneTimeCustomer = 'Test OneTime Customer';
        oDOEPIReqWrapper.OneTimeEmail = 'Test email';
        oDOEPIReqWrapper.ShipToCompanyName = 'Test ShipToCompanyName';
        oDOEPIReqWrapper.ShipToCountry = 'Test ShipToCountry';
        oDOEPIReqWrapper.ShipToCity = 'Test ShipToCity';
        oDOEPIReqWrapper.ShipToPostalCode = 'Test ShipToPostalCode';
        oDOEPIReqWrapper.ShipToStreetOnly = 'Test ShipToStreetOnly';
        oDOEPIReqWrapper.ShipToHouseNumber = 'Test ShipToHouseNumber';
        oDOEPIReqWrapper.ShipToHouseNumberSupplement = 'Test ShipToHouseNumberSupplement';
        oDOEPIReqWrapper.BillToContactName = 'Test BillToContactName';
        oDOEPIReqWrapper.BillToEmail = 'Test BillToEmail';
        oDOEPIReqWrapper.BillToCompanyName = 'Test BillToCompanyName';
        oDOEPIReqWrapper.BillToCountry = 'Test BillToCountry';
        oDOEPIReqWrapper.BillToCity = 'Test BillToCity';
        oDOEPIReqWrapper.BillToPostalCode = 'Test BillToPostalCode';
        oDOEPIReqWrapper.BillToStreetOnly = 'Test BillToStreetOnly';
        oDOEPIReqWrapper.BillToHouseNumber = 'Test BillToHouseNumber';
        oDOEPIReqWrapper.BillToHouseNumberSupplement = 'Test BillToHouseNumberSupplement';
        oDOEPIReqWrapper.SourceOrderNumber = 'Test Order No';
        oDOEPIReqWrapper.SalesforceAccountID = 'Test AccountID';
        oDOEPIReqWrapper.SalesforceContactID = 'Test contactID';
        oDOEPIReqWrapper.SalesforcePriceListID = 'Test PriceList ID';
        oDOEPIReqWrapper.ShipToOverride = 'Yes';
        oDOEPIReqWrapper.BillToOverride = 'Yes';
        oDOEPIReqWrapper.SalesforceAccountLocationID = 'test Loc ID';
        oDOEPIReqWrapper.SalesOrganization = 'Test Sales Org';
        oDOEPIReqWrapper.RequestDeliveryDate = dateTime.Now();
        oDOEPIReqWrapper.Source = 'test Source';
        oDOEPIReqWrapper.PrepaidFlag = 'yes';
        oDOEPIReqWrapper.PaymentReferenceNumber = 'test Payment reference Number';
        oDOEPIReqWrapper.PaymentMethod = 'Test Payment Method';
        oDOEPIReqWrapper.PONumber = 'test PO';
        oDOEPIReqWrapper.ReferenceNumber = 'Test Reference Number';
        oDOEPIReqWrapper.AdjustmentType = 'Test Adjustment';
        oDOEPIReqWrapper.TotalOrderAmount = 4;
        oDOEPIReqWrapper.TotalShippingCost = 5;
        oDOEPIReqWrapper.TotalOrderAdjustment = 5;
        oDOEPIReqWrapper.TotalAdjustment = 5;
        oDOEPIReqWrapper.TotalAdjustedPrice = 5;
        oDOEPIReqWrapper.TotalTaxAmount = 8;
        oDOEPIReqWrapper.TotalVATAmount = 8;
        oDOEPIReqWrapper.OrderDate = 'Test Date';
        oDOEPIReqWrapper.OrderType = 'Route Sales';
        oDOEPIReqWrapper.OrderSubType = 'Standard order';
        oDOEPIReqWrapper.OrderDate = 'Date';
        oDOEPIReqWrapper.CaseID = 'Test case';
        oDOEPIReqWrapper.FulfilledFromVan = TRUE;
        oDOEPIReqWrapper.RSOEmployeeEmail = 'Test Email';
        oDOEPIReqWrapper.CustomerComment = 'Test comments';

        oDOEPIReqWrapper.OrderLineItems = new List<APTS_DOEPIReqWrapper.EPIOrderLI>();
        List<APTS_DOEPIReqWrapper.EPIAdjustmentLI> eALILst = new List<APTS_DOEPIReqWrapper.EPIAdjustmentLI>();
        List<APTS_DOEPIReqWrapper.EPIOrderLI> eOLILst = new List<APTS_DOEPIReqWrapper.EPIOrderLI>();
        APTS_DOEPIReqWrapper.EPIAdjustmentLI objALI = new APTS_DOEPIReqWrapper.EPIAdjustmentLI();
        objALI.SubType = 'Test SubType';
        objALI.IncentiveAmount = 7;
        objALI.AdjustmentValue = 8;
        eALILst.add(objALI);
        APTS_DOEPIReqWrapper.EPIOrderLI oOLI = new APTS_DOEPIReqWrapper.EPIOrderLI();
        oOLI.SourceLineNumber = 'test Source Number';
        oOLI.ProductCode = 'Test Source code';
        oOLI.Quantity = 5;
        oOLI.SellingUnitofMeasure = 'Piece';
        oOLI.ProductId = 'Test prdo';
        oOLI.ReasonCode = 'Test Reason';
        oOLI.ConfigurationType = 'Test';
        oOLI.ParentBundleNumber = 4;
        oOLI.LineItemListPrice = 5;
        oOLI.LineItemAdjustmentAmount = 6;
        oOLI.LineItemAdustedPrice = 7;
        oOLI.LineItemTaxAmount = 8;
        oOLI.LineItemVATAmount = 8;
        oOLI.Adjustments = new List<APTS_DOEPIReqWrapper.EPIAdjustmentLI>();
        oOLI.Adjustments = eALILst;
        eOLILst.add(oOLI);
        oDOEPIReqWrapper.OrderLineItems = eOLILst;

        test.stopTest();
        
        System.assertEquals(5,oOLI.Quantity);
        System.assertNotEquals(False, oDOEPIReqWrapper.FulfilledFromVan);
        
        
    }
}