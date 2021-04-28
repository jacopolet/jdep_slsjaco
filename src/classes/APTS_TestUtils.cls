//v101 Neev Shah Updated requested dates
//V102 added logic related newly added validation rule('Please provide a reason for requesting elevated access') on user Object
//From DEV
@isTest
public with sharing class APTS_TestUtils {

    /* Create User */
    public static User createUser() {

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' Limit 1];

        User testuser = new User();
        testuser.Alias = 'tstUsr';
        testuser.Email = '123testuser@apttusdemo.com';
        testuser.EmailEncodingKey = 'ISO-8859-1';
        testuser.LastName = '123Smith';
        testuser.LanguageLocaleKey = 'en_US';
        testuser.ProfileId = p.Id;
        testuser.TimeZoneSidKey = 'Europe/Amsterdam';
        testuser.LocaleSidKey = 'en_GB';
        testuser.UserName = 'testuser123@jdecoffee.com';
        //V102 Start
        testuser.Elevated_Access_Reason__c='Batch job execution';
        testuser.Elevated_Access_Reference__c='Test User';
        //V102 End

        return testuser;

    }

    public static Apttus_Config2__ConfigCustomClasses__c getCustomClassSettings() {

        Apttus_Config2__ConfigCustomClasses__c configCustomClasses = new Apttus_Config2__ConfigCustomClasses__c();
        configCustomClasses.Apttus_Config2__AdjustmentLineItemCallbackClass__c = 'APTS_AdjustmentLineItemCallback_Draft';
        configCustomClasses.Name  = 'System Properties';
        return configCustomClasses;

    }

    
    /*public static APTS_Contract_Pricing_Settings__mdt getContractPricingSettings() {

        APTS_Contract_Pricing_Settings__mdt contractPricing = new APTS_Contract_Pricing_Settings__mdt();
        contractPricing.APTS_Discount_Sequence__c = 'PPR,TPR,EFF,BDF,BMC';
        contractPricing.APTS_Sub_Type__c = 'ZP03,ZP06,ZP07,ZP04,ZP08,ZP10,ZX05,ZP12,ZP11,ZP13,ZP15';
        contractPricing.MasterLabel  = 'System Properties';

        return contractPricing;

    }*/

    /* create Grand Parent Aaccount **/
    public static Account createGrandParentAccount() {
        
        APTS_Payment_Method__c pm = paymentMethod();
        insert pm;
        Account organisation = new Account();
        organisation.Name = 'Grand Parent Account';
        organisation.Phone = '+919898468401';
        organisation.Main_Street_Only__c = 'Test Street';
         organisation.Sales_Organization__c='SAP_0111';
        organisation.Main_House_Number__c = 'Test no.';
        organisation.APTS_Payment_Method__c = pm.id;
        organisation.billingcountry = 'Netherlands';
        return organisation;

    }
    
    /* create Parent Account **/
    public static Account createParentAccount(Account grandParentAccount) {
        APTS_Payment_Method__c pm = paymentMethod();
        insert pm;
        Account organisation = new Account();
        organisation.Name = 'Parent Account';
        organisation.Phone = '+919898468401';
        organisation.Main_Street_Only__c = 'Test Street';
        organisation.Main_House_Number__c = 'Test no.';
        organisation.Sales_Organization__c='SAP_0111';
        organisation.Parent = grandParentAccount;
        organisation.APTS_Payment_Method__c = pm.id;
        organisation.ParentId = grandParentAccount.Id;
        return organisation;

    }
    
    /* create Child Account **/
    public static Account createChildAccount(Account parentAccount) {

        APTS_Payment_Method__c pm = paymentMethod();
        insert pm;
        Account organisation = new Account();
        organisation.Name = 'Child Account';
        organisation.Phone = '+919898468401';
        organisation.Sales_Organization__c='SAP_0111';
        organisation.Main_Street_Only__c = 'Test Street';
        organisation.Main_House_Number__c = 'Test no.';
        organisation.Parent = parentAccount;
        organisation.APTS_Payment_Method__c = pm.id;
        organisation.ParentId = parentAccount.Id;
       
        return organisation;

    }

    /* Create purchasing organisation**/
    public static Account createBuyingGroup() {

        APTS_Payment_Method__c pm = paymentMethod();
        insert pm;
        Account organisation = new Account();
        organisation.Name = 'Purchasing Organization';
        organisation.Phone = '+919898468401';
        organisation.Main_Street_Only__c = 'Test Street';
        organisation.Main_House_Number__c = 'Test no.';
        organisation.Sales_Organization__c ='SAP_0111';
        RecordType rt = [select Id from RecordType where Name = 'Purchasing Organization' and SobjectType = 'Account' limit 1];
        organisation.RecordTypeId = rt.Id;
        organisation.APTS_Payment_Method__c = pm.id;
        organisation.Purchase_Organization__c = true;
        return organisation;

    }

    /* create Cer Records  **/
    /* public static Account createCerRecords(Account parentAccount) {
        APTS_Contract_Entitlement_Repository__c cerRecord =new APTS_Contract_Entitlement_Repository__c();
        cerRecord.APTS_Agreement_Adjustment_Line_Item__c=aali.ID;
                                    cerRecord.APTS_Adjustment_Type__c='% Discount';
                                    cerRecord.APTS_Adjustment_Value__c=10;
                                    cerRecord.APTS_Contributing_Agreement__c=;
                                    cerRecord.APTS_Agreement_Type__c=agreementMap.get(aali.Apttus_CMConfig__LineItemId__r.Apttus__AgreementId__c);
                                    cerRecord.APTS_Contributing_Agreement_Level__c=tempAccountId==hierarchy.accountHierarchy.buyingGroupId?BUYING_GROUP:tempAccountId==hierarchy.accountHierarchy.grandParentId?GRAND_PARENT:tempAccountId==hierarchy.accountHierarchy.parentId?PARENT:CHILD;
                                    cerRecord.APTS_Agreement_Line_Item__c=aali.Apttus_CMConfig__LineItemId__r.Id;
                                    cerRecord.APTS_Type__c=aali.Apttus_CMConfig__Type__c;
                                    cerRecord.APTS_Sub_Type__c=aali.Apttus_CMConfig__SubType__c;
                                    cerRecord.APTS_Adjustment_Applies_To__c =aali.Apttus_CMConfig__AdjustmentAppliesTo__c;
                                    cerRecord.APTS_Bucket__c=aali.Apttus_CMConfig__Bucket__c;
                                    cerRecord.APTS_Product__c=PRODUCT_SERVICE.equalsIgnoreCase(aali.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__LineType__c)?aali.Apttus_CMConfig__LineItemId__r.Apttus__ProductId__c:aali.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__OptionId__c;
                                    cerRecord.APTS_Rebate__c=aali.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__IncentiveId__c;
                                    cerRecord.APTS_UOM__c=aali.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceUom__c;
                                    cerRecord.APTS_Sold_to_Party__c=a.Apttus__Account__c;
                                    cerRecord.APTS_Category_Level__c=aali.Apttus_CMConfig__LineItemId__r.APTS_Category_Level__c;
                                    cerRecord.APTS_CategoryCER__c=aali.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__ClassificationId__c;
                                    cerRecord.APTS_Sub_Category__c=aali.Apttus_CMConfig__LineItemId__r.APTS_Sub_Category__c;
                                    cerRecord.APTS_Sub_Sub_Category__c=aali.Apttus_CMConfig__LineItemId__r.APTS_Sub_Sub_Category__c;
                                    cerRecord.APTS_Charge_Type__c=aali.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__ChargeType__c;
                                    cerRecord.APTS_Is_Pending__c=false;
                                    return cerRecord; 

    } */
    Public static Account getchildaccount(){
        
        Account acc = [Select Id,ParentId,Name,Phone,Main_Street_Only__c,Main_House_Number__c,Sales_Organization__c From Account where Name =: 'Child Account' ];
        return acc;
    }

    Public static Account getParentAccount(){
        
        Account acc = [Select Id,ParentId,Name,Phone,Main_Street_Only__c,Main_House_Number__c,Sales_Organization__c From Account where Name =: 'Parent Account'];
        return acc;
    }

    Public static Account getGrandParentAccount(){
        
        Account acc = [Select Id,ParentId,Name,Phone,Main_Street_Only__c,Main_House_Number__c,Sales_Organization__c From Account where Name =: 'Grand Parent Account'];
        return acc;
    }

    Public static Account getBuyingGroup(){
        
        Account acc = [Select Id,ParentId,Name,Phone,Main_Street_Only__c,Main_House_Number__c,Sales_Organization__c From Account where Name =: 'Purchasing Organization'];
        return acc;
    }
    
    /* create account **/
     public static Account createOrganisation() {

        Account organisation = new Account();
        organisation.Name = 'Test Account';
        organisation.Phone = '+919898468401';
        organisation.Main_Street_Only__c = 'Test Street';
        organisation.Main_House_Number__c = 'Test no.';
        organisation.Sales_Organization__c ='SAP_0111';
        return organisation;

    }
    
    public static Account createOrganisationsub() {

        Account organisation = new Account();
        organisation.Name = 'Test Account Sub';
        organisation.Phone = '+919898468401';
        organisation.Main_Street_Only__c = 'Test Street';
        organisation.Main_House_Number__c = 'Test no.';
        organisation.Sales_Organization__c ='SAP_0111';
        return organisation;

    }
    
    public static Account createOrganisationsubsub() {

        Account organisation = new Account();
        organisation.Name = 'Test Account Sub Sub';
        organisation.Phone = '+919898468401';
        organisation.Main_Street_Only__c = 'Test Street';
        organisation.Main_House_Number__c = 'Test no.';
        organisation.Sales_Organization__c ='SAP_0111';
        return organisation;

    }
    
    public static Account createOrganisationproduct() {

        Account organisation = new Account();
        organisation.Name = 'Test Account Product';
        organisation.Phone = '+919898468401';
        organisation.Main_Street_Only__c = 'Test Street';
        organisation.Main_House_Number__c = 'Test no.';
        organisation.Sales_Organization__c ='SAP_0111';
        return organisation;

    }

    /* create opportunity */
    public static Opportunity createOpportunity(Id accountId) {

        Opportunity oppty = new Opportunity();
        oppty.Name = 'Test Opportunity';
        oppty.AccountId = accountId;
        oppty.Go_To_Market__c = 'Direct';
        oppty.StageName = 'Proposal';
        oppty.CloseDate = date.Today().addDays(365);
        oppty.Probability = 10;
        return oppty;

    }

    /* create price list */
    public static Apttus_Config2__PriceList__c createPriceList() {

        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        priceList.Name = 'JDE Price List';
        priceList.Apttus_Config2__Active__c = true;
        priceList.APTS_SalesOrg__c = 'SalesOrg';
        return priceList;

    }

    public static Apttus_Config2__PriceList__c getpricelist() {
        
        Apttus_Config2__PriceList__c pricelist = [Select id,Name,Apttus_Config2__Active__c,APTS_SalesOrg__c From Apttus_Config2__PriceList__c where Name =: 'JDE Price List'];
        return pricelist;
    }
    /* create price list item */
    public static Apttus_Config2__PriceListItem__c createPriceListItem(Id priceListId, Id productId) {

        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__PriceListId__c = priceListId;
        pli.Apttus_Config2__ProductId__c = productId;
        pli.Apttus_Config2__ListPrice__c = 0;
        pli.Apttus_Config2__ChargeType__c = 'Sales Price';
        pli.Apttus_Config2__PriceType__c = 'One Time';
        pli.Apttus_Config2__PriceMethod__c = 'Per Unit';
        pli.Apttus_Config2__Active__c = true;
        pli.Apttus_Config2__BillingFrequency__c = 'One Time';
        pli.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        return pli;

    }
    
    Public static Apttus_Config2__PriceListItem__c getpli(id plid){
        
        Apttus_Config2__PriceListItem__c pli = [Select id,name,Apttus_Config2__PriceListId__c,Apttus_Config2__ProductId__c,
                                    Apttus_Config2__ListPrice__c,Apttus_Config2__ChargeType__c,Apttus_Config2__PriceType__c,
                                    Apttus_Config2__PriceMethod__c,Apttus_Config2__Active__c,Apttus_Config2__BillingFrequency__c,
                                    Apttus_Config2__BillingRule__c From Apttus_Config2__PriceListItem__c where Apttus_Config2__PriceListId__c =: plid ];
        return pli;
    }

    /* create price matrix */
    public static Apttus_Config2__PriceMatrix__c createPriceMatrix(Id priceListItemId, Id dimension1Id) {

        Apttus_Config2__PriceMatrix__c pm = new Apttus_Config2__PriceMatrix__c();
        pm.Apttus_Config2__Sequence__c = 1;
        pm.Apttus_Config2__PriceListItemId__c = priceListItemId;
        pm.Apttus_Config2__Dimension1Id__c = dimension1Id;
        pm.Apttus_Config2__Dimension1ValueType__c = 'Discrete';

        return pm;

    }


    /* create product */
    public static Product2 createProduct(String productName, String productCode, String productFamily) {

        Product2 product = new Product2();
        product.Name = productName;
        product.ProductCode = productCode;
        product.Family = productFamily;
        product.IsActive = true;
        product.Apttus_Config2__ConfigurationType__c = 'Standalone';
        product.APTS_Associated_Sales_Org__c ='SAP_0111';
        return product;

    }
    
    Public static Product2 getProduct(){
        
        Product2 prd =[Select id,name,ProductCode,Family,IsActive,Apttus_Config2__ConfigurationType__c,APTS_Associated_Sales_Org__c  From Product2 where Name =: 'Piazza DOro Estremo Bonen 1000 Gram'];
        return prd;
    }

    /*Create Proposal*/
    public static Apttus_Proposal__Proposal__c getQuoteProposal(ID accId, ID optyId, String recordTypeName, String quoteName, ID priceList) {

        Apttus_Proposal__Proposal__c quote = new Apttus_Proposal__Proposal__c(Apttus_Proposal__Proposal_Name__c = quoteName,
                Apttus_Proposal__Opportunity__c = optyId,
                Apttus_Proposal__Account__c = accId,
                //RecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId(),
                Apttus_QPConfig__PriceListId__c = priceList);

        return quote;
    }

    /* Product Configuration */
    public static Apttus_Config2__ProductConfiguration__c getProductConfiguration(String configName,
            Integer versionNbr,
            ID bObjectId,
            String bObjectType,
            String groupType,
            ID priceListId,
            ID ancestorId,
            String status,
            Datetime finalizedDate,
            Datetime effectiveDate,
            Boolean isTransient) {

        Apttus_Config2__ProductConfiguration__c configSO = new Apttus_Config2__ProductConfiguration__c(Name = configName, OwnerId = UserInfo.getUserId());
        configSO.Apttus_Config2__VersionNumber__c = versionNbr;
        configSO.Apttus_Config2__SummaryGroupType__c = groupType;
        configSO.Apttus_Config2__BusinessObjectId__c = bObjectId;
        configSO.Apttus_Config2__BusinessObjectType__c = bObjectType;
        configSO.Apttus_QPConfig__Proposald__c = bObjectId;
        configSO.Apttus_Config2__PriceListId__c = priceListId;
        configSO.Apttus_Config2__AncestorId__c = ancestorId;
        configSO.Apttus_Config2__Status__c = status;
        configSO.Apttus_Config2__IsTransient__c = isTransient;
        configSO.Apttus_Config2__FinalizedDate__c = finalizedDate;
        configSO.Apttus_Config2__EffectiveDate__c = effectiveDate;

        return configSO;
    }
    /* Product Configuration */
    public static Apttus_Config2__ProductConfiguration__c getProductConfiguration2(String configName,
            Integer versionNbr,
            ID bObjectId,
            String bObjectType,
            String groupType,
            ID priceListId,
            String status,
            Datetime finalizedDate,
            Datetime effectiveDate,
            Boolean isTransient) {

        Apttus_Config2__ProductConfiguration__c configSO = new Apttus_Config2__ProductConfiguration__c(Name = configName, OwnerId = UserInfo.getUserId());
        configSO.Apttus_Config2__VersionNumber__c = versionNbr;
        configSO.Apttus_Config2__SummaryGroupType__c = groupType;
        configSO.Apttus_Config2__BusinessObjectId__c = bObjectId;
        configSO.Apttus_Config2__BusinessObjectType__c = bObjectType;
        configSO.Apttus_QPConfig__Proposald__c = bObjectId;
        configSO.Apttus_Config2__PriceListId__c = priceListId;
        configSO.Apttus_Config2__Status__c = status;
        configSO.Apttus_Config2__IsTransient__c = isTransient;
        configSO.Apttus_Config2__FinalizedDate__c = finalizedDate;
        configSO.Apttus_Config2__EffectiveDate__c = effectiveDate;

        return configSO;
    }

    /* Create Line Item */
    public static Apttus_Config2__LineItem__c getConfigLineItem(ID configId,
            ID groupId,
            Integer lineNumber,
            Boolean isPrimaryLine,
            Integer itemSeq,
            String lineType,
            ID productId,
            Boolean customizable,
            ID productOptionId,
            ID optionId,
            ID classId,
            String classHierarchy,
            Decimal quantity,
            Boolean isQtyModifiable,
            String uom,
            Integer term,
            ID priceListId,
            ID plItemId,
            String priceType,
            String priceMethod,
            String chargeType,
            String frequency,
            Boolean allowManualAdj,
            Boolean allocateGroupAdj,
            Decimal listPrice,
            Decimal basePrice,
            String basePriceMethod,
            Decimal baseExtPrice,
            Decimal optionPrice,
            Decimal extPrice,
            String lineDesc) {

        Apttus_Config2__LineItem__c lineItem = new Apttus_Config2__LineItem__c(Apttus_Config2__ConfigurationId__c = configId);
        lineItem.Apttus_Config2__LineNumber__c = lineNumber;
        lineItem.Apttus_Config2__IsPrimaryLine__c = isPrimaryLine;
        lineItem.Apttus_Config2__PrimaryLineNumber__c = 1;
        lineItem.Apttus_Config2__ItemSequence__c = itemSeq;
        lineItem.Apttus_Config2__SummaryGroupId__c = groupId;
        lineItem.Apttus_Config2__LineType__c = lineType;
        lineItem.Apttus_Config2__ProductId__c = productId;
        lineItem.Apttus_Config2__Customizable__c = customizable;
        lineItem.Apttus_Config2__ProductOptionId__c = productOptionId;
        lineItem.Apttus_Config2__OptionId__c = optionId;
        lineItem.Apttus_Config2__ClassificationId__c = classId;
        lineItem.Apttus_Config2__ClassificationHierarchy__c = classHierarchy;
        lineItem.Apttus_Config2__Quantity__c = quantity;
        lineItem.Apttus_Config2__IsQuantityModifiable__c = isQtyModifiable;
        lineItem.Apttus_Config2__Uom__c = uom;
        lineItem.Apttus_Config2__Term__c = term;
        lineItem.Apttus_Config2__PriceListId__c = priceListId;
        lineItem.Apttus_Config2__PriceListItemId__c = plItemId;
        lineItem.Apttus_Config2__PriceType__c = priceType;
        lineItem.Apttus_Config2__PriceMethod__c = priceMethod;
        lineItem.Apttus_Config2__ChargeType__c = chargeType;
        lineItem.Apttus_Config2__Frequency__c = frequency;
        lineItem.Apttus_Config2__AllowManualAdjustment__c = allowManualAdj;
        lineItem.Apttus_Config2__AllocateGroupAdjustment__c = allocateGroupAdj;
        lineItem.Apttus_Config2__ListPrice__c = listPrice;
        lineItem.Apttus_Config2__BasePrice__c = basePrice;
        lineItem.Apttus_Config2__BasePriceMethod__c = basePriceMethod;
        lineItem.Apttus_Config2__BaseExtendedPrice__c = baseExtPrice;
        lineItem.Apttus_Config2__OptionPrice__c = optionPrice;
        lineItem.Apttus_Config2__ExtendedPrice__c = extPrice;
        lineItem.Apttus_Config2__Description__c = lineDesc;
        lineItem.Apttus_Config2__AdjustedPrice__c = 0;

        return lineItem;
    }

    /* create Agreement Adjustment line Item */
    public static List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> getAgreementAdjustmentLineItems(String lineItemId) {

        List<Apttus_CMConfig__AgreementAdjustmentLineItem__c> adjustmentLineItems = new List<Apttus_CMConfig__AgreementAdjustmentLineItem__c>();

        Apttus_CMConfig__AgreementAdjustmentLineItem__c adjustmentLineItem = new Apttus_CMConfig__AgreementAdjustmentLineItem__c(
            Apttus_CMConfig__AdjustmentAmount__c = 5,
            Apttus_CMConfig__AdjustmentAppliesTo__c = 'Starting Price',
            Apttus_CMConfig__AdjustmentType__c = '% Discount',
            Apttus_CMConfig__SubType__c = 'Default',
            Apttus_CMConfig__Type__c = 'PPR',
            Apttus_CMConfig__LineNumber__c = 1,
            Apttus_CMConfig__LineType__c = 'Manual',
            Apttus_CMConfig__LineItemId__c = lineItemId);

        adjustmentLineItems.add(adjustmentLineItem);

        Apttus_CMConfig__AgreementAdjustmentLineItem__c adjustmentLineItem1 = new Apttus_CMConfig__AgreementAdjustmentLineItem__c(
            Apttus_CMConfig__AdjustmentAmount__c = 5,
            Apttus_CMConfig__AdjustmentAppliesTo__c = 'Starting Price',
            Apttus_CMConfig__AdjustmentType__c = '% Discount',
            Apttus_CMConfig__SubType__c = 'Default',
            Apttus_CMConfig__Type__c = 'EFF',
            Apttus_CMConfig__LineNumber__c = 1,
            Apttus_CMConfig__LineType__c = 'Manual',
            Apttus_CMConfig__LineItemId__c = lineItemId);

        adjustmentLineItems.add(adjustmentLineItem1);


        return adjustmentLineItems;

    }
    
    //START: TJ Murillo; Commented out APTS_Adjustment_Type__c, APTS_Custom_Adjustment_Amount__c, APTS_Is_Primary__c of Apttus_Config2__AdjustmentLineItem__c to deploy test class
    public static List<Apttus_Config2__AdjustmentLineItem__c> getAdjustmentLineItems(String lineItemId) {

        List<Apttus_Config2__AdjustmentLineItem__c> adjustmentLineItemsToInsert = new List<Apttus_Config2__AdjustmentLineItem__c>();

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem.Apttus_Config2__AdjustmentType__c = '% Discount';
        //adjustmentLineItem.APTS_Adjustment_Type__c = '% Discount';
        //adjustmentLineItem.APTS_Custom_Adjustment_Amount__c = 1;
        adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItemId;
        adjustmentLineItem.Apttus_Config2__LineNumber__c = 1;
        adjustmentLineItem.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem.Apttus_Config2__SubType__c = 'Trade';
        //adjustmentLineItem.APTS_Is_Primary__c = true;
        
        adjustmentLineItemsToInsert.add(adjustmentLineItem);

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem1 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem1.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem1.Apttus_Config2__AdjustmentType__c = '% Discount';
        //adjustmentLineItem1.APTS_Adjustment_Type__c = '% Discount';
        //adjustmentLineItem1.APTS_Custom_Adjustment_Amount__c = 1;
        adjustmentLineItem1.Apttus_Config2__LineItemId__c = lineItemId;
        adjustmentLineItem1.Apttus_Config2__LineNumber__c = 2;
        adjustmentLineItem1.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem1.Apttus_Config2__Type__c = 'PPR';
        adjustmentLineItem1.Apttus_Config2__SubType__c = 'Trade';

        adjustmentLineItemsToInsert.add(adjustmentLineItem1);

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem2 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem2.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem2.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem2.Apttus_Config2__AdjustmentType__c = '% Discount';
        //adjustmentLineItem2.APTS_Adjustment_Type__c = '% Discount';
        //adjustmentLineItem2.APTS_Custom_Adjustment_Amount__c = 1;
        adjustmentLineItem2.Apttus_Config2__LineItemId__c = lineItemId;
        adjustmentLineItem2.Apttus_Config2__LineNumber__c = 3;
        adjustmentLineItem2.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem2.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem2.Apttus_Config2__SubType__c =  'ZP03';

        adjustmentLineItemsToInsert.add(adjustmentLineItem2);

        return adjustmentLineItemsToInsert;

    }

    public static List<Apttus_Config2__AdjustmentLineItem__c> getUpdatedAdjustmentLineItems(String lineItemId) {

        List<Apttus_Config2__AdjustmentLineItem__c> adjustmentLineItemsToInsert = new List<Apttus_Config2__AdjustmentLineItem__c>();

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem.Apttus_Config2__AdjustmentType__c = '% Discount';
        //adjustmentLineItem.APTS_Adjustment_Type__c = '% Discount';
        //adjustmentLineItem.APTS_Custom_Adjustment_Amount__c = 1;
        adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItemId;
        adjustmentLineItem.Apttus_Config2__LineNumber__c = 4;
        adjustmentLineItem.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem.Apttus_Config2__SubType__c =  'ZP03';

        adjustmentLineItemsToInsert.add(adjustmentLineItem);

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem1 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem1.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem1.Apttus_Config2__AdjustmentType__c = '% Discount';
        //adjustmentLineItem1.APTS_Adjustment_Type__c = '% Discount';
        //adjustmentLineItem1.APTS_Custom_Adjustment_Amount__c = 1;
        adjustmentLineItem1.Apttus_Config2__LineItemId__c = lineItemId;
        adjustmentLineItem1.Apttus_Config2__LineNumber__c = 5;
        adjustmentLineItem1.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem1.Apttus_Config2__Type__c = 'PPR';
        adjustmentLineItem1.Apttus_Config2__SubType__c = 'ZP06';

        adjustmentLineItemsToInsert.add(adjustmentLineItem1);

        Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem2 = new Apttus_Config2__AdjustmentLineItem__c();
        adjustmentLineItem2.Apttus_Config2__AdjustmentAmount__c = 1;
        adjustmentLineItem2.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjustmentLineItem2.Apttus_Config2__AdjustmentType__c = '% Discount';
        //adjustmentLineItem2.APTS_Adjustment_Type__c = '% Discount';
        //adjustmentLineItem2.APTS_Custom_Adjustment_Amount__c = 1;
        adjustmentLineItem2.Apttus_Config2__LineItemId__c = lineItemId;
        adjustmentLineItem2.Apttus_Config2__LineNumber__c = 6;
        adjustmentLineItem2.Apttus_Config2__LineType__c = 'Manual';
        adjustmentLineItem2.Apttus_Config2__Type__c = 'TPR';
        adjustmentLineItem2.Apttus_Config2__SubType__c = 'Trade';

        adjustmentLineItemsToInsert.add(adjustmentLineItem2);

        return adjustmentLineItemsToInsert;

    }

    

    public static Apttus__APTS_Agreement__c getAgreements() {
        
        Apttus__APTS_Agreement__c agreement = [SELECT Id, Name, Apttus__Account__c, Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__PricingDate__c,
                                               Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c, Apttus_CMConfig__PONumber__c,
                                               Apttus_QPComply__RelatedProposalId__c
                                               FROM Apttus__APTS_Agreement__c Limit 1];

        return agreement;

    }

    public static List<Apttus__APTS_Agreement__c> getAllAgreements() {
       
        List<Apttus__APTS_Agreement__c> agreements = [SELECT Id, Name, Apttus__Account__c, Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__PricingDate__c,
                                               Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c, Apttus_CMConfig__PONumber__c,
                                               Apttus_QPComply__RelatedProposalId__c
                                               FROM Apttus__APTS_Agreement__c ];

        return agreements;

    }


    public static List<Account> getAccounts() {

        List<Account> account = [SELECT Id, Name,Purchasing_Organization__c FROM Account LIMIT 5];
        return account;
    }
    /* create Proposal line Item */
    public static Apttus_Proposal__Proposal_Line_Item__c getProposalLineItem(String quoteId, String lineId, String pliId, String prodId, String optionId) {

        Apttus_Proposal__Proposal_Line_Item__c propLineItem = new Apttus_Proposal__Proposal_Line_Item__c(
            Apttus_Proposal__Proposal__c = quoteId,
            Apttus_QPConfig__DerivedFromId__c = lineId,
            Apttus_QPConfig__PriceListItemId__c = pliId, Apttus_QPConfig__OptionId__c = optionId, Apttus_Proposal__Product__c = prodId);
        return propLineItem;
    }
    
    public static Apttus_Proposal__Proposal_Line_Item__c getProposalLineItemforassetlinebatch(String quoteId, String lineId, String pliId, String prodId, String optionId) {

        Apttus_Proposal__Proposal_Line_Item__c propLineItem = new Apttus_Proposal__Proposal_Line_Item__c(
            Apttus_Proposal__Proposal__c = quoteId,
            Apttus_QPConfig__DerivedFromId__c = lineId,
            Apttus_QPConfig__PriceListItemId__c = pliId, Apttus_QPConfig__OptionId__c = optionId, Apttus_Proposal__Product__c = prodId,Apttus_QPConfig__PriceType__c = 'Recurring');
        //Apttus_Proposal__Proposal_Line_Item__c propLineItem = [Select Apttus_Proposal__Proposal__c,Apttus_QPConfig__DerivedFromId__c,Apttus_QPConfig__PriceListItemId__c,Apttus_QPConfig__OptionId__c,Apttus_Proposal__Product__c,Apttus_QPConfig__PriceType__c From Apttus_Proposal__Proposal_Line_Item__c limit 1];
        return propLineItem;
    }

    /* Create PricebookEntry */
    public static PricebookEntry getPricebookEntry(String pricebookId, String productID) {
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = productID,
            UnitPrice = 10000, IsActive = true);
        return standardPrice;

    }

    /* Create Contact */
    public static Contact createContact() {

        Contact con = new Contact(FirstName = 'Test', LastName = ' Contact 1 ', Email = 'xyz@abc.com', Phone = '+09898468402');
        return con;

    }

    /*Create Agreement*/
    public static Apttus__APTS_Agreement__c createAgreement(Id conId, Id quoteId, Id priceListId, Id accountId) {

        Apttus__APTS_Agreement__c aptContract = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Standard Deal').getRecordTypeId(),
                Name = 'Agreement',
                Apttus__Primary_Contact__c = conId,
                Apttus__Agreement_Category__c = 'Standard',
                Apttus_CMConfig__PriceListId__c = priceListId,
                                                                              
                Apttus_CMConfig__PricingDate__c = System.Today(),
                Apttus__Account__c = accountId);
        return aptContract;

    }
    public static Apttus__APTS_Agreement__c createconsumptionAgreement(Id conId, Id quoteId, Id priceListId, Id accountId) {

        Apttus__APTS_Agreement__c aptContract = new Apttus__APTS_Agreement__c(recordtypeid = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Consumption Model').getRecordTypeId(),
                Name = 'Agreement',
                Apttus__Primary_Contact__c = conId,
                Apttus__Agreement_Category__c = 'Standard',
                Apttus_CMConfig__PriceListId__c = priceListId,
                Apttus_CMConfig__PricingDate__c = System.Today());
        return aptContract;

    }

    /* Create  Agreement Line Item*/
    public static List<Apttus__AgreementLineItem__c> createAgreementLineItem(Id productId, Id agreementId, Id testAccountId, Apttus_Config2__LineItem__c lineItem, Id priceListItemId, Id subCategoryHierarchyId) {

        Apttus__AgreementLineItem__c agreementLineItem = new Apttus__AgreementLineItem__c();
        agreementLineItem.Apttus__ProductId__c = productId;
        agreementLineItem.Apttus_CMConfig__LineNumber__c = 1;
        agreementLineItem.Apttus_CMConfig__ItemSequence__c = 1;
        agreementLineItem.Apttus__AgreementId__c = agreementId;
        agreementLineItem.Apttus_CMConfig__BaseProductId__c = productId;
        agreementLineItem.Apttus_CMConfig__BillToAccountId__c = testAccountId;
        agreementLineItem.Apttus_CMConfig__DerivedFromId__c = lineItem.Id;
        agreementLineItem.Apttus_CMConfig__PriceListItemId__c = priceListItemId;
        agreementLineItem.Apttus__Quantity__c = 1;
        agreementLineItem.Apttus_CMConfig__LineType__c = 'Product/Service';
        agreementLineItem.Apttus_CMConfig__ChargeType__c = lineItem.Apttus_Config2__ChargeType__c;
        agreementLineItem.Apttus_CMConfig__SellingTerm__c = 1;
        agreementLineItem.Apttus_CMConfig__SellingFrequency__c = 'One Time';
        agreementLineItem.Apttus_CMConfig__ClassificationHierarchy__c = 'Coffee | Espresso Beans';
        agreementLineItem.Apttus_CMConfig__ClassificationId__c = subCategoryHierarchyId;
        agreementLineItem.Apttus_CMConfig__StartDate__c = System.Today();
        agreementLineItem.Apttus_CMConfig__EndDate__c = System.Today();
        agreementLineItem.Apttus_CMConfig__Term__c = lineItem.Apttus_Config2__Term__c ;
        List<Apttus__AgreementLineItem__c> agreementLineItems = new List<Apttus__AgreementLineItem__c>();
        agreementLineItems.add(agreementLineItem);

        return agreementLineItems;

    }

    /* create attachment */
    public static Attachment createAttachment(ID pid) {
        Attachment atc = new Attachment();
        atc.Name = 'Sample Attachment';
        atc.ParentID = pid;
        return atc;
    }

    /* create product attribute group */
    public static Apttus_Config2__ProductAttributeGroup__c createProductAttributeGroup(String businessObject) {
        Apttus_Config2__ProductAttributeGroup__c productAttributeGroup = new Apttus_Config2__ProductAttributeGroup__c();
        productAttributeGroup.Name = 'Test Product Attribute Group';
        productAttributeGroup.Apttus_Config2__BusinessObject__c = businessObject;
        productAttributeGroup.Apttus_Config2__Description__c = 'Test Product Attribute Group';
        productAttributeGroup.Apttus_Config2__TwoColumnAttributeDisplay__c = true;

        return productAttributeGroup;
    }

    /*  create product attribute */
    public static Apttus_Config2__ProductAttribute__c createProductAttribute(String field, Id attributeGroupId) {
        Apttus_Config2__ProductAttribute__c productAttribute = new Apttus_Config2__ProductAttribute__c();
        productAttribute.Apttus_Config2__Sequence__c = 1;
        productAttribute.Apttus_Config2__Field__c = field;
        productAttribute.Apttus_Config2__AttributeGroupId__c = attributeGroupId;

        return productAttribute;
    }

    /* create price dimension */
    public static List<Apttus_Config2__PriceDimension__c> createPriceDimension(String dimensionName, String contextType, String businessObject,
            String field, Id productAttributeId) {

        List<Apttus_Config2__PriceDimension__c> listPriceDimension = new List<Apttus_Config2__PriceDimension__c>();
        Apttus_Config2__PriceDimension__c priceDimension = new Apttus_Config2__PriceDimension__c();
        priceDimension.Name = dimensionName;
        priceDimension.Apttus_Config2__ContextType__c = contextType;
        priceDimension.Apttus_Config2__BusinessObject__c = businessObject;
        priceDimension.Apttus_Config2__Datasource__c = field;
        priceDimension.Apttus_Config2__AttributeId__c = productAttributeId;

        listPriceDimension.add(priceDimension);
        return listPriceDimension;

    }

    /* create price matrix */
    public static List<Apttus_Config2__PriceMatrixEntry__c> createPriceMatrixEntry(Id priceMatrixId) {

        List<Apttus_Config2__PriceMatrixEntry__c> listPME = new List<Apttus_Config2__PriceMatrixEntry__c>();

        Apttus_Config2__PriceMatrixEntry__c pme1 = new Apttus_Config2__PriceMatrixEntry__c();
        pme1.Apttus_Config2__Dimension1Value__c = '12 Months';
        pme1.Apttus_Config2__PriceMatrixId__c = priceMatrixId;
        pme1.Apttus_Config2__Sequence__c = 1;
        pme1.Apttus_Config2__UsageRate__c = 1;
        pme1.Apttus_Config2__AdjustmentAmount__c = 1;
        pme1.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(pme1);

        Apttus_Config2__PriceMatrixEntry__c pme2 = new Apttus_Config2__PriceMatrixEntry__c();
        pme2.Apttus_Config2__Dimension1Value__c = '6 Months';
        pme2.Apttus_Config2__PriceMatrixId__c = priceMatrixId;
        pme2.Apttus_Config2__Sequence__c = 1;
        pme2.Apttus_Config2__UsageRate__c = 1;
        pme2.Apttus_Config2__AdjustmentAmount__c = 1;
        pme2.Apttus_Config2__PriceOverride__c = 1;
        listPME.add(pme2);

        return listPME;

    }

    //Neev ++ <<
    /* create Order **/
    public static Apttus_Config2__Order__c createOrder(Final String sType, Final Id priceListID, Final Id accountID, Final Id billPrefID) {
        Apttus_Config2__Order__c order = new Apttus_Config2__Order__c();
        order.Apttus_Config2__Status__c = 'Pending';
        order.Apttus_Config2__Type__c = sType;
        order.Apttus_Config2__PriceListId__c = priceListID;
        order.Apttus_Config2__Source__c = 'Account';
        order.Apttus_Config2__BillingPreferenceId__c = billPrefID;
        order.Apttus_Config2__BillToAccountId__c = accountID;
        order.Apttus_Config2__SoldToAccountId__c = accountID;
        order.Apttus_Config2__ShipToAccountId__c = accountID;
        order.Apttus_Config2__PricingDate__c = Date.today();
        order.Apttus_Config2__OrderStartDate__c = Date.today();
        order.Apttus_Config2__OrderEndDate__c = Date.today().addYears(1);
        //v101 ++ <<
        order.APTS_Requested_Delivery_Date__c = System.today().toStartOfWeek().addDays(3);
        order.APTS_Requested_De_Installation_Date__c = System.today().toStartOfWeek().addDays(7);
        order.APTS_Requested_Installation_Date__c = System.today().toStartOfWeek().addDays(7);
        order.APTS_Requested_Movement_Date__c = System.today();
        //v101 ++ >>
        return order;
    }

    /* create Billing Prefrence (Apttus_Config2__BillingPreference__c) **/
    public static Apttus_Config2__BillingPreference__c createBillingPrefrence() {
        return createBillingPrefrence('April');
    }

    public static Apttus_Config2__BillingPreference__c createBillingPrefrence(String calendarCycleStart) {
        Apttus_Config2__BillingPreference__c oBillingPref = new Apttus_Config2__BillingPreference__c();
        oBillingPref.Name = 'Pending';
        oBillingPref.Apttus_Config2__BillingDayOfMonth2__c = '1st of the Month';
        oBillingPref.Apttus_Config2__Active__c = true;
        oBillingPref.Apttus_Config2__BillingCycleStart__c = 'Billing Day of Month';
        oBillingPref.Apttus_Config2__BillingInterval__c = 'Anytime';
        oBillingPref.Apttus_Config2__CalendarCycleStart__c = calendarCycleStart;
        oBillingPref.Apttus_Config2__TaxLevel__c = 'Product';
        oBillingPref.Apttus_Config2__InvoiceDeliveryMethod__c = 'Email';
        oBillingPref.Apttus_Config2__InvoiceOutputFormat__c = 'PDF';
        return oBillingPref;
    }

    public static Apttus_Config2__BillingPreference__c getBillingPrefrence(Id agreementid, String interval) {
        Apttus_Config2__BillingPreference__c oBillingPref = new Apttus_Config2__BillingPreference__c();
        oBillingPref.Name = 'Pending';
        oBillingPref.Apttus_Config2__BillingDayOfMonth2__c = '1st of the Month';
        oBillingPref.Apttus_Config2__Active__c = true;
        oBillingPref.Apttus_Config2__BillingCycleStart__c = 'Billing Day of Month';
        oBillingPref.Apttus_Config2__BillingInterval__c = interval;
        oBillingPref.Apttus_CMConfig__AgreementId__c=agreementid;
        oBillingPref.Apttus_Config2__TaxLevel__c = 'Product';
        oBillingPref.Apttus_Config2__InvoiceDeliveryMethod__c = 'Email';
        oBillingPref.Apttus_Config2__InvoiceOutputFormat__c = 'PDF';
        oBillingPref.APTS_Billing_Rule_Contract__c = 'Bill in Arrears';
        return oBillingPref;
    }    

    /* create Asset Line Item (Apttus_Config2__AssetLineItem__c) **/
    public static Apttus_Config2__AssetLineItem__c createAssetLineItem(Final Id accountID, Final Id prodID, Final Id priceListID, Final Id pliID, Final Id billPrefID, Final Id orderID) {
        Apttus_Config2__AssetLineItem__c oAssetLine = new Apttus_Config2__AssetLineItem__c();
        oAssetLine.Apttus_Config2__AssetStatus__c = 'Pending Activation';
        oAssetLine.Apttus_Config2__AssetTCV__c = 100;
        oAssetLine.Apttus_Config2__BasePrice__c = 10;
        oAssetLine.Apttus_Config2__BaseExtendedPrice__c = 100;
        oAssetLine.Apttus_Config2__BasePriceMethod__c = 'Per Unit';
        oAssetLine.Apttus_Config2__BillingPreferenceId__c = billPrefID;
        oAssetLine.Apttus_Config2__BillingFrequency__c =  'One Time';
        oAssetLine.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        oAssetLine.Apttus_Config2__BillToAccountId__c = accountID;
        oAssetLine.Apttus_Config2__BillingStartDate__c = Date.today();
        oAssetLine.Apttus_Config2__BillingEndDate__c = Date.today().addYears(1);
        oAssetLine.Apttus_Config2__BusinessObjectType__c = 'Apttus_Config2__Order__c';
        oAssetLine.Apttus_Config2__BusinessObjectId__c = orderID;
        oAssetLine.Apttus_Config2__ChargeType__c = 'Standard Price';
        oAssetLine.Apttus_Config2__DeltaPrice__c = 100;
        oAssetLine.Apttus_Config2__DeltaQuantity__c = 10;
        oAssetLine.Apttus_Config2__Description__c = 'Test Asset';
        oAssetLine.Apttus_Config2__EndDate__c = Date.today().addYears(1);
        oAssetLine.Apttus_Config2__ExtendedPrice__c = 100;
        oAssetLine.Apttus_Config2__LineType__c = 'Product/Service';
        oAssetLine.Apttus_Config2__ListPrice__c = 10;
        oAssetLine.Apttus_Config2__LineNumber__c = 1;
        oAssetLine.Apttus_Config2__ItemSequence__c = 1;
        oAssetLine.Apttus_Config2__IsPrimaryLine__c = true;
        oAssetLine.Apttus_Config2__NetPrice__c = 100;
        oAssetLine.Apttus_Config2__NetUnitPrice__c = 10;
        oAssetLine.Apttus_Config2__PrimaryLineNumber__c = 1;
        oAssetLine.Apttus_Config2__PriceListId__c = priceListID;
        oAssetLine.Apttus_Config2__PriceListItemId__c = pliID;
        oAssetLine.Apttus_Config2__PriceType__c = 'One Time';
        oAssetLine.Apttus_Config2__ProductId__c = prodID;
        oAssetLine.Apttus_Config2__RenewalFrequency__c = 'One Time';
        oAssetLine.Apttus_Config2__Quantity__c = 10;
        oAssetLine.Apttus_Config2__ShipToAccountId__c = accountID;
        oAssetLine.Apttus_Config2__AccountId__c = accountID;
        oAssetLine.Apttus_Config2__StartDate__c = Date.today();
        oAssetLine.Apttus_Config2__SellingFrequency__c = 'One Time';
        oAssetLine.Apttus_Config2__SellingTerm__c = 1;

        return oAssetLine;
    }

    /* create Order Line Item (Apttus_Config2__OrderLineItem__c) **/
    public static Apttus_Config2__OrderLineItem__c createOrderLineItem(Final Id prodID, Final Id orderID, Final Id assetID, Final Id billPrefID, Final Id pricelistID, Final Id pliID) {
        Apttus_Config2__OrderLineItem__c oOLI = new Apttus_Config2__OrderLineItem__c();
        oOLI.Apttus_Config2__OrderId__c = orderID;
        oOLI.Apttus_Config2__ProductId__c = prodID;
        oOLI.Apttus_Config2__LineStatus__c = 'New';
        oOLI.Apttus_Config2__BillingPreferenceId__c = billPrefID;
        oOLI.Apttus_Config2__BillingFrequency__c = 'Monthly';
        oOLI.Apttus_Config2__PriceType__c = 'One Time';
        oOLI.Apttus_Config2__SellingFrequency__c = 'Monthly';
        oOLI.Apttus_Config2__BasePrice__c = 2;
        oOLI.Apttus_Config2__OptionPrice__c = 3;
        oOLI.Apttus_Config2__SellingTerm__c = 12;
        oOLI.Apttus_Config2__Quantity__c = 5;
        oOLI.Apttus_Config2__NetUnitPrice__c = 9;
        oOLI.Apttus_Config2__StartDate__c = Date.newInstance(2017, 4, 4);
        oOLI.Apttus_Config2__EndDate__c = Date.newInstance(2020, 4, 4);
        oOLI.Apttus_Config2__AssetLineItemId__c = assetID;
        oOLI.Apttus_Config2__PriceListId__c = priceListID;
        oOLI.Apttus_Config2__PriceListItemId__c = pliID;
        oOLI.Apttus_Config2__BillingRule__c = 'Bill In Advance';
        return oOLI;
    }

    /*
    public static Apttus_Config2__OrderSystemProperties__c getOrderSystemProperties() {
        Apttus_Config2__OrderSystemProperties__c oOSP = new Apttus_Config2__OrderSystemProperties__c();
        oOSP.name = 'System Properties';
        oOSP.Apttus_Config2__InitiateBillingOnOrderActivation__c = true;
        oOSP.APTS_Product_Ingredients_Family__c = 'Coffee';
        oOSP.APTS_Product_Machines_Family__c = 'Machines'; //+-Galin : was Machine
         
        return oOSP;
    }*/
    //Neev ++ >>

    //Ankit ++ <<

    /* create category */
    
    public static Apttus_Config2__ClassificationName__c createCategory() {

        Apttus_Config2__ClassificationName__c category = new Apttus_Config2__ClassificationName__c();
        category.Name = 'Machines';
        category.Apttus_Config2__Active__c = true;
        category.Apttus_Config2__HierarchyLabel__c = 'Machines';
        category.Apttus_Config2__Type__c = 'Offering';
        category.APTS_Allow_Adjustments__c = true;
        return category;

    }

    /* create category hierarchy */
    public static Apttus_Config2__ClassificationHierarchy__c createCategoryHierarchy(Id categoryId) {

        Apttus_Config2__ClassificationHierarchy__c categoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        categoryHierarchy.Name = 'Machines';
        categoryHierarchy.Apttus_Config2__HierarchyId__c = categoryId;
        categoryHierarchy.Apttus_Config2__AncestorId__c = null;
        categoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        categoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        categoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        categoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        categoryHierarchy.Apttus_Config2__IsHidden__c = false;
        categoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        categoryHierarchy.Apttus_Config2__Label__c = 'Machines';
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
    
    Public static Apttus_Config2__ClassificationHierarchy__c getcategory(){
        
        Apttus_Config2__ClassificationHierarchy__c cat =[Select Id,Name,Apttus_Config2__HierarchyId__c ,Apttus_Config2__AncestorId__c,Apttus_Config2__DefaultSearchCategory__c,Apttus_Config2__ExpandedByDefault__c ,Apttus_Config2__HideAllSearchFilters__c,Apttus_Config2__IncludeInTotalsView__c,
                                                        Apttus_Config2__IsHidden__c,Apttus_Config2__IsPicklist__c, Apttus_Config2__Label__c,Apttus_Config2__LargeImageSize__c ,Apttus_Config2__Left__c,Apttus_Config2__Level__c,Apttus_Config2__MaxOptions__c,
                                                        Apttus_Config2__MinOptions__c,Apttus_Config2__Modifiable__c,Apttus_Config2__PrimordialId__c,Apttus_Config2__ProductAttributeGroupId__c,Apttus_Config2__Right__c From Apttus_Config2__ClassificationHierarchy__c Where Apttus_Config2__Label__c =: 'Machines'];
        return cat;
    }

    /* create sub-category */
    public static Apttus_Config2__ClassificationHierarchy__c createSubCategory(Id categoryId, Id categoryHierarchyId) {

        Apttus_Config2__ClassificationHierarchy__c subCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subCategoryHierarchy.Name = 'Cafitesse';
        subCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subCategoryHierarchy.Apttus_Config2__HierarchyId__c = categoryId;
        subCategoryHierarchy.Apttus_Config2__AncestorId__c = categoryHierarchyId;
        subCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subCategoryHierarchy.Apttus_Config2__Label__c = 'Cafitesse';
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
    
    Public static Apttus_Config2__ClassificationHierarchy__c getsubcategory(){
        
        Apttus_Config2__ClassificationHierarchy__c subcat =[Select Id,Name,Apttus_Config2__HierarchyId__c ,Apttus_Config2__AncestorId__c,Apttus_Config2__DefaultSearchCategory__c,Apttus_Config2__ExpandedByDefault__c ,Apttus_Config2__HideAllSearchFilters__c,Apttus_Config2__IncludeInTotalsView__c,
                                                        Apttus_Config2__IsHidden__c,Apttus_Config2__IsPicklist__c, Apttus_Config2__Label__c,Apttus_Config2__LargeImageSize__c ,Apttus_Config2__Left__c,Apttus_Config2__Level__c,Apttus_Config2__MaxOptions__c,
                                                        Apttus_Config2__MinOptions__c,Apttus_Config2__Modifiable__c,Apttus_Config2__PrimordialId__c,Apttus_Config2__ProductAttributeGroupId__c,Apttus_Config2__Right__c From Apttus_Config2__ClassificationHierarchy__c Where Apttus_Config2__Label__c =: 'Cafitesse'];
        return subcat;
    }

    /* create sub-sub-category */
    public static Apttus_Config2__ClassificationHierarchy__c createSubSubCategory(Id categoryId, Id categoryHierarchyId, Id subCategoryHierarchyId ) {

        Apttus_Config2__ClassificationHierarchy__c subSubCategoryHierarchy = new Apttus_Config2__ClassificationHierarchy__c();
        subSubCategoryHierarchy.Name = 'Sub Sub Category Beans';
        subSubCategoryHierarchy.CurrencyIsoCode = 'EUR';
        subSubCategoryHierarchy.Apttus_Config2__HierarchyId__c = categoryId;
        subSubCategoryHierarchy.Apttus_Config2__AncestorId__c = subCategoryHierarchyId;
        subSubCategoryHierarchy.Apttus_Config2__DefaultSearchCategory__c = false;
        subSubCategoryHierarchy.Apttus_Config2__ExpandedByDefault__c = false;
        subSubCategoryHierarchy.Apttus_Config2__HideAllSearchFilters__c = false;
        subSubCategoryHierarchy.Apttus_Config2__IncludeInTotalsView__c = true;
        subSubCategoryHierarchy.Apttus_Config2__IsHidden__c = false;
        subSubCategoryHierarchy.Apttus_Config2__IsPicklist__c = false;
        subSubCategoryHierarchy.Apttus_Config2__Label__c = 'Espresso Beans';
        subSubCategoryHierarchy.Apttus_Config2__Left__c = 2;
        subSubCategoryHierarchy.Apttus_Config2__Level__c = 1;
        subSubCategoryHierarchy.Apttus_Config2__MaxOptions__c = 1.00000;
        subSubCategoryHierarchy.Apttus_Config2__MinOptions__c = 1.00000;
        subSubCategoryHierarchy.Apttus_Config2__Modifiable__c = true;
        subSubCategoryHierarchy.Apttus_Config2__PrimordialId__c = categoryHierarchyId;
        subSubCategoryHierarchy.Apttus_Config2__ProductAttributeGroupId__c = null;
        subSubCategoryHierarchy.Apttus_Config2__Right__c = 3;
        return subSubCategoryHierarchy;

    }
    
    Public static Apttus_Config2__ClassificationHierarchy__c getsubsubcategory(){
        
        Apttus_Config2__ClassificationHierarchy__c subsubcat =[Select Id,Name,Apttus_Config2__HierarchyId__c ,Apttus_Config2__AncestorId__c,Apttus_Config2__DefaultSearchCategory__c,Apttus_Config2__ExpandedByDefault__c ,Apttus_Config2__HideAllSearchFilters__c,Apttus_Config2__IncludeInTotalsView__c,
                                                        Apttus_Config2__IsHidden__c,Apttus_Config2__IsPicklist__c, Apttus_Config2__Label__c,Apttus_Config2__LargeImageSize__c ,Apttus_Config2__Left__c,Apttus_Config2__Level__c,Apttus_Config2__MaxOptions__c,
                                                        Apttus_Config2__MinOptions__c,Apttus_Config2__Modifiable__c,Apttus_Config2__PrimordialId__c,Apttus_Config2__ProductAttributeGroupId__c,Apttus_Config2__Right__c From Apttus_Config2__ClassificationHierarchy__c Where Apttus_Config2__Label__c =: 'Espresso Beans'];
        return subsubcat;
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
    /* create adjustments */
    public static APTS_Adjustments__c createadjustments(Id categoryHierarchyId, Id testAgreementId, String adjlevel) {
        APTS_Adjustments__c adj = new APTS_Adjustments__c();
        adj.APTS_Adjustment_Level__c = adjlevel;
        adj.APTS_Adjustment_Type__c = ' % Discount';
        adj.APTS_Adjustment_Value__c = 10.00;
        adj.APTS_Agreement__c = testAgreementId;
        adj.APTS_Level_Id__c = categoryHierarchyId;
        adj.APTS_Level_Name__c = 'Test';
        adj.APTS_Type__c = 'TPR';
        return adj;
    }

    /* create prduct classification */
    
    public static List<APTS_Adjustments__c> getAdjustmentLineItems(Id agreementId, Id categoryId, Id subCategoryId,Id subSubCategoryId, Id accountId, Id priceListItemId) {

        List<APTS_Adjustments__c> adjustmentLineItems = new List<APTS_Adjustments__c>();

        APTS_Adjustments__c adjustmentLineItem = new APTS_Adjustments__c();
        adjustmentLineItem.APTS_Adjustment_Type__c = 'Discount Amount';
        adjustmentLineItem.APTS_Adjustment_Value__c = 1.00;
        adjustmentLineItem.APTS_Agreement__c = agreementId;
        adjustmentLineItem.APTS_Type__c = 'TPR';
        adjustmentLineItem.APTS_Sub_Type__c = 'ZP03';
        adjustmentLineItem.APTS_Adjustment_Level__c = 'Category';
        adjustmentLineItem.APTS_Level_Id__c = ( categoryId != null ? String.ValueOf(categoryId) : '');
        adjustmentLineItem.APTS_Account__c = accountId;
        adjustmentLineItem.APTS_UoM__c = 'Each';
        adjustmentLineItems.add(adjustmentLineItem);

        APTS_Adjustments__c adjustmentLineItem1 = new APTS_Adjustments__c();
        adjustmentLineItem1.APTS_Adjustment_Type__c = 'Markup Amount';
        adjustmentLineItem1.APTS_Adjustment_Value__c = 2;
        adjustmentLineItem1.APTS_Agreement__c = agreementId;
        adjustmentLineItem1.APTS_Type__c = 'TPR';
        adjustmentLineItem1.APTS_Adjustment_Level__c = 'SubCategory';
        adjustmentLineItem1.APTS_Sub_Type__c = 'ZP07';
        adjustmentLineItem1.APTS_Level_Id__c = ( subCategoryId != null ? String.ValueOf(subCategoryId) : '');
        adjustmentLineItem1.APTS_Account__c = accountId;
        adjustmentLineItem1.APTS_UoM__c = 'Each';
        adjustmentLineItems.add(adjustmentLineItem1);

        APTS_Adjustments__c adjustmentLineItem2 = new APTS_Adjustments__c();
        adjustmentLineItem2.APTS_Adjustment_Type__c = 'Markup Amount';
        adjustmentLineItem2.APTS_Adjustment_Value__c = 2;
        adjustmentLineItem2.APTS_Agreement__c = agreementId;
        adjustmentLineItem2.APTS_Type__c = 'EFF';
        adjustmentLineItem2.APTS_Adjustment_Level__c = 'Product';
        adjustmentLineItem2.APTS_Sub_Type__c = 'ZP08';
        adjustmentLineItem2.APTS_Level_Id__c = ( priceListItemId != null ? String.ValueOf(priceListItemId) : '');
        adjustmentLineItem2.APTS_Account__c = accountId;
        adjustmentLineItem2.APTS_UoM__c = 'Each';
        adjustmentLineItems.add(adjustmentLineItem2);

        APTS_Adjustments__c adjustmentLineItem3 = new APTS_Adjustments__c();
        adjustmentLineItem3.APTS_Adjustment_Type__c = 'Markup Amount';
        adjustmentLineItem3.APTS_Adjustment_Value__c = 2;
        adjustmentLineItem3.APTS_Agreement__c = agreementId;
        adjustmentLineItem3.APTS_Type__c = 'BMC';
        adjustmentLineItem3.APTS_Adjustment_Level__c = 'SubSubCategory';
        adjustmentLineItem3.APTS_Sub_Type__c = 'ZP08';
        adjustmentLineItem3.APTS_Level_Id__c = ( subSubCategoryId != null ? String.ValueOf(subSubCategoryId) : '');
        adjustmentLineItem3.APTS_Account__c = accountId;
        adjustmentLineItem3.APTS_UoM__c = 'Each';
        adjustmentLineItems.add(adjustmentLineItem3);

        return adjustmentLineItems;

    }
    
    Public static Apttus_Config2__AdjustmentLineItem__c createadjustmentlineitems(id lineitemid){
        Apttus_Config2__AdjustmentLineItem__c adjline = new Apttus_Config2__AdjustmentLineItem__c();
        //adjline.APTS_Is_Primary__c = False;        
        adjline.Apttus_Config2__AdjustmentAmount__c = 10.00;
        adjline.Apttus_Config2__LineNumber__c = 1;
        adjline.Apttus_Config2__AdjustmentAppliesTo__c = 'Previous Price';
        adjline.Apttus_Config2__AdjustmentType__c= '% Discount';
        adjline.Apttus_Config2__Bucket__c= 'Bucket 1';
        adjline.Apttus_Config2__LineItemId__c= lineitemid;
        return adjline;
            
    }
     Public static Apttus_CMConfig__AgreementAdjustmentLineItem__c createagrementadjustmentlineitemCER(id Agreementlineid){
    
        Apttus_CMConfig__AgreementAdjustmentLineItem__c agradjline = new Apttus_CMConfig__AgreementAdjustmentLineItem__c ();
        agradjline.Apttus_CMConfig__AdjustmentAmount__c = 10.00;
        agradjline.Apttus_CMConfig__AdjustmentAppliesTo__c = 'Previous Price' ;
        agradjline.Apttus_CMConfig__AdjustmentType__c = '% Discount';
        agradjline.Apttus_CMConfig__AdjustmentUom__c='Box';
        //agradjline.APTS_Agreement_LineItem_Id__c=Agreementlineid;
        //agradjline.APTS_Agreement_Number__c='';
        agradjline.Apttus_CMConfig__BenefitQuantity__c=10.00;
        agradjline.Apttus_CMConfig__Bucket__c='Bucket 1';
        agradjline.Apttus_CMConfig__LineType__c='Manual';
        agradjline.Apttus_CMConfig__SubType__c='PPR';
        agradjline.Apttus_CMConfig__Type__c='PPR';
        agradjline.Apttus_CMConfig__LineNumber__c = 1;
        agradjline.Apttus_CMConfig__LineItemId__c = Agreementlineid;
        agradjline.APTS_Adjustment_Source__c='Child';
        //agradjline.Apttus_CMConfig__Bucket__c = 'Bucket 1';
        
        return agradjline;
    }
    
    Public static Apttus_CMConfig__AgreementAdjustmentLineItem__c createagrementadjustmentlineitem(id Agreementlineid){
    
        Apttus_CMConfig__AgreementAdjustmentLineItem__c agradjline = new Apttus_CMConfig__AgreementAdjustmentLineItem__c ();
        agradjline.Apttus_CMConfig__AdjustmentAmount__c = 10.00;
        agradjline.Apttus_CMConfig__AdjustmentAppliesTo__c = 'Previous Price' ;
        agradjline.Apttus_CMConfig__AdjustmentType__c = '% Discount';
        agradjline.Apttus_CMConfig__LineNumber__c = 1;
        agradjline.Apttus_CMConfig__LineItemId__c = Agreementlineid;
        //agradjline.Apttus_CMConfig__Bucket__c = 'Bucket 1';
        
        return agradjline;
    }
    public static APTS_Contract_Entitlement_Repository__c createCerrecords(id adjlineitemid,id aglId,id prdId){
        APTS_Contract_Entitlement_Repository__c cer = new APTS_Contract_Entitlement_Repository__c();
        cer.APTS_Adjustment_Type__c = '% Discount';
        cer.APTS_Adjustment_Value__c = 10.00;
        cer.APTS_Agreement_Adjustment_Line_Item__c = adjlineitemid;
        cer.APTS_Agreement_Line_Item__c = aglId;
        cer.APTS_Bucket__c = 'Bucket 1';
        cer.APTS_Product__c = prdId;
        cer.APTS_Type__c = 'PPR';
        cer.APTS_UOM__c = 'Piece';
        cer.APTS_Agreement_Type__c = 'Standard Deal';
        return cer;
        
    }

    /* create prduct classification */
    /*
    public static List<APTS_AgreementAdjustmentLineItem__c> getTemporaryAdjustments(Id agreementId, Id categoryId, Id subCategoryId, Id priceListItemId) {

        List<APTS_AgreementAdjustmentLineItem__c> temporaryAdjustments = new List<APTS_AgreementAdjustmentLineItem__c>();

        APTS_AgreementAdjustmentLineItem__c temporaryAdjustment = new APTS_AgreementAdjustmentLineItem__c();
        temporaryAdjustment.APTS_Adjustment_Type__c = 'Discount Amount';
        temporaryAdjustment.APTS_Adjustment_Value__c = 1;
        temporaryAdjustment.APTS_Agreement__c = agreementId;
        temporaryAdjustment.APTS_Discount_Type__c = 'PPR';
        temporaryAdjustment.APTS_Sub_Type__c = 'PPR';
        temporaryAdjustment.APTS_Type__c = 'Category';
        temporaryAdjustment.APTS_Value__c = ( categoryId != null ? String.ValueOf(categoryId) : '');
        temporaryAdjustment.APTS_Adjustment_Start_Date__c = System.Today();
        temporaryAdjustment.APTS_Adjustment_End_Date__c = System.Today();
        temporaryAdjustment.APTS_Value_Name__c = 'Test';
        temporaryAdjustments.add(temporaryAdjustment);

        APTS_AgreementAdjustmentLineItem__c temporaryAdjustment1 = new APTS_AgreementAdjustmentLineItem__c();
        temporaryAdjustment1.APTS_Adjustment_Type__c = 'Markup Amount';
        temporaryAdjustment1.APTS_Adjustment_Value__c = 1;
        temporaryAdjustment1.APTS_Agreement__c = agreementId;
        temporaryAdjustment1.APTS_Discount_Type__c = 'PPR';
        temporaryAdjustment1.APTS_Sub_Type__c = 'PPR';
        temporaryAdjustment1.APTS_Type__c = 'SubCategory';
        temporaryAdjustment1.APTS_Value__c = ( subCategoryId != null ? String.ValueOf(subCategoryId) : '');
        temporaryAdjustment1.APTS_Adjustment_Start_Date__c = System.Today();
        temporaryAdjustment1.APTS_Adjustment_End_Date__c = System.Today();
        temporaryAdjustment1.APTS_Value_Name__c = 'Test';
        temporaryAdjustments.add(temporaryAdjustment1);

        APTS_AgreementAdjustmentLineItem__c temporaryAdjustment2 = new APTS_AgreementAdjustmentLineItem__c();
        temporaryAdjustment2.APTS_Adjustment_Type__c = 'Markup Amount';
        temporaryAdjustment2.APTS_Adjustment_Value__c = 1;
        temporaryAdjustment2.APTS_Agreement__c = agreementId;
        temporaryAdjustment2.APTS_Discount_Type__c = 'PPR';
        temporaryAdjustment2.APTS_Sub_Type__c = 'PPR';
        temporaryAdjustment2.APTS_Type__c = 'Product';
        temporaryAdjustment2.APTS_Value__c = ( priceListItemId != null ? String.ValueOf(priceListItemId) : '');
        temporaryAdjustment2.APTS_Adjustment_Start_Date__c = System.Today();
        temporaryAdjustment2.APTS_Adjustment_End_Date__c = System.Today();
        temporaryAdjustment2.APTS_Value_Name__c = 'Test';
        temporaryAdjustments.add(temporaryAdjustment2);
        
        /*APTS_AgreementAdjustmentLineItem__c temporaryAdjustment3 = new APTS_AgreementAdjustmentLineItem__c();
        temporaryAdjustment3.APTS_Adjustment_Type__c = 'Markup Amount';
        temporaryAdjustment3.APTS_Adjustment_Value__c = 1;
        temporaryAdjustment3.APTS_Agreement__c = agreementId;
        temporaryAdjustment3.APTS_Discount_Type__c = 'PPR';
        temporaryAdjustment3.APTS_Sub_Type__c = 'PPR';
        temporaryAdjustment3.APTS_Type__c = 'Product';
        temporaryAdjustment3.APTS_Value__c = ( priceListItemId != null ? String.ValueOf(priceListItemId) : '');
        temporaryAdjustment3.APTS_Adjustment_Start_Date__c = System.Today();
        temporaryAdjustment3.APTS_Adjustment_End_Date__c = System.Today() -1;
        temporaryAdjustment3.APTS_Value_Name__c = 'Test';
        temporaryAdjustments.add(temporaryAdjustment3);

        return temporaryAdjustments;

    }*/

    /*
    public static List<Apttus__AgreementLineItem__c> getAgreementLineItemsWithRelatedFields() {

        List<Apttus__AgreementLineItem__c> agreementLineItemList = [SELECT Id, Apttus__ProductId__c, Apttus_CMConfig__LineNumber__c,
                                           Apttus_CMConfig__ItemSequence__c, Apttus__AgreementId__c,
                                           Apttus_CMConfig__BaseProductId__c, Apttus_CMConfig__BillToAccountId__c,
                                           Apttus_CMConfig__DerivedFromId__c, Apttus_CMConfig__PriceListItemId__c, Apttus__Quantity__c,
                                           Apttus_CMConfig__LineType__c, Apttus_CMConfig__ChargeType__c, Apttus_CMConfig__SellingTerm__c,
                                           Apttus_CMConfig__SellingFrequency__c, Apttus_CMConfig__ClassificationHierarchy__c,
                                           Apttus__ProductId__r.Apttus_Config2__ConfigurationType__c, Apttus_CMConfig__Term__c,
                                           Apttus_CMConfig__StartDate__c, Apttus_CMConfig__EndDate__c,
                                           Apttus_CMConfig__Comments__c, Apttus_CMConfig__ServiceLocationId__c,
                                           Apttus_CMConfig__ClassificationId__c, Apttus_CMConfig__AdjustmentType__c, Apttus_CMConfig__AdjustmentAmount__c,
                                           Asset_Details__c,Apttus_CMConfig__LineStatus__c,Apttus_CMConfig__AssetLineItemId__c
                                           FROM  Apttus__AgreementLineItem__c LIMIT 1  ];

        return agreementLineItemList;

    }

    */
     public static Apttus__AgreementLineItem__c getAgreementLineItems(Id agreementId) 
        {

            Apttus__AgreementLineItem__c agreementLineItemList = [SELECT Id,Name 
                                               FROM  Apttus__AgreementLineItem__c where Apttus__AgreementId__c=:agreementId  LIMIT 1  ];

            return agreementLineItemList;

        }
    public static List<Apttus__AgreementLineItem__c> getAllAgreementLineItems(Id agreementId) 
    {
        
        List<Apttus__AgreementLineItem__c> agreementLineItemList = [SELECT Id,Name 
                                             FROM  Apttus__AgreementLineItem__c where Apttus__AgreementId__c=:agreementId];
        return agreementLineItemList;
    }

    public static List<Apttus_Config2__LineItem__c> getLineItemsFromOrderCart(Id cartId) {
        
        List<Apttus_Config2__LineItem__c> lineItems = [ SELECT Id, Apttus_Config2__PriceListItemId__c,Apttus_Config2__OptionId__c,Apttus_Config2__LineType__c,
                                                            Apttus_Config2__ClassificationId__c, Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c,
                                                            Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c,Apttus_Config2__IsCustomPricing__c FROM Apttus_Config2__LineItem__c WHERE Apttus_Config2__ConfigurationId__c = : cartId];

        return lineItems;

    }
    //Ankit ++ >>

    //++<<Galin
    /* create signed attachment */
    public static Attachment createSignedDoc(ID pid) {

        Attachment atc = new Attachment();
        atc.Name = 'Proposal_signed.pdf';
        atc.ParentID = pid;
        Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        atc.Body = bodyBlob;

        return atc;
    }
    /* create proposal adjustment line item */
    public static Apttus_QPConfig__ProposalAdjustmentLineItem__c createProposalAdjustmentLineItem(Id lineItemId) {

        Apttus_QPConfig__ProposalAdjustmentLineItem__c oProposalAdjustmentLineItem = new Apttus_QPConfig__ProposalAdjustmentLineItem__c();
        oProposalAdjustmentLineItem.Apttus_QPConfig__LineNumber__c = 1;
        oProposalAdjustmentLineItem.Apttus_QPConfig__LineItemId__c = lineItemId;
        oProposalAdjustmentLineItem.Apttus_QPConfig__AdjustmentAmount__c = 10;
        oProposalAdjustmentLineItem.Apttus_QPConfig__AdjustmentType__c = '% Discount';

        return oProposalAdjustmentLineItem;
    }
    /*  create proposal product attribute */
    public static Apttus_QPConfig__ProposalProductAttributeValue__c createProposalProductAttribute(Apttus_Proposal__Proposal_Line_Item__c oProposalLineItem) {

        Apttus_QPConfig__ProposalProductAttributeValue__c oProposalProductAttribute = new Apttus_QPConfig__ProposalProductAttributeValue__c();
        oProposalProductAttribute.Apttus_QPConfig__LineItemId__c = oProposalLineItem.Id;

        return oProposalProductAttribute;
    }
    /*  create incentive */
    public static Apttus_Config2__Incentive__c createIncentive(Id proposalId) {

        Apttus_Config2__Incentive__c oIncentive = new Apttus_Config2__Incentive__c();
        //oIncentive.APTS_Quote_Proposal__c = proposalId;
        oIncentive.Apttus_Config2__Sequence__c = 1;
        oIncentive.Apttus_Config2__Status__c = 'Draft';

        return oIncentive;
    }
    /*  create price rule set */
    public static Apttus_Config2__PriceRuleset__c createPriceRuleSet(Id incentiveId) {

        Apttus_Config2__PriceRuleset__c oPriceRuleSet = new Apttus_Config2__PriceRuleset__c();
        oPriceRuleSet.Apttus_Config2__IncentiveId__c = incentiveId;
        oPriceRuleSet.Apttus_Config2__Sequence__c = 1;

        return oPriceRuleSet;
    }
    /*  create price rule */
    public static Apttus_Config2__PriceRule__c createPriceRule(Id priceRuleSetId) {

        Apttus_Config2__PriceRule__c oPriceRule = new Apttus_Config2__PriceRule__c();
        oPriceRule.Apttus_Config2__RulesetId__c = priceRuleSetId;
        oPriceRule.Apttus_Config2__Sequence__c = 1;

        return oPriceRule;
    }
    /*  create price rule entry */
    public static Apttus_Config2__PriceRuleEntry__c createPriceRuleEntry(Id priceRuleId) {

        Apttus_Config2__PriceRuleEntry__c oPriceRuleEntry = new Apttus_Config2__PriceRuleEntry__c();
        oPriceRuleEntry.Apttus_Config2__PriceRuleId__c = priceRuleId;
        oPriceRuleEntry.Apttus_Config2__Sequence__c = 1;

        return oPriceRuleEntry;
    }
    /*  create sync agreement mapping entry */
    /*
    public static List<APTS_Sync_Agreement_Mapping__c> createSyncAgreementMapping() {

        List<APTS_Sync_Agreement_Mapping__c> listSyncAgreementMapping = new List<APTS_Sync_Agreement_Mapping__c>();

        APTS_Sync_Agreement_Mapping__c oSync_Agreement_Mapping = new APTS_Sync_Agreement_Mapping__c();
        oSync_Agreement_Mapping.Name = 'Default';
        oSync_Agreement_Mapping.APTS_Agreement_Field__c = 'Name,Apttus__Contract_Start_Date__c';
        oSync_Agreement_Mapping.APTS_Proposal_Field__c = 'Apttus_Proposal__Proposal_Name__c,Apttus_Proposal__ExpectedStartDate__c';
        oSync_Agreement_Mapping.APTS_Agreement_Field_one__c = 'APTS_Payer_To__c,Apttus_CMConfig__AutoActivateOrder__c';
        oSync_Agreement_Mapping.APTS_Proposal_Field_one__c = 'Payer_To_APTS_Account_Location_Name__c,Apttus_QPConfig__AutoActivateOrder__c';
        oSync_Agreement_Mapping.APTS_Agreement_Field_two__c = 'Apttus_CMConfig__PaymentTermId__c,Apttus__Special_Terms__c';
        oSync_Agreement_Mapping.APTS_Proposal_Field_two__c = 'Apttus_QPConfig__PaymentTermId__c,Apttus_Proposal__Special_Terms__c';
        listSyncAgreementMapping.add(oSync_Agreement_Mapping);

        APTS_Sync_Agreement_Mapping__c oSync_Agreement_Mapping_two = new APTS_Sync_Agreement_Mapping__c();
        oSync_Agreement_Mapping_two.Name = 'Default two';
        oSync_Agreement_Mapping_two.APTS_Agreement_Field_one__c = 'Apttus__Special_Terms__c,Apttus__Primary_Contact__c';
        oSync_Agreement_Mapping_two.APTS_Proposal_Field_one__c = 'Apttus_Proposal__Special_Terms__c,Apttus_Proposal__Primary_Contact__c';
        oSync_Agreement_Mapping_two.APTS_Agreement_Field_two__c = 'Apttus__Contract_End_Date__c';
        oSync_Agreement_Mapping_two.APTS_Proposal_Field_two__c = 'Apttus_Proposal__ExpectedEndDate__c';
        listSyncAgreementMapping.add(oSync_Agreement_Mapping_two);

        APTS_Sync_Agreement_Mapping__c oSync_Agreement_Mapping_three = new APTS_Sync_Agreement_Mapping__c();
        oSync_Agreement_Mapping_three.Name = 'Default three';
        oSync_Agreement_Mapping_three.APTS_Agreement_Field_two__c = 'Apttus__Contract_End_Date__c';
        oSync_Agreement_Mapping_three.APTS_Proposal_Field_two__c = 'Apttus_Proposal__ExpectedEndDate__c';
        listSyncAgreementMapping.add(oSync_Agreement_Mapping_three);

        return listSyncAgreementMapping;
    }
    */
    /*  create sync order mapping entry */
    /*
    public static List<APTS_Sync_Order_Mapping__c> createSyncOrderMapping() {

        List<APTS_Sync_Order_Mapping__c> listSyncOrderMapping = new List<APTS_Sync_Order_Mapping__c>();

        APTS_Sync_Order_Mapping__c oSync_Order_Mapping = new APTS_Sync_Order_Mapping__c();
        oSync_Order_Mapping.Name = 'Default';
        oSync_Order_Mapping.APTS_Agreement_Field__c = 'Name';
        oSync_Order_Mapping.APTS_Order_Field__c = 'APTS_Name__c';
        oSync_Order_Mapping.APTS_Agreement_Field_one__c = 'Apttus_CMConfig__PONumber__c';
        oSync_Order_Mapping.APTS_Order_Field_one__c = 'Apttus_Config2__PONumber__c';
        oSync_Order_Mapping.APTS_Agreement_Field_two__c = 'Apttus__Description__c';
        oSync_Order_Mapping.APTS_Order_Field_two__c = 'Apttus_Config2__Description__c';
        listSyncOrderMapping.add(oSync_Order_Mapping);

        APTS_Sync_Order_Mapping__c oSync_Order_Mapping_two = new APTS_Sync_Order_Mapping__c();
        oSync_Order_Mapping_two.Name = 'Default two';
        oSync_Order_Mapping_two.APTS_Agreement_Field_one__c = 'Apttus__Contract_Start_Date__c';
        oSync_Order_Mapping_two.APTS_Order_Field_one__c = 'Apttus_Config2__OrderStartDate__c';
        oSync_Order_Mapping_two.APTS_Agreement_Field_two__c = 'Apttus__Contract_End_Date__c';
        oSync_Order_Mapping_two.APTS_Order_Field_two__c = 'Apttus_Config2__OrderEndDate__c';
        listSyncOrderMapping.add(oSync_Order_Mapping_two);

        APTS_Sync_Order_Mapping__c oSync_Order_Mapping_three = new APTS_Sync_Order_Mapping__c();
        oSync_Order_Mapping_three.Name = 'Default three';
        oSync_Order_Mapping_three.APTS_Agreement_Field_two__c = 'Apttus__Contract_End_Date__c';
        oSync_Order_Mapping_three.APTS_Order_Field_two__c = 'Apttus_Config2__OrderEndDate__c';
        listSyncOrderMapping.add(oSync_Order_Mapping_three);

        return listSyncOrderMapping;
    }*/
    /*  create quote volume obligation */
    /*
    public static APTS_QuoteVolumeObligation__c createQuoteVolumeObligation(Id quoteId) {

        APTS_QuoteVolumeObligation__c oQuoteVolumeObligation = new APTS_QuoteVolumeObligation__c();
        oQuoteVolumeObligation.APTS_Quote_Proposal__c = quoteId;
        oQuoteVolumeObligation.APTS_Value_Name__c = 'test quote volume obligation';

        return oQuoteVolumeObligation;
    }*/
    /*  create jde rebate settings */
    /*
    public static APTS_Rebate_JDE_Settings__c createRebateJDESettings(Id incentiveId) {

        APTS_Rebate_JDE_Settings__c oRebateJDESettings = new APTS_Rebate_JDE_Settings__c();
        oRebateJDESettings.Name = 'Default';
        oRebateJDESettings.APTS_Default_Rebate_ID__c = incentiveId;

        return oRebateJDESettings;
    }*/
    /*  create account location */
    public static Apttus_Config2__AccountLocation__c createAccountLocation(Id accountId) {

        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
        acctLoc.Name = 'AL Test Account';
        acctLoc.Apttus_Config2__AccountId__c = accountId;
        acctLoc.Copy_of_Parent_Account__c = true;
        acctLoc.Customer_calendar_key__c = 'SAP_NL';
        acctLoc.Shipping_Address_Validation_Timestamp__c = date.Today();

        return acctLoc;
    }
    //++>>Galin
    //Added by Hari
    /*  create account location */
    public static Apttus_Config2__AccountLocation__c createAccountLocationagreement(Id accountId) {

        Apttus_Config2__AccountLocation__c acctLoc = new Apttus_Config2__AccountLocation__c();
        acctLoc.Name = 'AL Test Account';
        acctLoc.Apttus_Config2__AccountId__c = accountId;
        acctLoc.Copy_of_Parent_Account__c = true;
        acctLoc.Customer_calendar_key__c = 'SAP_NL';
        acctLoc.Shipping_Address_Validation_Timestamp__c = date.Today();
        acctLoc.Apttus_Config2__IsDefault__c = True;

        return acctLoc;
    }

    //Added By Santosh
    /*  create payment term entry */
    public static Apttus_Config2__PaymentTerm__c createPaymentterm(String name, String termid) {

        Apttus_Config2__PaymentTerm__c oPaymentterm = new Apttus_Config2__PaymentTerm__c();
        oPaymentterm.Name = name;
        oPaymentterm.Apttus_Config2__Sequence__c = 1;
        oPaymentterm.Apttus_Config2__Label__c = 'Due Upon Receipt';
        oPaymentterm.Apttus_Config2__Value__c = 10;
        oPaymentterm.Apttus_Config2__OffsetType__c = 'Day';
        oPaymentterm.Apttus_Config2__StartType__c = 'Invoice Date';
        //oPaymentterm.Payment_Term_ID__c = termid;

        return oPaymentterm;
    }

    /*  create TemplateCustomization custom setting */
    /*
    public static APTS_TemplateCustomization__c createTemplateCS(String name, boolean isactive, String objname, String fields, String orcondition, String andcondition) {
        APTS_TemplateCustomization__c oCustSetting = new APTS_TemplateCustomization__c();
        oCustSetting.Name = name;
        oCustSetting.APTS_IsActive__c = isactive;
        oCustSetting.APTS_ObjectName__c = objname;
        oCustSetting.APTS_Fields__c = fields;
        oCustSetting.APTS_OrCondition__c = orcondition;
        oCustSetting.APTS_AndCondition__c = andcondition;

        return oCustSetting;
    }

    public static Indexation__c createIndexation(Id quoteid, String category) {
        Indexation__c oIndex = new Indexation__c();
        oIndex.Indexation__c = quoteid;
        oIndex.Category__c = category;
        oIndex.APTS_Indexation_Start_Date__c = date.Today();

        return oIndex;
    }*/

    //Added by Santosh 
    public static Integration_Log__c createIntegrationlog(String objectstr, String status) {
        Integration_Log__c oInteglog = new Integration_Log__c();
        oInteglog.Object__c = objectstr;
        oInteglog.Object_Id__c = '123dfsdfsdf';
        oInteglog.Integration_Status__c = status;
        oInteglog.Triggered_Timestamp__c = Datetime.now();
        return oInteglog;
    }

    public static APTS_Index_Country_Defaulted_Values__c createcountrydefaultvalues(String Country, String Category) {
        APTS_Index_Country_Defaulted_Values__c ocountrydefval = new APTS_Index_Country_Defaulted_Values__c();
        ocountrydefval.APTS_Start_Date__c = date.Today().addMonths(-120);
        ocountrydefval.APTS_Indexation_Number__c = 'Big Mac';
        ocountrydefval.APTS_Frequency__c='Half-Yearly';
        ocountrydefval.APTS_Country__c = Country;
        ocountrydefval.APTS_Maximum_Bandwidth__c = 10;
        ocountrydefval.APTS_Additional_Conditions__c = 'Test Conditions';
        ocountrydefval.APTS_Communication_Deadline__c = '1';
        ocountrydefval.APTS_Communication_Needed__c = true;
        ocountrydefval.APTS_Default_Category__c = Category;
        ocountrydefval.APTS_Default_Indexation_Type__c = 'Standard Indexation';
        return ocountrydefval;
    } 

    public static APTS_Index_Contract__c createindexcontract(Apttus__APTS_Agreement__c testAgreement, String indextype, String category) {
        APTS_Index_Contract__c oindexcontract = new APTS_Index_Contract__c();
        oindexcontract.APTS_Index_Type__c = indextype;
        oindexcontract.APTS_Indexation_Category__c = category;
        oindexcontract.APTS_Contract__c = testAgreement.Id;
        oindexcontract.APTS_Communication_Needed__c = true;
        oindexcontract.APTS_Communication_Deadline__c = '1';
        oindexcontract.APTS_Start_Date__c = date.Today().addMonths(-120);
        oindexcontract.APTS_Frequency__c = 'Half-Yearly';
        return oindexcontract;
    }

   /* public static APTS_Indexation_Executing__c createIndexExecute(String category, String oAggId, String country) {

        APTS_Indexation_Executing__c oindexexecute = new APTS_Indexation_Executing__c();
        oindexexecute.APTS_Execution_Date__c = date.Today().addMonths(-10);
        oindexexecute.APTS_Indexation_Category__c = category;
        oindexexecute.APTS_Indexation_Country__c = country;
        oindexexecute.APTS_Indexation_Number__c = 2;
        if(oAggId != null){
            oindexexecute.APTS_Indexation_Contract__c = oAggId;
        }
        return oindexexecute;
    } */   

    //End of code -- Santosh

     public static Account createaccount()
     {
     Account acc = new Account();
     //acc.recordtypeid =Schema.SObjecttype.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();         
     acc.Name='Test account';
     acc.Main_Street_Only__c='test address';
     acc.Main_House_Number__c='test number 1';
     acc.Main_Postal_Code__c='635109';
     acc.Main_City__c='chicago';
     acc.Phone='+652314596';
     acc.Account_Tier__c='Gold';
     acc.Segment__c='SAP_A';
     acc.Account_Type__c='Prospect';
     acc.Language__c='SAP_NL';
     APTS_Payment_Method__c pm = APTS_TestUtils.paymentMethod();
        insert pm;  
       acc.APTS_Payment_Method__c = pm.id; 
       
     //acc.CurrencyIsoCode='USD - U.S.DOLLAR';
     return acc;
     }
    
    /*added by nirmal*/
    public static List<Apttus__APTS_Agreement__c>autorenewagr(integer i)
    {
         List<Apttus__APTS_Agreement__c> aggrlist = new List<Apttus__APTS_Agreement__c>();
         Account acc = new Account();
         acc.Name='Test account';
             acc.Main_Street_Only__c='test address';
             acc.Main_House_Number__c='test number 1';
             acc.Main_Postal_Code__c='635109';
             acc.Main_City__c='chicago';
             acc.Phone='+652314596';
             acc.Account_Tier__c='Gold';
             acc.Segment__c='Education';
             acc.Account_Type__c='Prospect';
             acc.CurrencyIsoCode='USD - U.S.DOLLAR';
         
         for(integer x=0;x<i;x++)
         {
         Apttus__APTS_Agreement__c aggr =new Apttus__APTS_Agreement__c();
         aggr.Name='test';
         aggr.Apttus__Account__c=acc.Id;
         aggr.CurrencyIsoCode='eur -EURO';
         aggrlist.add(aggr);
         }
     return (aggrlist);
    }


    /* START: added by Balashanthi for Credit Memo Creation*/
    public static Apttus_Billing__CreditMemo__c createCreditMemo(Id accountId, Id invoiceId,id locationId,id caseId)
    {
        Apttus_Billing__CreditMemo__c creditMemo = new Apttus_Billing__CreditMemo__c();
        creditMemo.Apttus_Billing__BillToAccountId__c = accountId;
        creditMemo.Apttus_Billing__InvoiceID__c = invoiceId;
        creditMemo.Apttus_Billing__Description__c = 'TEST CREDIT MEMO';
        creditMemo.CurrencyIsoCode = 'EUR';
        creditMemo.Apttus_Billing__LocationId__c = locationId;
        creditMemo.Apttus_Billing__CreditMemoDate__c = date.Today();
        creditMemo.Apttus_Billing__CreditAmount__c = 50;
        creditMemo.Apttus_Billing__ReasonCode__c = 'X00';
        creditMemo.Apttus_Billing__Status__c = 'Draft';
        creditMemo.Case__c = caseId;
        return (creditMemo);
    }

    public static Apttus_Billing__Invoice__c createInvoice(Id accountId)
    {
        Apttus_Billing__Invoice__c invoice = new Apttus_Billing__Invoice__c();
        invoice.APTS_External_Invoice_Number__c = '12345';
        invoice.Apttus_Billing__TotalInvoiceAmount__c = 100;
        invoice.CurrencyIsoCode = 'EUR';
        invoice.Apttus_Billing__Type__c = 'Standard';
        invoice.Apttus_Billing__Status__c = 'Draft';
        invoice.Apttus_Billing__SoldToAccountId__c = accountId;
        return (invoice);
    }

    public static Case createcase(Id accountId)
    {
        Case caseData = new Case();
        caseData.AccountId = accountId;
        caseData.CurrencyIsoCode = 'EUR';
        caseData.Type = 'Complaint';
        caseData.Status = 'New';        
        return (caseData);
    }

    public static Apttus_Billing__CreditMemoLineItem__c createcreditMemoLineItem(Id creditMemoId, Id productId)
    {
        Apttus_Billing__CreditMemoLineItem__c creditMemoLineItem = new Apttus_Billing__CreditMemoLineItem__c();
        creditMemoLineItem.Apttus_Billing__CreditMemoId__c = creditMemoId;
        creditMemoLineItem.CurrencyIsoCode = 'EUR';
        creditMemoLineItem.Apttus_Billing__Description__c = 'Test Credit Memo Line Item';
        creditMemoLineItem.APTS_Product__c = productId;
        creditMemoLineItem.Apttus_Billing__Amount__c = 100;
        creditMemoLineItem.Apttus_Billing__Status__c = 'Draft';     
        creditMemoLineItem.Apttus_Billing__Quantity__c = 10;
        return (creditMemoLineItem);
    }
    public static Apttus_Billing__InvoiceLineItem__c createInvoiceLineItem(Id invoiceId)
    {
        Apttus_Billing__InvoiceLineItem__c invoiceLineItem = new Apttus_Billing__InvoiceLineItem__c();
        invoiceLineItem.APTS_External_Invoice_Line_Number__c = '12345';
        invoiceLineItem.CurrencyIsoCode = 'EUR';
        invoiceLineItem.Apttus_Billing__InvoiceId__c = invoiceId;
        return (invoiceLineItem);
    }
    /* END: added by Balashanthi for Credit Memo Creation*/
    public static PhysicalAsset__c createPhysicalAsset()
    {
    PhysicalAsset__c phyasset= new PhysicalAsset__c ();
    phyasset.SerialNumber__c='01232345';
    phyasset.Name='test';
    return phyasset;
    }
    /* START: added by Balashanthi for Payment Method & Payment Term Creation*/
    public static APTS_Payment_Method__c paymentMethod()
    {
        APTS_Payment_Method__c paymentMethod = new APTS_Payment_Method__c();
        paymentMethod.APTS_Company_Code2__c ='JDE PRO BE BVBA';
        paymentMethod.APTS_Country_Code__c ='BE';
        paymentMethod.APTS_Ext_ID__c ='SAP_02022'+String.valueOf(Math.random()*100);
        paymentMethod.APTS_Payment_Method_Code__c ='2';
        return(paymentMethod);
    }

    public static Apttus_Config2__PaymentTerm__c paymentTerm()
    {
        Apttus_Config2__PaymentTerm__c paymentTerm = new Apttus_Config2__PaymentTerm__c();
        paymentTerm.Name ='BE - Net 8 Days';
        paymentTerm.Apttus_Config2__OffsetType__c ='Day';
        paymentTerm.Apttus_Config2__OffsetOccurrence__c = 8;
        paymentTerm.Apttus_Config2__StartType__c ='Invoice Date';
        paymentTerm.APTS_Ext_ID__c ='SAP_2310';
        //paymentTerm.APTS_Sales_Org__c ='SAP_0111';
        return(paymentTerm);
    }
    // Create Billing Setting
    public static APTS_Billing_Settings__c createBillingSetting(Id agreementId,Id accountId,Id billPref,Id paymentMthod, Id paymentTerm)
    {
        APTS_Billing_Settings__c billingSetting = new APTS_Billing_Settings__c();
        billingSetting.APTS_Agreement_ID__c = agreementId;
        billingSetting.APTS_Billing_Preference_Setting__c = billPref;
        billingSetting.APTS_Billing_Rule_Contract__c = 'Bill in Advance';
        billingSetting.APTS_Bill_To_ID__c = accountId;
        billingSetting.APTS_Invoice_Delivery_Preference__c ='Paper';
        billingSetting.APTS_Invoice_Type__c ='Single Invoice';
        billingSetting.APTS_Payment_Method__c = paymentMthod;
        billingSetting.APTS_Payment_Term_Setting__c = paymentTerm;
        return(billingSetting);
    } 

    /* END: added by Balashanthi for Payment Method & Payment Term Creation*/
    
    // Create Volume Obligation
    public static APTS_AgreementTotalVolumeObligation__c createTotalAgreementVolumeObligation(Id agreementId)
    {
        APTS_AgreementTotalVolumeObligation__c volObligation = new APTS_AgreementTotalVolumeObligation__c();
        volObligation.APTS_Agreement__c=agreementId;
        return volObligation;
    }

    //Added by santosh
    public static Contracted_kpi_sla__c getcontractkpisla(Id agreementId, String frequency, String stype, Decimal panality) {
        Contracted_kpi_sla__c conkipsla = new Contracted_kpi_sla__c();
        conkipsla.kpi_contract__c = agreementId;
        conkipsla.kpi_frequency__c = frequency;
        conkipsla.KPI_type__c = stype;
        conkipsla.KPI_Penalty__c = panality;
        return conkipsla;
    }

    public static APTS_RebateDefiniation__c getrebate(Id agreementId, String rebname, String tiertype, String metrictype, String description) {
        APTS_RebateDefiniation__c orebdef = new APTS_RebateDefiniation__c();
        orebdef.APTS_Agreement__c = agreementId;
        orebdef.Name = rebname;
        /*orebdef.APTS_RebateTableTierType__c = tiertype;
        orebdef.APTS_TierMetricType__c = metrictype;
        orebdef.APTS_Description__c = description;*/
        return orebdef;
    }

    public static APTS_Indexation_Executing__c getIndexExec(Id recordId, string category, Id agreementId, string country) {
        APTS_Indexation_Executing__c oIndexex = new APTS_Indexation_Executing__c();
        oIndexex.RecordTypeId = recordId;
        oIndexex.APTS_Execution_Date__c = date.Today().addDays(2);
        oIndexex.APTS_Indexation_Category__c = category;
        oIndexex.APTS_Indexation_Number__c = 3.0;
        if(agreementId != null) {
            oIndexex.APTS_Indexation_Contract__c = agreementId;
        }
        if(country != null) {
            oIndexex.APTS_Indexation_Country__c = country;
        }
        return oIndexex;
    }

    
    //End of code santosh
}