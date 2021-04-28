/*************************************************************
@Name: APTS_DOEPIReqWrapper
@Author: Neev Shah
@CreateDate: 6-04-2018
@Description: A wrapper class for EPI Interface log
******************************************************************/
// V101 11-Oct-2019 Aarthi - QTCFLEX1-1542

public with sharing class APTS_DOEPIReqWrapper {
    public String SourceOrderNumber{get;set;}
    public String SalesforceAccountID{get;set;}
    public String SalesforceContactID{get;set;}
    public String SalesforcePriceListID{get;set;}
    public String ShipToOverride{get;set;}
    public String BillToOverride{get;set;}
    public String SalesforceAccountLocationID{get;set;}
    public String SalesOrganization{get;set;}
    public Datetime RequestDeliveryDate{get;set;}
    public String Type{get;set;} //V101 ++ <<>>
    public String Source{get;set;}
    public String PrepaidFlag{get;set;}
    public String PaymentReferenceNumber{get;set;}
    public String PaymentMethod{get;set;}
    public String PONumber{get;set;}
    public String ReferenceNumber{get;set;}
    public String AdjustmentType{get;set;}
    public Decimal TotalOrderAmount{get;set;}
    public Decimal TotalShippingCost{get;set;}
    public Decimal TotalOrderAdjustment{get;set;}
    public Decimal TotalAdjustment{get;set;}
    public Decimal TotalAdjustedPrice{get;set;}
    public Decimal TotalTaxAmount{get;set;}
    public Decimal TotalVATAmount{get;set;}
    public String CurrencyCode{get;set;}
    public String OneTimeCustomer{get;set;}
    public String OneTimeContactName{get;set;}
    public String OneTimeEmail{get;set;}
    public String ShipToCompanyName{get;set;}
    public String ShipToCountry{get;set;}
    public String ShipToCity {get;set;}
    public String ShipToPostalCode {get;set;}
    public String ShipToStreetOnly{get;set;}
    public String ShipToHouseNumber{get;set;}
    public String ShipToHouseNumberSupplement{get;set;}
    public String BillToContactName{get;set;}
    public String BillToEmail{get;set;}
    public String BillToCompanyName{get;set;}
    public String BillToCountry{get;set;}
    public String BillToCity{get;set;}
    public String BillToPostalCode{get;set;}
    public String BillToStreetOnly{get;set;}
    public String BillToHouseNumber{get;set;}
    public String BillToHouseNumberSupplement{get;set;}
    
    public List<EPIOrderLI> OrderLineItems{get;set;}
    //fields for RSO
    public String OrderType{get;set;}
    public String OrderSubType{get;set;}
    public String OrderDate{get;set;}
    public String CaseID{get;set;}
    public Boolean FulfilledFromVan{get;set;}
    public String RSOEmployeeEmail{get;set;}
    public String CustomerComment{get;set;}
    public String DeliveryDate{get;set;}
    
    public class EPIOrderLI{
        public String SourceLineNumber{get;set;}
        public String ProductCode{get;set;}
        public String ProductId{get;set;}
        public String ReasonCode{get;set;}
        public Decimal Quantity{get;set;}
        public String SellingUnitofMeasure{get;set;}
        public String ConfigurationType{get;set;}
        public Decimal ParentBundleNumber{get;set;}
        public Decimal LineItemListPrice{get;set;}
        public Decimal LineItemAdjustmentAmount{get;set;}
        public Decimal LineItemAdustedPrice{get;set;}
        public Decimal LineItemTaxAmount{get;set;}
        public Decimal LineItemVATAmount{get;set;}
        public List<EPIAdjustmentLI> Adjustments{get;set;}
    }

    public class EPIAdjustmentLI{
        public String SubType{get;set;}
        public Decimal IncentiveAmount{get;set;}
        public Decimal AdjustmentValue{get;set;}
    }
}