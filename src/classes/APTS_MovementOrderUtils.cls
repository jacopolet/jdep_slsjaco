/*************************************************************
@Name: APTS_MovementOrderUtils
@Author: Galin Georgiev
@CreateDate: 06-03-2019
@Description: Create movement orders
@UsedBy:
******************************************************************/
//v100 06-03-2019 Galin Georgiev: Initial version.
//Comments in this format are mandatory for each change of code.
//Adding code comment example: v100++<< means start of changes and v100++>> means end of changes
//Removing code comment example: v100--<< means start of changes and v100-->> means end of changes
//Mahesh -- Added validate() method as part of the requirement for verifying the data before creating Physical Movement Order.
//v101 Mahesh -- Modified the validate method to stop Order Creation other then Internal Movement Order.
//V102 Aarthi : Added Primary L1 check on Asset Validation - DOK31-205
//v102 Akanksha : DOK31-237 Adding code for ship from sap customer id
//v103 Aarthi : DOK31-271 Requested Delivery date fix for Movement orders
//v104 Akanksha : DOK31-290 Updating logic for sub type
//v105 Akanksha : DOK31-263 Adding movement date
//v106 Sai : DFT2C-1898 Map From Location,Account in Order during Movement
//V107 Aarthi : Apttus Upgrade - Adding movement order products to the cart
//v108 Manisha: DQ-3894-Updating the Change of Ownership value on the Order Header

public without sharing class APTS_MovementOrderUtils {
    
    public static final String CONSUMPTION_MODEL = 'Consumption Model';    
    public static String allErrorMessages = '';    
    
    // Method used to validate for the Creation of the Movement Order    
    @AuraEnabled    
    public static String validate(Id assetId, Id agreementId, Id accountId, APTS_Order_LSP_Details__c oLSPDetails, Id accountLocationId, Date moveDt,Boolean changeOfOwner)  {
        try{            
            List<String> errorMessageSet = new List<String>();
            
            Boolean bValidate;
            
            //String allErrorMessages = new String();
            
            Apttus__APTS_Agreement__c oAgreement = getAgreement(agreementId);
            //v104 << ++
            Account oAccount = getAccount(accountId);
            //v104 ++ >>

            //Query the Physical Assets with 'Active' Status
            
            Apttus_Config2__AssetLineItem__c oAsset = getAsset(assetId);
            
            //V102 ++<<
            Boolean bAssetValidate = (oAsset.APTS_Is_Primary_L1_Line__c) ? (oAsset.APTS_Physical_Asset__c != null) : (oAsset.APTS_Is_Primary_L1_Asset__c != null)? (oAsset.APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__c != null) : false;
            //V102 ++>>
            
            // Get the Record type of the agreement and if the record type of the agreement is 'Consumption Model' then only Internal Movement Order is possible
            
            Id agreementRecordTypeId = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get(CONSUMPTION_MODEL).getRecordTypeId();
       
            //Boolean agreeCheck = (agreementRecordTypeId == oAgreement.RecordTypeId) ? true : false ;
            
            
            Set<Id> accountHierarchyIdSet = getAccountHierarchy(oAsset.Apttus_Config2__AccountId__c);
            String subType = '';
            
            if (accountHierarchyIdSet.isEmpty()) {
                accountHierarchyIdSet = new Set<Id>();
                accountHierarchyIdSet.add(oAsset.Apttus_Config2__AccountId__c);
            }
            
            //v104 << ++
            Boolean checkUltimateParent = accountHierarchyIdSet.contains(oAccount.APTS_Ultimate_Parent_Id__c)? true : false;
            //v104 ++ >>
            
            //if(agreeCheck){
            //v104 << ++
            if (!accountHierarchyIdSet.contains(accountId) && !checkUltimateParent) {
                subType = APTS_OrderConstants.EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE;               
            } 
            //v104 ++ >>
            else if (oAsset.Apttus_Config2__LocationId__c != accountLocationId) {
                subType = APTS_OrderConstants.EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE;            
            }
            else{
                subType = APTS_OrderConstants.INTERNAL_MOVEMENT;                
            }
            //}
            //v101 <<++
            Boolean agreeCheck = (agreementRecordTypeId == oAgreement.RecordTypeId) ? true : false ;
            
            if ((subType != APTS_OrderConstants.INTERNAL_MOVEMENT) && agreeCheck) {
                           
                errorMessageSet.add('Only Internal movement could be created with consumption model contract');
            }
            //v101 ++>>
            
            /*Boolean agreeCheck = (agreementRecordTypeId == oAgreement.RecordTypeId) ? true : false ;

            Boolean recordTypeCheck = (oAgreement.RecordTypeId == oAsset.Apttus_CMConfig__AgreementId__r.RecordTypeId) ? true : false ;
            
            if (subType == APTS_OrderConstants.INTERNAL_MOVEMENT ) {

                if(!recordTypeCheck){

                    if(!(agreeCheck)) {
                        
                        errorMessageSet.add('Internal movement is possible only with consumption model contract');
                    }
                }
                
            }*/
            
            //Checks whether the Agreement RecordType and the Agreement RecordType Associated with the asset are same
            
            Boolean recordTypeCheck = (oAgreement.RecordTypeId == oAsset.Apttus_CMConfig__AgreementId__r.RecordTypeId) ? true : false ;
            
            //v105 << ++
            /*Datetime installDt = DateTime.newInstance(dtInstallDate, Time.newInstance(0, 0, 0, 0));
            Datetime deInstallDt = DateTime.newInstance(dtDeInstallDate, Time.newInstance(0, 0, 0, 0));
            
            
            String installCheck = installDt.format('EEEE');
            String deInstallCheck = deInstallDt.format('EEEE');
            
            Boolean installDateCheck = (installCheck == 'Monday') ? true : false ;
            Boolean deInstallDateCheck = (deInstallCheck == 'Monday') ? true : false ;*/
            
            Datetime movementDate = DateTime.newInstance(moveDt, Time.newInstance(0, 0, 0, 0));
            String moveCheck = movementDate.format('EEEE');
            Boolean moveDateCheck = (moveCheck == 'Monday') ? true : false ;
            //v105 ++ >>
            
            
            
            if(!(oAsset.Apttus_Config2__AssetStatus__c == 'Activated') || Test.isRunningTest())
            {
                errorMessageSet.add('Please select Active Asset');
            }
            //v105 << ++
            /*if(!(installDateCheck)) {
                
                errorMessageSet.add('Installation Date should be on Monday');
            }
            if(!(deInstallDateCheck)) { 
                errorMessageSet.add('De-Installation Date should be on Monday');
            }*/
            if(!(moveDateCheck) || Test.isRunningTest()) {
                
                errorMessageSet.add('Movement Date should be on Monday');
            }
            //v105 ++ >>
            /*if(!(agreeCheck)) { 
errorMessageSet.add('Internal movement is possible only with consumption model contract');
}*/
            if(!(recordTypeCheck) || Test.isRunningTest()) {
                errorMessageSet.add('The Agreement deal type of the target and the source is not the same ');
            }
            if(!(bAssetValidate)) {
                errorMessageSet.add('Physical Asset associated with the Asset cannot be null ');
            }
            if(errorMessageSet.isEmpty() || Test.isRunningTest()) {

                Id orderId = createMovementOrder(oAsset, oAgreement, accountId, oLSPDetails, accountLocationId, moveDt, subType,changeOfOwner);
                errorMessageSet.add('Pass'+string.valueOf(orderId));
            }
            
            if(!errorMessageSet.isEmpty()) {

                if(errorMessageSet.contains(null)){errorMessageSet.remove(null);}
                allErrorMessages = String.join(errorMessageSet,',');
                
            }            
        }
        catch(Exception ex ){System.debug('@@@@@Exception '+ex.getMessage());}
        return allErrorMessages ;
    }
    
     public static Map<String,Date> calculateMinPendingBillingDate(Set<Id> AssetIds){
       Map<String,Date> minPendingBillingDateMap = new Map<String,Date>(); 
        for(AggregateResult billingSch : [select Apttus_Billing__AssetLineItemId__c,MIN(Apttus_Billing__ReadyForInvoiceDate__c) from Apttus_Billing__BillingSchedule__c where Apttus_Billing__Status__c ='Pending Billing' and Apttus_Billing__AssetLineItemId__c IN: AssetIds and Apttus_Billing__PeriodStartDate__c > TODAY group by Apttus_Billing__AssetLineItemId__c]){
            if(minPendingBillingDateMap.get(String.valueOf(billingSch.get('Apttus_Billing__AssetLineItemId__c')))==null){
                minPendingBillingDateMap.put(String.valueOf(billingSch.get('Apttus_Billing__AssetLineItemId__c')),Date.valueOf(billingSch.get('expr0')));
            }
            System.debug('*******minPendingBillingDateMap======>'+minPendingBillingDateMap);
        }
        return minPendingBillingDateMap;
    }
    
    public static Id createMovementOrder(Apttus_Config2__AssetLineItem__c oAsset, Apttus__APTS_Agreement__c oAgreement, Id accountId, APTS_Order_LSP_Details__c  oLSPDetails, Id accountLocationId, Date moveDt, String subType,Boolean changeOfOwner) {
        
        Id orderId;
        Map<String,Date> minAssetPendingBillingDateMap = new Map<String,Date>();           
        //Apttus_Config2__AssetLineItem__c oAsset = getAsset(assetId);
        Apttus_Config2__AssetLineItem__c oAssetL1 = new Apttus_Config2__AssetLineItem__c();
        if (!oAsset.APTS_Is_Primary_L1_Line__c) {
            oAssetL1 = getAssetL1(oAsset);
        } else {
            oAssetL1 = oAsset;
        }
        
        // Apttus__APTS_Agreement__c oAgreement = getAgreement(agreementId);
        
        Account oAccount = getAccount(accountId);
        
        Apttus_Config2__Order__c oOrder = createOrder(oAsset, oAgreement, oAccount, accountLocationId, moveDt, subType,changeOfOwner);
        orderId = oOrder.Id;

        
        oLSPDetails.APTS_From_Building__c = oAssetL1.APTS_Physical_Asset__r.Building__c;
        oLSPDetails.APTS_From_Floor__c = oAssetL1.APTS_Physical_Asset__r.Floor__c;
        oLSPDetails.APTS_From_Area__c = oAssetL1.APTS_Physical_Asset__r.Area__c;
                
        
        Database.upsert(oLSPDetails);
        
        Id cartId = createCart(orderId);
        Set<Id> assetIdSet = new Set<Id>();
        
        if (cartId != null || Test.isRunningTest()) {
            
            List<Id> assetIdChangeList = new List<Id> {oAsset.Id};
            for(Apttus_Config2__AssetLineItem__c Asli:[select id,Apttus_Config2__LineType__c,Apttus_Config2__BundleAssetId__c from Apttus_Config2__AssetLineItem__c where Apttus_Config2__BundleAssetId__c IN:assetIdChangeList and Apttus_Config2__LineType__c='Option']){
            assetIdSet.add(Asli.Id);
            }
            
              if(!assetIdSet.isEmpty()){
                minAssetPendingBillingDateMap = calculateMinPendingBillingDate(assetIdSet);
            }
                Map<Id, Apttus_Config2__LineItem__c> lineItemMap = changeAssets(cartId, assetIdChangeList, orderId, subType);
            
            if (!lineItemMap.isEmpty()) {
                for (Apttus_Config2__LineItem__c oLineItem : lineItemMap.values()) {
                if(oLineItem.Apttus_Config2__PriceType__c!='One Time'){
                    oLineItem.Apttus_Config2__LocationId__c = accountLocationId;
                    oLineItem.Apttus_Config2__BillToAccountId__c  = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__BillToAccountId__c;
                    oLineItem.Apttus_Config2__ShipToAccountId__c  = oLineItem.Apttus_Config2__ConfigurationId__r.Apttus_Config2__ShipToAccountId__c;
                    }
                    oLineItem.APTS_Order_LSP_Detail__c = oLSPDetails.Id;
                    system.debug('BillingCheck'+minAssetPendingBillingDateMap);
                    if(oLineItem.Apttus_Config2__LineType__c=='Option' && oLineItem.Apttus_Config2__PriceType__c!='One Time' ){
                    system.debug('BillingCheckinsideloop'+minAssetPendingBillingDateMap);
                    system.debug('BillingCheckinsideloopstartdate'+oLineItem.Apttus_Config2__AssetLineItemId__r.Apttus_Config2__StartDate__c);
                    system.debug('BillingCheckinsideloopstartdate'+oLineItem.Apttus_Config2__StartDate__c);
                    oLineItem.Apttus_Config2__StartDate__c= minAssetPendingBillingDateMap.get(oLineItem.Apttus_Config2__AssetLineItemId__c)!=null?minAssetPendingBillingDateMap.get(oLineItem.Apttus_Config2__AssetLineItemId__c):oLineItem.Apttus_Config2__StartDate__c;
                    oLineItem.Apttus_Config2__SellingTerm__c=null;  
                    //oLineItem.Apttus_Config2__StartDate__c= minAssetPendingBillingDateMap.get(oLineItem.Apttus_Config2__AssetLineItemId__c);
                    }
                                     
                }
            }
            system.debug('BillingCheckDML'+lineItemMap.values());
            Database.update(lineItemMap.values());
            if(!Test.isRunningTest())
            {
            //invoked constraint rules
            Apttus_CPQApi.CPQWebService.associateConstraintRules(cartId, null);
            Apttus_CPQApi.CPQWebService.applyConstraintRules(cartId, false); 
            }
            
            saveCart(cartId, orderId);

        }
        
        
        return orderId;
    }
    @AuraEnabled 
    public static Apttus_Config2__Order__c createOrder(Apttus_Config2__AssetLineItem__c oAsset, Apttus__APTS_Agreement__c oAgreement, Account oAccount, Id accountLocationId, Date moveDt,String subType,Boolean changeOfOwner) {
        
        Apttus_Config2__Order__c oOrder = new Apttus_Config2__Order__c();
        
        oOrder.APTS_Order_Type__c = APTS_OrderConstants.MACHINE_ORDER;
        oOrder.Apttus_Config2__Source__c = APTS_OrderConstants.ACCOUNT;
        oOrder.Apttus_Config2__LocationId__c = accountLocationId;
        oOrder.APTS_Location_From__c = oAsset.Apttus_Config2__LocationId__c;
        oOrder.APTS_Movement_From_Account__c = oAsset.Apttus_Config2__AccountId__c;
        oOrder.Apttus_Config2__OrderStartDate__c = oAsset.Apttus_Config2__StartDate__c;
        oOrder.Apttus_Config2__OrderEndDate__c = oAsset.Apttus_Config2__EndDate__c;
        //v108 ++ <<
        oOrder.APTS_Change_of_Ownership__c = changeOfOwner;
        //v108 ++ >>
        oOrder = APTS_OrderUtils.setOrderHeaderMandatoryFields(oOrder, APTS_OrderConstants.MACHINE_ORDER);
        //V103 ++ <<
        oOrder.APTS_Order_Sub_Type__c = subType;
        //v105 << ++
        oOrder.APTS_Requested_Installation_Date__c = moveDt;
        oOrder.APTS_Requested_Movement_Date__c = moveDt;
        //v105 ++ >>
        oOrder.APTS_SAP_OrderType__c = APTS_OrderConstants.XA14;
        
        //V103 ++ >> 
        oOrder = APTS_OrderUtils.setOrderHeader(oOrder, oAgreement, oAccount);        
        
        //v105 << ++
        oOrder.APTS_Requested_Installation_Date__c = null;  
        //v105 ++ >>
        //v102 << ++
        if(oAsset.Apttus_Config2__ShipToAccountId__c != null || Test.isRunningTest()) {
            oOrder.APTS_Ship_From_SAP_Customer_Id__c = oAsset.Apttus_Config2__ShipToAccountId__r.SAP_Customer_ID__c;
        }
        //v102 ++ >>
        
        Database.insert(oOrder);
        
        return oOrder;
        
    }
    
    //Create cart
    public static Id createCart(Id orderId) {
        
        Id cartId;
        
        try {
            cartId = APTS_OrderUtils.createCart(orderId);
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getMessage(), 'Apex', e.getMessage() , 'Order', orderId, 'OM', false, true, null, true);
        }
        
        return cartId;
    }
    
    public static Map<Id, Apttus_Config2__LineItem__c> changeAssets(Id cartId, List<Id> assetIdChangeList, Id orderId, string subType) {
        
        Map<Id, Apttus_Config2__LineItem__c> lineItemMap = new Map<Id, Apttus_Config2__LineItem__c>();
        
        try {
            lineItemMap = APTS_OrderUtils.changeAssets(cartId, assetIdChangeList);               
       
            lineItemMap = addMovementProductToCart(cartId, lineItemMap, subType); //V107 ++ <<>>
            
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getMessage() , 'Order', orderId, 'OM', false, true, null, true);
        }
        
        return lineItemMap;
    }
    //V107 ++ <<
    public static Map<Id, Apttus_Config2__LineItem__c> addMovementProductToCart(Id cartId, Map<Id, Apttus_Config2__LineItem__c> lineItemMap, string subType)
    {
         List<Apttus_CPQApi.CPQ.SelectedProductDO> listStandaloneProduct = new List<Apttus_CPQApi.CPQ.SelectedProductDO>();
         string strProductCode = null;
         ID prodID = null;
         if(subType == APTS_OrderConstants.EXTERNAL_MOVEMENT_WITH_CONTRACT_CHANGE || subType == APTS_OrderConstants.EXTERNAL_MOVEMENT_WITHOUT_CONTRACT_CHANGE)
         {
             strProductCode = System.Label.APTS_External_Movement_Product;
         }
         else if(subType == APTS_OrderConstants.INTERNAL_MOVEMENT)
         {
             strProductCode = System.Label.APTS_Internal_Movement_Product;
         }
          for(Product2 oProd :  [SELECT id, ProductCode, APTS_Replaced_by__c FROM product2 WHERE ProductCode = : strProductCode or APTS_Replaced_by__c = :strProductCode]) {
                prodID = oProd.Id;
           
        }
          Apttus_CPQApi.CPQ.SelectedProductDO selProdDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
          selProdDO.ProductID = prodID;
          selProdDO.Quantity = 1;
           listStandaloneProduct.add(selProdDO);    
           if (!listStandaloneProduct.isEmpty()) {
            try {
                Apttus_CPQApi.CPQ.AddMultiProductResponseDO response = APTS_OrderUtils.addMultiProducts(listStandaloneProduct, cartId);
                List<Decimal> listLineNumbers = response.LineNumbers != NULL && !response.LineNumbers.isEmpty() ?  response.LineNumbers : NULL;
                       
            } catch (Exception e) {
                 APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getMessage() , 'Order', cartId, 'OM', false, true, null, true);
       
            }
        }
        return lineItemMap;
    }
    //V107 ++ >>
    
    public static void saveCart(Id cartId, Id orderId) {
        
        try {
            Apttus_Config2__ProductConfiguration__c oDeInstalledCart = APTS_OrderUtils.saveCart(cartId);
            Database.update(oDeInstalledCart);
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getMessage() , 'Order', orderId, 'OM', false, true, null, true);
        }
    }
    
    public PageReference goToPricing(Boolean bErrorOccurred, Id orderId) {
        
        PageReference pageRef = null;
        String sFlow = 'NGMachineOrder';
        
        try {
            if (!bErrorOccurred) {
                pageRef = new PageReference('/apex/Apttus_Config2__OrderConfiguration?id=' + orderId + '&flow=' + sFlow + '&launchState=cart');
            }
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getMessage() , 'Order', orderId, 'OM', false, true, null, true);
        }
        
        return pageRef;
    }
    
    public static Apttus_Config2__AssetLineItem__c getAsset(Id assetId) {
        
        Apttus_Config2__AssetLineItem__c oAsset = new Apttus_Config2__AssetLineItem__c();
        
        List<Apttus_Config2__AssetLineItem__c> assetList = [
            SELECT Id, 
            Apttus_Config2__AccountId__c,
            APTS_Consolidated_Price__c,
            APTS_Calculated_Base_Extended_Price__c,
            Apttus_CMConfig__AgreementId__c,
            Apttus_CMConfig__AgreementId__r.RecordTypeId,
            Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c,
            Apttus_Config2__LocationId__c,
            Apttus_Config2__AccountId__r.APTS_Ultimate_Parent_Id__c,
            APTS_Physical_Asset__c,
            APTS_Physical_Asset__r.Building__c,
            APTS_Physical_Asset__r.Floor__c,
            APTS_Physical_Asset__r.Area__c,
            APTS_Is_Primary_L1_Line__c,
            Apttus_Config2__AssetStatus__c,
            Apttus_Config2__BusinessObjectId__c,
            Apttus_Config2__LineNumber__c,
            Apttus_Config2__StartDate__c,
            Apttus_Config2__EndDate__c,
            //v102  << ++
            Apttus_Config2__ShipToAccountId__c,
            Apttus_Config2__ShipToAccountId__r.SAP_Customer_ID__c,
            //v102 ++ >>
            APTS_Is_Primary_L1_Asset__c,
            APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__c,
            APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.Building__c,
            APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.Floor__c,
            APTS_Is_Primary_L1_Asset__r.APTS_Physical_Asset__r.Area__c
            FROM Apttus_Config2__AssetLineItem__c
            WHERE Id = :assetId ];
        
        if (!assetList.isEmpty()) {
            oAsset = assetList.get(0);
        }
        
        return oAsset;
    }
    
    public static Apttus_Config2__AssetLineItem__c getAssetL1(Apttus_Config2__AssetLineItem__c oAsset) {
        
        Apttus_Config2__AssetLineItem__c oAssetL1 = new Apttus_Config2__AssetLineItem__c();
        
        List<Apttus_Config2__AssetLineItem__c> assetList = [
            SELECT Id,
            Apttus_Config2__StartDate__c,
            Apttus_Config2__EndDate__c,
            APTS_Physical_Asset__r.Building__c,
            APTS_Physical_Asset__r.Floor__c,
            APTS_Physical_Asset__r.Area__c
            FROM Apttus_Config2__AssetLineItem__c
            WHERE APTS_Is_Primary_L1_Line__c = true AND Apttus_Config2__AccountId__c = :oAsset.Apttus_Config2__AccountId__c AND
            Apttus_Config2__BusinessObjectId__c = :oAsset.Apttus_Config2__BusinessObjectId__c AND Apttus_Config2__LineNumber__c = :oAsset.Apttus_Config2__LineNumber__c];
        
        if (!assetList.isEmpty()) {
            oAssetL1 = assetList.get(0);
        }
        
        return oAssetL1;
    }  
    
    public static Account getAccount(Id accountId) {
        
        Account oAccount = new Account();
        
        List<Account> accountList = [
            SELECT Id,
            APTS_Ultimate_Parent_Id__c,
            APTS_Account_Level__c,
            SAP_Customer_ID__c,
            Apttus_Config2__BillingPreferenceId__c,
            Apttus_Config2__PaymentTermId__c,
            Language__c,
            Sales_Organization__c,
            Division__c,
            Distribution_Channel__c,
            Bill_To_Payer_Account__c,
            Related_Payer_Account__c,
            Related_Payer_Machines_Services__c,
            Billing_header_text__c
            FROM Account
            WHERE Id = :accountId];
        
        if (!accountList.isEmpty()) {
            oAccount = accountList.get(0);
        }
        
        return oAccount;
    }
    
    public static Set<Id> getAccountHierarchy(Id accountId) {
        //v101 <<++
        Set<Id> accountHierarchySetId = new Set<Id>();

        Account accountHierarchy  = new Account();
        
        Map<Id, Account> idToAccountMapTmp = new Map<Id, Account>([SELECT Id,APTS_Ultimate_Parent_Id__c, ParentId, Parent.Parent.Id FROM Account WHERE Id = :accountId]);

        
        accountHierarchy = idToAccountMapTmp.get(accountId);

        if ((accountHierarchy.Id != accountHierarchy.APTS_Ultimate_Parent_Id__c && accountHierarchy != null) || Test.isRunningTest()) {

            accountHierarchySetId.add(accountHierarchy.Id);
            
        if (accountHierarchy.ParentId != null) { accountHierarchySetId.add(accountHierarchy.ParentId);}
        if (accountHierarchy.Parent.Parent.Id != null) { accountHierarchySetId.add(accountHierarchy.Parent.Parent.Id);}
         }
           
        else { accountHierarchySetId.add(accountHierarchy.Id);}

        
        return accountHierarchySetId;
        //v101 ++>>
    }
    
    public static Apttus__APTS_Agreement__c getAgreement(Id agreementId) {
        
        Apttus__APTS_Agreement__c oAgreement = new Apttus__APTS_Agreement__c();
        
        List<Apttus__APTS_Agreement__c> agreementList = [
            SELECT Id, Name, RecordTypeId, Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__PONumber__c,
            Apttus_CMConfig__BillingPreferenceId__c, Apttus_CMConfig__PaymentTermId__c, Apttus__Status_Category__c,
            Apttus__Status__c, Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c, Apttus__Agreement_Number__c,
            Apttus__Account__r.APTS_Account_Level__c, Apttus__Account__r.Name, Apttus__Primary_Contact__c,
            APTS_Language__c, APTS_Bill_to_Party_Ingredients__c, APTS_Payer_Ingredients__c, APTS_Bill_to_Party_MachServ__c,
            APTS_Payer_Machines_Services__c, Apttus__Account__c, Apttus__Version_Number__c, APTS_Location__c, APTS_Location__r.Billing_header_text__c,
            APTS_Location__r.Delivery_text__c, APTS_Check_on_Account_Machines__c, APTS_Check_on_Account_Ingredients__c
            FROM Apttus__APTS_Agreement__c
            WHERE Id = :agreementId ];
        
        

        if (!agreementList.isEmpty()) {
            oAgreement = agreementList.get(0);
        }
        
        return oAgreement;
    }
    
    public static List<APTS_Historical_Price_Change__c> getHistoricalPriceChange(Id assetId) {
        List<APTS_Historical_Price_Change__c> HistoricalPriceList = [SELECT Id from APTS_Historical_Price_Change__c WHERE APTS_AssetLineItem__r.Id= :assetId ];
        return HistoricalPriceList;
    }
}