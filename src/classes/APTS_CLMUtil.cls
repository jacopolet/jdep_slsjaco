/********************************************************************************************************
This class will contain all the generic code created by CLM Team.
********************************************************************************************************/
//V101 18-Aug-2019 Aarthi - QTCFLEX1-859 - Fix for Null pointer exception on APTS_CLMUtil.calculateAssetBaseExtendedPrice()
//V102 16-Oct-2019 Aarthi - QTCFLEX1 - Fix for the incorrect update on Last related Agreement field during renewal process
//V103 03-JAN-2020 Karan - DFT2C-2174 - Optimizing manageAssetAdjLineItemData method
//V103 27-Mar-2020 Shahul- DQ-1385 - ABO Conversion LAE/RAR
//V104 2-Apr-2020 Karan- DQ-1891 - calculateAssetBaseExtendedPrice method - only LAE/RAR logic to enhance net price change logic and remove assets which are unchanged from the map.
//V105 21-Mar-2020 shahul- DQ-4161 - 004 creation on technical service swap( field added on query)

public without sharing class APTS_CLMUtil{

    public static final String ACTIVATED = 'Activated';
    public static final String IN_EFFECT = 'In Effect';
    private static final String OPTION = System.Label.APTS_Option;
    private static final String ACCOUNT = System.Label.APTS_Account;
    private static final String ADMIN = System.Label.APTS_AdminOrder;
    private static final String XA13 = System.Label.APTS_XA13;
    public static final String EXPIRED = 'Expired';
    public static final String FULLY_SIGNED = 'Fully Signed';
    public static final String PRODUCTSERVICE = 'Product/Service';
    public static final String BILLING_SCHEDULE = 'Billing Schedule';
    //// v1.2 - DFT2C-853 - New static variable added for creating Transaction Data.
    public static boolean isQueueableEnable = false;
    public static boolean isFirstCall = false;
    public static boolean isSecondCall = false;
    public static Map<Id, Apttus_Config2__AssetLineItem__c> newAssetOnFirstCallMap = new Map<Id, Apttus_Config2__AssetLineItem__c>();
    public static Map<Id, Apttus_Config2__AssetLineItem__c> oldMapNetPrice = new Map<Id, Apttus_Config2__AssetLineItem__c>();  
    //// v1.2 - DFT2C-853 
    

    

    public static Map<Id, Apttus_Config2__OrderLineItem__c> OrderLineItemData(Set<Id> orderLineItemIdSet) {

        Map<Id, Apttus_Config2__OrderLineItem__c> idToOrderLineItemMap = new Map<Id, Apttus_Config2__OrderLineItem__c>([
                    SELECT Id, Name, Apttus_Config2__LocationId__c, APTS_Machine_Age__c,
                    APTS_Serial_Number__c, APTS_Goods_Issue_Date__c, APTS_RefurbishedMachine__c,
                    Apttus_Config2__LineType__c,
                    APTS_Physical_Asset__c,
                    Apttus_Config2__ParentBundleNumber__c,
                    Apttus_Config2__LineNumber__c, Apttus_Config2__ChargeType__c,
                    Apttus_Config2__AssetLineItemId__c,
                    Apttus_Config2__AssetLineItemId__r.APTS_RefurbishedMachine__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__StartDate__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__EndDate__c,
                    Apttus_Config2__AssetLineItemId__r.Apttus_Config2__AssetStatus__c,
                    /*Apttus_Config2__AssetLineItemId__r.APTS_Physical_Asset_Id__c,*/
                    Apttus_Config2__AssetLineItemId__r.APTS_Physical_Asset__c,
                    Apttus_CMConfig__AgreementId__c,
                    Apttus_CMConfig__AgreementId__r.RecordType.DeveloperName,
                    Apttus_CMConfig__AgreementId__r.RecordType.Name,
                    Apttus_CMConfig__AgreementId__r.Apttus__Status_Category__c,
                    Apttus_CMConfig__AgreementId__r.Apttus__Status__c,
                    APTS_Order_LSP_Detail__c,
                    APTS_Order_LSP_Detail__r.APTS_Building__c,
                    APTS_Order_LSP_Detail__r.APTS_Floor__c,
                    APTS_Order_LSP_Detail__r.APTS_Area__c,
                    APTS_Order_LSP_Detail__r.APTS_CustomerReference__c,
                    APTS_Order_LSP_Detail__r.APTS_SmokingArea__c,
                    APTS_Order_LSP_Detail__r.APTS_ConfigurationFileURL__c,
                    APTS_Order_LSP_Detail__r.APTS_JDE_crockeryVolumeSize__c,
                    Apttus_Config2__OrderId__c,
                    Apttus_Config2__OrderId__r.Apttus_Config2__PONumber__c,
                    Apttus_Config2__OrderId__r.APTS_Sales_Organization__c,
                    Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c,
                    Apttus_Config2__OrderId__r.APTS_Confirmed_De_Installation_Date__c,
                    Apttus_Config2__OrderId__r.APTS_Confirmed_Installation_Date__c,
                    Apttus_Config2__AttributeValueId__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Number_of_months__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c,
                    Apttus_Config2__AttributeValueId__r.APTS_WTS_Changed_By__c,
                    Apttus_Config2__ProductId__c,
                    Apttus_Config2__ProductId__r.Name,
                    Apttus_Config2__ProductId__r.Description,
                    Apttus_Config2__ProductId__r.ProductCode,
                    Apttus_Config2__ProductId__r.APTS_Material_Type__c,
                    Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,
                    Apttus_Config2__OptionId__c,
                    Apttus_Config2__OptionId__r.Name,
                    Apttus_Config2__OptionId__r.Description,
                    Apttus_Config2__OptionId__r.ProductCode,
                    Apttus_Config2__OptionId__r.APTS_Material_Type__c,
                    Apttus_Config2__ShipToAccountId__c,
                    Apttus_Config2__ShipToAccountId__r.ShippingCountry,
                    Apttus_Config2__ShipToAccountId__r.WSONE_DATA__ShippingAddressCountryISO__c,
                    Apttus_Config2__ShipToAccountId__r.ShippingPostalCode,
                    Apttus_Config2__ShipToAccountId__r.ShippingStreet,
                    Apttus_Config2__ShipToAccountId__r.WSONE_DATA__ShippingAddressHouseNumber__c,
                    Apttus_Config2__ShipToAccountId__r.ShippingCity,
                    Apttus_Config2__HasOptions__c 
                    FROM Apttus_Config2__OrderLineItem__c
                    WHERE Id IN :orderLineItemIdSet]);

        return idToOrderLineItemMap;
    }

    public static void populateURL(List<Apttus__APTS_Agreement__c> newList, Map<Id, Apttus__APTS_Agreement__c> mapAgreements,
                            List<Apttus__APTS_Agreement__c> oldList, Map<Id, Apttus__APTS_Agreement__c> mapOldAgreements){


        List<Apttus__AgreementLineItem__c> lstAggrLineItemUpdate = new List<Apttus__AgreementLineItem__c>();
        Set<Id> setAggrId = new Set<Id>();
        List<Apttus__AgreementLineItem__c> lstALI = new List<Apttus__AgreementLineItem__c>();
        Map<String, String> mapKeyToURL = new Map<String, String>();
        List<String> lstOption = new List<String>();
        List<String> lstCupSize = new List<String>();
        List<String> lstTastePallet = new List<String>();
        List<String> lstProduct = new List<String>();

        for(Apttus__APTS_Agreement__c s : newList){
            
            if(mapOldAgreements.get(s.Id).Apttus_CMConfig__ConfigurationFinalizedDate__c != mapAgreements.get(s.Id).Apttus_CMConfig__ConfigurationFinalizedDate__c){
                setAggrId.add(s.Id);
            }
        }
        
        if(setAggrId.size()>0){

            lstALI = [SELECT Id, Apttus_CMConfig__OptionId__c, Apttus_CMConfig__AttributeValueId__r.APTS_Cup_Size__c,
                                                    Apttus_CMConfig__AttributeValueId__r.APTS_Taste_Pallet__c,
                                                    Apttus__ProductId__c
                                                    FROM Apttus__AgreementLineItem__c
                                                     WHERE Apttus__AgreementId__c IN :setAggrId
                                                    AND APTS_Option_Group_Text__c = 'Menu'
                                                    AND Apttus_CMConfig__AttributeValueId__c != NULL
                                                    AND Apttus_CMConfig__OptionId__c != NULL
                                                    AND Apttus__ProductId__c != NULL];
            
            System.debug('lstALI++'+ lstALI);
        }

        if(lstALI != null && lstALI.size()>0){
            for(Apttus__AgreementLineItem__c tmp : lstALI){   


                if(tmp.Apttus_CMConfig__AttributeValueId__r.APTS_Cup_Size__c != null
                     && tmp.Apttus_CMConfig__AttributeValueId__r.APTS_Taste_Pallet__c != null
                        && tmp.Apttus_CMConfig__OptionId__c != null){


                    //String strKey = tmp.Apttus_CMConfig__OptionId__c + tmp.Apttus_CMConfig__AttributeValueId__r.APTS_Cup_Size__c + tmp.Apttus_CMConfig__AttributeValueId__r.APTS_Taste_Pallet__c;
                    //mapKeyToURL.put(strKey, '');
                    lstOption.add(tmp.Apttus_CMConfig__OptionId__c);
                    lstCupSize.add(tmp.Apttus_CMConfig__AttributeValueId__r.APTS_Cup_Size__c);
                    lstTastePallet.add(tmp.Apttus_CMConfig__AttributeValueId__r.APTS_Taste_Pallet__c);
                    lstProduct.add(tmp.Apttus__ProductId__c);

                }

            }

            for(APTS_Consumption_Categories_Details__c tmp : [SELECT Id, APTS_Planogram_Bundle_Product_ID__c, APTS_Cup_Size_Picklist__c,
                                                                APTS_Taste_Pallet_Picklist__c, APTS_Recipe_Link_Text__c, APTS_Machine_Bundle_Product_ID__c
                                                                FROM APTS_Consumption_Categories_Details__c
                                                                WHERE APTS_Planogram_Bundle_Product_ID__c IN :lstOption
                                                                AND APTS_Cup_Size_Picklist__c IN :lstCupSize
                                                                AND APTS_Taste_Pallet_Picklist__c IN :lstTastePallet
                                                                AND APTS_Machine_Bundle_Product_ID__c IN :lstProduct]){
                String strKey = tmp.APTS_Planogram_Bundle_Product_ID__c + tmp.APTS_Cup_Size_Picklist__c + tmp.APTS_Taste_Pallet_Picklist__c + tmp.APTS_Machine_Bundle_Product_ID__c;

                mapKeyToURL.put(strKey, tmp.APTS_Recipe_Link_Text__c);
            }

            for(Apttus__AgreementLineItem__c tmp : lstALI){

                String strKey = tmp.Apttus_CMConfig__OptionId__c + tmp.Apttus_CMConfig__AttributeValueId__r.APTS_Cup_Size__c + tmp.Apttus_CMConfig__AttributeValueId__r.APTS_Taste_Pallet__c + tmp.Apttus__ProductId__c;


                if(mapKeyToURL.containsKey(strKey)){

                    tmp.APTS_ConfigurationFileURL__c = mapKeyToURL.get(strKey);
                    lstAggrLineItemUpdate.add(tmp);
                }
            }
        try{
            if(lstAggrLineItemUpdate != null && lstAggrLineItemUpdate.size() > 0){
                update lstAggrLineItemUpdate;
            }
        }catch(Exception e){APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'APTS_CLMUtil', null,'CLM',false,false,null,true);}
        }
    }

    /*
    //Activates the agreement using latest signed agreement document
    public static void autoActivateSignedAggr(List<Apttus__APTS_Agreement__c> newList, Map<Id, Apttus__APTS_Agreement__c> mapAgreements,
                            List<Apttus__APTS_Agreement__c> oldList, Map<Id, Apttus__APTS_Agreement__c> mapOldAgreements){
        for(Apttus__APTS_Agreement__c oAgreement : mapAgreements.values()){
            Apttus__APTS_Agreement__c oOldAgreement = mapOldAgreements.get(oAgreement.id);
            if (oOldAgreement != null &&
                    (oOldAgreement.Apttus__Status__c != oAgreement.Apttus__Status__c || oOldAgreement.Apttus__Status_Category__c != oAgreement.Apttus__Status_Category__c) &&
                    (oAgreement.Apttus__Status__c == 'Fully Signed' && oAgreement.Apttus__Status_Category__c == 'In Signatures')) {

                try {
                    //Database.executeBatch(new APTS_AutoActivateSignedAgreement(oAgreement.Id), 1);
                    activateAgreement(oAgreement);
                } catch (exception e) {
                    System.debug('Activation Error+++' + e.getMessage());
                }
            }
        }
    }

    //Activates the agreement, publishes the document first
    public static void activateAgreement(Apttus__APTS_Agreement__c oAgreement) {
        Attachment oAttachment = getLatestSignedDoc(oAgreement.Id);
        List<Id> listActivatedDocIds = new List<Id>();
        System.debug('oAttachment+++' + oAttachment);
        if (oAttachment != null) {
            //Id publishedDocId = publishSignedDocToContent(oAgreement.Id, oAttachment.Id);
            listActivatedDocIds.add(oAttachment.Id);
            List<Id> listRemovableDocIds = new List<Id>();
            Apttus.AgreementWebService.activateAgreement(oAgreement.Id, listActivatedDocIds, listRemovableDocIds);
            Apttus.AgreementWebService.publishToDocumentRepository(oAgreement.Id, oAttachment.Id);
        }
        List<Id> listRemovableDocIds = new List<Id>();
        Apttus.AgreementWebService.activateAgreement(oAgreement.Id, listActivatedDocIds, listRemovableDocIds);
        Apttus.AgreementWebService.publishToDocumentRepository(oAgreement.Id, oAttachment.Id);
    }

    //Publishes the document to Content Repository
    public static Id publishSignedDocToContent(Id agreementId, Id attachmentId) {
        Apttus_Content.PublishRequest publicRequest = new Apttus_Content.PublishRequest();
        publicRequest.AttachmentId  = attachmentId;
        publicRequest.WorkspaceName = Apttus.ComplyWebService.selectContentWorkspaceForAgreement(agreementId);
        //publicRequest.WorkspaceName = [SELECT Name FROM ContentWorkspace LIMIT 1].Name;
        System.debug('publicRequest.WorkspaceName : ' + publicRequest.WorkspaceName);
        Id contentId  = Apttus_Content.ContentWebService.publishContentForAgreement(agreementId, publicRequest);
        return contentId;
    }

    //Fetch the latest singed document of an agreement record
    public static Attachment getLatestSignedDoc(Id parentId) {
        Attachment oAttachment;
        List<Attachment> listAttachments = [SELECT Id FROM Attachment WHERE ParentId = :parentId AND Name LIKE '%signed%' ORDER BY LastModifiedDate DESC LIMIT 1];
        System.debug('listAttachments+++' + listAttachments);
        if (!listAttachments.isEmpty()) {
            oAttachment = listAttachments.get(0);
        }
        return oAttachment;
    }
    */
   //V103=====>
   public static void manageAssetAdjLineItemData(Set<Id> assetOrderlineItemSet) {
        List<Apttus_Config2_AssetAdjustItem__c> upsertAsset = new List<Apttus_Config2_AssetAdjustItem__c>();
        Set<Id> deleteAssetAdjSet = new Set<Id>();
        Apttus_Config2_AssetAdjustItem__c assetAdj = new Apttus_Config2_AssetAdjustItem__c();
        System.debug('*****assetOrderlineItemSet======>'+assetOrderlineItemSet);
        /*The below code is doing the following but we always ignore billing run and migration transactiom:
        1) We delete all adjustments for the asset
        2) We insert the adjustments from the current order line item in the transaction to the asset
        */
        if(!assetOrderlineItemSet.isEmpty()){
            system.debug('INSIDE assetOrderlineItemSet check ===>'+assetOrderlineItemSet);
            List<Apttus_Config2__OrderLineItem__c> orderLineItemList = [SELECT ID,
                                                            Apttus_Config2__AssetLineItemId__c,
                                                            Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
                                                            Apttus_Config2__OrderId__r.Approval_Status__c , 
                                                            APTS_Physical_Asset__c,
                                                            Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                                                            Apttus_Config2__OrderId__r.Apttus_Config2__Source__c,
                                                            APTS_Description__c,
                                                            Apttus_Config2__OrderId__c,
                                                            Apttus_Config2__Status__c,
                                                            (SELECT id, 
                                                                    Name, 
                                                                    CurrencyIsoCode,
                                                                    Apttus_Config2__LineItemId__c,
                                                                    Apttus_Config2__LineItemId__r.Id,
                                                                    Apttus_Config2__AdjustmentAmount__c, 
                                                                    Apttus_Config2__AdjustmentAppliesTo__c, 
                                                                    Apttus_Config2__AdjustmentType__c, 
                                                                    Apttus_Config2__BenefitQuantity__c, 
                                                                    Apttus_Config2__CouponCode__c, 
                                                                    Apttus_Config2__IncentiveId__c, 
                                                                    Apttus_Config2__IncentiveAdjustmentAmount__c,
                                                                    Apttus_Config2__IncentiveCode__c,
                                                                    Apttus_Config2__IsModifiable__c, 
                                                                    Apttus_Config2__LineNumber__c, 
                                                                    Apttus_Config2__LineType__c, 
                                                                    Apttus_Config2__PriceRuleId__c, 
                                                                    Apttus_Config2__PriceRuleEntryId__c,
                                                                    Apttus_Config2__SubType__c, 
                                                                    Apttus_Config2__Type__c, 
                                                                    Apttus_Config2__RunningTotalAdjustedPrice__c, 
                                                                    Apttus_Config2__Bucket__c,
                                                                    APTS_Agreement_Number__c,
                                                                    APTS_Agreement_LineItem_Id__c,
                                                                    Apttus_Config2__LineItemId__r.Apttus_Config2__AssetLineItemId__c,
                                                                    Apttus_Config2__AdjustmentUom__c
                                                             FROM Apttus_Config2__AdjustmentLineItems__r) 
                                                          FROM Apttus_Config2__OrderLineItem__c 
                                                          WHERE id IN: assetOrderlineItemSet
                                                          AND Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c !=: BILLING_SCHEDULE
                                                          ORDER BY CreatedDate DESC];
            if(!orderLineItemList.isEmpty()){
                for(Apttus_Config2__OrderLineItem__c oLi : orderLineItemList){
                    System.debug('oli++++++++++'+oli.Apttus_Config2__Status__c);
                    deleteAssetAdjSet.add(oLi.Apttus_Config2__AssetLineItemId__c);
                }
                /*********************************CR2279 Changes*********************************************/
                system.debug('###### deleteAssetAdjSet'+deleteAssetAdjSet);
                //deleting all adjustments except one which has sub type Billing schedule(Migration and Billing run)
                if(!deleteAssetAdjSet.isEmpty()){
                    List<Apttus_Config2_AssetAdjustItem__c> assetAdjLineItemLst = [SELECT Id,  Apttus_Config2_AssetAdjustType__c, Apttus_Config2_AssetLineItemId__c  
                                                                               FROM Apttus_Config2_AssetAdjustItem__c where Apttus_Config2_AssetLineItemId__c IN :deleteAssetAdjSet];
                    if(!assetAdjLineItemLst.isEmpty()){
                        Delete assetAdjLineItemLst;
                    }
                }
                
                for(Apttus_Config2__OrderLineItem__c orderLineItem : orderLineItemList){
                    
                    for(Apttus_Config2__OrderAdjustmentLineItem__c orderAdjust : orderLineItem.Apttus_Config2__AdjustmentLineItems__r){
                        if(orderLineItem.Apttus_Config2__AssetLineItemId__c!=null){
                            assetAdj = new Apttus_Config2_AssetAdjustItem__c();
                            assetAdj.Name = orderAdjust.Name;
                            assetAdj.CurrencyIsoCode = orderAdjust.CurrencyIsoCode;
                            system.debug('$$$$$ Asset Line Item'+orderLineItem.Apttus_Config2__AssetLineItemId__c); 
                            assetAdj.Apttus_Config2_AssetLineItemId__c = orderLineItem.Apttus_Config2__AssetLineItemId__c;  
                            assetAdj.Apttus_Config2_AssetAdjustAmount__c= orderAdjust.Apttus_Config2__AdjustmentAmount__c;
                            assetAdj.Apttus_Config2_AssetAdjustAppliesTo__c= orderAdjust.Apttus_Config2__AdjustmentAppliesTo__c;
                            assetAdj.Apttus_Config2_AssetAdjustType__c = orderAdjust.Apttus_Config2__AdjustmentType__c;
                            assetAdj.Apttus_Config2_BenefitQuantity__c= orderAdjust.Apttus_Config2__BenefitQuantity__c;
                            assetAdj.Apttus_Config2_CouponCode__c= orderAdjust.Apttus_Config2__CouponCode__c;
                            assetAdj.Apttus_Config2_IncentiveId__c = orderAdjust.Apttus_Config2__IncentiveId__c;
                            assetAdj.Apttus_Config2_IncentiveAsetAdjustAmount__c = orderAdjust.Apttus_Config2__IncentiveAdjustmentAmount__c;
                            assetAdj.Apttus_Config2_IncentiveCode__c = orderAdjust.Apttus_Config2__IncentiveCode__c;
                            assetAdj.Apttus_Config2_IsModifiable__c= orderAdjust.Apttus_Config2__IsModifiable__c;
                            assetAdj.Apttus_Config2_LineNumber__c=orderAdjust.Apttus_Config2__LineNumber__c;
                            assetAdj.Apttus_Config2_LineType__c= orderAdjust.Apttus_Config2__LineType__c;
                            assetAdj.Apttus_Config2_PriceRuleId__c = orderAdjust.Apttus_Config2__PriceRuleId__c;
                            assetAdj.Apttus_Config2_PriceRuleEntryId__c =orderAdjust.Apttus_Config2__PriceRuleEntryId__c;
                            assetAdj.Apttus_Config2_SubType__c= orderAdjust.Apttus_Config2__SubType__c;
                            assetAdj.Apttus_Config2_Type__c = orderAdjust.Apttus_Config2__Type__c;
                            assetAdj.RunningTotalAdjustedPrice__c = orderAdjust.Apttus_Config2__RunningTotalAdjustedPrice__c;
                            assetAdj.Apttus_Config2_Bucket__c = orderAdjust.Apttus_Config2__Bucket__c;
                            assetAdj.APTS_Agreement_Number__c = orderAdjust.APTS_Agreement_Number__c;
                            assetAdj.Agreement_LineItem_Id__c = orderAdjust.APTS_Agreement_LineItem_Id__c;
                            assetAdj.Apttus_Config2_Adjustment_Uom__c = orderAdjust.Apttus_Config2__AdjustmentUom__c;
                            //assetAdj.APTS_Discount_Type__c = orderAdjust.APTS_Discount_Type__c;
                            upsertAsset.add(assetAdj);
                        }
                    }
                }
                if(!upsertAsset.isEmpty()){
                    upsert upsertAsset;
                }
             } 
        } 
    }
    //V103<=====
    //Finalize Cart
    public static void finalizeCart(Id cartId) {
        Boolean isFinalizationPending = Apttus_CMConfig.CMConfigWebService.finalizeConfiguration(cartId);
        System.debug('isFinalizationPending+++' + isFinalizationPending);
        Boolean isFinalizationPending1 = Apttus_CMConfig.CMConfigWebService.afterFinalizeConfiguration(cartId);
        System.debug('isFinalizationPending1+++' + isFinalizationPending1);
    }

    //Reprice Cart
    public static Boolean updatePricing(Id cartId) {
        Apttus_CpqApi.CPQ.UpdatePriceRequestDO objUpdatePriceRequestDO = new Apttus_CpqApi.CPQ.UpdatePriceRequestDO();
        objUpdatePriceRequestDO.CartId = cartId;
        Apttus_CpqApi.CPQ.UpdatePriceResponseDO objUpdatePrice = Apttus_CpqApi.CPQWebService.updatePriceForCart(objUpdatePriceRequestDO);
        return objUpdatePrice.IsPricePending;
    }  

    //Synchronize Cart
    public static void syncCart(Id cartId) {
        Apttus_Config2.CPQStruct.SynchronizeCartRequestDO request = new Apttus_Config2.CPQStruct.SynchronizeCartRequestDO();
        request.CartId = cartId;
        Apttus_Config2.CPQStruct.SynchronizeCartResponseDO result = Apttus_Config2.OrderWebService.synchronizeCart(request);
        Boolean bSyncCartStatus = result.IsSuccess;
        System.debug('bSyncCartStatus : ' + bSyncCartStatus);
    }

    //Accept Order
    public static Apttus_Config2.CPQStruct.AcceptOrderResponseDO acceptorder(Id orderId) {
        Apttus_Config2.CPQStruct.AcceptOrderRequestDO orderAcceptRequest = new Apttus_Config2.CPQStruct.AcceptOrderRequestDO();
        orderAcceptRequest.OrderId = orderId;
        Apttus_Config2.CPQStruct.AcceptOrderResponseDO response2 = Apttus_Config2.OrderWebService.acceptOrder(orderAcceptRequest);  
        return response2;
    }
    
    // Methods being called from AssetlineItem trigger
    public static List<Apttus_Config2__AssetLineItem__c> calculateAssetBaseExtendedPrice(List<Apttus_Config2__AssetLineItem__c> assetLineItemList,Map<Id, Apttus_Config2__AssetLineItem__c> storedOldMapAsset)
    {
        Set<Id> setOfCurrentAssetIds = new Set<Id>();
        Map<Id, Decimal> prvVlue = new Map<Id, Decimal>();
        Map<Id, Decimal> prvSrvRollUp = new Map<Id, Decimal>();
        Map<String, Apttus_Config2__AssetLineItem__c> parentAssets = new Map<String, Apttus_Config2__AssetLineItem__c>();
        Boolean hasChangedAdditionalServiceLine=false;
        //Map<Id, Decimal> yocirollup = new Map<Id, Decimal>();
        
        
        for(Apttus_Config2__AssetLineItem__c itrasst : assetLineItemList){
            if(itrasst.APTS_Is_Primary_L1_Asset__c == NULL&&itrasst.APTS_Type_Of_Contract__c!=null){
                setOfCurrentAssetIds.add(itrasst.Id);
                
            }else if(itrasst.APTS_Is_Primary_L1_Asset__c != NULL&&itrasst.APTS_Type_Of_Contract__c!=null){
                setOfCurrentAssetIds.add(itrasst.APTS_Is_Primary_L1_Asset__c);
            }
        }
        //V104 - Start
        System.debug('****storedOldMapAsset===>'+storedOldMapAsset);
        //V104 - End
        //lstHistory = [SELECT Id, Apttus_Config2__AssetLineItemId__c, Apttus_Config2__Action__c FROM Apttus_Config2__AssetTransactionHistory__c WHERE Apttus_Config2__AssetLineItemId__c IN :newList ORDER BY CreatedDate DESC];
        

        
        //V105
        List<Apttus_Config2__AssetLineItem__c> lstOfUsedALI = [SELECT Id, Apttus_Config2__ChargeType__c, APTS_Old_Net_Price__c,
           Apttus_Config2__HasOptions__c, Apttus_Config2__ParentAssetId__c, Apttus_Config2__BundleAssetId__c,
           APTS_YOCI_OptionRollup__c,APTS_YOCI_Rollup__c, APTS_Is_Primary_L1_Asset__c, Apttus_Config2__NetPrice__c, 
           APTS_Consolidated_Price__c, APTS_Service_Rollup_Net_Amount__c, APTS_Amendment_Effective_Date__c, 
           Apttus_Config2__BaseExtendedPrice__c, Apttus_Config2__OptionId__r.APTS_Option_Group_Indicator__c, APTS_Stop_RtR_Transactions_from__c ,APTS_Type_Of_Contract__c,
           Apttus_Config2__BasePrice__c, APTS_Calculated_Base_Extended_Price__c, Apttus_Config2__LineType__c, 
           Apttus_Config2__Quantity__c, Apttus_Config2__SellingTerm__c, Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c, Apttus_CMConfig__AgreementId__r.Recordtype.Name, Apttus_Config2__IsPrimaryLine__c, APTS_Physical_Asset__c, APTS_Contract_Type__c, APTS_Calculated_List_Price__c, APTS_Asset_Validaton_Error__c, Apttus_Config2__SellingFrequency__c FROM Apttus_Config2__AssetLineItem__c 
                                                               WHERE (Id IN :setOfCurrentAssetIds OR APTS_Is_Primary_L1_Asset__c IN :setOfCurrentAssetIds)];
        system.debug('$$$$$ lstOfUsedALI '+lstOfUsedALI);
        
                //if(!Test.isRunningTest()){
        for(Apttus_Config2__AssetLineItem__c itrasst : lstOfUsedALI){
            //V103
            //V104 - Start
            if(itrasst.Apttus_Config2__LineType__c!=null && itrasst.Apttus_Config2__LineType__c == 'Product/Service' &&
            itrasst.Apttus_Config2__ChargeType__c!=null && itrasst.Apttus_Config2__ChargeType__c.equalsIgnoreCase('Additional Service Fee') &&
            storedOldMapAsset!=null && !storedOldMapAsset.isEmpty() && storedOldMapAsset.get(itrasst.id)!=null){
                System.debug('*****itrasst.id====>'+itrasst.id);
                System.debug('*****itrasst.APTS_Old_Net_Price__c====>'+itrasst.APTS_Old_Net_Price__c);
                System.debug('*****itrasst.Apttus_Config2__NetPrice__c====>'+itrasst.Apttus_Config2__NetPrice__c);
                hasChangedAdditionalServiceLine=true;
                
            }
            //V104 - End
            System.debug('****hasChangedAdditionalServiceLine===>'+hasChangedAdditionalServiceLine);
            if(itrasst.Apttus_Config2__LineType__c == 'Product/Service'){
                if(itrasst.APTS_Is_Primary_L1_Asset__c == NULL){
                    parentAssets.put(itrasst.Id+itrasst.Apttus_Config2__ChargeType__c, itrasst);
                }else if(itrasst.APTS_Is_Primary_L1_Asset__c != NULL){
                    parentAssets.put(itrasst.APTS_Is_Primary_L1_Asset__c+itrasst.Apttus_Config2__ChargeType__c, itrasst);
                }
                
            }else if(itrasst.Apttus_Config2__LineType__c == 'Option'){parentAssets.put(itrasst.Id, itrasst);} 
            prvVlue.put(itrasst.Id, itrasst.APTS_Calculated_Base_Extended_Price__c);prvSrvRollUp.put(itrasst.Id, itrasst.APTS_Service_Rollup_Net_Amount__c);itrasst.APTS_Calculated_Base_Extended_Price__c = 0;itrasst.APTS_YOCI_optionRollup__c = 0;
        }
        //}
        
        //system.debug('$$$$$ parentAssets '+parentAssets);
        for(Apttus_Config2__AssetLineItem__c itrasst : parentAssets.values()){                      
            if(itrasst.Apttus_Config2__LineType__c == 'Option'){        
                /*itrasst.APTS_Calculated_Base_Extended_Price__c = ((itrasst.Apttus_Config2__BasePrice__c!=null)?itrasst.Apttus_Config2__BasePrice__c:0.0)* // Bundle Base Price
((itrasst.Apttus_Config2__Quantity__c!=null)?itrasst.Apttus_Config2__Quantity__c:0.0) * 
((itrasst.Apttus_Config2__SellingTerm__c!=null)?itrasst.Apttus_Config2__SellingTerm__c:0.0);*/
                if(itrasst.Apttus_Config2__BasePrice__c==0 || itrasst.Apttus_Config2__Quantity__c==0 || itrasst.Apttus_Config2__SellingTerm__c==0){itrasst.APTS_Calculated_Base_Extended_Price__c = 0;}
                if(itrasst.Apttus_Config2__BasePrice__c!=null && itrasst.Apttus_Config2__Quantity__c!=null && itrasst.Apttus_Config2__SellingTerm__c!=null
                   && itrasst.Apttus_Config2__BasePrice__c!=0 && itrasst.Apttus_Config2__Quantity__c!=0 && itrasst.Apttus_Config2__SellingTerm__c!=0){
                       if(itrasst.Apttus_Config2__SellingFrequency__c == 'One Time'){itrasst.APTS_Calculated_Base_Extended_Price__c = itrasst.Apttus_Config2__BasePrice__c * itrasst.Apttus_Config2__Quantity__c;}
                       else{itrasst.APTS_Calculated_Base_Extended_Price__c = itrasst.Apttus_Config2__BasePrice__c * itrasst.Apttus_Config2__Quantity__c * itrasst.Apttus_Config2__SellingTerm__c;}
                       
                   }
                
                if(itrasst.Apttus_Config2__ChargeType__c != 'Additional Service Fee'){              
                    Apttus_Config2__AssetLineItem__c tmpAst = parentAssets.get(itrasst.APTS_Is_Primary_L1_Asset__c+itrasst.Apttus_Config2__ChargeType__c);                  
                    if(tmpAst != null){
                        tmpAst.APTS_Calculated_Base_Extended_Price__c = tmpAst.APTS_Calculated_Base_Extended_Price__c + itrasst.APTS_Calculated_Base_Extended_Price__c;                       
                        if(itrasst.APTS_YOCI_Rollup__c != null){tmpAst.APTS_YOCI_optionRollup__c += math.ABS(itrasst.APTS_YOCI_Rollup__c);}
                    }
                }
                if(itrasst.Apttus_Config2__ChargeType__c == 'Additional Service Fee'){
                    Apttus_Config2__AssetLineItem__c tmpAst = parentAssets.get(itrasst.APTS_Is_Primary_L1_Asset__c+itrasst.Apttus_Config2__ChargeType__c);
                    if(tmpAst != null){
                        tmpAst.APTS_Calculated_Base_Extended_Price__c = tmpAst.APTS_Calculated_Base_Extended_Price__c + itrasst.APTS_Calculated_Base_Extended_Price__c;                      
                        if(itrasst.APTS_YOCI_Rollup__c != null){tmpAst.APTS_YOCI_optionRollup__c += math.ABS(itrasst.APTS_YOCI_Rollup__c);}
                    }
                }
            }else if(itrasst.Apttus_Config2__LineType__c == 'Product/Service' && itrasst.Apttus_Config2__ChargeType__c == 'Additional Service Fee'){
                Apttus_Config2__AssetLineItem__c tmpAst = parentAssets.get(itrasst.APTS_Is_Primary_L1_Asset__c+'Service Fee');
                if(tmpAst != null && itrasst.APTS_Consolidated_Price__c != null){ //V101 ++ <<>>
                  tmpAst.APTS_Service_Rollup_Net_Amount__c =  itrasst.APTS_Consolidated_Price__c;   
                }
            }
            //V104 - Start
            if(hasChangedAdditionalServiceLine && itrasst.Apttus_Config2__ChargeType__c.equalsIgnoreCase('Service Fee') && storedOldMapAsset!=null && !storedOldMapAsset.isEmpty()){
                if(storedOldMapAsset.get(itrasst.id)==null){
                    storedOldMapAsset.put(itrasst.id,itrasst);
                }
            }
            //V104 - End
        }
        
        upsert parentAssets.values();
        
        system.debug('$$$$$ parentAssets1 '+parentAssets);
        //remove the non changed assets
        for(String rmvChang : parentAssets.keyset()){
            Apttus_Config2__AssetLineItem__c tmpAst = parentAssets.get(rmvChang);
            system.debug('$$$$$$ tmpAst.APTS_Calculated_Base_Extended_Price__c '+tmpAst.APTS_Calculated_Base_Extended_Price__c);
            system.debug('$$$$$$ prvVlue.get(tmpAst.Id) '+prvVlue.get(tmpAst.Id));
            system.debug('tmpAst.APTS_Service_Rollup_Net_Amount__c'+tmpAst.APTS_Service_Rollup_Net_Amount__c);
            system.debug('prvSrvRollUp.get(tmpAst.Id)'+prvSrvRollUp.get(tmpAst.Id));
            
            if( tmpAst.Apttus_Config2__LineType__c == 'Option'){
                parentAssets.remove(rmvChang);
            }
            /*else if(tmpAst.APTS_Type_Of_Contract__c!='RentBuy'&&prvSrvRollUp.get(tmpAst.Id)!=null&&tmpAst.APTS_Service_Rollup_Net_Amount__c!=null&&tmpAst.APTS_Calculated_Base_Extended_Price__c == prvVlue.get(tmpAst.Id) && tmpAst.APTS_Service_Rollup_Net_Amount__c == prvSrvRollUp.get(tmpAst.Id) && tmpAst.Apttus_Config2__LineType__c == 'Product/Service'&&tmpAst.Apttus_Config2__ChargeType__c=='Service Fee'){
                parentAssets.remove(rmvChang);
            //V104 - Start
            }
            */
            else if(storedOldMapAsset!=null && storedOldMapAsset.get(tmpAst.Id)==null){
                parentAssets.remove(rmvChang);
            }
            //V104 - End
        }
        system.debug('$$$$$ parentAssets2 '+parentAssets);
        
        return parentAssets.values();
    }

    
    // Methods added by Ariel Quesada to support calculated Base Extended Price logic
    public static void calculateBaseExtendedPrice(Apttus_Config2__AssetLineItem__c assetLineItem)
    {        
        assetLineItem.APTS_Calculated_Base_Extended_Price__c = ((assetLineItem.Apttus_Config2__BasePrice__c!=null)?assetLineItem.Apttus_Config2__BasePrice__c:0.0)* // Bundle Base Price
                                                               ((assetLineItem.Apttus_Config2__Quantity__c!=null)?assetLineItem.Apttus_Config2__Quantity__c:0.0) * 
                                                               ((assetLineItem.Apttus_Config2__SellingTerm__c!=null)?assetLineItem.Apttus_Config2__SellingTerm__c:0.0);
        System.debug(logginglevel.error, 'CX_Message: CLM Util: CalculateBaseExtendedPrice ' + assetlineitem);
        String chargeType = assetlineitem.Apttus_Config2__ChargeType__c;
        if (assetlineitem.Apttus_Config2__HasOptions__c == true){
            System.debug(logginglevel.error, 'CX_Message: Charge Type: ' + chargeType);
            List<Apttus_Config2__AssetLineItem__c> Options = 
                        [SELECT Id, Apttus_Config2__Quantity__c, Apttus_Config2__SellingTerm__c,  Apttus_Config2__BasePrice__c
                        FROM Apttus_Config2__AssetLineItem__c
                        WHERE Apttus_Config2__BundleAssetId__c =: assetLineItem.Id
                        AND Apttus_Config2__ChargeType__c =: chargeType];
            System.debug(logginglevel.error, 'CX_Message: Number of options: ' + options.size());
            System.debug(logginglevel.error, 'CX_Message: Options: ' + options);
            Decimal calculatedBaseExtendedPrice = 0.0;
            for (Apttus_Config2__AssetLineItem__c option: options){
                System.debug(logginglevel.error, 'CX_Message: Value of option to be added to the Calculated Base Extended Price: ' + option.Apttus_Config2__BasePrice__c);
                System.debug(logginglevel.error, 'CX_Message: Quantity of option to be added to the Calculated Base Extended Price: ' + option.Apttus_Config2__Quantity__c);
                calculatedBaseExtendedPrice = calculatedBaseExtendedPrice + 
                    ( ((option.Apttus_Config2__BasePrice__c!=null)?option.Apttus_Config2__BasePrice__c:0.0) // Option base price
                    * ((option.Apttus_Config2__Quantity__c!=null)? option.Apttus_Config2__Quantity__c:0.0) // Quantity
                    * ((option.Apttus_Config2__SellingTerm__c!=null)?option.Apttus_Config2__SellingTerm__c:0.0));
            }
            assetlineitem.APTS_Calculated_Base_Extended_Price__c = calculatedBaseExtendedPrice;
            System.debug(logginglevel.error, 'CX_Message: New Calculated Base Extended Price for the item: ' + calculatedBaseExtendedPrice);
        }
    }

     // Methods added by Venky  to support calculated Base Extended Price logic
    public static List<Apttus_Config2__AssetLineItem__c> calculateBaseExtendedPrice(List<Apttus_Config2__AssetLineItem__c> assetLineItemList)
    {        

        Map<Id,List<Apttus_Config2__AssetLineItem__c>> aliOptions =new Map<Id,List<Apttus_Config2__AssetLineItem__c>>();
        List<Apttus_Config2__AssetLineItem__c> tempList =new List<Apttus_Config2__AssetLineItem__c>();
        List<Apttus_Config2__AssetLineItem__c> returnObject =new List<Apttus_Config2__AssetLineItem__c>();
        List<Apttus_Config2__AssetLineItem__c> totalAssetList =new List<Apttus_Config2__AssetLineItem__c>();
        List<Apttus_Config2__AssetLineItem__c> options =new List<Apttus_Config2__AssetLineItem__c>();
        //CR 2098
        Decimal calculatedListPrice;
     
        totalAssetList  = 
        [
            SELECT Id,
            Apttus_Config2__BasePrice__c,
            Apttus_Config2__Quantity__c,
            Apttus_Config2__LineType__c,
            Apttus_Config2__SellingTerm__c,
            APTS_Is_Primary_L1_Asset__c,
            Apttus_Config2__BundleAssetId__c,
            Apttus_Config2__SellingFrequency__c,
            Apttus_Config2__HasOptions__c,
            Apttus_Config2__ChargeType__c,
            APTS_MigrationDate__c,
            Apttus_Config2__ListPrice__c 
            FROM Apttus_Config2__AssetLineItem__c 
            WHERE (Id in: assetLineItemList or APTS_Is_Primary_L1_Asset__c in: assetLineItemList)
            AND Apttus_Config2__LineType__c =:OPTION
        ];
        system.debug('assetlineit@@@' +totalAssetList);
        for(Apttus_Config2__AssetLineItem__c ali:totalAssetList)
        {
            
            tempList= aliOptions.get(ali.APTS_Is_Primary_L1_Asset__c)!=null?aliOptions.get(ali.APTS_Is_Primary_L1_Asset__c):new List<Apttus_Config2__AssetLineItem__c>();
            tempList.add(ali);
            aliOptions.put(ali.APTS_Is_Primary_L1_Asset__c,tempList);
        }
        system.debug('aliOptions****'+aliOptions);

        for(Apttus_Config2__AssetLineItem__c assetLineItem: assetLineItemList)
            {   
                if(assetLineItem.Apttus_Config2__LineType__c==OPTION)
                    continue;
                
                assetLineItem.APTS_Calculated_Base_Extended_Price__c = ((assetLineItem.Apttus_Config2__BasePrice__c!=null)?assetLineItem.Apttus_Config2__BasePrice__c:0.0)* // Bundle Base Price
                                                                       ((assetLineItem.Apttus_Config2__Quantity__c!=null)?assetLineItem.Apttus_Config2__Quantity__c:0.0) * 
                                                                       ((assetLineItem.Apttus_Config2__SellingTerm__c!=null)?assetLineItem.Apttus_Config2__SellingTerm__c:0.0);

                //CR 2098
                assetLineItem.APTS_Calculated_List_Price__c = ((assetLineItem.Apttus_Config2__ListPrice__c!=null)?assetLineItem.Apttus_Config2__ListPrice__c:0.0)* // Bundle List Price
                                                                       ((assetLineItem.Apttus_Config2__Quantity__c!=null)?assetLineItem.Apttus_Config2__Quantity__c:0.0) * 
                                                                       ((assetLineItem.Apttus_Config2__SellingTerm__c!=null)?assetLineItem.Apttus_Config2__SellingTerm__c:0.0);

                System.debug(logginglevel.error, 'CX_Message: CLM Util: CalculateBaseExtendedPrice ' + assetlineitem);
                String chargeType = assetlineitem.Apttus_Config2__ChargeType__c;
                //if (assetlineitem.Apttus_Config2__HasOptions__c == true){
                System.debug(logginglevel.error, 'CX_Message: Charge Type: ' + chargeType);
                options = aliOptions.get(assetlineitem.Id) != null ? aliOptions.get(assetlineitem.Id) : aliOptions.get(assetlineitem.APTS_Is_Primary_L1_Asset__c) !=null ? aliOptions.get(assetlineitem.APTS_Is_Primary_L1_Asset__c) : new List<Apttus_Config2__AssetLineItem__c>();
                System.debug('assetlineitem.Id******'+assetlineitem.Id);
                System.debug(logginglevel.error, 'CX_Message: Number of options: ' + options.size());
                System.debug(logginglevel.error, 'CX_Message: Options: ' + options);
                
                Decimal calculatedBaseExtendedPrice = 0.0;
                calculatedListPrice = 0.0;
                
                for (Apttus_Config2__AssetLineItem__c option: options){
                    if(option.Apttus_Config2__ChargeType__c!=chargeType)
                       continue;
                    System.debug(logginglevel.error, 'CX_Message: Value of option to be added to the Calculated Base Extended Price: ' + option.Apttus_Config2__BasePrice__c);
                    System.debug(logginglevel.error, 'CX_Message: Quantity of option to be added to the Calculated Base Extended Price: ' + option.Apttus_Config2__Quantity__c);
                    if(option.Apttus_Config2__ChargeType__c=='Sales Price'&& option.Apttus_Config2__SellingFrequency__c=='One Time')
                        {
                            calculatedBaseExtendedPrice = calculatedBaseExtendedPrice + 
                        ( ((option.Apttus_Config2__BasePrice__c!=null)?option.Apttus_Config2__BasePrice__c:0.0) // Option base price
                        * ((option.Apttus_Config2__Quantity__c!=null)? option.Apttus_Config2__Quantity__c:0.0) // Quantity
                        );

                            //CR 2098
                            //Do calculations only for migrated assets
                            if(option.APTS_MigrationDate__c != null){
                                calculatedListPrice = calculatedListPrice + 
                                                        ( 
                                                            ((option.Apttus_Config2__ListPrice__c != null) ? option.Apttus_Config2__ListPrice__c : 0.0) *// Option list price
                                                            ((option.Apttus_Config2__Quantity__c != null) ? option.Apttus_Config2__Quantity__c : 0.0) // Quantity
                                                        ); 
                            }
                        }
                    else
                        {
                    calculatedBaseExtendedPrice = calculatedBaseExtendedPrice + 
                        ( ((option.Apttus_Config2__BasePrice__c!=null)?option.Apttus_Config2__BasePrice__c:0.0) // Option base price
                        * ((option.Apttus_Config2__Quantity__c!=null)? option.Apttus_Config2__Quantity__c:0.0) // Quantity
                        * ((option.Apttus_Config2__SellingTerm__c!=null)?option.Apttus_Config2__SellingTerm__c:0.0));

                            //CR 2098
                            //Do calculations only for migrated assets
                            if(option.APTS_MigrationDate__c != null){
                                calculatedListPrice = calculatedListPrice + 
                                                                ( 
                                                                    ((option.Apttus_Config2__ListPrice__c != null) ? option.Apttus_Config2__ListPrice__c : 0.0) * // Option list price
                                                                    ((option.Apttus_Config2__Quantity__c != null) ? option.Apttus_Config2__Quantity__c : 0.0) * // Quantity
                                                                    ((option.Apttus_Config2__SellingTerm__c != null) ? option.Apttus_Config2__SellingTerm__c : 0.0) // Selling Term
                                                                );
                            }
                        }
                }
                
                assetlineitem.APTS_Calculated_Base_Extended_Price__c = calculatedBaseExtendedPrice;

                //CR 2098
                if(calculatedListPrice > 0.0){
                    assetlineitem.APTS_Calculated_List_Price__c = calculatedListPrice;
                }

                returnObject.add(assetlineitem);
                System.debug(logginglevel.error, 'CX_Message: New Calculated Base Extended Price for the item: ' + calculatedBaseExtendedPrice);
                System.debug(logginglevel.error, 'CX_Message: New Calculated Base List Price for the item: ' + calculatedListPrice);
                //}
            }
        return returnObject;
    }

    /*@future
    public static void adminOrderQueue(Id cartId, Id orderId){
        APTS_OrderUtils.finalizeCart(cartId);
        APTS_OrderUtils.syncCart(cartId);
        //APTS_OrderUtils.acceptOrder(orderId);
    }*/

    public static Apttus_Config2__Order__c createAdminOrder(Apttus__APTS_Agreement__c oAggr, Account oAccount, String ordersubtype) {
        Apttus_Config2__Order__c oOrder = new Apttus_Config2__Order__c();
        APTS_OrderUtils.setOrderHeaderMandatoryFields(oOrder, ADMIN);
        oOrder.Apttus_Config2__Source__c = ACCOUNT;
        oOrder.APTS_SAP_OrderType__c = XA13;
        oOrder.APTS_Order_Sub_Type__c = ordersubtype;
        oOrder.Apttus_Config2__AutoActivateOrder__c = true;
        oOrder = APTS_OrderUtils.setOrderHeader(oOrder, oAggr, oAccount);       
        return oOrder; 
    }
    
    public static Id processAdminOrder(Apttus__APTS_Agreement__c oAgreement, Apttus_Config2__Order__c oOrder)
    {
        Boolean cloneind;
        String adminString1 = 'Non-Physical'; 
        String adminString2 = 'Renewal';
        Set<Integer> rmvLines = new Set<Integer>();
        Map<String, String> assettxn = new Map<String, String>();
        //Apttus_CPQApi.CPQ.RemoveBundleRequestDO request;
        Id cartId = null;
        if(oAgreement!=null && oOrder!=null){
            cloneind = Apttus_CMConfig.CMConfigWebService.copyProductConfiguration(oAgreement.Id,oOrder.Id);
        }
        system.debug('$$$ cloneind '+cloneind);
        
        for(Apttus__AgreementLineItem__c lstALI : [SELECT Id,
                        APTS_Serial_Number__c,
                        APTS_Asset_Change_type__c
                        FROM Apttus__AgreementLineItem__c
                        WHERE Apttus__AgreementId__c = :oAgreement.Id 
            AND Apttus__AgreementId__r.RecordType.DeveloperName != 'Registration_Form'])
        {
            if(lstALI.APTS_Serial_Number__c!=null && lstALI.APTS_Asset_Change_type__c != null && (lstALI.APTS_Asset_Change_type__c.contains(adminString1) || lstALI.APTS_Asset_Change_type__c.contains(adminString2))){
             assettxn.put(lstALI.APTS_Serial_Number__c, lstALI.APTS_Asset_Change_type__c);   
            }
        }
        system.debug('$$$$$ assettxn '+assettxn);
        if(cloneind){
        Apttus_Config2__ProductConfiguration__c prodConList1 = [SELECT Id FROM Apttus_Config2__ProductConfiguration__c
                                                                            WHERE Apttus_Config2__OrderId__c = :oOrder.Id LIMIT 1];
        cartId = prodConList1.Id;
        List<Apttus_Config2__LineItem__c> liSOList = [select id, APTS_Asset_Change_type__c, APTS_Serial_Number__c, Apttus_Config2__LineType__c,Apttus_Config2__ProductId__c,Apttus_Config2__ProductOptionId__c,Apttus_Config2__ChargeType__c,Apttus_Config2__AssetLineItemId__c,Apttus_Config2__LineStatus__c,Apttus_Config2__LineNumber__c 
                                                                  from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c
                                                                     = :prodConList1.Id and Apttus_Config2__LineType__c = 'Product/Service' and (Apttus_Config2__IsPrimaryLine__c = true OR APTS_Serial_Number__c != null) ];
        
            for(Apttus_Config2__LineItem__c li : liSOList){
                
                /*
                if(li.Apttus_Config2__AssetLineItemId__c == null){
                    rmvLines.add(li.Apttus_Config2__LineNumber__c);
                }else if(li.APTS_Serial_Number__c != null && (li.APTS_Asset_Change_type__c.contains(adminString1) || li.APTS_Asset_Change_type__c.contains(adminString2) )){
                    rmvLines.add(li.Apttus_Config2__LineNumber__c);
                }
                */
                if(li.Apttus_Config2__AssetLineItemId__c == null && li.APTS_Asset_Change_type__c != 'Registration'){
                    rmvLines.add(Integer.valueOf(li.Apttus_Config2__LineNumber__c));
                    system.debug('$$$$$ li '+li);
                }else if(li.APTS_Serial_Number__c != null && assettxn.get(li.APTS_Serial_Number__c) == null && li.APTS_Asset_Change_type__c != 'Registration'){
                    rmvLines.add(Integer.valueOf(li.Apttus_Config2__LineNumber__c));
                    system.debug('$$$$$ li '+li);
                }
            }
            system.debug('$$$$$ rmvLines'+rmvLines);
            /*if(!rmvLines.isEmpty()){
                for(Decimal i : rmvLines){
                    System.debug('$$$$$ i '+i);
                    request = new Apttus_CPQApi.CPQ.RemoveBundleRequestDO();
                    request.CartId = cartId;
                    request.LineNumber = i;
                    Apttus_CPQApi.CPQ.RemoveBundleResponseDO response = Apttus_CPQApi.CPQWebService.removeBundle(request);
                    System.debug('Remove bundle from cart response status = ' +response.IsSuccess);
                    request = null;
                }
                List<Integer> linesToRemove = new List<Integer>();
                linesToRemove.addAll(rmvLines);
                Apttus_CPQApi.CPQ.RemoveMultiBundlesRequestDO request = new Apttus_CPQApi.CPQ.RemoveMultiBundlesRequestDO();
                request.CartId = cartId;
                request.LineNumbers = linesToRemove;
                Apttus_CPQApi.CPQ.RemoveMultiBundlesResponseDO response = Apttus_CPQApi.CPQWebService.removeMultiBundles(request);
            }*/
            
        }
        return cartId;
    }
    
    /**public static void addBundleProductToCart(Apttus__AgreementLineItem__c oAGLI, Id cartId)
        {
            Apttus_Config2__ProductAttributeValue__c tempPAV = new Apttus_Config2__ProductAttributeValue__c();
            List<Apttus_Config2__ProductAttributeValue__c> insertList = new List<Apttus_Config2__ProductAttributeValue__c>();
            List<ID> tempList = new List<ID>();
            try
                {
                    List<Apttus__AgreementLineItem__c> lstALI = 
                    [
                        SELECT Id,
                        Apttus_CMConfig__OptionId__c,
                        Apttus_CMConfig__ProductOptionId__c,
                        Apttus_CMConfig__Uom__c,
                        Apttus_CMConfig__LineType__c,
                        Apttus_CMConfig__BasePriceOverride__c,
                        Apttus__ProductId__c,
                        Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c,
                        Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Type_of_contract__c,
                        Apttus_CMConfig__ChargeType__c,
                        Apttus_CMConfig__EndDate__c,
                        Apttus_CMConfig__SellingTerm__c,
                        APTS_Asset_Change_type__c,
                        Apttus_CMConfig__BillingFrequency__c,
                        Apttus_CMConfig__BillingRule__c,
                        Apttus__AgreementId__r.Apttus_CMConfig__BillingPreferenceId__c,
                        Apttus_CMConfig__AssetLineItemId__c,
                        Apttus_CMConfig__LineStatus__c
                        FROM Apttus__AgreementLineItem__c
                        WHERE Apttus_CMConfig__LineNumber__c =:oAGLI.Apttus_CMConfig__LineNumber__c and Apttus__AgreementId__c=:oAGLI.Apttus__AgreementId__c and Apttus__ProductId__c=:oAGLI.Apttus__ProductId__c 
                    ];
                    system.debug('LINEitem@@' +oAGLI);
                    Apttus_CPQApi.CPQ.AddBundleRequestDO request = new Apttus_CPQApi.CPQ.AddBundleRequestDO();
                    request.CartId = cartId;
                    request.SelectedBundle = new Apttus_CPQApi.CPQ.SelectedBundleDO();
                    request.SelectedBundle.SelectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
                    request.SelectedBundle.SelectedProduct.ProductId = oAGLI.Apttus__ProductId__c;
                    request.SelectedBundle.SelectedProduct.Quantity = 1;
                    List<Apttus_CPQApi.CPQ.SelectedOptionDO> options = new List<Apttus_CPQApi.CPQ.SelectedOptionDO>();
                    for(Apttus__AgreementLineItem__c ali:lstALI){
                        if(ali.Apttus_CMConfig__LineType__c== 'Option')
                        {
                            Apttus_CPQApi.CPQ.SelectedOptionDO objSelectedOptionDO = new Apttus_CPQApi.CPQ.SelectedOptionDO();
                            objSelectedOptionDO.ComponentId =ali.Apttus_CMConfig__ProductOptionId__c;
                           objSelectedOptionDO.ComponentProductId =ali.Apttus_CMConfig__OptionId__c;
                            objSelectedOptionDO.Quantity = 1;
                            options.Add(objSelectedOptionDO);
                        }
                        tempList.add(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c);
                    }
                    if(options.size()>0){
                        request.SelectedBundle.SelectedOptions = options ;
                    }
                      String AttributeValueFetchQuery = 'SELECT '  
                                            + APTS_Utility.getObjectFields('Apttus_Config2__ProductAttributeValue__c')  
                                            + ' FROM Apttus_Config2__ProductAttributeValue__c WHERE Id  IN :tempList';
                    
                    Map<Id,Apttus_Config2__ProductAttributeValue__c> pavMap =  new Map<Id, Apttus_Config2__ProductAttributeValue__c>((List<Apttus_Config2__ProductAttributeValue__c>)Database.query(AttributeValueFetchQuery));
                    Apttus_CPQApi.CPQ.AddBundleResponseDO response =Apttus_CPQApi.CPQWebService.addBundle(request);
                    
                    if(cartId!=null){
                    APTS_OrderUtils.repriceCart(cartId);
                        }
                    
                    List<Apttus_Config2__LineItem__c> liSOList = [select id, Apttus_Config2__LineType__c,Apttus_Config2__SellingFrequency__c,Apttus_Config2__EndDate__c,Apttus_Config2__ProductId__c,Apttus_Config2__AttributeValueId__c,Apttus_Config2__ProductOptionId__c,Apttus_Config2__ChargeType__c,Apttus_Config2__SellingTerm__c,Apttus_Config2__AssetLineItemId__c,Apttus_Config2__LineStatus__c
                                                                  from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c
                                                                     = :cartId and Apttus_Config2__ProductId__c=:oAGLI.Apttus__ProductId__c ];
                    system.debug('cart@@' +cartId);
                    List<Apttus_Config2__LineItem__c> updateList =new List<Apttus_Config2__LineItem__c>();
                    Set<Id> templiSet =new Set<Id>();
                    Set<Id> tempaliSet =new Set<Id>();
                    
                    for(Apttus_Config2__LineItem__c l:liSOList)
                        {
                            for(Apttus__AgreementLineItem__c ali:lstALI)
                                {
                                    if(templiSet.contains(l.id) || tempaliSet.contains(ali.id))
                                        {
                                            continue;
                                        }
                                    if(((l.Apttus_Config2__LineType__c!='Option' && ali.Apttus_CMConfig__LineType__c!='Option' )||(l.Apttus_Config2__LineType__c=='Option' && ali.Apttus_CMConfig__LineType__c=='Option' && l.Apttus_Config2__ProductOptionId__c==ali.Apttus_CMConfig__ProductOptionId__c)) &&  l.Apttus_Config2__ProductId__c==ali.Apttus__ProductId__c )
                                        {
                                            l.APTS_Agreement_Line_Item__c=ali.ID;
                                            l.Apttus_Config2__AssetLineItemId__c = ali.Apttus_CMConfig__AssetLineItemId__c;
                                            l.Apttus_Config2__SellingTerm__c=ali.Apttus_CMConfig__SellingTerm__c;
                                            l.Apttus_Config2__ChargeType__c=ali.Apttus_CMConfig__ChargeType__c;
                                            l.APTS_Asset_Change_type__c=ali.APTS_Asset_Change_type__c;
                                            l.Apttus_Config2__LineStatus__c = ali.Apttus_CMConfig__LineStatus__c;
                                              
                                            tempPAV = pavMap.get(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c)!=null?pavMap.get(ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c).clone():new Apttus_Config2__ProductAttributeValue__c();
                                            tempPAV.Apttus_Config2__LineItemId__c = l.id;

                                            insertList.add(tempPAV);

                                            l.Apttus_Config2__AttributeValueId__c=ali.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c;
                                            if(ali.Apttus_CMConfig__BasePriceOverride__c!=null)
                                                {
                                                    l.Apttus_Config2__BasePriceOverride__c=ali.Apttus_CMConfig__BasePriceOverride__c;
                                                }
                                            if(l.Apttus_Config2__LineType__c=='Option' && l.Apttus_Config2__ChargeType__c=='Sales Price' &&l.Apttus_Config2__SellingFrequency__c=='One Time')
                                                {
                                                    l.Apttus_Config2__EndDate__c=ali.Apttus_CMConfig__EndDate__c;
                                                }
                                            l.Apttus_Config2__PricingStatus__c = 'Complete'; 
                                            updateList.add(l);
                                            templiSet.add(l.id);
                                            tempaliSet.add(ali.id);
                                        }

                                }
                        }
                    update updateList;
                    insert insertList;
                    Decimal lineNumber = response.LineNumber;
                }
            Catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Add Bundle', oAGLI.Id, 'CLM', false, false, null, true);}
        }

    public static void submitadminorder(Id orderId) {
        try{
            List<Apttus_Config2__OrderLineItem__c> orderLineItemUpdateList = new List<Apttus_Config2__OrderLineItem__c>();
            for(Apttus_Config2__OrderLineItem__c orderLineItem : [SELECT Id, APTS_Item_Relevant_for_SAP__c, Apttus_Config2__ActivatedDate__c, Apttus_Config2__OrderId__c, APTS_Status__c FROM Apttus_Config2__OrderLineItem__c WHERE Apttus_Config2__OrderId__c =: orderId]){
                orderLineItem.Apttus_Config2__ActivatedDate__c = System.Today();
                orderLineItem.Apttus_Config2__ReadyForBillingDate__c = System.Today();
                orderLineItem.APTS_Item_Relevant_for_SAP__c = false;
                orderLineItemUpdateList.add(orderLineItem);
            }
            
            if(!orderLineItemUpdateList.IsEmpty()){
                APTS_OrderUtils.stopOrderLineItemTrigger();
                Database.SaveResult[] updateResult = Database.update(orderLineItemUpdateList, false);
                APTS_OrderUtils.startOrderLineItemTrigger();
            }
            //acceptorder(orderId);
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Submit Admin Order', orderId, 'OM', false, false, null, true);}
    }**/

    /** Method Name : setContractedProductsOnly
    * Description : Method to update Contracted_Products_Only__c and Enable_Invoice_Payment_Flag__c fields
    of Account based on Activated Agreement
    Used in AccountTriggerHandler
    **/
    public static void setContractedProductsOnly(List<Account> newAccountList, Map<Id, Account> oldAccountMap){
        try {
            Set<Id> allAccountIdSet = new Set<Id>();
            Map<Id, Apttus__APTS_Agreement__c> agreementToCPMap = new Map<Id, Apttus__APTS_Agreement__c>();

            for(Account oAccount : newAccountList){
                if(oAccount.Id == null){
                    if(String.IsNotBlank(oAccount.ParentId)) allAccountIdSet.add(oAccount.ParentId);
                    if(String.IsNotBlank(oAccount.APTS_Ultimate_Parent_Id__c)) allAccountIdSet.add(oAccount.APTS_Ultimate_Parent_Id__c);
                }else if(!oldAccountMap.isEmpty() && oldAccountMap.containsKey(oAccount.Id) && oldAccountMap.get(oAccount.Id) != null && oldAccountMap.get(oAccount.Id).ParentId != oAccount.ParentId){
                    allAccountIdSet.add(oAccount.Id);
                    if(String.IsNotBlank(oAccount.ParentId)) allAccountIdSet.add(oAccount.ParentId);
                    if(String.IsNotBlank(oAccount.APTS_Ultimate_Parent_Id__c)) allAccountIdSet.add(oAccount.APTS_Ultimate_Parent_Id__c);
                }
            }
            for(Apttus__APTS_Agreement__c oAgg : [SELECT Id,
                                                        Apttus__Account__c,
                                                        Apttus__Account__r.Enable_Invoice_Payment_Flag__c,
                                                        APTS_Order_Non_Contracted_Products__c
                                                        FROM Apttus__APTS_Agreement__c
                                                        WHERE Apttus__Status_Category__c = 'In Effect'
                                                        AND Apttus__Status__c = 'Activated'
                                                        AND Apttus__Account__c IN: allAccountIdSet
                                                        LIMIT 50000]){
                agreementToCPMap.put(oAgg.Apttus__Account__c, oAgg);
            }

            for(Account oAccount : newAccountList){
                //if(allAccountIdSet.contains(oAccount.Id) || allAccountIdSet.contains(oAccount.ParentId) || allAccountIdSet.contains(oAccount.APTS_Ultimate_Parent_Id__c)){
                    if(agreementToCPMap.containsKey(oAccount.ParentId) && agreementToCPMap.get(oAccount.ParentId) != null){
                        oAccount.Contracted_Products_Only__c = !(agreementToCPMap.get(oAccount.ParentId).APTS_Order_Non_Contracted_Products__c);
                        oAccount.Enable_Invoice_Payment_Flag__c = agreementToCPMap.get(oAccount.ParentId).Apttus__Account__r.Enable_Invoice_Payment_Flag__c;
                    }else if(agreementToCPMap.containsKey(oAccount.APTS_Ultimate_Parent_Id__c)  && agreementToCPMap.get(oAccount.APTS_Ultimate_Parent_Id__c) != null){
                        oAccount.Contracted_Products_Only__c = !(agreementToCPMap.get(oAccount.APTS_Ultimate_Parent_Id__c).APTS_Order_Non_Contracted_Products__c);
                        oAccount.Enable_Invoice_Payment_Flag__c = agreementToCPMap.get(oAccount.APTS_Ultimate_Parent_Id__c).Apttus__Account__r.Enable_Invoice_Payment_Flag__c;
                    }
                //}
            }
        } catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', String.valueof(ex), 'Contracted Products Only', newAccountList[0].Id, 'CLM', false, false, null, true);}
    }

    /** Method Name : mapAgreementFieldInALI
    * Description : Method to update Apttus_CMConfig__AgreementId__c field of Asset Line Item
    if it is different from APTS_relatedlist_agreement__c on ALI activation
    Used in APTS_AssetLineItemTriggerHandler
    **/
    public static void mapAgreementFieldInALI(List<Apttus_Config2__AssetLineItem__c> aLIList){
        try{
            for(Apttus_Config2__AssetLineItem__c aLI : aLIList){
                if(String.IsNotBlank(aLI.Apttus_CMConfig__AgreementId__c) && string.IsBlank(aLI.APTS_relatedlist_agreement__c)){ //V102
                    aLI.APTS_relatedlist_agreement__c = aLI.Apttus_CMConfig__AgreementId__c;
                }
            }
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'ALI Mapping', aLIList[0].Id, 'CLM', false, false, null, true);}
    }

    /** Method Name : populateAgreementInALI
    * Description : Method to populate APTS_relatedlist_agreement__c field of Asset Line Item
    on Agreement activation
    Used in APTS_AgreementTriggerHandler
    **/
    public static void populateAgreementInALI(List<Apttus__APTS_Agreement__c> agreementList){
        try{
            Map<String, Id> agreementNoToIdMap = new Map<String, Id>();
            List<Apttus_Config2__AssetLineItem__c> aLIUpdateList = new List<Apttus_Config2__AssetLineItem__c>();
            
            Set<Id> agreementSet = new Set<Id>();
            
            for(Apttus__APTS_Agreement__c oAgreement : agreementList){
                agreementNoToIdMap.put(oAgreement.Apttus__Agreement_Number__c, oAgreement.Id);
            }
            
            for(Apttus__APTS_Agreement__c oAgreement : [Select Id from Apttus__APTS_Agreement__c where Apttus__Agreement_Number__c IN: agreementNoToIdMap.keySet() LIMIT 50000]){
                agreementSet.add(oAgreement.Id);
            }

            for(Apttus_Config2__AssetLineItem__c oALI : [SELECT Id, 
                                                                APTS_relatedlist_agreement__c,
                                                                Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c,
                                                                Apttus_CMConfig__AgreementId__c
                                                                FROM Apttus_Config2__AssetLineItem__c
                                                                WHERE Apttus_CMConfig__AgreementId__c IN: agreementSet LIMIT 50000]){
                if(agreementNoToIdMap.containsKey(oALI.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c)){
                    oALI.APTS_relatedlist_agreement__c = agreementNoToIdMap.get(oALI.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c);
                    aLIUpdateList.add(oALI);
                }
            }

            APTS_CheckRecursive.processedSet.add('APTS_AssetLineItemTriggerHandlerBeforeUpdate');
            APTS_CheckRecursive.processedSet.add('APTS_AssetLineItemTriggerHandlerAfterUpdate');
            update aLIUpdateList;
            APTS_CheckRecursive.processedSet.remove('APTS_AssetLineItemTriggerHandlerBeforeUpdate');
            APTS_CheckRecursive.processedSet.remove('APTS_AssetLineItemTriggerHandlerAfterUpdate');
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Agreement Population', agreementList[0].Id, 'CLM', false, false, null, true);}
    }
    
    /** Method Name : amendPhysicalAssetUpdate
    * Description : Method to update PhysicalAssetPO Details on the agreement 
    Used in APTS_AgreementTriggerHandler
    **/
    public static void amendPhysicalAssetUpdate(Map<Id, Apttus__APTS_Agreement__c> activatedAgreementMap){
    
        try{
            Set<Id> physicalAssetId = new Set<Id>();
            Map<String, Id> agreementNoToIdMap = new Map<String, Id>();
            Set<Id> agreementSet = new Set<Id>();
            Map<Id, Apttus_Config2__AssetLineItem__c> physicalAssetIdToALIMap = new Map<Id, Apttus_Config2__AssetLineItem__c>();
            List<PhysicalAsset__c> physicalAssetUpdateList = new List<PhysicalAsset__c>();
            
            Map<Id, APTS_Agreement_PO_Details__c> idToAgreementPODetailsMap = new Map<Id, APTS_Agreement_PO_Details__c>();
                    
            for(Apttus__APTS_Agreement__c oAgreement : activatedAgreementMap.values()){
                agreementNoToIdMap.put(oAgreement.Apttus__Agreement_Number__c, oAgreement.Id);
            }
            
            for(Apttus__APTS_Agreement__c oAgreement : [SELECT Id
                                                                FROM Apttus__APTS_Agreement__c 
                                                                WHERE Apttus__Agreement_Number__c IN: agreementNoToIdMap.keySet() 
                                                                LIMIT 50000]){
                agreementSet.add(oAgreement.Id);
            }
            
            List<APTS_Agreement_PO_Details__c> poDetailsList = [SELECT Id,
                                                                    APTS_Agreement__c,
                                                                    APTS_Agreement__r.Apttus__Agreement_Number__c,
                                                                    APTS_PO_Number__c,
                                                                    APTS_PO_Number_Required__c,
                                                                    APTS_PO_Category__c,
                                                                    APTS_PO_Number_Type__c
                                                                    FROM APTS_Agreement_PO_Details__c
                                                                    WHERE APTS_Agreement__c IN :activatedAgreementMap.keySet()];

            for(Apttus_Config2__AssetLineItem__c aALI : [SELECT Id, 
                                                                APTS_Physical_Asset__c,
                                                                Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c,
                                                                Apttus_CMConfig__AgreementId__c
                                                                FROM Apttus_Config2__AssetLineItem__c
                                                                WHERE Apttus_CMConfig__AgreementId__c IN: agreementSet AND APTS_Serial_Number__c != null
                                                                AND APTS_Physical_Asset__c != null
                                                                LIMIT 50000]){
                physicalAssetIdToALIMap.put(aALI.APTS_Physical_Asset__c, aALI);
                system.debug('assetLineItem' +aALI);
            }

            if (!physicalAssetIdToALIMap.IsEmpty()) {
                for (PhysicalAsset__c updatedPA : [SELECT ID, 
                                                            PONumberMachines__c,
                                                            PONumberRequiredMachines__c,
                                                            PONumberTypeMachines__c,
                                                            PONumberServices__c,
                                                            PONumberRequiredServices__c,
                                                            PONumberTypeServices__c
                                                            FROM PhysicalAsset__c
                                                            WHERE Id IN: physicalAssetIdToALIMap.keyset()
                                                            LIMIT 50000]) {
                    Apttus_Config2__AssetLineItem__c aLI = physicalAssetIdToALIMap.get(updatedPA.Id);
                    APTS_OrderLineItemUtils.setAgreementPODetails(updatedPA, poDetailsList);
                    physicalAssetUpdateList.add(updatedPA);
                }    
            }
            
            if (!physicalAssetUpdateList.IsEmpty()) {
                update physicalAssetUpdateList;
            }
        }
        catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'APEX', ex.getStackTraceString() ,'Agreement PO Details', null,'CLM',false,false, null, true);}
    }
    
    /** Method Name : validateLock
    * Description : Method to lock the record creation and updation while lock Agreement checkbox is checked 
    Used in APTS_AgreementTriggerHandler
    **/
    public static void validateLock(List<sObject> newList, String apiObject){
        Set<Id> agreementSetId = new Set<Id>();
        Set<Id> lockAgreementSet = new Set<Id>();
        if(String.IsNotBlank(apiObject)){
            if(apiObject.equalsIgnoreCase('APTS_Agreement_Budget__c')){
                for(APTS_Agreement_Budget__c bud : (List<APTS_Agreement_Budget__c>) newList){
                    if(bud.Agreement__c != null){
                        agreementSetId.add(bud.Agreement__c);
                    }
                }
                for(Apttus__APTS_Agreement__c  agreement: [SELECT Id, APTS_Lock_Agreement__c FROM Apttus__APTS_Agreement__c  WHERE Id IN :agreementSetId AND APTS_Lock_Agreement__c = true]){
                    lockAgreementSet.add(agreement.Id);
                }
                for(APTS_Agreement_Budget__c bud : (List<APTS_Agreement_Budget__c>) newList){
                    if(lockAgreementSet.contains(bud.Agreement__c)){
                        bud.addError('Respective agreement is locked');
                    }
                }
            }

            if(apiObject.equalsIgnoreCase('Contracted_kpi_sla__c')){
                for(Contracted_kpi_sla__c kpiSla : (List<Contracted_kpi_sla__c>) newList){
                    if(kpiSla.kpi_contract__c!= null){
                       agreementSetId.add(kpiSla.kpi_contract__c);
                    }
                }
                for(Apttus__APTS_Agreement__c  agreement: [SELECT Id, APTS_Lock_Agreement__c FROM Apttus__APTS_Agreement__c  WHERE Id IN :agreementSetId AND APTS_Lock_Agreement__c = true]){
                    lockAgreementSet.add(agreement.Id);
                }
                for(Contracted_kpi_sla__c kpiSla : (List<Contracted_kpi_sla__c >) newList){
                    if(lockAgreementSet.contains(kpiSla.kpi_contract__c)){
                        kpiSla.addError('Respective agreement is locked');
                    }
                }
            }

            if(apiObject.equalsIgnoreCase('APTS_Billing_Settings__c')){
                for(APTS_Billing_Settings__c billingSetting : (List<APTS_Billing_Settings__c>) newList){
                    if(billingSetting.APTS_Agreement_ID__c!= null){
                        agreementSetId.add(billingSetting.APTS_Agreement_ID__c);
                    }
                }
                for(Apttus__APTS_Agreement__c  agreement: [SELECT Id, APTS_Lock_Agreement__c FROM Apttus__APTS_Agreement__c  WHERE Id IN :agreementSetId AND APTS_Lock_Agreement__c = true]){
                    lockAgreementSet.add(agreement.Id);
                }
                for(APTS_Billing_Settings__c billingSetting : (List<APTS_Billing_Settings__c >) newList){
                    if(lockAgreementSet.contains(billingSetting.APTS_Agreement_ID__c)){
                        billingSetting.addError('Respective agreement is locked');
                    }
                }
            }

            if(apiObject.equalsIgnoreCase('APTS_Index_Contract__c')){
                for(APTS_Index_Contract__c indexContract : (List<APTS_Index_Contract__c>) newList){
                    if(indexContract.APTS_Contract__c!= null){
                        agreementSetId.add(indexContract.APTS_Contract__c);
                    }
                }
                for(Apttus__APTS_Agreement__c  agreement: [SELECT Id, APTS_Lock_Agreement__c FROM Apttus__APTS_Agreement__c  WHERE Id IN :agreementSetId AND APTS_Lock_Agreement__c = true]){
                    lockAgreementSet.add(agreement.Id);
                }
                for(APTS_Index_Contract__c indexContract : (List<APTS_Index_Contract__c >) newList){
                    if(lockAgreementSet.contains(indexContract.APTS_Contract__c)){
                        indexContract.addError('Respective agreement is locked');
                    }
                }
            }
        }
    }

    /** Method Name : CMRDMRPenaltyCalculation
    Description : Method for CR Penalty Calculation DMR/CMR Integration 
    Used in APTS_AgreementTriggerHandler
    **/
    public static void CMRDMRPenaltyCalculation(Id orderId){
        List<Apttus_Config2__OrderLineItem__c> oLIList = new List<Apttus_Config2__OrderLineItem__c>();
        for(Apttus_Config2__OrderLineItem__c oLI : [SELECT Id,
                                                            Apttus_Config2__LineType__c,
                                                           Apttus_Config2__OrderId__c,
                                                            APTS_Item_Relevant_for_SAP__c,
                                                            Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c,
                                                            Apttus_Config2__AssetLineItemId__r.APTS_Serial_Number__c
                                                            FROM Apttus_Config2__OrderLineItem__c
                                                            WHERE Apttus_Config2__OrderId__c =: orderId AND 
                                                            (Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c = 'XC01' OR Apttus_Config2__OrderId__r.APTS_SAP_OrderType__c = 'XD01')
                                                            LIMIT 50000]){
            oLI.APTS_Cumulative_Spare_Parts_Coverage__c = 0;
            oLI.APTS_Cumulative_Call_Out_Coverage__c = 0;
            oLI.APTS_Cumulative_Labour_coverage__c = 0;
            if(PRODUCTSERVICE.equalsIgnoreCase(oLI.Apttus_Config2__LineType__c) && String.IsBlank(oLI.Apttus_Config2__AssetLineItemId__r.APTS_Serial_Number__c)){
                oLI.APTS_Item_Relevant_for_SAP__c = false;
            }
            oLIList.add(oLI);
        }
        
        if(oLIList != null){Database.update(oLIList, false);}
    }

    /** Method Name : createadminorder
    Description : Method moved from APTS_AgreementTriggerHandler inorder to resolve the CPU timeout issue 
    Used in APTS_AdminOrderQueue
    **/
    public static void createadminorder(Apttus__APTS_Agreement__c oAgreement, Account oAccount) {     
        try{
            Set<Id> adminAgreementIdSet = new Set<Id>();
            Apttus_Config2__Order__c oOrder;

            for(Apttus__AgreementLineItem__c oAGLI : [SELECT Id,
                                                                APTS_Asset_Change_type__c,
                                                                APTS_Serial_Number__c,
                                                                Apttus__AgreementId__c,
                                                                Apttus_CMConfig__LineNumber__c,
                                                                Apttus_CMConfig__AssetLineItemId__c,
                                                                Apttus_CMConfig__IsPrimaryLine__c,
                                                                Apttus_CMConfig__LineType__c,
                                                               Apttus__ProductId__c
                                                                FROM Apttus__AgreementLineItem__c
                                                                WHERE Apttus__AgreementId__c =: oAgreement.Id
                                                                AND ((Apttus_CMConfig__AssetLineItemId__c != null
                                                                AND APTS_Serial_Number__c != null
                                                                AND (APTS_Asset_Change_type__c = 'Non-Physical Conversion'
                                                                OR APTS_Asset_Change_type__c = 'Non-Physical Movement'
                                                                OR APTS_Asset_Change_type__c = 'Renewal')) OR APTS_Asset_Change_type__c = 'Registration')]) {
                adminAgreementIdSet.add(oAGLI.Apttus__AgreementId__c);
            }

            if(!adminAgreementIdSet.IsEmpty()) {
                oOrder = APTS_CLMUtil.createAdminOrder(oAgreement, oAccount, 'Conversion Order');
                if(oOrder != null) {insert oOrder;Id cartId = APTS_CLMUtil.processAdminOrder(oAgreement, oOrder);if(cartId != null && oOrder.Id != null){System.enqueueJob(new APTS_AdminOrderQueue(cartId,oOrder.Id,true));}}
}
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Batch', ex.getStackTraceString() ,'Agreement', null,'CLM',false,false, null, true);}

    }
    
    /** Method Name : agreementAdminChanges
    Description : 
    **/
    public static void agreementAdminChanges(Apttus__APTS_Agreement__c oAgreement, Account oAccount) {
        Set<Id> agreementIdSet = new Set<Id>();
        Set<Id> adminAgreementIdSet = new Set<Id>();
        Map<Integer, List<Id>> integerToALIMap = new Map<Integer, List<Id>>();
        Set<String> adminAgreementNoSet = new Set<String>();
        List<Id> assetLIIdList = new List<Id>();
        Set<String> aLISerialNoSet = new Set<String>();
        Integer assetCount = Integer.valueOf(Label.APTS_Admin_Order_Asset_Count);

        try{
            if(assetCount == 0){assetCount = 1;}
            
            if(oAgreement.APTS_Is_Admin_Order_Needed__c){
                adminAgreementNoSet.add(oAgreement.Apttus__Agreement_Number__c);
                adminAgreementIdSet.add(oAgreement.Id);
            }

            for(Apttus__APTS_Agreement__c agreement : [SELECT Id,
                                                                Apttus__Agreement_Number__c
                                                                FROM Apttus__APTS_Agreement__c 
                                                                WHERE Apttus__Agreement_Number__c IN: adminAgreementNoSet 
                                                                LIMIT 50000]){
                agreementIdSet.add(agreement.Id);
            }

            if(!adminAgreementIdSet.IsEmpty()){
                for(Apttus__AgreementLineItem__c aLI : [SELECT Id,
                                                                APTS_Serial_Number__c,
                                                                Apttus__AgreementId__c
                                                                FROM Apttus__AgreementLineItem__c
                                                                WHERE Apttus__AgreementId__c IN: adminAgreementIdSet
                                                                LIMIT 50000]){
                    aLISerialNoSet.add(aLI.APTS_Serial_Number__c);
                }

                for(Apttus_Config2__AssetLineItem__c assetLI : [SELECT Id,
                                                                        Apttus_Config2__LineType__c,
                                                                        Apttus_Config2__IsPrimaryLine__c,
                                                                        APTS_Type_Of_Contract__c,
                                                                        Apttus_Config2__BundleAssetId__c,
                                                                        APTS_Serial_Number__c,
                                                                        Apttus_CMConfig__AgreementId__c
                                                                        FROM Apttus_Config2__AssetLineItem__c
                                                                        WHERE Apttus_CMConfig__AgreementId__c IN: agreementIdSet
                                                                        AND APTS_Serial_Number__c NOT IN: aLISerialNoSet
                                                                        AND Apttus_Config2__LineType__c =: PRODUCTSERVICE
                                                                        LIMIT 50000]){
                    if(assetLI.Apttus_Config2__IsPrimaryLine__c){
                        assetLIIdList.add(assetLI.Id);
                    }else if(!assetLI.Apttus_Config2__IsPrimaryLine__c && String.IsNotBlank(assetLI.Apttus_Config2__BundleAssetId__c)){
                        assetLIIdList.add(assetLI.Apttus_Config2__BundleAssetId__c);
                    }
                }

                Integer j=0;
                Integer i=0;
                for(Id aLI : assetLIIdList){
                    if(i<=assetCount){
                        if(integerToALIMap.containsKey(j)){
                            List<Id> aLIList = integerToALIMap.get(j);
                            aLIList.add(aLI);
                            integerToALIMap.put(j, aLIList);
                        }else{
                            integerToALIMap.put(j, new List<Id>{aLI});
                        }
                        i++;
                        if(i==assetCount){j++;i=0;}
                    }
                }
                
                for(Integer mapKey : integerToALIMap.keySet()){
                    adminOrderCreationForAgg(oAgreement, oAccount, integerToALIMap.get(mapKey));
                }
            }
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Agreement', null, 'CLM', false, false, null, true);}
    }
    
    //Method to create Admin Order, Add Assets and does the finalize logic
    public static void adminOrderCreationForAgg(Apttus__APTS_Agreement__c oAgreement, Account oAccount, List<Id> assetLIIdList){
        try{
            Apttus_Config2__Order__c oOrder;
            oOrder = APTS_CLMUtil.createAdminOrder(oAgreement, oAccount, 'Conversion Order');
            if(oOrder != null) {
                insert oOrder;
                
                //Id cartId = APTS_CLMUtil.processAdminOrder(oAgreement, oOrder);
                Id cartId = APTS_OrderUtils.createCart(oOrder.Id);
               if(oOrder != null && !assetLIIdList.isEmpty()){
                    activateOrder(cartId, assetLIIdList, oOrder.Id);
                }
            }
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'AO Creation Method', null, 'CLM', false, false, null, true);}
    }
    
    //Order activation
    @future
    public static void activateOrder(Id cartId, List<Id> assetLIIdList, Id orderId) {
        Apttus_Config2.CPQStruct.ChangeAssetsRequestDO request = new Apttus_Config2.CPQStruct.ChangeAssetsRequestDO();
        request.AssetIds = assetLIIdList;
        request.CartId = cartId;
        Apttus_Config2.CPQStruct.ChangeAssetsResponseDO response = Apttus_Config2.AssetService.changeAssets(request);
        
        if(cartId != null && orderId != null) {
            System.enqueueJob(new APTS_AdminOrderQueue(cartId,orderId,true));
        }
    }
    
    public static void adminOrderPAUpdate(Id orderId) {
        try{
            List<Apttus_Config2__OrderLineItem__c> updatedOLIList = new List<Apttus_Config2__OrderLineItem__c>();
            Map<Id, String> parentIdToSerialNoMap = new Map<Id, String>();
            
            for(Apttus_Config2__OrderLineItem__c orderLineItem : [SELECT Id,
                                                                            APTS_Serial_Number__c,
                                                                            APTS_Is_Primary_L1_Line__c,
                                                                            APTS_Is_Primary_L1_Parent__c
                                                                            FROM Apttus_Config2__OrderLineItem__c
                                                                            WHERE Apttus_Config2__OrderId__c =: orderId
                                                                            AND APTS_Is_Primary_L1_Line__c = true
                                                                            AND APTS_Serial_Number__c != null
                                                                            AND APTS_Is_Primary_L1_Parent__c != null
                                                                            LIMIT 50000]){
                parentIdToSerialNoMap.put(orderLineItem.APTS_Is_Primary_L1_Parent__c, orderLineItem.APTS_Serial_Number__c);
            }
            
            for(Id parentId : parentIdToSerialNoMap.keySet()){
                Apttus_Config2__OrderLineItem__c oLI = new Apttus_Config2__OrderLineItem__c(Id=parentId);                
                oLI.APTS_Serial_Number__c = parentIdToSerialNoMap.get(parentId);
                updatedOLIList.add(oLI);
            }
            
            if(!updatedOLIList.isEmpty()){Database.update(updatedOLIList);}
            
        }catch(Exception ex){APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'adminOrderPAUpdate', orderId, 'CLM', false, false, null, true);}
    }

    /*
    * Method to update the billing date on order line items.
    */
    public static void updateReadyForBillingDateOnOrderLineItems(List<Apttus_Config2__OrderLineItem__c> childOLIList){
        
        for(Apttus_Config2__OrderLineItem__c orderLineSO : childOLIList){
            orderLineSO.Apttus_Config2__ReadyForBillingDate__c = orderLineSO.Apttus_Config2__StartDate__c;
            orderLineSO.Apttus_Config2__ActivatedDate__c = orderLineSO.Apttus_Config2__StartDate__c;
            orderLineSO.APTS_Item_Relevant_for_SAP__c = false;
        }
        if(childOLIList.size() > 0)
        {
            APTS_OrderUtils.stopOrderLineItemTrigger();
            update childOLIList;
            APTS_OrderUtils.startOrderLineItemTrigger();
        }
    }

    /*
   * Method to update Asset Line Item and Physical Assets on Agreement Activation.
    */
    public static void updateAssetsOnAgreementActivation(List<Apttus_Config2__AssetLineItem__c> assetLineItemList, Set<ID> agreementIdSet, Map<String, Id> agreementNoToIdMap, Map<String, APTS_Agreement_PO_Details__c> agreementPODetailsMap)
    {
        try
        {
            List<Apttus_Config2__AssetLineItem__c> aLIUpdateList = new List<Apttus_Config2__AssetLineItem__c>();
            List<PhysicalAsset__c> physicalAssetUpdateList = new List<PhysicalAsset__c>();
            Boolean updateAssets = false;
            /*<--DQ-12 START  Get Billing Settings after New Agreement Activation on Physical asset */
            Map<Id,Id> agreementIdBillingSettingMap = APTS_OrderLineItemUtils.getBillingSettings(agreementIdSet);           
            /* DQ-12 -- END>>*/        
            for(Apttus_Config2__AssetLineItem__c assetLineItemSO : assetLineItemList) {
                /*Update Agreement reference on Asset Line Items logic START*/
                if(agreementNoToIdMap != null && agreementNoToIdMap.containsKey(assetLineItemSO.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c))
                {
                   assetLineItemSO.APTS_relatedlist_agreement__c = agreementNoToIdMap.get(assetLineItemSO.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c);updateAssets = true;
                }
                /*Update Agreement reference on Asset Line Items logic END*/
                PhysicalAsset__c oPhysicalAsset = new PhysicalAsset__c();
                /*Update Physical Assets logic START*/
                if(agreementPODetailsMap != null && agreementPODetailsMap.size() > 0 && assetLineItemSO.APTS_Physical_Asset__c != null){                    
                    oPhysicalAsset.ID = assetLineItemSO.APTS_Physical_Asset__c;                 
                    if (agreementPODetailsMap.containsKey('Machine')){
                        APTS_Agreement_PO_Details__c oAgreementPODetails = agreementPODetailsMap.get('Machine');
                        oPhysicalAsset.PONumberRequiredMachines__c = (oAgreementPODetails.APTS_PO_Number_Required__c != null) ? oAgreementPODetails.APTS_PO_Number_Required__c : oPhysicalAsset.PONumberRequiredMachines__c;
                        oPhysicalAsset.PONumberTypeMachines__c = (oAgreementPODetails.APTS_PO_Number_Type__c != null) ? oAgreementPODetails.APTS_PO_Number_Type__c : oPhysicalAsset.PONumberTypeMachines__c;
                        oPhysicalAsset.PONumberMachines__c = (oAgreementPODetails.APTS_PO_Number__c != null) ? oAgreementPODetails.APTS_PO_Number__c : oPhysicalAsset.PONumberMachines__c;
                    }
                    else if (agreementPODetailsMap.containsKey('Services')){
                        APTS_Agreement_PO_Details__c oAgreementPODetails = agreementPODetailsMap.get('Services');
                        oPhysicalAsset.PONumberRequiredServices__c = (oAgreementPODetails.APTS_PO_Number_Required__c != null) ? oAgreementPODetails.APTS_PO_Number_Required__c : oPhysicalAsset.PONumberRequiredServices__c;
                        oPhysicalAsset.PONumberServices__c = (oAgreementPODetails.APTS_PO_Number__c != null) ? oAgreementPODetails.APTS_PO_Number__c : oPhysicalAsset.PONumberServices__c;
                        oPhysicalAsset.PONumberTypeServices__c = (oAgreementPODetails.APTS_PO_Number_Type__c != null) ? oAgreementPODetails.APTS_PO_Number_Type__c : oPhysicalAsset.PONumberTypeServices__c;
                    }                    
                }
                /*<--DQ-12 START  Get Billing Settings after New Agreement Activation on Physical asset */
                if(agreementIdBillingSettingMap != null && assetLineItemSO.APTS_relatedlist_agreement__c != null &&
                     agreementIdBillingSettingMap.containskey(assetLineItemSO.APTS_relatedlist_agreement__c) && assetLineItemSO.APTS_Physical_Asset__c != null) {
                     oPhysicalAsset.Id = assetLineItemSO.APTS_Physical_Asset__c;oPhysicalAsset.Billing_Setting__c = agreementIdBillingSettingMap.get(assetLineItemSO.APTS_relatedlist_agreement__c);
                }
                /* DQ-12 -- END>>*/ 

                if(oPhysicalAsset.id != NULL){physicalAssetUpdateList.add(oPhysicalAsset);}

                /*Update Physical Assets logic END*/
            }
            /*Update Agreement reference on Asset Line Items logic START*/
            if(updateAssets){
                APTS_CheckRecursive.processedSet.add('APTS_AssetLineItemTriggerHandlerBeforeUpdate');APTS_CheckRecursive.processedSet.add('APTS_AssetLineItemTriggerHandlerAfterUpdate');update assetLineItemList;APTS_CheckRecursive.processedSet.remove('APTS_AssetLineItemTriggerHandlerBeforeUpdate');APTS_CheckRecursive.processedSet.remove('APTS_AssetLineItemTriggerHandlerAfterUpdate');
            }
           /*Update Agreement reference on Asset Line Items logic END*/
            /*Update Physical Assets logic START*/
            if (physicalAssetUpdateList.size() > 0){update physicalAssetUpdateList;}
            /*Update Physical Assets logic END*/
        }
        catch(Exception ex)
        {
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'APEX', ex.getStackTraceString()+' Message:'+ex.getMessage() ,'Update Assets on Agreement Activation', null,'CLM',false,false, null, true);
        }
    }        

     //Method to invoke batch.
     public static void invokeCERRecordsBatch(List <Apttus__APTS_Agreement__c> agrtList) {
        List<APTS_CER_Transaction__c> cerTransList = new List <APTS_CER_Transaction__c> ();
        Integer batchSize = Integer.valueOf(System.label.CERQueueableBatchSize);
        APTS_updateCERRecordsBatch updateCER  = new APTS_updateCERRecordsBatch(cerTransList);
         if(!Test.isRunningTest()) //V102
             Database.executeBatch(updateCER, batchSize);
    }     
}