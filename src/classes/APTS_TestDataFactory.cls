/*************************************************************
@Name: APTS_TestDataFactory
@Author: Neev Shah
@CreateDate: 22-01-2018
@Description: Test Data Factory
@UsedBy: Apttus Test class
******************************************************************/
//v101 20-02-2018 Galin : Adding some methods
//v102 21-02-2018 Shankar : Adding some methods
//v103 09-05-2018 Shankar : Modified createIntegrationUserAndProfile and createIntegrationLog methods. Created createFandFInterfaces method
//v104 13-07-2018 Neev Shah :  Updated requested dates for Order Creation

@isTest
public  class  APTS_TestDataFactory {

    private static final string COLLECTIVEINVOICE = 'Collective Invoice';

    public static Map<String, Schema.RecordTypeInfo> getRecordTypeMap(String objectName) {
        return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByName();
    }

    public static Id getRecordTypeId(String objectName, String recordTypeName) {
        return getRecordTypeMap(objectName).get(recordTypeName).getRecordTypeId();
    }

    public static Apttus_Config2__BillingPreference__c createBillingPrefrence(String name) {
        Apttus_Config2__BillingPreference__c billingp = new Apttus_Config2__BillingPreference__c ();
        billingp.Name = name;
        billingp.Apttus_Config2__PrefLevel__c = 'Organization';
        billingp.Apttus_Config2__TaxLevel__c = 'Account';
        billingp.Apttus_Config2__BillingInterval__c = 'Monthly';
        billingp.Apttus_Config2__BillingCycleStart__c = 'Billing Day of Month';
        billingp.Apttus_Config2__BillingDayOfMonth2__c = '1st of the Month';
        billingp.Apttus_Config2__Active__c = TRUE;
        billingp.Apttus_Config2__DoNotCreateInformational__c = TRUE;
        billingp.Apttus_Config2__HideInformational__c = TRUE;
        return billingp;
    }
    
    public static Apttus_Config2__FrequencyConversionRate__c createConversionRate(String fromUOM, String toUOM){
        Apttus_Config2__FrequencyConversionRate__c conversionRate = new Apttus_Config2__FrequencyConversionRate__c();
        conversionRate.Apttus_Config2__FromUom__c = fromUOM;
        conversionRate.Apttus_Config2__ToUom__c = toUOM;
        conversionRate.Apttus_Config2__FromFrequency__c = 'Daily';
        return conversionRate;
    }

    //Shama 12.11.2018 start]
       public static Apttus_CMConfig__AgreementProductAttributeValue__c createAgreementProductAttributeValue(id coffeeALI ){
        Apttus_CMConfig__AgreementProductAttributeValue__c pav = new Apttus_CMConfig__AgreementProductAttributeValue__c();
        pav.APTS_Type_of_Consumption__c = 'Both';
        pav.Apttus_CMConfig__LineItemId__c = coffeeALI;
        pav.APTS_List_Price_per_cup__c = 10;
        return pav;
    }
    public static Apttus_CMConfig__AgreementUsagePriceTier__c createAgreementUsagePriceTier(id coffeeALI,string priceType,decimal sequence){
        Apttus_CMConfig__AgreementUsagePriceTier__c ut1 = new Apttus_CMConfig__AgreementUsagePriceTier__c();
        ut1.APTS_Price_Type__c = priceType;
        ut1.Apttus_CMConfig__Sequence__c = sequence;
        return ut1;
    }
        public static TriggerSettings__c CreateTriggerSettings(boolean ProductTrigger,boolean APTSLineItemTrigger ){
        TriggerSettings__c ts =new TriggerSettings__c();
        ts.ProductTrigger__c = ProductTrigger;
        ts.APTS_LineItemTrigger__c = APTSLineItemTrigger;
        //insert ts;
        return ts;
    }  
    public static APTS_CounterReadingData__c createCounterREadingData(id li2)
    { APTS_CounterReadingData__c counterData=new APTS_CounterReadingData__c();
        counterData.APTS_LineItem__c = li2;
        return counterData;
    }


   public static Apttus_Config2__PriceListItem__c CreatePriceListIemWithOnlyPriceList(Id pricelistId,decimal APTSLabourCoverage,
                                                                        decimal APTSCallOutCoverage,decimal SparePartsCoverage ){
        Apttus_Config2__PriceListItem__c pli=new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__PriceListId__c =pricelistId;
        pli.APTS_Labour_Coverage__c = APTSLabourCoverage ;
        pli.APTS_Call_Out_Coverage__c = SparePartsCoverage;
        pli.APTS_Spare_Parts_Coverage__c = SparePartsCoverage;
        return pli;
    }  
    // //Insert Consumption Group master
    public static APTS_Consumption_Group_Master__c createConsumptionGroupMaster(id L3Productid,id ConsumptionGroupDetailID,id prodId,id planogramProductID){
     APTS_Consumption_Group_Master__c cgm = new APTS_Consumption_Group_Master__c();
        cgm.APTS_Consumption_Detail__c = ConsumptionGroupDetailID;
        cgm.APTS_Consumption_Category__c = L3Productid;
        cgm.APTS_Machine_ID__c = prodId;
        cgm.APTS_Planogram__c = planogramProductID;
        cgm.APTS_Sequence_ID__c = 1;
       // insert cgm;
        return cgm;
    }
           //insert Consumption Group Detail
    public static APTS_Consumption_Group_Detail__c createConsumptionGroupDetail(){
         APTS_Consumption_Group_Detail__c cgd = new APTS_Consumption_Group_Detail__c();
        cgd.APTS_Consumption_Name__c = 'Coffee';
      //  insert cgd;
        return  cgd;
    }       
          //Insert Recipe Master
    public static APTS_Recipe_Master__c createRecipeMaster(id prodId,id planogramProductId){
        APTS_Recipe_Master__c rm = new APTS_Recipe_Master__c();
        rm.APTS_Machine_ID__c = prodId;
        rm.APTS_Planogram__c = planogramProductId;
        //insert rm;
        return rm;
    }
    
    public static APTS_Recipe_Details__c createRecipeDetails(id RecipeMasterID,id ConsumptionGroupDetailID) {
        APTS_Recipe_Details__c rd = new APTS_Recipe_Details__c();
        rd.APTS_Recipe__c = RecipeMasterID;
        rd.APTS_Consumption_Group_Detail__c = ConsumptionGroupDetailID;
        rd.APTS_G1_Grammage__c = String.valueOf(1);
        rd.APTS_G2_Grammage__c = String.valueOf(1);
        rd.APTS_G3_Grammage__c = String.valueOf(1);
        rd.APTS_G4_Grammage__c = String.valueOf(1);
        rd.APTS_G5_Grammage__c = String.valueOf(1);
        rd.APTS_G6_Grammage__c = String.valueOf(1);
        rd.APTS_G7_Grammage__c = String.valueOf(1);
        //insert rd;
        return rd;
    }
    //shama 12.11.2018 end
    
    
    
    //Create Payment Term
    public static Apttus_Config2__PaymentTerm__c createPaymentTerm(String strName, String strLabel, Decimal dcValue, Boolean blnDefault, Decimal dcSequence) {
        Apttus_Config2__PaymentTerm__c objPaymentTerm = new Apttus_Config2__PaymentTerm__c();
        objPaymentTerm.Name = strName;
        objPaymentTerm.Apttus_Config2__Label__c = strLabel;
        objPaymentTerm.Apttus_Config2__Value__c = dcValue;
        objPaymentTerm.Apttus_Config2__IsDefault__c = blnDefault;
        objPaymentTerm.Apttus_Config2__Sequence__c = dcSequence;
        return objPaymentTerm;
    }
    public static Opportunity createOpportunity(String nam, Id accId) {
        Opportunity opp = new Opportunity();
        opp.Name = nam;
        opp.Amount = 1000;
        opp.CurrencyISOCode = 'USD';
        opp.StageName = 'Proposal/Price Quote';
        opp.CloseDate = system.today() + 20;
        opp.AccountId = accId;
        return opp;
    }
    public static Account createAccount(string accountName) {
        Account acc = new Account();
        acc.name = accountName;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Valid').getRecordTypeId();
        acc.Phone = '+31123456789';
        acc.Account_Tier__c = 'Platinum';
        acc.Division__c = 'SAP_20';
        acc.Distribution_Channel__c = 'SAP_10';
        acc.Sales_Organization__c = 'SAP_0111';
        acc.Language__c = 'SAP_EN';
/*

        acc.BillingStreet = '224 Mountain Rd';
        acc.BillingCity = 'Kingston';
        acc.BillingState = 'New York';
        acc.BillingPostalCode = '12401';
        acc.BillingCountry = 'United States';
        acc.ShippingStreet = 'Abell Street';
        acc.ShippingCity = 'Toronto';
        acc.ShippingState = 'Ontario';
        acc.ShippingPostalCode = 'M6P 1H3';
        acc.ShippingCountry = 'Canada';
*/
        return acc;
    }

    public static Contact createContact(Account acc, String mobile) {
        Contact contact = new Contact();
        contact.AccountId = acc.Id;
        contact.MobilePhone = mobile;
        contact.Phone = mobile;
        contact.LastName = acc.Name;
        contact.Email = 'test@qp1.org';
        return contact;
    }

    public static Apttus_Config2__PriceList__c createPriceList(String name) {
        Apttus_Config2__PriceList__c price = new Apttus_Config2__PriceList__c();
        price.Apttus_Config2__Active__c = true;
        price.Name = name;
        price.Apttus_Config2__EffectiveDate__c = System.today().addYears(-1);
        price.Apttus_Config2__ExpirationDate__c = System.today().addYears(2);
        price.CurrencyIsoCode = 'USD';
        price.APTS_SalesOrg__c = 'Netherlands';
        return price;
    }

    public static Product2 createProduct(String PRoductName, String pcode, String pfamily, String sConfigType, Boolean bHasAttributes, Boolean bHasOptions) {
        Product2 productSO = new Product2();
        productSO.Name = ProductName;
        productSO.Family = pfamily;
        productSO.ProductCode = pcode;
        productSO.IsActive = true;
        productSO.Apttus_Config2__ConfigurationType__c = sConfigType;
        productSO.Apttus_Config2__HasAttributes__c = bHasAttributes;
        productSO.Apttus_Config2__HasOptions__c = bHasOptions;
        return productSO;
    }

    public static Apttus_Config2__PriceListItem__c createPriceListItem(Id PriceListId, Id ProductId) {
        Apttus_Config2__PriceListItem__c priceListItem = new Apttus_Config2__PriceListItem__c();
        priceListItem.Apttus_Config2__PriceListId__c = PriceListId;
        priceListItem.Apttus_Config2__ProductId__c = ProductId;
        priceListItem.Apttus_Config2__ChargeType__c = 'Sales Price';
        priceListItem.Apttus_Config2__PriceType__c = 'One Time';
        priceListItem.Apttus_Config2__PriceMethod__c = 'Flat Price';
        priceListItem.Apttus_Config2__ListPrice__c = 50.0;
        priceListItem.Apttus_Config2__EffectiveDate__c = Date.today().addDays(-100);
        priceListItem.Apttus_Config2__ExpirationDate__c = Date.today().addDays(365);
        priceListItem.Apttus_Config2__Frequency__c = 'Weekly';
        priceListItem.Apttus_Config2__PriceUom__c = 'SAP_PCE';
        priceListItem.Apttus_Config2__Active__c = true;
        priceListItem.Apttus_Config2__BillingFrequency__c = 'One Time';
        priceListItem.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        /* Commented for Migration : Starts
        priceListItem.APTS_Call_Out_Coverage__c = 10.0;
        priceListItem.APTS_Labour_Coverage__c = 10.0;
        priceListItem.APTS_Spare_Parts_Coverage__c = 10.0;
        Commented for Migration : Ends*/
        priceListItem.APTS_Default_Selling_Uom__c = 'SAP_PCE';
        return priceListItem;
    }

    public static Apttus_Config2__Order__c createOrder(Id AccountId, Id PriceListID, Id PrimaryConId ) {
        Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
        order.Apttus_Config2__Type__c = 'New';
        order.Apttus_Config2__Status__c = 'Draft';
        order.Apttus_Config2__OrderStartDate__c = Date.today();//Date.newInstance(2015, 12, 01);
        order.Apttus_Config2__OrderEndDate__c = Date.today() + 365;//Date.newInstance(2016, 11, 30);
        order.Apttus_Config2__BillToAccountId__c = AccountId;
        order.Apttus_Config2__ShipToAccountId__c = AccountId;
        order.Apttus_Config2__SoldToAccountId__c = AccountId;
        order.Apttus_Config2__PriceListId__c = PriceListID;
        order.Apttus_Config2__PrimaryContactId__c = PrimaryConId;
        //order.Apttus_Config2__Description__c  = 'TestRunning';
        //v104 ++ <<
        order.APTS_Requested_Delivery_Date__c = System.today().toStartOfWeek().addDays(3);
        order.APTS_Requested_De_Installation_Date__c = System.today().toStartOfWeek().addDays(7);
        order.APTS_Requested_Installation_Date__c = System.today().toStartOfWeek().addDays(7);
        order.APTS_Requested_Movement_Date__c = System.today().toStartOfWeek().addDays(7); //System.today();
        //v104 ++ >>
        return order;
    }

    public static Apttus_Config2__ProductConfiguration__c createProductConfig(Apttus_Config2__Order__c oOrder) {
        Apttus_Config2__ProductConfiguration__c config = new Apttus_Config2__ProductConfiguration__c();
        config.Name = 'JDETest Product Config';
        config.Apttus_Config2__SummaryGroupType__c = 'Category';
        config.Apttus_Config2__Status__c = 'New';
        config.Apttus_Config2__BusinessObjectType__c = 'Order';
        config.Apttus_Config2__VersionNumber__c = 1;
        config.Apttus_Config2__IsTransient__c = true;
        config.Apttus_Config2__OrderId__c = oOrder.Id;
        config.Apttus_Config2__BusinessObjectId__c = string.valueof(oOrder.Id);
        config.Apttus_Config2__AccountId__c = oOrder.Apttus_Config2__BillToAccountId__c;
        config.Apttus_Config2__EffectivePriceListId__c = oOrder.Apttus_Config2__PriceListId__c;
        config.Apttus_Config2__PriceListId__c = oOrder.Apttus_Config2__PriceListId__c;
        config.Apttus_Config2__ExpectedStartDate__c = oOrder.Apttus_Config2__OrderStartDate__c;
        config.Apttus_Config2__ExpectedEndDate__c = oOrder.Apttus_Config2__OrderEndDate__c;
        return config;
    }
    //v101++<<
    public static Apttus_Config2__ProductConfiguration__c createProductConfig(Apttus__APTS_Agreement__c oAgreement) {
        Apttus_Config2__ProductConfiguration__c config = new Apttus_Config2__ProductConfiguration__c();
        config.Name = 'JDETest Product Config';
        config.Apttus_Config2__SummaryGroupType__c = 'Category';
        config.Apttus_Config2__Status__c = 'New';
        config.Apttus_Config2__BusinessObjectType__c = 'Agreement';
        config.Apttus_Config2__VersionNumber__c = 1;
        config.Apttus_Config2__IsTransient__c = true;
        config.Apttus_CMConfig__AgreementId__c = oAgreement.Id;
        config.Apttus_Config2__BusinessObjectId__c = string.valueof(oAgreement.Id);
        config.Apttus_Config2__AccountId__c = oAgreement.Apttus__Account__c;
        config.Apttus_Config2__EffectivePriceListId__c = oAgreement.Apttus_CMConfig__PriceListId__c;
        config.Apttus_Config2__PriceListId__c = oAgreement.Apttus_CMConfig__PriceListId__c;
        config.Apttus_Config2__ExpectedStartDate__c = oAgreement.Apttus__Contract_Start_Date__c;
        config.Apttus_Config2__ExpectedEndDate__c = oAgreement.Apttus__Contract_End_Date__c;
        return config;
    }    
    //v101++>>
    public static Apttus_Config2__LineItem__c createLineItem(Apttus_Config2__ProductConfiguration__c ProdConfig, Id PriceListItemId, Id LocationId, Id ProductId, Id OptionId, Id AssetLineItemId, Decimal dPrimaryLineNo, Decimal dLineNumber, Decimal dItemSequence, String sLineType, Id BillPreferenceId, String sBillFrequency, String sBillingRule, String sPriceType, String sPriceMethod, String sPriceUOM, Decimal dBasePrice, Decimal quantity) {
        Apttus_Config2__LineItem__c oLineItem = new Apttus_Config2__LineItem__c();
        oLineItem.Apttus_Config2__SellingTerm__c = 1;
        oLineItem.Apttus_Config2__LineStatus__c = 'New';
        oLineItem.Apttus_Config2__ConfigurationId__c = ProdConfig.Id;
        oLineItem.Apttus_Config2__BillToAccountId__c = ProdConfig.Apttus_Config2__BillToAccountId__c;
        oLineItem.Apttus_Config2__ShipToAccountId__c = ProdConfig.Apttus_Config2__ShipToAccountId__c;
        oLineItem.Apttus_Config2__StartDate__c = ProdConfig.Apttus_Config2__ExpectedStartDate__c;
        oLineItem.Apttus_Config2__EndDate__c = ProdConfig.Apttus_Config2__ExpectedEndDate__c;
        oLineItem.Apttus_Config2__PriceListId__c = ProdConfig.Apttus_Config2__PriceListId__c;
        oLineItem.Apttus_Config2__PriceListItemId__c = PriceListItemId;
        oLineItem.Apttus_Config2__LocationId__c = LocationId;
        oLineItem.Apttus_Config2__ProductId__c = ProductId;
        oLineItem.Apttus_Config2__OptionId__c = OptionId;
        oLineItem.Apttus_Config2__AssetLineItemId__c = AssetLineItemId;
        oLineItem.Apttus_Config2__PrimaryLineNumber__c = dPrimaryLineNo;
        oLineItem.Apttus_Config2__LineNumber__c = dLineNumber;
        oLineItem.Apttus_Config2__ItemSequence__c = dItemSequence;
        oLineItem.Apttus_Config2__LineType__c = sLineType;
        oLineItem.Apttus_Config2__BillingPreferenceId__c = BillPreferenceId;
        oLineItem.Apttus_Config2__BillingFrequency__c = sBillFrequency;
        oLineItem.Apttus_Config2__BillingRule__c = sBillingRule;
        oLineItem.Apttus_Config2__PriceType__c = sPriceType;
        oLineItem.Apttus_Config2__PriceMethod__c = sPriceMethod;
        oLineItem.Apttus_Config2__PriceUom__c = sPriceUOM;
        oLineItem.Apttus_Config2__BasePrice__c = dBasePrice;
        oLineItem.Apttus_Config2__NetPrice__c = dBasePrice;
        oLineItem.Apttus_Config2__Quantity__c = quantity;
        /*oLineItem.APTS_Call_Out_Coverage__c = 10.0;
        oLineItem.APTS_Labour_Coverage__c = 10.0;
        oLineItem.APTS_Spare_Parts_Coverage__c = 10.0; */
        return oLineItem;
    }


    public static Apttus_Config2__AssetLineItem__c createAssetLineItem(Apttus_Config2__Order__c oOrder, Id PriceListItemId, Id LocationId, Id ProductId, Id OptionId, Decimal dLineNumber, Decimal dItemSequence, String sLineType, Id BillPreferenceId, String sBillFrequency, String sBillingRule, String sPriceType, String sPriceMethod, String sPriceUOM, Decimal dBasePrice, Decimal quantity ) {
        Apttus_Config2__AssetLineItem__c assetLine = new Apttus_Config2__AssetLineItem__c();
        assetLine.Apttus_Config2__AccountId__c = oOrder.Apttus_Config2__SoldToAccountId__c;
        assetLine.Apttus_Config2__BillToAccountId__c = oOrder.Apttus_Config2__BillToAccountId__c;
        assetLine.Apttus_Config2__ShipToAccountId__c = oOrder.Apttus_Config2__ShipToAccountId__c;
        assetLine.Apttus_Config2__PriceListId__c = oOrder.Apttus_Config2__PriceListId__c;
        assetLine.Apttus_Config2__StartDate__c = oOrder.Apttus_Config2__OrderStartDate__c;
        assetLine.Apttus_Config2__EndDate__c = oOrder.Apttus_Config2__OrderEndDate__c;
        assetLine.Apttus_Config2__BillingStartDate__c = oOrder.Apttus_Config2__OrderStartDate__c;
        assetLine.Apttus_Config2__BillingEndDate__c = oOrder.Apttus_Config2__OrderEndDate__c;
        assetLine.Apttus_Config2__PriceListItemId__c = PriceListItemId;
        // assetLine.Apttus_Config2__LocationId__c = LocationId;
        assetLine.Apttus_Config2__ProductId__c = ProductId;
        assetLine.Apttus_Config2__OptionId__c = OptionId;
        assetLine.Apttus_Config2__LineNumber__c = dLineNumber;
        assetLine.Apttus_Config2__ItemSequence__c = dItemSequence;
        assetLine.Apttus_Config2__LineType__c = sLineType;
        assetLine.Apttus_Config2__BillingPreferenceId__c = BillPreferenceId;
        assetLine.Apttus_Config2__BillingFrequency__c = sBillFrequency;
        assetLine.Apttus_Config2__BillingRule__c = sBillingRule;
        assetLine.Apttus_Config2__PriceType__c = sPriceType;
        assetLine.Apttus_Config2__PriceMethod__c = sPriceMethod;
        assetLine.Apttus_Config2__PriceUom__c = sPriceUOM;
        assetLine.Apttus_Config2__ListPrice__c = dBasePrice;
        assetLine.Apttus_Config2__BasePrice__c = dBasePrice;
        assetLine.Apttus_Config2__NetPrice__c = dBasePrice;
        assetLine.Apttus_Config2__SellingTerm__c = 1;
        assetLine.Apttus_Config2__SellingFrequency__c = 'Yearly';
        assetLine.Apttus_Config2__Quantity__c = quantity;
        assetLine.Apttus_Config2__IsPrimaryLine__c = true;
        return assetLine;
    }

    public static Apttus_Config2__AssetAttributeValue__c createAssetAttributeValue(Id assetLineItemID) {
        Apttus_Config2__AssetAttributeValue__c attributeVal = new Apttus_Config2__AssetAttributeValue__c();
        attributeVal.Apttus_Config2__AssetLineItemId__c = assetLineItemID;
        return attributeVal;
    }

    public static Apttus_Config2__OrderLineItem__c createOrderLineItem(Apttus_Config2__Order__c order, Id priceListItemId, Id locationId, Id productId, Id optionId, Id assetLineItemID, Id originalAssetLineId, Decimal dPrimaryLineNo, Decimal dLineNumber, Decimal dItemSequence, String sLineType, Id billPreferenceId, String sBillFrequency, String sBillingRule, String sPriceType, String sPriceMethod, String sPriceUOM, Decimal dBasePrice, Decimal quantity) {
        Apttus_Config2__OrderLineItem__c orderLine = new Apttus_Config2__OrderLineItem__c();
        orderLine.Apttus_Config2__OrderId__c = order.Id;
        orderLine.Apttus_Config2__BillToAccountId__c = order.Apttus_Config2__BillToAccountId__c;
        orderLine.Apttus_Config2__ShipToAccountId__c = order.Apttus_Config2__ShipToAccountId__c;
        orderLine.Apttus_Config2__PriceListId__c = order.Apttus_Config2__PriceListId__c;
        orderLine.Apttus_QPConfig__ProposalId__c = order.Apttus_QPConfig__ProposalId__c;
        orderLine.Apttus_Config2__PriceListItemId__c = priceListItemId;
        orderLine.Apttus_Config2__LocationId__c = locationId;
        orderLine.Apttus_Config2__ProductId__c = productId;
        orderLine.Apttus_Config2__OptionId__c = optionId;
        orderLine.Apttus_Config2__AssetLineItemId__c = assetLineItemID;
        orderLine.Apttus_Config2__OriginalAssetLineItemId__c = originalAssetLineId;
        orderLine.Apttus_Config2__PrimaryLineNumber__c = dPrimaryLineNo;
        orderLine.Apttus_Config2__LineNumber__c = dLineNumber;
        orderLine.Apttus_Config2__ItemSequence__c = dItemSequence;
        orderLine.Apttus_Config2__LineType__c = sLineType;
        orderLine.Apttus_Config2__StartDate__c = order.Apttus_Config2__OrderStartDate__c;
        orderLine.Apttus_Config2__EndDate__c = order.Apttus_Config2__OrderEndDate__c;
        orderLine.Apttus_Config2__BillingPreferenceId__c = billPreferenceId;
        orderLine.Apttus_Config2__BillingFrequency__c = sBillFrequency;
        orderLine.Apttus_Config2__BillingRule__c = sBillingRule;
        orderLine.Apttus_Config2__PriceType__c = sPriceType;
        orderLine.Apttus_Config2__PriceMethod__c = sPriceMethod;
        orderLine.Apttus_Config2__PriceUom__c = sPriceUOM;
        orderLine.Apttus_Config2__BasePrice__c = dBasePrice;
        orderLine.Apttus_Config2__NetPrice__c = dBasePrice;
        orderLine.Apttus_Config2__SellingTerm__c = 1;
        orderLine.Apttus_Config2__Quantity__c = quantity;
        return orderLine;
    }

    public static Apttus_Config2__OrderProductAttributeValue__c createOrderAttributeValue(Id accountId, Id orderLineItemID, String serviceType, String sFunctionalityLevel, String sDataDepth, String sTerms, String sDuration) {
        Apttus_Config2__OrderProductAttributeValue__c attributeVal = new Apttus_Config2__OrderProductAttributeValue__c();
        attributeVal.Apttus_Config2__LineItemId__c = orderLineItemID;
        return attributeVal;
    }

    //v101++<<
    /* Create User */
    public static User createUser() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' Limit 1];

        User testuser = new User();
        testuser.Alias = 'tstUsr';
        testuser.Email = 'testUser@apttusdemo.com';
        testuser.EmailEncodingKey = 'ISO-8859-1';
        testuser.LastName = 'testUserForTestClasses';
        testuser.LanguageLocaleKey = 'en_US';
        testuser.ProfileId = p.Id;
        testuser.TimeZoneSidKey = 'Europe/Amsterdam';
        testuser.LocaleSidKey = 'en_GB';
        testuser.UserName = 'testuser123@jdecoffee.com';
        //added due to custom validation rule on User
        //VR_Elevated_Access_Reason
        testuser.Elevated_Access_Reason__c = 'Authorization Issue';
        testuser.Elevated_Access_Reference__c = 'Authorization Issue';

        return testuser;

    }
    
    //creating user registration data : 13/12/2018
    public static Map < String, String > createUserRegistrationData(){
        Map < String, String > userRegisterMap = new Map < String, String > ();        
        String firstName = 'test';
        String lastName = 'User';
        String email = 'testUser@salesforce.com';
        String password = 'testuser123';
        String confirmPasswordCorrect = 'testuser123';
        String confirmPasswordWrong = 'wrongpassword';
        String accountId = 'testuser123';
        String regConfirmUrl = 'http://registration-confirm.com';
        String startUrl = 'http://my.company.salesforce.com';
        userRegisterMap.put('firstName', firstName);
        userRegisterMap.put('lastName', lastName);
        userRegisterMap.put('email', email);
        userRegisterMap.put('password', password);
        userRegisterMap.put('confirmPasswordCorrect', confirmPasswordCorrect);
        userRegisterMap.put('confirmPasswordWrong', confirmPasswordWrong);
        userRegisterMap.put('accountId', accountId);
        userRegisterMap.put('regConfirmUrl', regConfirmUrl);
        userRegisterMap.put('startUrl', startUrl);
        return userRegisterMap;
    }
    

    public static Apttus_Config2__OrderSystemProperties__c getOrderSystemProperties() {

        Apttus_Config2__OrderSystemProperties__c oOSP = new Apttus_Config2__OrderSystemProperties__c();
        oOSP.name = 'System Properties';
        oOSP.Apttus_Config2__InitiateBillingOnOrderActivation__c = true;
        oOSP.APTS_Product_Ingredients_Family__c = 'Coffee';
        oOSP.APTS_Product_Machines_Family__c = 'Machines';
        oOSP.APTS_Orders_to_display__c = 1;

        return oOSP;
    }

    /*Create Agreement*/
    public static Apttus__APTS_Agreement__c createAgreement(Id conId, Id priceListId, Id accountId, String sRecordType) {

        Apttus__APTS_Agreement__c oAgreement = new Apttus__APTS_Agreement__c(
            recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(sRecordType).getRecordTypeId(),
            Name = 'Agreement',
            Apttus__Primary_Contact__c = conId,
            Apttus__Agreement_Category__c = 'Standard',
            Apttus_CMConfig__PriceListId__c = priceListId,
            Apttus_CMConfig__PricingDate__c = System.Today(),
            Apttus__Account__c = accountId);

        return oAgreement;
    }

    /*Create Agreement*/
    public static Apttus__APTS_Agreement__c createAgreement(Id conId, Id priceListId, Id accountId, String sRecordType, String sName) {

        Apttus__APTS_Agreement__c oAgreement = new Apttus__APTS_Agreement__c(
            recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(sRecordType).getRecordTypeId(),
            Name = sName,
            Apttus__Primary_Contact__c = conId,            
            Apttus_CMConfig__PriceListId__c = priceListId,
            Apttus_CMConfig__PricingDate__c = System.Today(),
            Apttus__Account__c = accountId);

        return oAgreement;
    }    

    /* Create  Agreement Line Item*/
    public static Apttus__AgreementLineItem__c createAgreementLineItem(Id productId, Id agreementId, Id testAccountId, Id priceListItemId) {

        Apttus__AgreementLineItem__c oAgreementLineItem = new Apttus__AgreementLineItem__c();
        oAgreementLineItem.Apttus__ProductId__c = productId;
        oAgreementLineItem.Apttus_CMConfig__IsPrimaryLine__c = TRUE;
        oAgreementLineItem.Apttus_CMConfig__LineNumber__c = 1;
        oAgreementLineItem.Apttus_CMConfig__ItemSequence__c = 1;
        oAgreementLineItem.Apttus__AgreementId__c = agreementId;
        oAgreementLineItem.Apttus_CMConfig__BaseProductId__c = productId;
        oAgreementLineItem.Apttus_CMConfig__BillToAccountId__c = testAccountId;
        //oAgreementLineItem.Apttus_CMConfig__DerivedFromId__c = lineItem.Id;
        oAgreementLineItem.Apttus_CMConfig__PriceListItemId__c = priceListItemId;
        oAgreementLineItem.Apttus__Quantity__c = 1;
        oAgreementLineItem.Apttus_CMConfig__LineType__c = 'Product/Service';
        //oAgreementLineItem.Apttus_CMConfig__ChargeType__c = lineItem.Apttus_Config2__ChargeType__c;
        oAgreementLineItem.Apttus_CMConfig__SellingTerm__c = 1;
        oAgreementLineItem.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        oAgreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        //oAgreementLineItem.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchyId;
        oAgreementLineItem.Apttus_CMConfig__StartDate__c = System.Today();
        oAgreementLineItem.Apttus_CMConfig__EndDate__c = System.Today();
        //oAgreementLineItem.Apttus_CMConfig__Term__c = lineItem.Apttus_Config2__Term__c ;

        return oAgreementLineItem;
    }
    
    //Creationg incentives for agreements
    public static Apttus_Config2__Incentive__c createIncentive(Apttus__APTS_Agreement__c agreement){
        Apttus_Config2__Incentive__c incentive = new Apttus_Config2__Incentive__c();
        incentive.Apttus_CMConfig__AgreementId__c = agreement.Id;
        incentive.Apttus_Config2__Active__c = true;
        incentive.Apttus_Config2__Sequence__c = 1;
        return incentive;
    }
    
    //creating Price Rule Set
    public static Apttus_Config2__PriceRuleset__c createPriceRuleSet(Apttus_Config2__Incentive__c incentive){
        Apttus_Config2__PriceRuleset__c priceRuleSet = new Apttus_Config2__PriceRuleset__c();
        priceRuleSet.Apttus_Config2__IncentiveId__c = incentive.Id;
        priceRuleSet.Apttus_Config2__Sequence__c = 1;
        
        return priceRuleSet;
    }
    
    //creating Price Rule
    public static Apttus_Config2__PriceRule__c createPriceRule(Apttus_Config2__PriceRuleset__c priceRuleSet){
        Apttus_Config2__PriceRule__c priceRule = new Apttus_Config2__PriceRule__c();
        priceRule.Apttus_Config2__RulesetId__c = priceRuleSet.Id;
        priceRule.Apttus_Config2__Sequence__c = 1;
        return priceRule;
    }
    
    //creating Price Rule Entry
    public static Apttus_Config2__PriceRuleEntry__c createPriceRuleEntry(Apttus_Config2__PriceRule__c priceRule){
        Apttus_Config2__PriceRuleEntry__c priceRuleEntry = new Apttus_Config2__PriceRuleEntry__c();
        priceRuleEntry.Apttus_Config2__PriceRuleId__c = priceRule.Id;
        priceRuleEntry.Apttus_Config2__Sequence__c = 1;
        return priceRuleEntry;
    }
    
    //Creating physical Asset Object
    public static PhysicalAsset__c createPhysicalAsset() {

        PhysicalAsset__c oPhysicalAsset = new PhysicalAsset__c();
        oPhysicalAsset.SerialNumber__c = '12345';
        oPhysicalAsset.InitialActivationDate__c = System.today();
        return oPhysicalAsset;
    }
    public static APTS_Agreement_PO_Details__c  createAgreementPOdetails(Id agreeId) {
    APTS_Agreement_PO_Details__c  POdetails = new APTS_Agreement_PO_Details__c();
    POdetails.APTS_PO_Category__c = 'Machine';
    POdetails.APTS_PO_Number_Required__c='YES';
    POdetails.APTS_PO_Number_Type__c='Fixed';
    POdetails.APTS_PO_Number__c='656524'; 
    POdetails.APTS_Agreement__c=agreeId;
    return POdetails ;
    }
    

    public static APTS_Billing_Settings__c createBillingSettings(Id agreementId) {

        APTS_Billing_Settings__c oBillingSettings = new APTS_Billing_Settings__c();
        oBillingSettings.APTS_Agreement_ID__c = agreementId;
        oBillingSettings.APTS_Invoice_Type__c = COLLECTIVEINVOICE;
        oBillingSettings.APTS_Invoice_Delivery_Preference__c = 'P001';
        //APTS_Bill_To_ID__c
        //APTS_Billing_Preference_Setting__c
        //APTS_Billing_Rule_Contract__c
        //APTS_Invoice_Delivery_Preference__c
        //APTS_Payment_Method__c
        //APTS_Payment_Term_Setting__c


        return oBillingSettings;
    }
    // Added by Balashanthi
    public static APTS_Billing_Settings__c createBillingSettings(Id agreementId, Id accountId,
                                                                    Id billingPrefId,Id paymentMethodId,Id paymentTermId,String bsType) {

        APTS_Billing_Settings__c oBillingSettings = new APTS_Billing_Settings__c();
        oBillingSettings.APTS_Agreement_ID__c = agreementId;
        oBillingSettings.APTS_Invoice_Type__c = COLLECTIVEINVOICE;
        oBillingSettings.APTS_Invoice_Delivery_Preference__c = 'P001';
        oBillingSettings.APTS_Bill_To_ID__c = accountId;
        oBillingSettings.APTS_Billing_Preference_Setting__c = billingPrefId;
        oBillingSettings.APTS_Billing_Rule_Contract__c = 'Bill in Advance';
        oBillingSettings.APTS_Payment_Method__c = paymentMethodId;
        oBillingSettings.APTS_Payment_Term_Setting__c = paymentTermId;
        oBillingSettings.APTS_Agreement_Billing_Type__c = bsType;
        return oBillingSettings;
    }
    public static APTS_Order_LSP_Details__c createLSPDetails() {

        APTS_Order_LSP_Details__c oLSPDetails = new APTS_Order_LSP_Details__c();
        oLSPDetails.APTS_Subject__c = 'Subject';
        oLSPDetails.APTS_LSP_Description__c = 'LSP Description';
        oLSPDetails.APTS_PlugPlay__c = true;
        oLSPDetails.APTS_Workshop__c = true;
        oLSPDetails.APTS_Deinstall_NonJDEMachine__c = true;
        oLSPDetails.APTS_Stopover__c = true;
        oLSPDetails.APTS_RefurbishedMachine__c = true;
        oLSPDetails.APTS_CommercialMachine__c = true;
        oLSPDetails.APTS_SmokingArea__c = true;
        oLSPDetails.APTS_OwnedByCustomer__c = true;
        oLSPDetails.APTS_StairClimber__c = true;
        oLSPDetails.APTS_Requires_LSP__c = true;
        oLSPDetails.APTS_Building__c = 'Building';
        oLSPDetails.APTS_Floor__c = 'Floor';
        oLSPDetails.APTS_Area__c = 'Area';
        oLSPDetails.APTS_CustomerReference__c = 'CustomerReference';
        oLSPDetails.APTS_ConfigurationFileURL__c = 'ConfigurationFileURL';
        oLSPDetails.APTS_ConfigurationManualAgreementsURL__c = 'ConfigurationManualAgreementsURL';
        oLSPDetails.APTS_JDE_crockeryVolumeSize__c = 'JDE_crockeryVolumeSize';

        return oLSPDetails;
    }

    public static Apttus_Config2__ProductOptionGroup__c createProductOptionGroup(Id categoryHierarchyId, Id subCategoryHierarchyId) {

        Apttus_Config2__ProductOptionGroup__c oProductOptionGroup = new Apttus_Config2__ProductOptionGroup__c();
        oProductOptionGroup.Apttus_Config2__OptionGroupId__c = subCategoryHierarchyId;
        oProductOptionGroup.Apttus_Config2__ParentOptionGroupId__c = categoryHierarchyId;
        oProductOptionGroup.Apttus_Config2__Sequence__c = 1;

        return oProductOptionGroup;
    }

    public static Apttus_Config2__ProductOptionComponent__c createProductOptionComponent(Id productOptionGroupId) {

        Apttus_Config2__ProductOptionComponent__c oProductOptionComponent = new Apttus_Config2__ProductOptionComponent__c();
        oProductOptionComponent.Apttus_Config2__ProductOptionGroupId__c = productOptionGroupId;
        oProductOptionComponent.Apttus_Config2__Sequence__c = 1;

        return oProductOptionComponent;
    }

    /* create category */
    public static Apttus_Config2__ClassificationName__c createCategory() {

        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c();
        category.Name = 'Coffee';
        category.Apttus_Config2__Active__c = true;
        category.Apttus_Config2__HierarchyLabel__c = 'Coffee';
        category.Apttus_Config2__Type__c = 'Offering';
        category.APTS_Allow_Adjustments__c = true;

        return category;
    }

    /* create category hierarchy */
    public static Apttus_Config2__ClassificationHierarchy__c createCategoryHierarchy(Id categoryId, String sName) {

        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        categoryHierarchy.Name = sName;
        categoryHierarchy.Apttus_Config2__HierarchyId__c = categoryId;
        categoryHierarchy.Apttus_Config2__AncestorId__c = null;
        categoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        categoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        categoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        categoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        categoryHierarchy.Apttus_Config2__IsHidden__c = false;
        categoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        categoryHierarchy.Apttus_Config2__Label__c = sName;
        categoryHierarchy.Apttus_Config2__LargeImageSize__c = '20x20';
        categoryHierarchy.Apttus_Config2__Left__c = 1;
        categoryHierarchy.Apttus_Config2__Level__c = 0;
        categoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        categoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        categoryHierarchy.Apttus_Config2__Modifiable__c = true;
        categoryHierarchy.Apttus_Config2__PrimordialId__c = null;
        categoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        categoryHierarchy.Apttus_Config2__Right__c = 20;

        return categoryHierarchy;
    }

    /* create sub-category */
    public static Apttus_Config2__ClassificationHierarchy__c createSubCategory(Id categoryId, Id categoryHierarchyId) {

        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subCategoryHierarchy.Name = 'Espresso Beans';
        subCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subCategoryHierarchy.Apttus_Config2__HierarchyId__c = categoryId;
        subCategoryHierarchy.Apttus_Config2__AncestorId__c = categoryHierarchyId;
        subCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subCategoryHierarchy.Apttus_Config2__Label__c = 'Technical Service';
        subCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subCategoryHierarchy.Apttus_Config2__Level__c = 1;
        subCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        subCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        subCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchyId;
        subCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        subCategoryHierarchy.Apttus_Config2__Right__c = 3;

        return subCategoryHierarchy;
    }

    /* create prduct classification */
    public static Apttus_Config2__ProductClassification__c createProductClassification(Id subCategoryHierarchyId, Id productId) {

        Apttus_Config2__ProductClassification__c productClassification = new Apttus_Config2__ProductClassification__c();
        productClassification.Apttus_Config2__ClassificationId__c = subCategoryHierarchyId;
        productClassification.Apttus_Config2__DefaultQuantity__c = 1.00000;
        productClassification.Apttus_Config2__MaxQuantity__c =  1.00000;
        productClassification.Apttus_Config2__MinQuantity__c = 0.00000;
        productClassification.Apttus_Config2__MinQuantity__c = 0.00000;
        productClassification.Apttus_Config2__Modifiable__c = true;
        productClassification.Apttus_Config2__ProductId__c = productId;

        return productClassification;
    }
    //v101++>>

    public static Apttus_Config2__OrderFulfillment__c createOrderFulfillment(ID accountId) {
        Apttus_Config2__OrderFulfillment__c orderF = new Apttus_Config2__OrderFulfillment__c();
        orderF.Apttus_Config2__AccountId__c = accountId;
        orderF.Apttus_Config2__FulfilledDate__c = Date.today();
        return orderF;
    }
    public static Apttus_Config2__OrderFulfillmentLineItem__c createOrderFLI(ID orderID, ID orderLIItem, ID OrderFID) {
        Apttus_Config2__OrderFulfillmentLineItem__c ofli = new Apttus_Config2__OrderFulfillmentLineItem__c();
        ofli.Apttus_Config2__OrderId__c = orderID;
        ofli.Apttus_Config2__OrderFulfillmentId__c = OrderFID;
        ofli.Apttus_Config2__OrderLineItemId__c = orderLIItem;
        ofli.APTS_Fulfilled_Quantity__c = 1;
        ofli.Apttus_Config2__LineNumber__c = 1;
        return ofli;
    }

    /* Commented for Migration : Starts
     public static WorkOrderTrigger__c createWorkOrderForOption(string orderType, Apttus_Config2__Order__c oOrder,Apttus_Config2__OrderLineItem__c orderLineItem, WorkOrderTrigger__c parentWO)
     {
        WorkOrderTrigger__c oWorkOrder = new WorkOrderTrigger__c();

        oWorkOrder.OrderType__c = 'Standard Order';//oOrder.APTS_Order_Type__c;
        oWorkOrder.Type__c = 'Option';
        oWorkOrder.Product__c = orderLineItem.Apttus_Config2__OptionId__c;
        oWorkOrder.OwnedByCustomer__c = orderLineItem.APTS_OwnedByCustomer__c;
        oWorkOrder.OrderLineItem__c = orderLineItem.Id;
         if(parentWO != null)
         {
        oWorkOrder.ParentLineItem__c = parentWO.Id;
         }
        oWorkOrder.ParentOrder__c = oOrder.Apttus_Config2__ParentOrderId__c;
        oWorkOrder.PhysicalAsset__c = orderLineItem.APTS_Physical_Asset__c;
        oWorkOrder.Load_ID__c = 'WOT-' + orderLineItem.Id;

        return oWorkOrder;

    }
    Commented for Migration : Ends */
    //v102++<<
    /*Method to create IntegrationUserAndProfile Custom Setting
    *Created as part of 1720 - Integration Log FD (Kauri Wave 3 Nov'18 Release)*/
    public static IntegrationUserAndProfile__c createIntegrationUserAndProfile() {
        IntegrationUserAndProfile__c custSetting = new IntegrationUserAndProfile__c();
        custSetting.SAP_Deletion_Day__c = 1;
        custSetting.Digital_Deletion_Day__c = 1;
        custSetting.Click_Deletion_Day__c = 1;
        custSetting.All_Deletion_Day__c = 1;
        custSetting.APTS_IntegrationLogFandFDeletionDay__c = 1;
        return custSetting;
    }

    /*Method to create List of Integration Log Object Records
    *Created as part of 1720 - Integration Log FD (Kauri Wave 3 Nov'18 Release)*/
    public static List<Integration_Log__c> createIntegrationLog(Integer i, String status) {
        List<Integration_Log__c> logList = new List<Integration_Log__c>();
        for (Integer x = 0; x < i; x++) {
            Integration_Log__c log = new Integration_Log__c();
            log.Integration_Status__c = status;
            log.Object__c = 'Test';
            log.Object_Id__c = '123'+i;
            log.CreatedDate = System.Today() - 2;
            logList.add(log);
        }
        return logList;
    }
    //v102++>>

    //v103++<<
    /*Method to create IntegrationLogFireForgetInterfaces Custom Setting
    *Created as part of CR-1861 - Integration Log FD (Kauri Wave 3 Nov'18 Release)*/
    public static List<APTS_IntegrationLogFireForgetInterfaces__c> createFandFInterfaces(){
        List<APTS_IntegrationLogFireForgetInterfaces__c> interfaceList = new List<APTS_IntegrationLogFireForgetInterfaces__c>();
        interfaceList.add(new APTS_IntegrationLogFireForgetInterfaces__c(Name='RelatedInvoice__c'));
        interfaceList.add(new APTS_IntegrationLogFireForgetInterfaces__c(Name='Account Hierarchy'));
        interfaceList.add(new APTS_IntegrationLogFireForgetInterfaces__c(Name='Work Order Line Item - CATS-record'));
        return interfaceList;
    }
    //v103++>>
    /*
      @name    buildBonsaiExtractionController
      @date    3.december.2018
      @author  Archana Suryawanshi
      @param   none.
      @return  Void. 
      @description Method to create BonsaiExtractionController Test data                            
     */
     public static void buildBonsaiExtraction(){
        Bonsai__c bonsaiCs = new Bonsai__c();
        bonsaiCs.Full_Load__c = true;
        bonsaiCs.Delta_Load__c = false;
        bonsaiCs.Name = 'Controller Settings';
        Database.insert(bonsaiCs);
    } 
}