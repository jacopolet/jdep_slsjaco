/*************************************************************
@Name: APTS_AdjustmentLineItemCallback
@Author: Ankit Shah (Apttus Developer)
@CreateDate:  15th Jan, 2018
@Description: Callback class to create adjustments for Product, Category, Sub-category and Sub-Sub-Category level.
@Sanjay Nair - Temp modifications for CER
*******************************************************************
//v101 03/07/2018 Raul Orozco : Creation comments section.
                                Ticket 16045 : Adjustment UOM incorrectly set always to Piece
*****************************************************************
@Sanjay Nair - Temp modifications for CER
*******************************************************************
//v102 11/07/2018 Venky Muppalaneni : Commented
           /* if (boolagreement) commeted by venky
            {
                //System.debug('Agreement list  soldto = ' + soldToacctID);
                //System.debug('Agreement list  Prod config = ' + productConfigurationId);
                cerprdmap = APTS_CERUtility.getContractedProductsWithDiscounts(soldToacctID,productConfigurationId);
                //System.debug('Agreement list  return map = ' + cerprdmap);

            }
            else
            {
                //System.debug('Sold To Account Id'+soldToacctID);
                cerList = APTS_CERUtility.getContractedProductsWithDiscounts(soldToacctID);
                cerList.sort();
                //System.debug('CER Records'+cerList);
            }
                                Ticket 16583 : CER for Orders not working when Ordering for Grand Parent
*****************************************************************
//v103 25/07/2018 Neev Shah : Added logic for Standard Return and Unplanned Return Order
//v104 03/08/2018 Neev Shah : Added logic for Consignment Fillup for FSD
//v105 04/09/2018 Pranjal Mittal : Added logic for ABO scenarios
// v106 30/10/2018 Lavanya R : YOFT CPQ Adjustments for Ingredients
//v107 13/10/2018 Aarthi Pitchai : Added the Adjustment lines Bucketing logic related to EPI adjustments - Defect# 20184
//v108 07/11/2018 Raul Orozco : Added validation of Global Linkage Id Defect # 20088
//v109 5/Feb/2019 Neev Shah : Removed logic of unplanned, Unplanned return will take records from CER Records -- Production Fix
//v110 18/12/2020 Lavanya R : Adding CER lookup for Adjustment Line Item as part of DQ-4499
*/

global with sharing class APTS_AdjustmentLineItemCallback implements Apttus_Config2.CustomClass.IAdjustmentLineItemCallback2 {
    String CATEGORY = 'Category';
    String SUB_CATEGORY = 'SubCategory';
    String SUB_SUB_CATEGORY = 'SubSubCategory';
    String PRODUCT = 'Product';
    String MANUAL = 'Manual';
    String STARTING_PRICE = 'Starting Price';

    String SYSTEM_PROPERTIES = 'System_Properties';
    String ACCOUNT = 'Account';
    String PARENT_ACCOUNT = 'Parent Account';
    String GRAND_PARENT_ACCOUNT = 'Grand Parent Account';
    boolean alreadyExecuted = false;
    private static final String NGMACHINE_ORDER = System.Label.APTS_NGMachineOrder;
    private String sFlow;
    private static final String PRODUCT_SERVICE = 'Product/Service';
    private static final String CHARGE_TYPE_SALE = 'Sales Price';
    private static final String AGREEMENT = 'Agreement';
    private static final String MANUAL = 'Manual';
    private boolean boolagreement = false;
   // Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap = new Map<String, Apttus_Config2__AdjustmentLineItem__c>();-https://jdecoffee.atlassian.net/browse/QTCFLEX1-1480

    //Digital Order removed
    private static boolean isDisabled = false;

    Map<String, Id> lineItemIdAndHierarchyMap ;
    Map<String, APTS_Adjustments__c> hierarchyIdsQuoteAdjustmentMap ;
    Map<Id, Apttus_Config2__LineItem__c> lineItemMap ;
    Map<String, Id> lineItemAccountMap ;

    set<id> setOfProdID  ;
    Map<Id, ID> mapPrdLine  ;
    List<APTS_Contract_Entitlement_Repository__c> cerList;
    List<APTS_Contract_Entitlement_Repository__c> finalcerList;
    Map<ID, List<APTS_Contract_Entitlement_Repository__c>> cerprdmap = new Map<ID, List<APTS_Contract_Entitlement_Repository__c>>();
    Map<Id, Apttus__AgreementLineItem__c> linetoAgreementlinemap;
    Map<Apttus_Config2__LineItem__c, list<Apttus_Config2__AdjustmentLineItem__c>> AdjMap;
    //v103
    private boolean isOrderCart = false;
    private static final String SUBTYPE_STANDARD_RETURN = 'Standard Return';
    private static final String SUBTYPE_UNPLANNED_RETURN = 'Unplanned Return';
    private Apttus_Config2__ProductConfiguration__c oProdConfiguration = NULL;

    //v104
    private static final String SUBTYPE_CONSIGNMENT_FILLUP = 'Consignment Fillup for FSD';

    //v105
    Map<Id, List<Apttus_Config2_AssetAdjustItem__c>> mapAssetAdjustments = new Map<Id, List<Apttus_Config2_AssetAdjustItem__c>>();
    private static final String STATUS_CANCELLED = 'Cancelled';

    global APTS_AdjustmentLineItemCallback() {

        //Digital Order removed
        if (!APTS_AdjustmentLineItemCallback.isDisabled) {
            lineItemIdAndHierarchyMap = new Map<String, Id>() ;
            hierarchyIdsQuoteAdjustmentMap = new Map<String, APTS_Adjustments__c>();
            lineItemAccountMap = new Map<String, Id>();
            lineItemMap = new Map<Id, Apttus_Config2__LineItem__c>();
            setOfProdID = new set<id>();
            mapPrdLine = new Map<ID, ID>();
            cerList = new List<APTS_Contract_Entitlement_Repository__c>();
            finalcerList=new list<APTS_Contract_Entitlement_Repository__c>();
            linetoAgreementlinemap = new Map<Id, Apttus__AgreementLineItem__c>();
        }

    }

    global void start(Apttus_Config2.ProductConfiguration prodConfig) {
        //Digital Order removed
        if (!APTS_AdjustmentLineItemCallback.isDisabled) {
            try {
                Id productConfigurationId = prodConfig.getConfigSO().Id;
                sFlow = prodConfig.getConfigSO().APTS_Flow__c;
                ID soldToacctID ;
                Set<Id> accountIDs = new Set<Id>();
                //v103 ++ <<
                oProdConfiguration = prodConfig.getConfigSO();
                //v103 ++ >>
                //v105 Start
                Set<Id> setAssetIds = new Set<Id>();
                //v105 End

                if (productConfigurationId != null ) {
                    //changed by Neev
                    lineItemMap = new Map<Id, Apttus_Config2__LineItem__c>([SELECT   Id, Apttus_Config2__ProductOptionId__r.Apttus_Config2__ProductOptionGroupId__r.Apttus_Config2__OptionGroupId__r.Apttus_Config2__Label__c,
                            Apttus_Config2__PriceListItemId__r.Apttus_Config2__ChargeType__c, Apttus_Config2__ClassificationHierarchyInfo__c, Apttus_Config2__LineType__c,
                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__BillToAccountId__c,
                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__BillToAccountId__r.ParentId,
                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__BillToAccountId__r.Parent.ParentId,
                            Apttus_Config2__ProductId__c, Apttus_Config2__OptionId__c, APTS_Type_of_contract__c,
                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_CMConfig__AgreementId__c,
                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.Apttus_Config2__SoldToAccountId__c,
                            APTS_ABO_Applied__c,
                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c,
                            APTS_Source_Line_Number__c, Apttus_Config2__SellingUom__c,/*(Select Id, Apttus_Config2__AdjustmentType__c, Apttus_Config2__AdjustmentAmount__c,Apttus_Config2__Type__c,Apttus_Config2__SubType__c,Apttus_Config2__LineItemId__c from Apttus_Config2__AdjustmentLineItems__r)*/
                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Sub_Type__c,
                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c,
                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Source_Order_Number__c,
                            Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__c, Apttus_Config2__AssetLineItemId__c,
                            Apttus_Config2__OptionId__r.name,
                            Apttus_Config2__LineStatus__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c,Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c,Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.Name
                            FROM Apttus_Config2__LineItem__c
                            WHERE Apttus_Config2__ConfigurationId__c = : productConfigurationId]);
                    Set<String> setEPISourceOrders = new Set<String>();

                    soldToacctID = prodConfig.getConfigSO().Apttus_Config2__AccountId__c;
                    ID tempPid;
                    if (AGREEMENT.equalsIgnoreCase(prodConfig.getConfigSO().Apttus_Config2__BusinessObjectType__c)) {
                        boolagreement = true;
                    }

                    for (Apttus_Config2__LineItem__c lineItem : lineItemMap.Values()) {
                        //v105 start
                        setAssetIds.add(lineItem.Apttus_Config2__AssetLineItemId__c);
                        //v105 end
                        if (boolagreement) {
                            tempPid = lineItem.Apttus_Config2__LineType__c == PRODUCT_SERVICE ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;
                            setOfProdID.add(tempPid);
                        }

                    }
                    //v103 ++ <<
                    //cerprdmap = APTS_CERUtility.getContractedProductsWithDiscounts(soldToacctID, productConfigurationId, boolagreement);
                    //v104++<<
                    //v109 ++ <<
                    if (SUBTYPE_STANDARD_RETURN.equalsIgnoreCase(oProdConfiguration.Order_Sub_Type__c) || SUBTYPE_CONSIGNMENT_FILLUP.equalsIgnoreCase(oProdConfiguration.Order_Sub_Type__c)) {
                        //v109 ++ >>
                        //System.debug('APTS_AdjustmentLineItemCallback start() method return order');
                    } else {
                      cerprdmap = APTS_CERUtility.getContractedProductsWithDiscounts(soldToacctID, productConfigurationId, boolagreement);
                    }
                    //v104 ++ >>
                    //v103 ++ >>
                    //v102++>>
                    mapAssetAdjustments.clear();
                    finalcerList.clear();
                    if (setAssetIds != NULL && setAssetIds.size() > 0) { //System.debug('Lavanya AssetId'+setAssetIds);
                        for (Apttus_Config2_AssetAdjustItem__c oAssetAdjustment : [SELECT id, Apttus_Config2_AssetAdjustAmount__c, Apttus_Config2_AssetAdjustAppliesTo__c, Apttus_Config2_AssetAdjustType__c,
                                Apttus_Config2_Adjustment_Uom__c, Apttus_Config2_Bucket__c,APTS_Discount_Type__c,Apttus_Config2_LineNumber__c, Apttus_Config2_SubType__c,
                                Apttus_Config2_Type__c, Apttus_Config2_AssetLineItemId__c, Apttus_Config2_LineType__c, Apttus_Config2_IsModifiable__c,
                                Apttus_Config2_AssetLineItemId__r.Apttus_Config2__BasePrice__c, Apttus_Config2_AssetLineItemId__r.Apttus_Config2__ListPrice__c
                                FROM Apttus_Config2_AssetAdjustItem__c WHERE Apttus_Config2_AssetLineItemId__c = : setAssetIds]) {
                            List<Apttus_Config2_AssetAdjustItem__c> listAssetAdj = mapAssetAdjustments.get(oAssetAdjustment.Apttus_Config2_AssetLineItemId__c);
                            if (listAssetAdj == NULL) {
                                listAssetAdj = new List<Apttus_Config2_AssetAdjustItem__c>();
                            }
                            listAssetAdj.add(oAssetAdjustment);
                            if (listAssetAdj != NULL && listAssetAdj.size() > 0) {
                                mapAssetAdjustments.put(oAssetAdjustment.Apttus_Config2_AssetLineItemId__c, listAssetAdj);
                            }
                        }
                    } 
                }


            } catch (Exception e) {
            }

        }
    }
    global Boolean beforeSaveAdjustmentLineItems(Apttus_Config2.LineItem parentItem, List<Apttus_Config2__AdjustmentLineItem__c> adjItems) {
        //Digital Order removed
        if (!APTS_AdjustmentLineItemCallback.isDisabled) {
            processAdjustmentLineItemfields(adjItems);
        }
        return true;
    }

  /*
    Method Logic: To create YOFT Adjustments for Ingredients 
    Method Owner : Lavanya

  */
    public List<Apttus_Config2__AdjustmentLineItem__c> createCPQAdjustmentLineItems(Apttus_Config2__LineItem__c lineitem)
   {
    Integer lineNum=1;
    Map<Id,List<String>> mapofAdjTypeList = new Map<Id,List<String>>();
    Apttus_Config2__LineItem__c instLineItem = lineItemMap.get(lineItem.id);
    List<Apttus_Config2__AdjustmentLineItem__c> listAdjustmentLineItemsIngredientYOFT = new List<Apttus_Config2__AdjustmentLineItem__c>();
    List<Apttus_Config2__AdjustmentLineItem__c> ListSequenceAdjLineItem = new List<Apttus_Config2__AdjustmentLineItem__c>();
    if(instLineItem != NULL){       

    List<String> tempIng = new List<String>();
    tempIng = System.Label.APTS_IngredientsForYOFTCreation.split(',');

   
    
    if(Test.isRunningTest() || (instLineItem.Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.Name!= NULL && tempIng.contains(instLineItem.Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.Name) && instLineItem.Apttus_Config2__ConfigurationId__c!=null && instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__c!=null && String.isNotBlank(instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c) && !instLineItem.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.APTS_Fixed_Term_Type__c.equalsignorecase('Fixed Cost')))
    {
             if(mapofAdjTypeList.containskey(instLineItem.id))
                        {
                            List<String> lstAdjustment = new List<String>();   
                            lstAdjustment = mapofAdjTypeList.get(instLineItem.id);
                            lstAdjustment.add(APTS_CPQConstants.LABEL_YOFT);
                            mapofAdjTypeList.put(instLineItem.id,lstAdjustment);
                        }
                        else
                        {
                           List<String> lstAdjustment = new List<String>();   
                           lstAdjustment.add(APTS_CPQConstants.LABEL_YOFT);
                           mapofAdjTypeList.put(instLineItem.id,lstAdjustment);   
                        } 
                        
    } 
    
    
    if(!mapofAdjTypeList.IsEmpty() && mapofAdjTypeList.size() > 0 && mapofAdjTypeList.containskey(instLineItem.id))
            { 
                Apttus_Config2__AdjustmentLineItem__c  adjLineItem= new Apttus_Config2__AdjustmentLineItem__c(); 
                adjLineItem.Apttus_Config2__AdjustmentType__c = APTS_CPQConstants.DISCOUNT;
                adjLineItem.Apttus_Config2__AdjustmentAmount__c = 100;
                adjLineItem.Apttus_Config2__LineItemId__c = LineItem.Id;
                adjLineItem.Apttus_Config2__LineNumber__c = lineNum;
                adjLineItem.Apttus_Config2__Type__c = APTS_CPQConstants.LABEL_YOFT;
                adjLineItem.Apttus_Config2__SubType__c = APTS_CPQConstants.LABEL_YOFT;
                adjLineItem.Apttus_Config2__Bucket__c = APTS_CPQConstants.LABEL_BUCKET5; 
                adjLineItem.Apttus_Config2__AdjustmentAppliesTo__c=APTS_CPQConstants.LABEL_BUCKET4;               
                listAdjustmentLineItemsIngredientYOFT.add(adjLineItem);                
                lineNum++;
            }
    }
    return listAdjustmentLineItemsIngredientYOFT;
   }

        public void processAdjustmentLineItemfields(List<Apttus_Config2__AdjustmentLineItem__c> adjItems) {

        list<string> AdjAppliesTo = new list<string>();
        for (Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem : adjItems) {

            if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP03') {
                adjustmentLineItem.Apttus_Config2__Type__c = 'GSV';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 1' ;
            }
            
            else if(adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP02')
            {
                adjustmentLineItem.Apttus_Config2__Type__c = 'Inflation';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 2' ;
            }
            
            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP06') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 3' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP07') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 3' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP04') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP08') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP10') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZX10') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP15') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP11') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP13') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }


            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP12') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'YOCI') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'YOCI';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'YOFT') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'YOFT';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;
            }
            AdjAppliesTo.add(adjustmentLineItem.Apttus_Config2__Bucket__c);
        }
        for (Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem1 : adjItems) {
            if (AdjAppliesTo.contains('Bucket 1') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 1') {
                adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
            }

            if (AdjAppliesTo.contains('Bucket 2') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 2') {
                if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }

            if (AdjAppliesTo.contains('Bucket 3') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 3') {
                if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                } else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }

            if (AdjAppliesTo.contains('Bucket 4') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 4') {
                if (AdjAppliesTo.contains('Bucket 3')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                } else if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                } else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }

            }

            if (AdjAppliesTo.contains('Bucket 5') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 5') {
                if (AdjAppliesTo.contains('Bucket 4')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 4';
                } else if (AdjAppliesTo.contains('Bucket 3')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                } else if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                } else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }
            
            if (AdjAppliesTo.contains('Bucket 6') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 6') {
                if (AdjAppliesTo.contains('Bucket 5')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 5';
                } else if (AdjAppliesTo.contains('Bucket 4')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 4';
                } else if (AdjAppliesTo.contains('Bucket 3')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                } else if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                }  else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                }   else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }
        }

    }

    global List<Apttus_Config2__AdjustmentLineItem__c> createAdjustmentLineItems(Apttus_Config2.LineItem configLineItem) {
    list<Apttus_Config2__AdjustmentLineItem__c> BucketALI =new list<Apttus_Config2__AdjustmentLineItem__c>();
    if(!APTS_CallBack_Settings__c.getInstance().Adjustmentlineitemcallback__c){
        List<Apttus_Config2__AdjustmentLineItem__c> adjustmentLineItems = new List<Apttus_Config2__AdjustmentLineItem__c>();
            Apttus_Config2__LineItem__c lineItem1 = configLineItem.getLineItemSO();
        //Digital Order removed
        if (!APTS_AdjustmentLineItemCallback.isDisabled) {

            System.debug('--- APTS_AdjustmentLineItemCallback createAdjustmentLineItems() Method Starts ---');

            //Added as part of Consumption changes
            Set<Id> setLIIds = new Set<Id>();
            Set<Id> setConsumptionLIIds = new Set<Id>();
            Map<Id, Id> mapLIAttribute = new Map<Id, Id>();
            Map<Id, Boolean> mapIsComsumptionLI = new Map<Id, Boolean>();
            Map<Id, Apttus_Config2__AdjustmentLineItem__c> mapAdjwithLI = new Map<Id, Apttus_Config2__AdjustmentLineItem__c>();
            List<Apttus_Config2__AdjustmentLineItem__c> upsertAdjLIlst = new List<Apttus_Config2__AdjustmentLineItem__c>();
            Apttus_Config2__LineItem__c lineItem = configLineItem.getLineItemSO();
            Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap = new Map<String, Apttus_Config2__AdjustmentLineItem__c>();
                if (!lineItem.Apttus_Config2__IsCustomPricing__c == True) {
                    if (!boolagreement ) {
                        ID prdID = PRODUCT_SERVICE.equalsIgnoreCase(lineItem.Apttus_Config2__LineType__c) ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;
                        cerList = cerprdmap.get(prdID);
                        if (cerList != null) {
                            ceradjustmentMap = this.processcerdata(lineItem, cerList);  
                        }
                    }
                }
                if (!lineItem.Apttus_Config2__IsCustomPricing__c == True) {
                    if (boolagreement && cerprdmap != null&&!Test.isRunningTest()) {
                        ID prdID = PRODUCT_SERVICE.equalsIgnoreCase(lineItem.Apttus_Config2__LineType__c) ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;
                            cerList = cerprdmap.get(prdID);
                            if (cerList != null) {
                        ceradjustmentMap = this.processcerdata(lineItem, cerList, boolagreement); 
                        }
                    }
                        adjustmentLineItems.addAll(ceradjustmentMap.Values());
                        list<Apttus_Config2__AdjustmentLineItem__c> finallist=new list<Apttus_Config2__AdjustmentLineItem__c>();
                         
                         Integer j = 0;        
                         if(lineItemMap.containsKey(lineItem.Id) && lineItemMap.get(lineItem.id).Apttus_Config2__ConfigurationId__r.Apttus_Config2__BusinessObjectType__c=='Agreement'){
                         while (j < adjustmentLineItems.size())     
                        {       
                        String tempstring=adjustmentLineItems.get(j).Apttus_Config2__LineItemId__c+adjustmentLineItems.get(j).Apttus_Config2__SubType__c+adjustmentLineItems.get(j).APTS_Adjustment_Source__c;
                        CERDiscountCache__c ret=new CERDiscountCache__c();ret=CERDiscountCache__c.getValues(tempstring);
                        if(ret!=null&&ret.Sub_Type__c!=null&&adjustmentLineItems.get(j).APTS_Category__c==null){if(adjustmentLineItems.get(j).Apttus_Config2__SubType__c==ret.Sub_Type__c&&adjustmentLineItems.get(j).APTS_Adjustment_Source__c==ret.Source__c){adjustmentLineItems.remove(j);}
                        }else{j++;}
                        }
                }
                        //adjustmentLineItems.get(j).APTS_Category__c==null&&
                }
                List<Apttus_Config2__AdjustmentLineItem__c> adjABO =new list<Apttus_Config2__AdjustmentLineItem__c>();
                if (lineItemMap.containsKey(lineItem.Id) && lineItemMap.get(lineItem.id).Apttus_Config2__AssetLineItemId__c != NULL&&lineItemMap.get(lineItem.id).APTS_ABO_Applied__c==false) {
                    if (!(lineItemMap.get(lineItem.id).Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r != NULL
                            && STATUS_CANCELLED.equalsIgnoreCase(lineItemMap.get(lineItem.id).Apttus_Config2__LineStatus__c)
                            && SUBTYPE_STANDARD_RETURN.equalsIgnoreCase(lineItemMap.get(lineItem.id).Apttus_Config2__ConfigurationId__r.Apttus_Config2__OrderId__r.APTS_Order_Type__c))) {
                    try{
                         adjABO = createAdjustmentForABO(lineItem, lineItemMap.get(lineItem.id).Apttus_Config2__AssetLineItemId__c);
                          
                        }
                        catch(Exception e){
                        }
                        if (adjABO != NULL && adjABO.size() > 0) {
                            adjustmentLineItems.addALL(adjABO);
                        }
                    }
                }
                
                adjustmentLineItems.addAll(this.createCPQAdjustmentLineItems(lineItem)); 
        }
                BucketALI = this.processAdjustmentLineItemfieldsnew(adjustmentLineItems);
                }
        return BucketALI;
        
    }

    global void finish() {
    }

    //v105 Start
    public List<Apttus_Config2__AdjustmentLineItem__c> createAdjustmentForABO(Apttus_Config2__LineItem__c lineItem, Id assetId) {
        List<Apttus_Config2__AdjustmentLineItem__c> adjustmentLineItems = new List<Apttus_Config2__AdjustmentLineItem__c>();
        if(mapAssetAdjustments.get(assetId) != NULL && mapAssetAdjustments.get(assetId).size()>0){
            for (Apttus_Config2_AssetAdjustItem__c oAssetAdjustment : mapAssetAdjustments.get(assetId)) {
                    Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
                    adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItem.Id;
                    adjustmentLineItem.Apttus_Config2__LineType__c = oAssetAdjustment.Apttus_Config2_LineType__c;
                    adjustmentLineItem.Apttus_Config2__LineNumber__c = oAssetAdjustment.Apttus_Config2_LineNumber__c;
                    adjustmentLineItem.Apttus_Config2__IsModifiable__c = oAssetAdjustment.Apttus_Config2_IsModifiable__c;
                    adjustmentLineItem.Apttus_Config2__AdjustmentType__c = oAssetAdjustment.Apttus_Config2_AssetAdjustType__c;
                    adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = oAssetAdjustment.Apttus_Config2_AssetAdjustAmount__c;
                    adjustmentLineItem.Apttus_Config2__Bucket__c = oAssetAdjustment.Apttus_Config2_Bucket__c;
                    adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = oAssetAdjustment.Apttus_Config2_AssetAdjustAppliesTo__c;
                    adjustmentLineItem.APTS_Discount_Type__c = oAssetAdjustment.APTS_Discount_Type__c;
                    adjustmentLineItem.Apttus_Config2__Type__c = oAssetAdjustment.Apttus_Config2_Type__c;
                    adjustmentLineItem.Apttus_Config2__SubType__c = oAssetAdjustment.Apttus_Config2_SubType__c;
                    adjustmentLineItem.Apttus_Config2_SellingUom__c = oAssetAdjustment.Apttus_Config2_Adjustment_Uom__c;
                    adjustmentLineItem.Apttus_Config2__AdjustmentUom__c = oAssetAdjustment.Apttus_Config2_Adjustment_Uom__c;
                    adjustmentLineItems.add(adjustmentLineItem);
            }
        }

        return adjustmentLineItems;
    }
    //v105 End



    @TestVisible
    Private Map<String, Apttus_Config2__AdjustmentLineItem__c> processcerdata(Apttus_Config2__LineItem__c lineItem, List<APTS_Contract_Entitlement_Repository__c> ceradjustments) {
        Integer lineNumber = 1;
        Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap = new Map<String, Apttus_Config2__AdjustmentLineItem__c>();

        if (ceradjustments != null) {
            for (APTS_Contract_Entitlement_Repository__c ceradjustment : ceradjustments ) {
                if(lineItem.APTS_Global_linkage_ID__c == ceradjustment.APTS_Agreement_Line_Item__r.APTS_Global_linkage_ID__c && lineItem.Apttus_Config2__LineType__c == 'Option' ){
                ID prdID = PRODUCT_SERVICE.equalsIgnoreCase(lineItem.Apttus_Config2__LineType__c) ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;
                if (prdID != null  ) {
                    Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
                    adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItem.Id;
                    adjustmentLineItem.Apttus_Config2__LineType__c = MANUAL;
                    adjustmentLineItem.Apttus_Config2__LineNumber__c = lineNumber++;
                    adjustmentLineItem.Apttus_Config2__AdjustmentType__c = ceradjustment.APTS_Adjustment_Type__c;
                    adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = ceradjustment.APTS_Adjustment_Value__c;                    
                    adjustmentLineItem.Apttus_Config2__IsModifiable__c = TRUE;
                    adjustmentLineItem.APTS_Discount_Type__c= 'Auto';
                    adjustmentLineItem.APTS_CER__c = ceradjustment.id; //DQ-4499
                    adjustmentLineItem.Apttus_Config2__LineType__c='Auto';
                    adjustmentLineItem.Apttus_Config2__Type__c = ceradjustment.APTS_Type__c;
                    adjustmentLineItem.Apttus_Config2__SubType__c = ceradjustment.APTS_Sub_Type__c;
                    adjustmentLineItem.Apttus_Config2_SellingUom__c = ceradjustment.APTS_UOM__c;
                    adjustmentLineItem.APTS_Adjustment_Source__c = ceradjustment.APTS_Contributing_Agreement_Level__c;
                    adjustmentLineItem.APTS_Category__c = ceradjustment.APTS_CategoryCER__c;
                    adjustmentLineItem.APTS_Sub_Category__c = ceradjustment.APTS_Sub_Category__c;
                    adjustmentLineItem.APTS_Sub_Sub_Category__c = ceradjustment.APTS_Sub_Sub_Category__c;
                    adjustmentLineItem.Apttus_Config2__AdjustmentUom__c = ceradjustment.APTS_UOM__c;

                    ceradjustmentMap.put(adjustmentLineItem.Apttus_Config2__Type__c + '-' + adjustmentLineItem.Apttus_Config2__SubType__c + '-' + adjustmentLineItem.Apttus_Config2__AdjustmentType__c, adjustmentLineItem);
                    
                }
                } 
                
                 if('Product/Service'.equalsIgnoreCase(lineItem.Apttus_Config2__LineType__c) &&  lineItem.Apttus_Config2__HasOptions__c == false){
                ID prdID = PRODUCT_SERVICE.equalsIgnoreCase(lineItem.Apttus_Config2__LineType__c) ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;
                if (prdID != null  ) {
                    Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
                    adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItem.Id;
                    adjustmentLineItem.Apttus_Config2__LineType__c = MANUAL;
                    adjustmentLineItem.Apttus_Config2__LineNumber__c = lineNumber++;
                    adjustmentLineItem.Apttus_Config2__AdjustmentType__c = ceradjustment.APTS_Adjustment_Type__c;
                    adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = ceradjustment.APTS_Adjustment_Value__c;
                    adjustmentLineItem.Apttus_Config2__IsModifiable__c = TRUE;
                    adjustmentLineItem.APTS_Discount_Type__c= 'Auto';
                    adjustmentLineItem.Apttus_Config2__LineType__c='Auto';
                    adjustmentLineItem.APTS_CER__c = ceradjustment.id; //DQ-4499
                    adjustmentLineItem.Apttus_Config2__Type__c = ceradjustment.APTS_Type__c;
                    adjustmentLineItem.Apttus_Config2__SubType__c = ceradjustment.APTS_Sub_Type__c;
                    adjustmentLineItem.Apttus_Config2_SellingUom__c = ceradjustment.APTS_UOM__c;
                    adjustmentLineItem.APTS_Adjustment_Source__c = ceradjustment.APTS_Contributing_Agreement_Level__c;
                    if(ceradjustment.APTS_Product__c!=lineItem.Apttus_Config2__ProductId__c){
                    adjustmentLineItem.APTS_Category__c = ceradjustment.APTS_CategoryCER__c;
                    adjustmentLineItem.APTS_Sub_Category__c = ceradjustment.APTS_Sub_Category__c;
                    adjustmentLineItem.APTS_Sub_Sub_Category__c = ceradjustment.APTS_Sub_Sub_Category__c;}
                    adjustmentLineItem.Apttus_Config2__AdjustmentUom__c = ceradjustment.APTS_UOM__c;
                    ceradjustmentMap.put(adjustmentLineItem.Apttus_Config2__Type__c + '-' + adjustmentLineItem.Apttus_Config2__SubType__c + '-' + adjustmentLineItem.Apttus_Config2__AdjustmentType__c, adjustmentLineItem);
                    
                }
                } 
            }
        }
        return ceradjustmentMap;
    }
    @TestVisible
    public List<Apttus_Config2__AdjustmentLineItem__c> processAdjustmentLineItemfieldsnew(List<Apttus_Config2__AdjustmentLineItem__c> adjItems) {
        List<Apttus_Config2__AdjustmentLineItem__c> ReturnCERAdj = new List<Apttus_Config2__AdjustmentLineItem__c>();
        list<string> AdjAppliesTo = new list<string>();
        for (Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem : adjItems) {

            if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP03') {
                adjustmentLineItem.Apttus_Config2__Type__c = 'GSV';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 1' ;
            }
            
            else if(adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP02')
            {
                adjustmentLineItem.Apttus_Config2__Type__c = 'Inflation';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 2' ;
            }
            
            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP06') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 3' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP07') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 3' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP04') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP08') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP10') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZX10') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP15') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP11') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP13') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }


            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP12') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'YOCI') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'YOCI';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'YOFT') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'YOFT';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;
            }
            AdjAppliesTo.add(adjustmentLineItem.Apttus_Config2__Bucket__c);
        }
        for (Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem1 : adjItems) {
            if (AdjAppliesTo.contains('Bucket 1') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 1') {
                adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
            }

            if (AdjAppliesTo.contains('Bucket 2') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 2') {
                if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }

            if (AdjAppliesTo.contains('Bucket 3') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 3') {
                if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                } else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }

            if (AdjAppliesTo.contains('Bucket 4') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 4') {
                if (AdjAppliesTo.contains('Bucket 3')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                } else if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                } else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }

            }

            if (AdjAppliesTo.contains('Bucket 5') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 5') {
                if (AdjAppliesTo.contains('Bucket 4')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 4';
                } else if (AdjAppliesTo.contains('Bucket 3')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                } else if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                } else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }
            
             if (AdjAppliesTo.contains('Bucket 6') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 6') {
                if (AdjAppliesTo.contains('Bucket 5')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 5';
                } else if (AdjAppliesTo.contains('Bucket 4')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 4';
                } else if (AdjAppliesTo.contains('Bucket 3')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                } else if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                }  else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                }   else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }
            ReturnCERAdj.add(adjustmentLineItem1);
        }
        List<Apttus_Config2__AdjustmentLineItem__c> lstAdjLineItemsToBeInserted = resequenceAdjustmentLines(ReturnCERAdj);

        return lstAdjLineItemsToBeInserted;
    }
    private List<Apttus_Config2__AdjustmentLineItem__c> resequenceAdjustmentLines (List<Apttus_Config2__AdjustmentLineItem__c> ReturnCERAdj)
    {
        Map<String,List<Apttus_Config2__AdjustmentLineItem__c>> mapToSequenceAdj = new Map<String,List<Apttus_Config2__AdjustmentLineItem__c>>();
        List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustmentLineItems = new List<Apttus_Config2__AdjustmentLineItem__c>();

        for(Apttus_Config2__AdjustmentLineItem__c instAdjLineItem : ReturnCERAdj)
        {
            {    
                if(mapToSequenceAdj.containsKey(instAdjLineItem.Apttus_Config2__AdjustmentAppliesTo__c))
                    { List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustment = new List<Apttus_Config2__AdjustmentLineItem__c>();
                      lstAdjustment = mapToSequenceAdj.get(instAdjLineItem.Apttus_Config2__AdjustmentAppliesTo__c);
                      lstAdjustment.add(instAdjLineItem);
                      mapToSequenceAdj.put(instAdjLineItem.Apttus_Config2__AdjustmentAppliesTo__c,lstAdjustment);
                    }
                    else
                    {
                      List<Apttus_Config2__AdjustmentLineItem__c> lstAdjustment = new List<Apttus_Config2__AdjustmentLineItem__c>();
                      lstAdjustment.add(instAdjLineItem);
                      mapToSequenceAdj.put(instAdjLineItem.Apttus_Config2__AdjustmentAppliesTo__c,lstAdjustment);
                    } 
            } 
        }


        List<String> lstString = new List<String>();
        for(String s : mapToSequenceAdj.keySet())
        {
        if(s=='Starting Price')
        s='Bucket 0';  
        lstString.add(s);
        } // here keySet List is sorted.
        lstString.sort();

        for(String instAdappto: lstString) 
        {
           if(instAdappto == 'Bucket 0') 
           instAdappto = 'Starting Price';
           lstAdjustmentLineItems.addAll(mapToSequenceAdj.get(instAdappto));
        }      
       
        return lstAdjustmentLineItems;
    }
    @TestVisible
    Private Map<String, Apttus_Config2__AdjustmentLineItem__c> processcerdata(Apttus_Config2__LineItem__c lineItem, List<APTS_Contract_Entitlement_Repository__c> ceradjustments, boolean agrflag) {
        Integer lineNumber = 1;
        Map<String, Apttus_Config2__AdjustmentLineItem__c> ceradjustmentMap = new Map<String, Apttus_Config2__AdjustmentLineItem__c>();

        if (ceradjustments != null) {
            for (APTS_Contract_Entitlement_Repository__c ceradjustment : ceradjustments ) {
                //v108 ++ <<
              /*  if(lineItem.APTS_Global_linkage_ID__c != ceradjustment.APTS_Agreement_Line_Item__r.APTS_Global_linkage_ID__c){
                    continue;
                }*/ 
                //v108 ++ >>

                ID prdID = PRODUCT_SERVICE.equalsIgnoreCase(lineItem.Apttus_Config2__LineType__c) ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;
                ////System.debug('Hari : Debug : Agreement Line Item'+lineitem.Agreement_Line_Item__c);
                //System.debug('Agreement Processing PRD ID1 = ' + prdID);
                //System.debug('Agreement Processing PRD ID2 = ' + ceradjustment.APTS_Product__c);
                //    if (prdID !=null  && (prdID == ceradjustment.APTS_Product__c) )

                //   {
                //System.debug('Hari : Debug : Bucket' + ceradjustment.APTS_Bucket__c);
                Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
                adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItem.Id;
                adjustmentLineItem.Apttus_Config2__LineNumber__c = lineNumber++;
                adjustmentLineItem.Apttus_Config2__AdjustmentType__c = ceradjustment.APTS_Adjustment_Type__c;
                adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = ceradjustment.APTS_Adjustment_Value__c;
               // adjustmentLineItem.Apttus_Config2__IsModifiable__c = TRUE;
                adjustmentLineItem.Apttus_Config2__Type__c = ceradjustment.APTS_Type__c;
                adjustmentLineItem.APTS_Discount_Type__c= 'Auto';
                adjustmentLineItem.Apttus_Config2__SubType__c = ceradjustment.APTS_Sub_Type__c;
                adjustmentLineItem.Apttus_Config2_SellingUom__c = ceradjustment.APTS_UOM__c;
                adjustmentLineItem.APTS_Adjustment_Source__c = ceradjustment.APTS_Contributing_Agreement_Level__c;
                if(ceradjustment.APTS_Product__c!=lineItem.Apttus_Config2__ProductId__c&&lineItem.Apttus_Config2__LineType__c!='option'){
                adjustmentLineItem.APTS_Category__c = ceradjustment.APTS_CategoryCER__c;
                adjustmentLineItem.APTS_Sub_Category__c = ceradjustment.APTS_Sub_Category__c;
                adjustmentLineItem.APTS_Sub_Sub_Category__c = ceradjustment.APTS_Sub_Sub_Category__c;}
                adjustmentLineItem.Apttus_Config2__AdjustmentUom__c = ceradjustment.APTS_UOM__c;
                ceradjustmentMap.put(adjustmentLineItem.Apttus_Config2__Type__c + '-' + adjustmentLineItem.Apttus_Config2__SubType__c + '-' + adjustmentLineItem.Apttus_Config2__AdjustmentType__c, adjustmentLineItem);
            }
        }

        return ceradjustmentMap;

    }

    //Digital Order removed start
    public static void setIsDisabled(Boolean isDisabled) {
        isDisabled = isDisabled;
    }

    //Method returns Adjustment Line Items to be inserted
    // Param :
    // 1. cartBusinessObject : possible values Order | Agreement
    // 2. listLineItems: List of Line Items
    // 3. cerprdmap : Map of CER records per Product of an Account
    public static Map<String, Apttus_Config2__AdjustmentLineItem__c> getCERAdjustmentLineItems(String cartBusinessObject, Apttus_Config2__LineItem__c lineItem, Map<ID, List<APTS_Contract_Entitlement_Repository__c>> cerprdmap) {
        Integer lineNumber = 1;
        List<string> AdjAppliesTo;
        Map<String, Apttus_Config2__AdjustmentLineItem__c> mapLineItemNewAdjustments = new Map<String, Apttus_Config2__AdjustmentLineItem__c>();

        ID prdID = PRODUCT_SERVICE.equalsIgnoreCase(lineItem.Apttus_Config2__LineType__c) ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;
        List<APTS_Contract_Entitlement_Repository__c> ceradjustments = cerprdmap.get(prdID);

        if (ceradjustments != null) {
            AdjAppliesTo = new list<string> ();

            for (APTS_Contract_Entitlement_Repository__c ceradjustment : ceradjustments ) {

                Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
                adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItem.Id;
                adjustmentLineItem.Apttus_Config2__LineType__c = MANUAL;
                adjustmentLineItem.Apttus_Config2__LineNumber__c = lineNumber++;
                adjustmentLineItem.Apttus_Config2__AdjustmentType__c = ceradjustment.APTS_Adjustment_Type__c;
                adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = ceradjustment.APTS_Adjustment_Value__c;
                adjustmentLineItem.Apttus_Config2__IsModifiable__c = TRUE;
                adjustmentLineItem.Apttus_Config2__Type__c = ceradjustment.APTS_Type__c;
                adjustmentLineItem.Apttus_Config2__SubType__c = ceradjustment.APTS_Sub_Type__c;
                adjustmentLineItem.Apttus_Config2_SellingUom__c = ceradjustment.APTS_UOM__c;
                adjustmentLineItem.APTS_Adjustment_Source__c = ceradjustment.APTS_Contributing_Agreement_Level__c;
                adjustmentLineItem.APTS_Category__c = ceradjustment.APTS_CategoryCER__c;
                adjustmentLineItem.APTS_Sub_Category__c = ceradjustment.APTS_Sub_Category__c;
                adjustmentLineItem.APTS_Sub_Sub_Category__c = ceradjustment.APTS_Sub_Sub_Category__c;
                adjustmentLineItem.Apttus_Config2__AdjustmentUom__c = ceradjustment.APTS_UOM__c;
                system.debug('adjustmentLineItem = ' + adjustmentLineItem);

                //set bucket and type
                setAdjustmentBucket(adjustmentLineItem);

                //after setting bucket prepare map to set 'appliesTo'
                AdjAppliesTo.add(adjustmentLineItem.Apttus_Config2__Bucket__c);

                mapLineItemNewAdjustments.put(lineitem.Id + '_' + adjustmentLineItem.Apttus_Config2__Type__c + '-' + adjustmentLineItem.Apttus_Config2__SubType__c + '-' + adjustmentLineItem.Apttus_Config2__AdjustmentType__c, adjustmentLineItem);
            }




            //after setting bucket prepare map to set 'appliesTo'
            mapLineItemNewAdjustments = setAdjustmentAppliesTo(lineitem.Id, mapLineItemNewAdjustments.values(), AdjAppliesTo);

        }


        return mapLineItemNewAdjustments;
    }


    //Method returns Adjustment Line Items to be inserted for digital order
    // Param :
    // 1. cartBusinessObject : possible values Order | Agreement
    // 2. listLineItems: List of Line Items
    // 3. cerprdmap : Map of CER records per Product of an Account
    public static List<Apttus_Config2__AdjustmentLineItem__c> getDigitalAdjustmentLineItems(String sSrc, String stype, String sAdjType, Apttus_Config2__LineItem__c lineItem, List<String> AdjAppliesTo, List<APTS_DOEPIReqWrapper.EPIAdjustmentLI> listEPIAdjustments) {
        List<Apttus_Config2__AdjustmentLineItem__c> listTempAdjustment = new List<Apttus_Config2__AdjustmentLineItem__c>();

        try {
            if (listEPIAdjustments != null) {
                AdjAppliesTo = AdjAppliesTo == null ? new list<string> () : AdjAppliesTo;
                Integer iLineNumber = 1;

                for (APTS_DOEPIReqWrapper.EPIAdjustmentLI oEPIAdj : listEPIAdjustments) {
                    Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
                    adjustmentLineItem.Apttus_Config2__LineNumber__c = iLineNumber++;
                    adjustmentLineItem.Apttus_Config2__AdjustmentType__c = sAdjType;
                    adjustmentLineItem.Apttus_Config2__LineType__c = MANUAL;
                    adjustmentLineItem.APTS_Adjustment_Source__c = sSrc;
                    adjustmentLineItem.Apttus_Config2__Type__c = stype;
                    adjustmentLineItem.Apttus_Config2__IsModifiable__c = TRUE;
                    adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = oEPIAdj.IncentiveAmount;
                    adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c == null && oEPIAdj.AdjustmentValue != null ? oEPIAdj.AdjustmentValue : adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c;
                    adjustmentLineItem.Apttus_Config2__SubType__c = oEPIAdj.SubType;
                    adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItem.Id;
                    adjustmentLineItem.Apttus_Config2_SellingUom__c = lineItem.Apttus_Config2__SellingUom__c;
                    adjustmentLineItem.Apttus_Config2__AdjustmentUom__c = lineItem.Apttus_Config2__SellingUom__c;

                    setAdjustmentBucket(adjustmentLineItem);

                    // After setting bucket prepare map to set 'appliesTo'
                    AdjAppliesTo.add(adjustmentLineItem.Apttus_Config2__Bucket__c);

                    listTempAdjustment.add(adjustmentLineItem);
                }

                if (listTempAdjustment != null && !listTempAdjustment.isEmpty()) {
                    listTempAdjustment = setAdjustmentAppliesTo(lineItem.Id, listTempAdjustment, AdjAppliesTo).values();
                }
            }
        } catch (Exception e) {

        }

        return listTempAdjustment;
    }

    // Duplicate code created for Digital Orders, Original Method can be refactored
    public static List<Apttus_Config2__AdjustmentLineItem__c> getABOAdjustmentLineItems(Id assetId, Apttus_Config2__LineItem__c lineItem, List<Apttus_Config2_AssetAdjustItem__c> listAssetAdjustments) {
        List<Apttus_Config2__AdjustmentLineItem__c> adjustmentLineItems = new List<Apttus_Config2__AdjustmentLineItem__c>();

        for (Apttus_Config2_AssetAdjustItem__c oAssetAdjustment : listAssetAdjustments) {
            Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem = new Apttus_Config2__AdjustmentLineItem__c();
            adjustmentLineItem.Apttus_Config2__LineItemId__c = lineItem.Id;
            adjustmentLineItem.Apttus_Config2__LineType__c = oAssetAdjustment.Apttus_Config2_LineType__c;
            adjustmentLineItem.Apttus_Config2__LineNumber__c = oAssetAdjustment.Apttus_Config2_LineNumber__c;
            adjustmentLineItem.Apttus_Config2__IsModifiable__c = oAssetAdjustment.Apttus_Config2_IsModifiable__c;
            adjustmentLineItem.Apttus_Config2__AdjustmentType__c = oAssetAdjustment.Apttus_Config2_AssetAdjustType__c;
            adjustmentLineItem.Apttus_Config2__AdjustmentAmount__c = oAssetAdjustment.Apttus_Config2_AssetAdjustAmount__c;
            adjustmentLineItem.Apttus_Config2__Bucket__c = oAssetAdjustment.Apttus_Config2_Bucket__c;
            adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = oAssetAdjustment.Apttus_Config2_AssetAdjustAppliesTo__c;
            adjustmentLineItem.Apttus_Config2__Type__c = oAssetAdjustment.Apttus_Config2_Type__c;
            adjustmentLineItem.Apttus_Config2__SubType__c = oAssetAdjustment.Apttus_Config2_SubType__c;
            adjustmentLineItem.Apttus_Config2_SellingUom__c = oAssetAdjustment.Apttus_Config2_Adjustment_Uom__c;
            adjustmentLineItem.Apttus_Config2__AdjustmentUom__c = oAssetAdjustment.Apttus_Config2_Adjustment_Uom__c;
            adjustmentLineItems.add(adjustmentLineItem);
        }

        return adjustmentLineItems;
    }


    // Duplicate code created for Digital Orders, Original Method can be refactored
    // Method sets Bucket and Type on Adjustment Line Item
    public static void setAdjustmentBucket(Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem) {
        try {


            if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP03') {
                adjustmentLineItem.Apttus_Config2__Type__c = 'GSV';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 1' ;
            }
            
            else if(adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP02')
            {
                adjustmentLineItem.Apttus_Config2__Type__c = 'Inflation';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 2' ;
            }
            
            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP06') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 3' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP07') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'PPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 3' ;
                //adjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP04') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP08') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP10') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZX10') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'TPR';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP15') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP11') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP13') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }


            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'ZP12') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'BMC';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'YOCI') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'YOCI';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;
            }

            else if (adjustmentLineItem.Apttus_Config2__SubType__c == 'YOFT') {

                adjustmentLineItem.Apttus_Config2__Type__c = 'YOFT';
                adjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;
            }

        } catch (Exception e) {
            throw e;
        }

    }


    // Duplicate code created for Digital Orders, Original Method can be refactored
    // Method sets applies To picklist
    public static Map<String, Apttus_Config2__AdjustmentLineItem__c> setAdjustmentAppliesTo(Id lineitemId, List<Apttus_Config2__AdjustmentLineItem__c> adjItems, list<string> AdjAppliesTo) {
        Map<String, Apttus_Config2__AdjustmentLineItem__c> mapAdjs = new Map<String, Apttus_Config2__AdjustmentLineItem__c>();

        try {
            for (Apttus_Config2__AdjustmentLineItem__c adjustmentLineItem1 : adjItems) {
if (AdjAppliesTo.contains('Bucket 1') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 1') {
                adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
            }

            if (AdjAppliesTo.contains('Bucket 2') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 2') {
                if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }

            if (AdjAppliesTo.contains('Bucket 3') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 3') {
                if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                } else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }
            }

            if (AdjAppliesTo.contains('Bucket 4') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 4') {
                if (AdjAppliesTo.contains('Bucket 3')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                } else if (AdjAppliesTo.contains('Bucket 2')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                } else if (AdjAppliesTo.contains('Bucket 1')) {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';
                } else {
                    adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                }

            }

            if (AdjAppliesTo.contains('Bucket 5') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 5') {if (AdjAppliesTo.contains('Bucket 4')) {adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 4';} else if (AdjAppliesTo.contains('Bucket 3')) {adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';} else if (AdjAppliesTo.contains('Bucket 2')) {adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';} else if (AdjAppliesTo.contains('Bucket 1')) {adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';} else {adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';}}
            
             if (AdjAppliesTo.contains('Bucket 6') && adjustmentLineItem1.Apttus_Config2__Bucket__c == 'Bucket 6') {if (AdjAppliesTo.contains('Bucket 5')) {adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 5';} else if (AdjAppliesTo.contains('Bucket 4')) {adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 4';} else if (AdjAppliesTo.contains('Bucket 3')) {adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';} else if (AdjAppliesTo.contains('Bucket 2')) {adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';}  else if (AdjAppliesTo.contains('Bucket 1')) {adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 1';}   else {adjustmentLineItem1.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';}}

                mapAdjs.put(lineitemId + '_' + adjustmentLineItem1.Apttus_Config2__Type__c + '-' + adjustmentLineItem1.Apttus_Config2__SubType__c + '-' + adjustmentLineItem1.Apttus_Config2__AdjustmentType__c, adjustmentLineItem1);
            }
        } catch (Exception e) {
            throw e;
        }

        return mapAdjs;
    }
    //Digital Order utils end

}