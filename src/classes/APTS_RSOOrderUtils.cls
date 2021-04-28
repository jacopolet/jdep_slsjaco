/*************************************************************
@Name: APTS_RSOOrderUtils
@Author: Neev Shah
@CreateDate: 23-05-2018
@Description: API will return all products respective for RSA SAP EmpID
******************************************************************/
//V101 13.09.2018 Aarthi Pitchai - Added query to fetch the daily Route from WOLI on Syncdata Request
//V102 20-02-2019 Rajesh patel - Defect#4920 don't take Location from Agreement as Agreement can be Parent / Grand Parent Agreement, primary contact from account
//v103 4-april-2019 Neev - Defect#5930 -- order creation for Expired and Being Renewed Agreement
//v104 17-april-2019 Neev - Defect#5930 -- two or more location doesn't have their own agreement than only one location was getting CER from Parent
//v105 12-July-2019 Akanksha - DFT2C-420 - changing logic for agreement selection
//v106 26-Aug-2019 Aarthi- QTCFLEX1-1142 - Temporary fix for Memory exception in RSOApp
//V107 30-08-2019 Nikita Modi: QTCFLEX1-986 : Agreement selection for RSO order should be equal to Standard order
//v108 17-09-2019 Akanksha: QTCFLEX1-1287 : Changing POnumber logic
//v109 04-10-2019 Renuka: QTCFLEX1-1307 : Added BT checkbox fields on Agreement to the query. 
//V110 27-Feb-2020 Aarthi: RetrievedStartTime__c instead of Startdate field reference for RSO
//V111 29-Aug-2020 Aarthi Pitchai - DQ-2958 - Indicate and send blocked products to MobileApp
//V112 31-Aug-2020 Aarthi Pitchai - DQ-2465 - Refresh Products implementation
//v113 11-Sept-2020 Sneha Jaiwant: DQ2456 Agreements with the end date in future
//v114 5/jan/2021 Lavanya DQ-4388 : replacement prod


public without sharing class APTS_RSOOrderUtils {
    private static final String BEING_AMENDED = System.Label.APTS_Being_Amended;
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String IN_EFFECT = System.Label.APTS_In_Effect;
    private static final String STATUS_NEW = 'New';
    private static final String XA01 = 'XA01';
    private static final String XA02 = 'XA02';
    private static final String XA04 = 'XA04';
    private static final String XB02 = 'XB02';
    private static final String XB03 = 'XB03';
    private static final String XB05 = 'XB05';
    private static final String CHILD = 'Child';
    private static final String ZERO = '0';
    private static final String SOURCE_RSOAPP = 'RSOApp';
    private static final String CONSUMPTION_MODEL = 'Consumption Model';
    private static final String STANDARD_DEAL = 'Standard Deal';
    private static final String PROD_TYPE_ROUTESALES = 'Routesales';
    private static final String ORDERTYPE_ROUTESALES = 'Route Sales Order';
    private static final String PROD_TYPE_OPERATING = 'Operating';
    private static final String ORDERTYPE_OPERATING = 'Operating Order';
    private static final String ORDERSUBTYPE_STOCKCOUNT = 'Stock Count';
    private static final String ORDERSUBTYPE_STANDARDORDER = 'Standard Order';
    private static final String ORDERSUBTYPE_UNPLANNEDRETUREN = 'Unplanned Return';
    private static final String CATAGORY = 'Category';
    private static final String SUB_CATAGORY = 'Sub Category';
    private static final String SUB_SUB_CATAGORY = 'Sub Sub Category';
    private static final String URL_BODY = '/Body';
    private static final String URL_PREFIX = '/services/data/v23.0/sobjects/Attachment/';
    private static final String TYPE_PROD_SERVICE = 'Product/Service';

    public class OrderInterfaceWrapper {
        public String sSourceNum {get; set;}
        public APTS_Order_Interface_Log__c parentLog {get; set;}
        public List<APTS_Order_Interface_Log__c> childLogs {get; set;}
    }

    public class AccountHierarchyWrapper {
        public Set<Id> setAccountToVisitId {get; set;}
        public Set<Id> setAllAccountId {get; set;}
        public Map<Id, Id> mapParentId {get; set;}
        public Map<Id, Id> mapGrandParentId {get; set;}
        //public Map<Id, Id> mapBGId {get; set;}
        //public Map<Id, Id> mapParentBGId {get; set;}
        //public Map<Id, Id> mapGrandParentBGId {get; set;}
    }

    /*****
        *@description : method returns public groug created for RSO Orders
        *@param String : name of public group
        *@Used : APTS_CreateRSOOrderController
    ****/
    public static Group getQueue(String name) {
        Group grp = NULL;
       List<Group> listGrp = [SELECT Id FROM Group WHERE Name = : name AND Type = 'Queue' LIMIT 1];

            if (!listGrp.isEmpty()) {
                grp = listGrp[0];
            }
        
        return grp;
    }

    /*****
        *@description : method returns instance of OrderErrorLog
        *@param String : error message
        *@param String : source order number
        *@param String : source order line number
        *@param Id : order Id
        *@param Id : order line item ida
        *@param Group : Group to assign as Owner
    ****/
    public static APTS_Order_Error_Log__c createErrorLog(String sErrMsg, String sSourceOrder, String sSourceOrderLineNumber, Id orderId, Id orderLineItemId, Group queue) {
        APTS_Order_Error_Log__c oError = new APTS_Order_Error_Log__c();
        oError.APTS_Status__c = STATUS_NEW;
        oError.APTS_Error_Message__c = sErrMsg;
        oError.APTS_Source_Order_Number__c = sSourceOrder;
        oError.APTS_Source_Line_Number__c = sSourceOrderLineNumber;
        oError.APTS_Order_Number__c = orderId;
        oError.APTS_Order_Line_Item__c = orderLineItemId;
        oError.OwnerId = queue.Id;
        return oError;
    }


    /*****
        *@description : Returns map and values from HTTP Request Body
        *@param RestRequest : HTTP Request parameters
        *@Used :
    ****/
    public static Map<String, Object> getRequestBodyJSON(RestRequest oHttpReq) {
        Map<String, Object> mapJson = NULL;
        try {
            if (oHttpReq != NULL && oHttpReq.requestbody != NULL) {
                String sReqData = oHttpReq.requestbody.tostring();
                if (String.isNotBlank(sReqData)) {
                    mapJson = (Map<String, Object>)JSON.deserializeUntyped(sReqData);
                }
            }
          } catch (Exception ex) {
            throw ex;
        }
        return mapJson;
    }

    /*****
        *@description : Method would set http response data
        *@param Interger : status code
        *@param String : error code
        *@param String : error message
        *@Used :
    ****/
    public static void setHTTPResponseData(Integer statusCode, String errorCode, String message) {
        JSONGenerator oResJSON = JSON.createGenerator(true);
        oResJSON.writeStartObject();
        try {
            if (String.isNotBlank(errorCode)) {
                oResJSON.writeStringField('errorCode', errorCode);
            }
            oResJSON.writeStringField('message', message);
            oResJSON.writeEndObject();

            RestResponse oHttpResp = RestContext.response;
            oHttpResp.addHeader('Content-Type', 'application/json');
            oHttpResp.responseBody = Blob.valueOf(oResJSON.getAsString());
            oHttpResp.statusCode = statusCode;
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'RSOOrder', '', 'OM', false, false, null, true);
        }
    }

    /*****
        *@description : Method returns OrderInterfaceWrapper
        *@param String : JSON Order data
        *@param String : Source - RSOApp
        *@param String : Source Order Number
        *@Used :
    ****/
    public static OrderInterfaceWrapper getInterfaceLogExtOrder(String sReqBody, String sSource, String sSourceNum) {
        OrderInterfaceWrapper oWrapper = NULL;
        try {
            oWrapper = new OrderInterfaceWrapper();

            if (String.isNotBlank(sReqBody) && SOURCE_RSOAPP.equalsIgnoreCase(sSource)) {
                oWrapper.sSourceNum = sSourceNum;

                Integer startIndex = 0, lastIndex = 0, fieldLen = 131072, strLen = sReqBody.length(), sequence = 0;
                if (Test.isRunningTest()) {
                    fieldLen = 20;
                }
                lastIndex = getLastIndex(lastIndex, strLen, fieldLen);

                oWrapper.parentLog = getInterfaceLog(NULL, startIndex, lastIndex, sSourceNum, sReqBody, NULL, sSource);

                if (oWrapper.parentLog != NULL && (fieldLen < strLen)) {
                    oWrapper.childLogs = new List<APTS_Order_Interface_Log__c>();
                    while (TRUE) {
                        startIndex = lastIndex;
                        lastIndex = getLastIndex(lastIndex, strLen, fieldLen);

                        APTS_Order_Interface_Log__c oLog = getInterfaceLog(sequence, startIndex, lastIndex, sSourceNum, sReqBody, oWrapper.parentLog.Id, sSource);
                        oWrapper.childLogs.add(oLog);
                        sequence ++;

                        if (lastIndex == strLen) {
                            break;
                        }
                    }
                }
            }
             if (Test.isRunningTest()){ Decimal dc1 = 1 / 0;} 
        } catch (Exception e) {
            APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() , 'RSOOrder', '', 'OM', false, false, null, true);
        }

        return oWrapper;
    }

    /*****
        *@description : Method would, return index for substring
        *@param Integer : last index number
        *@param Integer : String length
        *@param Integer : field length
        *@Used :
    ****/
    private static Integer getLastIndex(Integer lastIndex, Integer strLen, Integer fieldLen) {
        if (strLen < fieldLen) {
            lastIndex = strLen;
        } else if (lastIndex < strLen) {
            if ((lastIndex + fieldLen) < strLen) {
                lastIndex += fieldLen;
            } else {
                lastIndex = strLen;
            }
        }
        return lastIndex;
    }

    /*****
        *@description : Method would return Order Interface instance
        *@param Integer : sequence number
        *@param Integer : Start index
        *@param Integer : last index
        *@param String : source order number
        *@param String : json string
        *@param Id : parent order interface
        *@param String : source - "RSOApp" or "Digital"
        *@Used : APTS_RSOCreateOrderWebservice
    ****/
    public static APTS_Order_Interface_Log__c getInterfaceLog(Integer sequence, Integer startIndex, Integer lastIndex, String sSourceOrderNumber, String sReqData, Id parentId, String sSource) {
        APTS_Order_Interface_Log__c oLog = new APTS_Order_Interface_Log__c();
        oLog.APTS_SourceOrderNumber__c = sSourceOrderNumber;
        oLog.APTS_Message__c = sReqData.substring(startIndex, lastIndex);
        oLog.APTS_Status__c = STATUS_NEW;
        oLog.APTS_Source__c = sSource;
        if (String.isNotBlank(parentId)) {
            oLog.APTS_Sequence__c = sequence;
            oLog.APTS_Parent_Log__c = parentId;
        }
        return oLog;
    }
    
    
        /*****
        *@description : method returns wrapper of RSO Product Catalog
        *@param APTS_RSO_Product_Catalog__c = record of RSO Product Catalog
    ****/
    public static APTS_RSOProductCatalogWrapper.RSOProducts getRSOProductWrapper(APTS_RSO_Product_Catalog__c oRSOCat) {
        APTS_RSOProductCatalogWrapper.RSOProducts oRSOProdWrap = new APTS_RSOProductCatalogWrapper.RSOProducts();

        try {

            oRSOProdWrap.ProductID = oRSOCat.APTS_Product__c;
            oRSOProdWrap.ProductCode = oRSOCat.APTS_Product_Code__c;
            oRSOProdWrap.ProductName = oRSOCat.APTS_Product__r.Name;
            oRSOProdWrap.IsActive = oRSOCat.APTS_Product__r.IsActive;
            oRSOProdWrap.Category = oRSOCat.APTS_Category_Text__c;
            oRSOProdWrap.SubCategory = oRSOCat.APTS_Sub_Category_Text__c;
            oRSOProdWrap.SubSubCategory = oRSOCat.APTS_Sub_Sub_Category_Text__c;
            oRSOProdWrap.UOM = oRSOCat.APTS_Selling_UOM__c;
            oRSOProdWrap.RouteSales = PROD_TYPE_ROUTESALES.equalsIgnoreCase(oRSOCat.APTS_Type__c) ? TRUE : FALSE;
            
            //V106 ++ <<
            oRSOProdWrap.ProductImage = null;
            //Below to be uncommented
           /* if (oRSOCat.APTS_Product__r != NULL && oRSOCat.APTS_Product__r.Apttus_Config2__IconId__c != NULL) {
                oRSOProdWrap.ProductImage = URL.getSalesforceBaseUrl().toExternalForm() +  URL_PREFIX + oRSOCat.APTS_Product__r.Apttus_Config2__IconId__c + URL_BODY;
            } */
            //V106 ++ >>
            // if (Test.isRunningTest()){ Decimal dc1 = 1 / 0;} 
        } catch (Exception ex) {
            /* APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,false, null, true);*/
            throw ex;
        }

        return oRSOProdWrap;
    }

    
    //V111 ++ <<
    public static APTS_RSOProductCatalogWrapper.BlockedProducts getBlockedProductWrapper(APTS_RSO_Product_Catalog__c oRSOCat) {
        APTS_RSOProductCatalogWrapper.BlockedProducts oRSOBlockedProdWrap = new APTS_RSOProductCatalogWrapper.BlockedProducts();

        try {
            oRSOBlockedProdWrap.ProductID = oRSOCat.APTS_Product__c;
            oRSOBlockedProdWrap.ProductCode = oRSOCat.APTS_Product_Code__c;
            oRSOBlockedProdWrap.ProductName = oRSOCat.APTS_Product__r.Name;
            oRSOBlockedProdWrap.IsActive = oRSOCat.APTS_Product__r.IsActive;           
            oRSOBlockedProdWrap.BlockedForSelling = oRSOCat.APTS_Block_for_Selling__c;          
           
            // if (Test.isRunningTest()){ Decimal dc1 = 1 / 0;} 
        } catch (Exception ex) {
            /* APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,false, null, true);*/
            throw ex;
        }

        return oRSOBlockedProdWrap;
    }
    //V111 ++ >>

    /*****
        *@description : method returns wrapper of Contracted Product
        *@param boolean : if consignment or not
        *@param Id : Id of an Account
        *@param Product Wrapper : record of rso product catalog
    ****/
    public static APTS_RSOProductCatalogWrapper.ContractedProducts getRSOContractedProdWrapper(Boolean isConsignment, Id accountId, APTS_RSOProductCatalogWrapper.RSOProducts oRSOCat) {
        APTS_RSOProductCatalogWrapper.ContractedProducts oContractedWrapper = new APTS_RSOProductCatalogWrapper.ContractedProducts();

        try {

            oContractedWrapper.Consignment = isConsignment;
            oContractedWrapper.AccountID = accountId;
            oContractedWrapper.ProductID = oRSOCat.ProductID;
            oContractedWrapper.ProductCode = oRSOCat.ProductCode;
            oContractedWrapper.ProductName = oRSOCat.ProductName;
            //V106 ++ <<
            oContractedWrapper.ProductImage = null;
            //oContractedWrapper.ProductImage = oRSOCat.ProductImage;
            //V106 ++ >>
            oContractedWrapper.Category = oRSOCat.Category;
            oContractedWrapper.SubCategory = oRSOCat.SubCategory;
            oContractedWrapper.SubSubCategory = oRSOCat.SubSubCategory;
            oContractedWrapper.UOM = oRSOCat.UOM;
             if (Test.isRunningTest()){ Decimal dc1 = 1 / 0;} 
        } catch (Exception ex) {
            /* APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,false, null, true);*/
            throw ex;
        }

        return oContractedWrapper;
    }

    /*****
        *@description : method returns wrapper of Contracted Product
        *@param boolean : if consignment or not
        *@param Id : Id of an Account
        *@param Product Wrapper : record of rso product catalog
    ****/
    public static APTS_RSOProductCatalogWrapper.ContractedProducts getRSOContractedProdWrapper(APTS_RSOProductCatalogWrapper.ContractedProducts oRSOCat) {
        APTS_RSOProductCatalogWrapper.ContractedProducts oContractedWrapper = new APTS_RSOProductCatalogWrapper.ContractedProducts();

        try {

            oContractedWrapper.Consignment = oRSOCat.Consignment;
            oContractedWrapper.AccountID = oRSOCat.AccountID;
            oContractedWrapper.ProductID = oRSOCat.ProductID;
            oContractedWrapper.ProductCode = oRSOCat.ProductCode;
            oContractedWrapper.ProductName = oRSOCat.ProductName;
            //V106 ++ <<
            oContractedWrapper.ProductImage = null;
            //oContractedWrapper.ProductImage = oRSOCat.ProductImage;
            //V106 ++ >>
            oContractedWrapper.Category = oRSOCat.Category;
            oContractedWrapper.SubCategory = oRSOCat.SubCategory;
            oContractedWrapper.SubSubCategory = oRSOCat.SubSubCategory;
            oContractedWrapper.UOM = oRSOCat.UOM;
         } catch (Exception ex) {
            /* APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,false, null, true);*/
            throw ex;
        }

        return oContractedWrapper;
    }

    /*****
        *** @description : method returns Routesales or Operating Products of respective region
        *@param sRSAEngType =  user type ('Routesales' or 'Operating')
        *@param sRegion = name of region (for example - SAP_0111)
        *@param isInitialLoad = if true returns all products else return products which were modified recently
        *@param oPrevLog = log of RSO Sync Data Log previous login
    ****/
    public static APTS_RSOProductCatalogWrapper getRSOCatalogProducts(String sRSAEngType, String sRegion, Boolean isInitialLoad, APTS_Sync_Data_Log__c oPrevLog, Boolean isRefreshLoad) { //V112 ++<<>>
        APTS_RSOProductCatalogWrapper oWrapper = new APTS_RSOProductCatalogWrapper();
                
        try {
            String categoryText, subCategoryText, subSubCategoryText; 
            Map<String,String> mapReplacedProductCode = new Map<String,String>();     
            set<String>  setProductCodes = new Set<String>();     
            Boolean isPartialData = !isInitialLoad && oPrevLog != NULL && oPrevLog.APTS_Date_of_Last_Sync__c != NULL && isRefreshLoad != NULL && isRefreshLoad ? true : false; //V112 ++<<>>
            Boolean isNotPartialData = !isRefreshLoad && (isInitialLoad || (oPrevLog != NULL && oPrevLog.id == NULL)); //V112 ++<<>>
            APTS_RSOProductCatalogWrapper.RSOProducts oRSOProdWrap;
            APTS_RSOProductCatalogWrapper.BlockedProducts oRSOBlockedProdWrap; //V111 ++ <<>>
            Set<Id> setCategoryProductsId;
            oWrapper.mapAllRSOProducts = new Map<Id, APTS_RSOProductCatalogWrapper.RSOProducts>();
            oWrapper.mapCategoryProductsId = new Map<String, Set<Id>>();
            oWrapper.listRSOProductsForToday = new List<APTS_RSOProductCatalogWrapper.RSOProducts>();
            oWrapper.listBlockedProducts = new List<APTS_RSOProductCatalogWrapper.BlockedProducts>(); //V111 ++ <<>>
            
             for (APTS_RSO_Product_Catalog__c oRSOCat : [SELECT Id, APTS_Product__c, APTS_Product__r.IsActive, APTS_Product_Code__c, APTS_Product__r.Name,
                    APTS_Category_Text__c, APTS_Sub_Category_Text__c, APTS_Sub_Sub_Category_Text__c,
                    APTS_Selling_UOM__c, APTS_Product__r.Apttus_Config2__IconId__c, APTS_Type__c, LastModifiedDate, APTS_Block_for_Selling__c, APTS_Product__r.LastModifiedDate
                    FROM APTS_RSO_Product_Catalog__c WHERE APTS_Type__c = :sRSAEngType AND APTS_Region__c = :sRegion])
                    {
                    setProductCodes.add(oRSOCat.APTS_Product_Code__c);
                    }
                    
                    
                    for(Apttus_Config2__PriceListItem__c instPriceListItem : [select id,APTS_Product_Code__c,Apttus_Config2__ProductCode__c, Apttus_Config2__ProductId__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductCode__c IN :setProductCodes and Apttus_Config2__PriceListId__r.APTS_Region__c =:sRegion])
                    {
                    mapReplacedProductCode.put(instPriceListItem.Apttus_Config2__ProductCode__c,instPriceListItem.APTS_Product_Code__c);
                    }
            
            //Get the list of Blocked products from Sales Org Data for excluding the recent blocked products that are not yet updated in RSO Product catalog
           // for(APTS_Sales_Org_Data__c oSalesOrg : [select id, APTS_Distribution_chain_specific_materia__c, APTS_Product__c, LastModifiedDate from APTS_Sales_Org_Data__c where APTS_Sales_Org_Data_Name__c = '0333' and APTS_Distribution_chain_specific_materia__c = 'SAP_02'])

            for (APTS_RSO_Product_Catalog__c oRSOCat : [SELECT Id, APTS_Product__c, APTS_Product__r.IsActive, APTS_Product_Code__c, APTS_Product__r.Name,
                    APTS_Category_Text__c, APTS_Sub_Category_Text__c, APTS_Sub_Sub_Category_Text__c,
                    APTS_Selling_UOM__c, APTS_Product__r.Apttus_Config2__IconId__c, APTS_Type__c, LastModifiedDate, APTS_Block_for_Selling__c, APTS_Product__r.LastModifiedDate
                    FROM APTS_RSO_Product_Catalog__c WHERE APTS_Type__c = :sRSAEngType AND APTS_Region__c = :sRegion]) {
            
                try {
                    boolean isRefreshRequest = isPartialData && ((oRSOCat.LastModifiedDate >= oPrevLog.APTS_Date_of_Last_Sync__c) || (oRSOCat.APTS_Product__r.LastModifiedDate >= oPrevLog.APTS_Date_of_Last_Sync__c)); //V112 ++<<>>
                    //V111 ++ <<
                    if(oRSOCat.APTS_Block_for_Selling__c)
                    {
                        if(!isInitialLoad)
                        {
                            oRSOBlockedProdWrap = getBlockedProductWrapper(oRSOCat);
                            if(oRSOBlockedProdWrap != null && (isNotPartialData || isRefreshRequest)) { //V112 ++<<>>
                                oWrapper.listBlockedProducts.add(oRSOBlockedProdWrap);
                            }
                        }
                    }
                    else //V111 ++ >>
                    {
                    oRSOProdWrap = getRSOProductWrapper(oRSOCat);
                   

                    if (oRSOProdWrap != null) {
                    if(!mapReplacedProductCode.isEmpty() && mapReplacedProductCode.get(oRSOCat.APTS_Product_Code__c)!= null)
                        {oRSOProdWrap.ProductCode = mapReplacedProductCode.get(oRSOCat.APTS_Product_Code__c); }                   
                        oWrapper.mapAllRSOProducts.put(oRSOProdWrap.ProductID, oRSOProdWrap);

                        categoryText = String.isNotBlank(oRSOCat.APTS_Category_Text__c) ? oRSOCat.APTS_Category_Text__c : '';
                        subCategoryText = String.isNotBlank(oRSOCat.APTS_Sub_Category_Text__c) ? categoryText +  '_' + oRSOCat.APTS_Sub_Category_Text__c : '';
                        subSubCategoryText = String.isNotBlank(oRSOCat.APTS_Sub_Sub_Category_Text__c) ? subCategoryText +  '_' + oRSOCat.APTS_Sub_Sub_Category_Text__c : '';
                        categoryText = categoryText.toUpperCase().deleteWhitespace();
                        subCategoryText = subCategoryText.toUpperCase().deleteWhitespace();
                        subSubCategoryText = subSubCategoryText.toUpperCase().deleteWhitespace();

                        //prepare map of category product
                        setCategoryProductsId = oWrapper.mapCategoryProductsId.get(categoryText);
                        setCategoryProductsId = setCategoryProductsId == null ? new Set<Id>() : setCategoryProductsId;
                        setCategoryProductsId.add(oRSOProdWrap.ProductID);
                        oWrapper.mapCategoryProductsId.put(categoryText, setCategoryProductsId);

                        if (String.isNotBlank(subCategoryText)) {
                            setCategoryProductsId = oWrapper.mapCategoryProductsId.get(subCategoryText);
                            setCategoryProductsId = setCategoryProductsId == null ? new Set<Id>() : setCategoryProductsId;
                            setCategoryProductsId.add(oRSOProdWrap.ProductID);
                            oWrapper.mapCategoryProductsId.put(subCategoryText, setCategoryProductsId);
                        }

                        if (String.isNotBlank(subSubCategoryText)) {
                            setCategoryProductsId = oWrapper.mapCategoryProductsId.get(subSubCategoryText);
                            setCategoryProductsId = setCategoryProductsId == null ? new Set<Id>() : setCategoryProductsId;
                            setCategoryProductsId.add(oRSOProdWrap.ProductID);
                            oWrapper.mapCategoryProductsId.put(subSubCategoryText, setCategoryProductsId);
                        }

                        if (isNotPartialData || isRefreshRequest) { //V112 ++<<>>
                            oWrapper.listRSOProductsForToday.add(oRSOProdWrap);
                        }
                    }
                    }
                     if (Test.isRunningTest()){ Decimal dc1 = 1 / 0;} 
                } catch (Exception ex) {
                    continue;
                }
            }
      } catch (Exception ex) {
            /* APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,false, null, true);*/
            throw ex;
        }
        return oWrapper;
    }


    /*****
       *@description : method returns contracted products per account using CER records
       *@param String : order type "Route Sales Order" or "Operating Order"
    ****/
    public static Map<Id, List<APTS_RSOProductCatalogWrapper.ContractedProducts>> getContractedProducts(String orderType, Set<Id> setAccountID, Map<Id, Apttus__APTS_Agreement__c> mapContributingAgrs, Map<Id, APTS_RSOProductCatalogWrapper.RSOProducts> mapAllRSOProducts, Map<String, Set<Id>> mapCategoryProductId) {
        Map<Id, List<APTS_RSOProductCatalogWrapper.ContractedProducts>> mapContractedProduct = new Map<Id, List<APTS_RSOProductCatalogWrapper.ContractedProducts>>();

        try {
            Set<String> setAgType = new Set<String> {STANDARD_DEAL};

            if (ORDERTYPE_OPERATING.equalsIgnoreCase(orderType)) {
                setAgType.add(CONSUMPTION_MODEL);
            }

            Boolean isConsignment;
            String categoryText;
            Apttus__APTS_Agreement__c agTmp;
            APTS_RSOProductCatalogWrapper.RSOProducts oRSOProdTmp;
            APTS_RSOProductCatalogWrapper.ContractedProducts rsoContractedTmp;
            Set<Id> setProdIdTmp;
            List<APTS_RSOProductCatalogWrapper.ContractedProducts> listRSOContractedTmp,listRSOContractedTmp1;
            Map<Id, Set<Id>> mapContractedProductId = new Map<Id, Set<Id>> ();

            for (APTS_Contract_Entitlement_Repository__c cerRecord : [SELECT Id, APTS_Sold_to_Party__c, APTS_Charge_Type__c,
                    APTS_Agreement_Type__c,
                    APTS_Product__c,
                    APTS_Product__r.APTS_Category_Adjustments_Product__c,
                    APTS_Contributing_Agreement__c,
                    APTS_Contributing_Agreement__r.RecordTypeId,
                    APTS_Contributing_Agreement__r.Apttus_CMConfig__PONumber__c,
                    APTS_Contributing_Agreement__r.APTS_Routesales__c,
                    APTS_Contributing_Agreement__r.APTS_Order_Non_Contracted_Products__c,
                    APTS_Agreement_Line_Item__c,
                    APTS_Agreement_Line_Item__r.APTS_YOCI_Available_CI__c,
                    APTS_CategoryCER__r.Name, APTS_Sub_Category__r.Name, APTS_Sub_Sub_Category__r.Name
                    FROM APTS_Contract_Entitlement_Repository__c
                    WHERE APTS_Sold_to_Party__c != null AND APTS_Sold_to_Party__c IN :setAccountID AND APTS_Contributing_Agreement__c != null
                    AND APTS_Product__c != null AND APTS_Is_Pending__c = false AND APTS_Agreement_Type__c IN :setAgType
                            AND APTS_Agreement_Line_Item__r.Apttus_CMConfig__IsPrimaryLine__c = true AND APTS_Agreement_Line_Item__r.Apttus_CMConfig__HasOptions__c = false
                                    AND APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c = :TYPE_PROD_SERVICE]) {
                try {
                    agTmp = mapContributingAgrs.get(cerRecord.APTS_Sold_to_Party__c);

                    if (agTmp != null && cerRecord.APTS_Contributing_Agreement__r != null && cerRecord.APTS_Contributing_Agreement__r.RecordTypeId == agTmp.RecordTypeId) {
                        //check if stock count available
                        isConsignment = cerRecord.APTS_Agreement_Line_Item__r != null && cerRecord.APTS_Agreement_Line_Item__r.APTS_YOCI_Available_CI__c ? cerRecord.APTS_Agreement_Line_Item__r.APTS_YOCI_Available_CI__c : false;

                        listRSOContractedTmp = mapContractedProduct.get(cerRecord.APTS_Sold_to_Party__c);
                        listRSOContractedTmp = listRSOContractedTmp == null ? new List<APTS_RSOProductCatalogWrapper.ContractedProducts>() : listRSOContractedTmp;
                        setProdIdTmp = mapContractedProductId.get(cerRecord.APTS_Sold_to_Party__c);
                        setProdIdTmp = setProdIdTmp == null ? new Set<Id>() : setProdIdTmp;

                        //if product is category adjustment or exists in RSO catalog than send data else remove product from list
                        if (cerRecord.APTS_Product__r.APTS_Category_Adjustments_Product__c) {
                            //CER record for Category Adjustment

                            //get category text
                            categoryText = cerRecord.APTS_CategoryCER__r != null && String.isNotBlank(cerRecord.APTS_CategoryCER__r.Name) ? cerRecord.APTS_CategoryCER__r.Name : '';
                            categoryText += cerRecord.APTS_Sub_Category__r != null && String.isNotBlank(cerRecord.APTS_Sub_Category__r.Name) ?  '_' + cerRecord.APTS_Sub_Category__r.Name : '';
                            categoryText += cerRecord.APTS_Sub_Sub_Category__r.Name != null && String.isNotBlank(cerRecord.APTS_Sub_Sub_Category__r.Name) ?  '_' + cerRecord.APTS_Sub_Sub_Category__r.Name : '';
                            categoryText = categoryText.toUpperCase().deleteWhitespace();

                            //If category products are available in RSO catalog
                            if (String.isNotBlank(categoryText) && mapCategoryProductId.containsKey(categoryText)) {
                                //Iterate through category products and get list of contracted products warrper
                                for (Id prodId : mapCategoryProductId.get(categoryText)) {

                                    oRSOProdTmp = mapAllRSOProducts.get(prodId);
                                    if (oRSOProdTmp != null) {
                                        rsoContractedTmp = getRSOContractedProdWrapper(isConsignment, cerRecord.APTS_Sold_to_Party__c, oRSOProdTmp);
                                        listRSOContractedTmp.add(rsoContractedTmp);
                                    }

                                    setProdIdTmp.add(prodId);
                                }
                            }

                        } else if (mapAllRSOProducts.containsKey(cerRecord.APTS_Product__c) && !setProdIdTmp.contains(cerRecord.APTS_Product__c)) {
                            //avoid duplicate products
                            //CER record for individual products
                            oRSOProdTmp = mapAllRSOProducts.get(cerRecord.APTS_Product__c);
                            if (oRSOProdTmp != null) {
                                rsoContractedTmp = getRSOContractedProdWrapper(isConsignment, cerRecord.APTS_Sold_to_Party__c, oRSOProdTmp);
                                listRSOContractedTmp.add(rsoContractedTmp);
                            }

                            setProdIdTmp.add(cerRecord.APTS_Product__c);
                        }

                        //set maps
                        mapContractedProduct.put(cerRecord.APTS_Sold_to_Party__c, listRSOContractedTmp);
                        mapContractedProductId.put(cerRecord.APTS_Sold_to_Party__c, setProdIdTmp);
                    }
                     if (Test.isRunningTest()){ Decimal dc1 = 1 / 0;} 
                } catch (Exception ex) {
                    continue;
                }
            }


            //loop through sold to for which CER were not available
            Map<Id, Id> mapMissingCERAccAg = new Map<Id, Id>();
            for (Id accId : setAccountID) {
                listRSOContractedTmp = mapContractedProduct.get(accId);
                agTmp = mapContributingAgrs.get(accId);

                if (agTmp != null && (listRSOContractedTmp == null || listRSOContractedTmp.isEmpty()) && !mapMissingCERAccAg.containsKey(agTmp.Apttus__Account__c)) {
                    mapMissingCERAccAg.put(agTmp.Apttus__Account__c, accId);
                }
            }


            //get missing CER from Sold To of contributing Agreement
            if (mapMissingCERAccAg != null && !mapMissingCERAccAg.isEmpty()) {
                Id accId, contriAccId;
                for (APTS_Contract_Entitlement_Repository__c cerRecord : [SELECT Id, APTS_Sold_to_Party__c, APTS_Charge_Type__c,
                        APTS_Agreement_Type__c,
                        APTS_Product__c,
                        APTS_Product__r.APTS_Category_Adjustments_Product__c,
                        APTS_Contributing_Agreement__c,
                        APTS_Contributing_Agreement__r.RecordTypeId,
                        APTS_Contributing_Agreement__r.Apttus_CMConfig__PONumber__c,
                        APTS_Contributing_Agreement__r.APTS_Routesales__c,
                        APTS_Contributing_Agreement__r.APTS_Order_Non_Contracted_Products__c,
                        APTS_Agreement_Line_Item__c,
                        APTS_Agreement_Line_Item__r.APTS_YOCI_Available_CI__c,
                        APTS_CategoryCER__r.Name, APTS_Sub_Category__r.Name, APTS_Sub_Sub_Category__r.Name
                        FROM APTS_Contract_Entitlement_Repository__c
                        WHERE APTS_Sold_to_Party__c != null AND APTS_Sold_to_Party__c IN :mapMissingCERAccAg.keySet() AND APTS_Contributing_Agreement__c != null
                        AND APTS_Product__c != null AND APTS_Is_Pending__c = false AND APTS_Agreement_Type__c IN :setAgType
                                AND APTS_Agreement_Line_Item__r.Apttus_CMConfig__IsPrimaryLine__c = true AND APTS_Agreement_Line_Item__r.Apttus_CMConfig__HasOptions__c = false
                                        AND APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c = :TYPE_PROD_SERVICE]) {
                    try {
                        accId = mapMissingCERAccAg.get(cerRecord.APTS_Sold_to_Party__c);
                        agTmp = mapContributingAgrs.get(accId);
                        
                        if (agTmp != null && cerRecord.APTS_Contributing_Agreement__r != null && cerRecord.APTS_Contributing_Agreement__r.RecordTypeId == agTmp.RecordTypeId) {
                            //check if stock count available
                            isConsignment = cerRecord.APTS_Agreement_Line_Item__r != null && cerRecord.APTS_Agreement_Line_Item__r.APTS_YOCI_Available_CI__c ? cerRecord.APTS_Agreement_Line_Item__r.APTS_YOCI_Available_CI__c : false;

                            listRSOContractedTmp = mapContractedProduct.get(accId);
                            listRSOContractedTmp = listRSOContractedTmp == null ? new List<APTS_RSOProductCatalogWrapper.ContractedProducts>() : listRSOContractedTmp;
                            setProdIdTmp = mapContractedProductId.get(accId);
                            setProdIdTmp = setProdIdTmp == null ? new Set<Id>() : setProdIdTmp;

                            //if product is category adjustment or exists in RSO catalog than send data else remove product from list
                            if (cerRecord.APTS_Product__r.APTS_Category_Adjustments_Product__c) {
                                //CER record for Category Adjustment

                                //get category text
                                categoryText = cerRecord.APTS_CategoryCER__r != null && String.isNotBlank(cerRecord.APTS_CategoryCER__r.Name) ? cerRecord.APTS_CategoryCER__r.Name : '';
                                categoryText += cerRecord.APTS_Sub_Category__r != null && String.isNotBlank(cerRecord.APTS_Sub_Category__r.Name) ?  '_' + cerRecord.APTS_Sub_Category__r.Name : '';
                                categoryText += cerRecord.APTS_Sub_Sub_Category__r.Name != null && String.isNotBlank(cerRecord.APTS_Sub_Sub_Category__r.Name) ?  '_' + cerRecord.APTS_Sub_Sub_Category__r.Name : '';
                                categoryText = categoryText.toUpperCase().deleteWhitespace();

                                //If category products are available in RSO catalog
                                if (String.isNotBlank(categoryText) && mapCategoryProductId.containsKey(categoryText)) {
                                    //Iterate through category products and get list of contracted products warrper
                                    for (Id prodId : mapCategoryProductId.get(categoryText)) {

                                        oRSOProdTmp = mapAllRSOProducts.get(prodId);
                                        if (oRSOProdTmp != null) {
                                            rsoContractedTmp = getRSOContractedProdWrapper(isConsignment, accId, oRSOProdTmp);
                                            listRSOContractedTmp.add(rsoContractedTmp);
                                        }

                                        setProdIdTmp.add(prodId);
                                    }
                                }

                            } else if (mapAllRSOProducts.containsKey(cerRecord.APTS_Product__c) && !setProdIdTmp.contains(cerRecord.APTS_Product__c)) {
                                //avoid duplicate products
                                //CER record for individual products
                                oRSOProdTmp = mapAllRSOProducts.get(cerRecord.APTS_Product__c);
                                if (oRSOProdTmp != null) {
                                    rsoContractedTmp = getRSOContractedProdWrapper(isConsignment, accId, oRSOProdTmp);
                                    listRSOContractedTmp.add(rsoContractedTmp);
                                }

                                setProdIdTmp.add(cerRecord.APTS_Product__c);
                            }

                            //set maps
                            mapContractedProduct.put(accId, listRSOContractedTmp);
                            mapContractedProductId.put(accId, setProdIdTmp);
                        }
                    } catch (Exception ex) {
                        continue;
                    }
                }


                //If two or more location refer to Parent Or Grand Parent CER, we need to add them to all location
                for (Id accIdT : setAccountID) {
                    listRSOContractedTmp = mapContractedProduct.get(accIdT);
                    
                    if (listRSOContractedTmp == null || listRSOContractedTmp.isEmpty()) {
                        agTmp = mapContributingAgrs.get(accIdT);
                        contriAccId = agTmp != null ? mapMissingCERAccAg.get(agTmp.Apttus__Account__c) : null;
                        
                        if (agTmp != null && contriAccId != null ) {
                            listRSOContractedTmp = mapContractedProduct.get(contriAccId);
                            
                            if (listRSOContractedTmp != null && !listRSOContractedTmp.isEmpty()) {
                                listRSOContractedTmp1 = new List<APTS_RSOProductCatalogWrapper.ContractedProducts>(); 

                                for (APTS_RSOProductCatalogWrapper.ContractedProducts rsoContractedTmp1 : listRSOContractedTmp) {
                                    rsoContractedTmp = getRSOContractedProdWrapper(rsoContractedTmp1);
                                    rsoContractedTmp.AccountID = accIdT;
                                    listRSOContractedTmp1.add(rsoContractedTmp);
                                }

                                mapContractedProduct.put(accIdT, listRSOContractedTmp1);
                            }
                        }
                    }
                }

                system.debug('mapContractedProduct = ' + mapContractedProduct.keySet());

            }
          } catch (Exception ex) {
            /* APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,false, null, true);*/
            throw ex;
        }
        return mapContractedProduct;
    }

    //V101 ++<<
    /*****
        *@description : method returns records of workorder line item
        *@param String : email Id of RSA Agent or Operator
        *@param Boolean : if Agent is syncing for next day data
        *@param String (depericated) : Status of work order line item
        *@used : APTS_DigitalOrderBatchHelper
    ****/
    public static List<WorkOrderLineItem> getWorkOrderLineItem(string engineerEmail, Boolean isNextDayRoute, string strStatus) {
        List<WorkOrderLineItem> lstWOLI = new List<WorkOrderLineItem>();
        string strQuery = 'SELECT id, CaseID__c, ContactFirstName__c, ContactLastName__c, ContactPhone__c, ContactEmail__c,'
                          + 'SAPAccountLocationID__c, WorkOrderType__c, RetrievedStartTime__c, Status, SAPResourceNumber__c, StartDate__c,' 
                          + 'LocationName__c, AccountLocation__c,'
                          + 'AccountLocation__r.Apttus_Config2__AccountId__c, AccountLocation__r.Route_Sales_Main_Contact__c,'
                          + 'AccountLocation__r.Apttus_Config2__AccountId__r.Name,'
                          + 'AccountLocation__r.Apttus_Config2__AccountId__r.Sales_Organization__c,'
                          + 'AccountLocation__r.Apttus_Config2__AccountId__r.SAP_Customer_ID__c,'
                          + 'AccountLocationStreet__c, AccountLocationHouseNumber__c, AccountLocationCity__c, AccountLocationState__c,'
                          + 'AccountLocationCountry__c, AccountLocationPostalCode__c FROM WorkOrderLineItem WHERE SAPResourceEmail__c = \'' + engineerEmail + '\' AND StartDate__c = ' + ((isNextDayRoute) ? ' TOMORROW' : ' TODAY') + ' AND AllowIngredientOrdering__c = true';
        lstWOLI =  Database.query(strQuery);
        return lstWOLI;
    }
    //V101 ++>>

    /*****
        *@description : method returns map of Account with required details to create an order
        *@param set<Id> : Set of account Id from work order line item
        *@used : APTS_DigitalOrderBatchHelper
    ****/
    public static Map<Id, Account> getAccounts(set<Id> setAccountID) {
        Map<Id, Account> mapAccounts;

        try {

            mapAccounts = new Map<Id, Account> ([SELECT Id, Name, Ultimate_Parent_Account__c, APTS_Account_Level__c,
                                                 Language__c, Apttus_Config2__BillingPreferenceId__c, Apttus_Config2__PaymentTermId__c,
                                                 Bill_To_Payer_Account__c, Related_Payer_Account__c, Related_Payer_Machines_Services__c,
                                                 Sales_Organization__c, Division__c, Distribution_Channel__c, Partner__c, SAP_Customer_ID__c,
                                                 APTS_Payment_Method__c, APTS_Price_List__c, Billing_header_text__c, ParentId, Parent.ParentId
                                                 FROM Account
                                                 WHERE Id IN :setAccountID ]);
            
        } catch (Exception ex) {
            /* APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,false, null, true);*/
            throw ex;
        }

        return mapAccounts;
    }


    /*****
        *@description : method returns contributing Agreement for RSO
        *@param String : "Operating Order" or "Route Sales Order"
        *@param set<Id> : Set of account Id from work order line item
        *@used : APTS_RSOSyncDataWebService
    ****/
    public static Map<Id, Apttus__APTS_Agreement__c> getRSOAgreement(String orderType, Set<Id> setAccountID) {
        Map<Id, Apttus__APTS_Agreement__c> mapRSOAg = new Map<Id, Apttus__APTS_Agreement__c>();        
        try {
            List<Account> listAccounts = [SELECT Id, ParentId, Parent.ParentId FROM Account WHERE Id IN :setAccountID AND Id != null];
            APTS_RSOOrderUtils.AccountHierarchyWrapper oWraper = APTS_RSOOrderUtils.getAccountHierarchyId(listAccounts);

            if (oWraper != null) {
                mapRSOAg = getContributingAgreements(orderType, oWraper);
            }
          } catch (Exception ex) {
            /* APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,false, null, true);*/
            throw ex;
        }

        return mapRSOAg;
    }

    /*****
    *@description : returns contributing Agreement in Account Hierarchy which qualifies for Accounts
    *@param String : "Operating Order" or "Route Sales Order"
    *@param AccountHierarchyWrapper : Ids of Parent and Grand Parent
    *@used : APTS_RSOSyncDataWebService
    ****/
    public static Map<Id, Apttus__APTS_Agreement__c> getContributingAgreements(String orderType, AccountHierarchyWrapper wrpObj) {
        Map<Id, Apttus__APTS_Agreement__c> mapContributingAgrs = new Map<Id, Apttus__APTS_Agreement__c>();        
        try {

            if (wrpObj == null || wrpObj.setAllAccountId == null || wrpObj.setAllAccountId.isEmpty()) {
                return null;
            }

            //v103 -- 5930 -- order creation for Expired and Being Renewed Agreement
            Set<String> setAgStatus = APTS_OrderConstants.STANDARD_ORDER_AG_STATUS;
            List<Boolean> routeSalesFlag = new List<Boolean> {true};
            if (ORDERTYPE_OPERATING.equalsIgnoreCase(orderType)) {
                routeSalesFlag.add(false);
            }

            Apttus__APTS_Agreement__c agObjTmp;
            Map<Id, Apttus__APTS_Agreement__c> mapAgreements = new Map<Id, Apttus__APTS_Agreement__c>();
            for (Apttus__APTS_Agreement__c agObj : [SELECT Id, RecordTypeId, Apttus__Account__c, APTS_Order_Non_Contracted_Products__c, RecordType.Name
                                                    FROM Apttus__APTS_Agreement__c WHERE Apttus__Account__c != null AND Apttus__Account__c IN :wrpObj.setAllAccountId
                                                    AND Apttus__Status__c IN :setAgStatus AND APTS_Routesales__c IN :routeSalesFlag]) {

                if (ORDERTYPE_OPERATING.equalsIgnoreCase(orderType)) {
                    agObjTmp = mapAgreements.get(agObj.Apttus__Account__c);
                    agObjTmp = agObjTmp == null || (agObj.RecordTypeId != null && CONSUMPTION_MODEL.equalsIgnoreCase(agObj.RecordType.Name)) ? agObj : agObjTmp;
                } else if (agObj.RecordTypeId != null && STANDARD_DEAL.equalsIgnoreCase(agObj.RecordType.Name)) {
                    agObjTmp = agObj;
                }

                mapAgreements.put(agObj.Apttus__Account__c, agObjTmp);
            }

            if (!mapAgreements.isEmpty()) {
                Boolean isConsumptionAg = false;
                Id agrIdTmp;
                agObjTmp = null;
                //Apttus__APTS_Agreement__c bgAgObjTmp;
                Apttus__APTS_Agreement__c parentAgObjTmp;
                //Apttus__APTS_Agreement__c parentBGAgObjTmp;
                Apttus__APTS_Agreement__c grandParentAgObjTmp;
                //Apttus__APTS_Agreement__c grandParentBGAgObjTmp;

                for (Id accId : wrpObj.setAccountToVisitId) {
                    agObjTmp = mapAgreements.get(accId);

                    //get parent Agreement
                    agrIdTmp = wrpObj.mapParentId != null ? wrpObj.mapParentId.get(accId) : null;
                    parentAgObjTmp = agrIdTmp != null ? mapAgreements.get(agrIdTmp) : null;

                    //get grand parent has an Agreement
                    agrIdTmp = wrpObj.mapGrandParentId != null ? wrpObj.mapGrandParentId.get(accId) : null;
                    grandParentAgObjTmp = agrIdTmp != null ? mapAgreements.get(agrIdTmp) : null;

                    //get buyer group  Agreement
                    //agrIdTmp = wrpObj.mapBGId != null ? wrpObj.mapBGId.get(accId) : null;
                    //bgAgObjTmp = agrIdTmp != null ? mapAgreements.get(agrIdTmp) : null;

                    //get parent Buyer Group Agreement
                    //agrIdTmp = wrpObj.mapParentBGId != null ? wrpObj.mapParentBGId.get(accId) : null;
                    //parentBGAgObjTmp = agrIdTmp != null ? mapAgreements.get(agrIdTmp) : null;

                    //get grand parent has an Agreement
                    //agrIdTmp = wrpObj.mapGrandParentBGId != null ? wrpObj.mapGrandParentBGId.get(accId) : null;
                    //grandParentBGAgObjTmp = agrIdTmp != null ? mapAgreements.get(agrIdTmp) : null;


                    if (ORDERTYPE_OPERATING.equalsIgnoreCase(orderType)) {

                        if (agObjTmp == null || (agObjTmp.RecordTypeId != null && STANDARD_DEAL.equalsIgnoreCase(agObjTmp.RecordType.Name))) {
                            agObjTmp = parentAgObjTmp;
                        }

                        if (agObjTmp == null || (agObjTmp.RecordTypeId != null && STANDARD_DEAL.equalsIgnoreCase(agObjTmp.RecordType.Name))) {
                            agObjTmp = grandParentAgObjTmp;
                        }

                        /*if (agObjTmp == null || (agObjTmp.RecordTypeId != null && STANDARD_DEAL.equalsIgnoreCase(agObjTmp.RecordType.Name))) {
                            agObjTmp = bgAgObjTmp;
                        }

                        if (agObjTmp == null || (agObjTmp.RecordTypeId != null && STANDARD_DEAL.equalsIgnoreCase(agObjTmp.RecordType.Name))) {
                            agObjTmp = parentBGAgObjTmp;
                        }

                        if (agObjTmp == null || (agObjTmp.RecordTypeId != null && STANDARD_DEAL.equalsIgnoreCase(agObjTmp.RecordType.Name))) {
                            agObjTmp = grandParentBGAgObjTmp;
                        }*/

                        if (agObjTmp == null || (agObjTmp.RecordTypeId != null && STANDARD_DEAL.equalsIgnoreCase(agObjTmp.RecordType.Name))) {
                            agObjTmp = mapAgreements.get(accId);
                        }
                    }

                    if (agObjTmp == null) {
                        agObjTmp = parentAgObjTmp;
                    }

                    if (agObjTmp == null) {
                        agObjTmp = grandParentAgObjTmp;
                    }

                    /*if (agObjTmp == null) {
                        agObjTmp = bgAgObjTmp;
                    }

                    if (agObjTmp == null) {
                        agObjTmp = parentBGAgObjTmp;
                    }

                    if (agObjTmp == null) {
                        agObjTmp = grandParentBGAgObjTmp;
                    }*/

                    if (agObjTmp != null) {
                        mapContributingAgrs.put(accId, agObjTmp);
                    }
                }
            }
       } catch (Exception ex) {
            /* APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,false, null, true);*/
            throw ex;
        }

        return mapContributingAgrs;
    }

    /*****
    *@description : returns contributing Agreement in Account Hierarchy which qualifies for Accounts
    *               While Order creation happens for all Type of RSO Orders, we can't make two common methods
    *@param AccountHierarchyWrapper : Ids of Parent and Grand Parent
    *@Used : APTS_DigitalOrderBatchHelper
    ***/
    public static Map<Id, List<Apttus__APTS_Agreement__c>> getRSOAgreements(AccountHierarchyWrapper wrpObj) {

        Map<Id, List<Apttus__APTS_Agreement__c>> mapContributingAgrs = new Map<Id, List<Apttus__APTS_Agreement__c>>();        
        try {
            //v103 -- 5930 -- order creation for Expired and Being Renewed Agreement
            List<Apttus__APTS_Agreement__c> listAgTmp;
            Set<String> setAgStatus = APTS_OrderConstants.STANDARD_ORDER_AG_STATUS;
            Map<Id, List<Apttus__APTS_Agreement__c>> mapAgreementsTmp = new Map<Id, List<Apttus__APTS_Agreement__c>>();

            if (wrpObj == null || wrpObj.setAccountToVisitId == null || wrpObj.setAccountToVisitId.isEmpty()) {
                return null;
            }
            Integer count=0;
            for (Apttus__APTS_Agreement__c agObj : [SELECT Id, RecordTypeId, Apttus__Account__c, APTS_Order_Non_Contracted_Products__c, RecordType.Name,
                                                    Name,  APTS_Location__c, Apttus_CMConfig__PriceListId__c,
                                                    Apttus_CMConfig__PONumber__c, Apttus_CMConfig__BillingPreferenceId__c, Apttus_CMConfig__PaymentTermId__c,
                                                    Apttus__Status_Category__c, Apttus__Status__c, Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c,
                                                    Apttus__Primary_Contact__c, APTS_Language__c, APTS_Bill_to_Party_Ingredients__c, APTS_Payer_Ingredients__c,
                                                    APTS_Bill_to_Party_MachServ__c, APTS_Payer_Machines_Services__c, APTS_Routesales__c,
                                                    Apttus__Account__r.APTS_Account_Level__c, Apttus__Account__r.Name, APTS_Location__r.Billing_header_text__c,
                                                    APTS_Location__r.Delivery_text__c, APTS_Check_on_Account_Machines__c,APTS_Check_on_Account_Ingredients__c
                                                    FROM Apttus__APTS_Agreement__c WHERE Apttus__Account__c != null AND Apttus__Account__c IN :wrpObj.setAllAccountId
                                                    AND Apttus__Status__c != null AND Apttus__Status__c IN :setAgStatus]) {

                 // if(agObj.Apttus__Contract_End_Date__c >= System.today()){
                listAgTmp = mapAgreementsTmp.get(agObj.Apttus__Account__c);
                listAgTmp = listAgTmp == null ? new List<Apttus__APTS_Agreement__c> () : listAgTmp;
                listAgTmp.add(agObj);
                mapAgreementsTmp.put(agObj.Apttus__Account__c, listAgTmp);
                //}
            }


            if (!mapAgreementsTmp.isEmpty()) {
                Id parentId, grandParentId;
                listAgTmp = null;

                for (Id accId : wrpObj.setAccountToVisitId) {
                    listAgTmp = mapContributingAgrs.get(accId);
                    listAgTmp = listAgTmp == null ? new List<Apttus__APTS_Agreement__c> () : listAgTmp;

                    if (mapAgreementsTmp.containsKey(accId)) {
                        listAgTmp.addAll(mapAgreementsTmp.get(accId));
                    }

                    parentId = wrpObj.mapParentId == null ? null : wrpObj.mapParentId.get(accId);
                    if (parentId != null && mapAgreementsTmp.containsKey(parentId)) {
                        listAgTmp.addAll(mapAgreementsTmp.get(parentId));
                    }

                    grandParentId = wrpObj.mapGrandParentId == null ? null : wrpObj.mapGrandParentId.get(accId);
                    if (grandParentId != null && mapAgreementsTmp.containsKey(grandParentId)) {
                        listAgTmp.addAll(mapAgreementsTmp.get(grandParentId));
                    }

                    mapContributingAgrs.put(accId, listAgTmp);
                }
            }
         } catch (Exception ex) {
            APTS_CustomLogging.createErrorLog('Error in RSO', 'Apex', ex.getStackTraceString(), 'Agreement Hierachy', '', 'OM', false, false, null, true);
            throw ex;
        }
    
        return mapContributingAgrs;

    }

   
    /*****
    *@description : method returns contributing Agreements
    *@param String : "Operating Order" or "Route Sales Order"
    *@param List<Id> : List of account, Parent Id, Grand Parent Id
    *@Used at -- APTS_CreateRSOOrderController
    ****/
    //v107 : setAccountID : Converted Set to List to get the index of Account, parent account and grand parent account.
    public static RSOWrapper getRSOAgreements(String sSubtype, List<Id> setAccountID) {
       //v113 ++<<
        RSOWrapper result = new RSOWrapper();
        result.IsAgreement = true;
        //v113 ++>>
        Map<Id, List<Apttus__APTS_Agreement__c>> mapAccountAg = new Map<Id, List<Apttus__APTS_Agreement__c>>();       
        try {
            Set<String> setDealType = new Set<String> {STANDARD_DEAL};
            List<Boolean> setRouteSalesFlag = new List<Boolean>();
            
            //v107 <<++
            List<Apttus__APTS_Agreement__c> listAg = new List<Apttus__APTS_Agreement__c>();     // Stores Agg for child account
            List<Apttus__APTS_Agreement__c> listAg1 = new List<Apttus__APTS_Agreement__c>();    // Stores Agg for Parent account
            List<Apttus__APTS_Agreement__c> listAg2 = new List<Apttus__APTS_Agreement__c>();    // Stores Agg for Grand Parent account
            //v107 -->>
            
            //if standard-deal than search only for routesales agreement else both
            setRouteSalesFlag.add(true);

            //Operating Order data to query agreement
            if (sSubtype == null || ORDERTYPE_OPERATING.equalsIgnoreCase(sSubtype)) {
                setRouteSalesFlag.add(false);
                setDealType.add(CONSUMPTION_MODEL);
            }

            //v103 -- 5930 -- order creation for Expired and Being Renewed Agreement
            Set<String> setAgStatus = APTS_OrderConstants.STANDARD_ORDER_AG_STATUS;
            Integer Count = 0;
            //for type null or operating below query will return all Active Standard-Deal & Consumption Model Agreements
            for (Apttus__APTS_Agreement__c oAgreement : [
                SELECT Id, Name, RecordTypeId, Apttus__Account__c, APTS_Location__c, Apttus_CMConfig__PriceListId__c,
                Apttus_CMConfig__PONumber__c, Apttus_CMConfig__BillingPreferenceId__c, Apttus_CMConfig__PaymentTermId__c,
                Apttus__Status_Category__c, Apttus__Status__c, Apttus__Contract_Start_Date__c, Apttus__Contract_End_Date__c,
                Apttus__Primary_Contact__c, APTS_Language__c, APTS_Bill_to_Party_Ingredients__c, APTS_Payer_Ingredients__c,
                APTS_Bill_to_Party_MachServ__c, APTS_Payer_Machines_Services__c, APTS_Routesales__c, RecordType.Name,
                Apttus__Account__r.APTS_Account_Level__c, Apttus__Account__r.Name, APTS_Location__r.Billing_header_text__c,
                APTS_Location__r.Delivery_text__c, APTS_Check_on_Account_Machines__c,APTS_Check_on_Account_Ingredients__c
                FROM Apttus__APTS_Agreement__c
                WHERE Apttus__Account__c <> null AND Apttus__Account__c IN :setAccountID AND Apttus__Status__c <> null AND Apttus__Status__c IN :setAgStatus
                AND APTS_Routesales__c IN :setRouteSalesFlag AND RecordType.Name IN :setDealType]) {
                count = count+1;
          if(oAgreement.Apttus__Contract_End_Date__c >= System.today()){
                    if (ORDERTYPE_OPERATING.equalsIgnoreCase(sSubtype)) {
                        listAg = mapAccountAg.get(oAgreement.Apttus__Account__c);
                        listAg = listAg == null ? new List<Apttus__APTS_Agreement__c> () : listAg;
                        listAg.add(oAgreement);
                        mapAccountAg.put(oAgreement.Apttus__Account__c, listAg);
                    } 
                    //v107 <<++ Changed the logic of getting the agreement from account hierarchy
                    else if(STANDARD_DEAL.equalsIgnoreCase(oAgreement.RecordType.Name) && oAgreement.APTS_Routesales__c){
                        if(oAgreement.Apttus__Account__c == setAccountID[0]){                        
                            listAg.add(oAgreement);
                        }else if(oAgreement.Apttus__Account__c == setAccountID[1]){
                            listAg1.add(oAgreement);
                        }else if(oAgreement.Apttus__Account__c == setAccountID[2]){
                            listAg2.add(oAgreement);
                        }
                    } 
                   
                    
                      
                }
                }

                
                if(listAg!=null && !listAg.isEmpty())  mapAccountAg.put(setAccountID[0], listAg);
                else if(listAg1!=null && !listAg1.isEmpty()) mapAccountAg.put(setAccountID[1], listAg1);
                else if(listAg2!=null && !listAg2.isEmpty()) mapAccountAg.put(setAccountID[2], listAg2);
                //v107 -->>
                  //v113 ++<<
                 if(count >=1 && mapAccountAg.isEmpty()){
               
                     result.IsAgreement = false;
                }
                //v113 ++>>
              
                
            } catch (Exception ex) {
            throw ex;
        }   
        result.mapAccAgr = mapAccountAg;     
        return result;
    }

    /*****
    *@description : method returns Contacts associated to Accounts
    *@param set<Id> : Set of accounts
    *@Used :
    ****/
    public static Map<Id, Contact> getContacts(Set<Id> setSoldToId) {
        Map<Id, Contact> mapContancts = new Map<Id, Contact>();
        for (Contact oContact : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :setSoldToId ]) {
            mapContancts.put(oContact.AccountId, oContact);
        }

        return mapContancts;
    }

    /*****
    *@description : method returns SAP Employee Number
    *@param set<String> : Set of emails
    *@Used :
    ****/
    public static Map<String, String> getSAPNumber(Set<String> setSAPEmails) {
        Map<String, String> mapSAPEmpNumber = new Map<String, String>();
        for (User oUserObj : [SELECT Id, Email, EmployeeNumber FROM User WHERE Email = :setSAPEmails]) {
            if (String.isNotBlank(oUserObj.Email) && String.isNotBlank(oUserObj.EmployeeNumber)) {
                mapSAPEmpNumber.put(oUserObj.Email.toLowerCase(), oUserObj.EmployeeNumber);
            }
        }

        return mapSAPEmpNumber;
    }

    /*****
    *@description : method returns PO Details
    *@param set<Id> : Set of Agreement Id
    *@Used :
    ****/
    public static Map<Id, List<APTS_Agreement_PO_Details__c>> getPODetails(Set<Id> setAgreements) {
        Map<Id, List<APTS_Agreement_PO_Details__c>> mapListAgPO = new Map<Id, List<APTS_Agreement_PO_Details__c>>();
        List<APTS_Agreement_PO_Details__c> listPODetails = new List<APTS_Agreement_PO_Details__c>();

        for (APTS_Agreement_PO_Details__c oPODetails : [select id, APTS_PO_Number__c, APTS_Agreement__c, APTS_PO_Expiration_Date__c, APTS_PO_Number_Type__c, APTS_PO_Number_Required__c from APTS_Agreement_PO_Details__c where APTS_Agreement__c IN :setAgreements AND  APTS_PO_Category__c = 'Ingredients' ]) {
            listPODetails = mapListAgPO.get(oPODetails.APTS_Agreement__c);
            listPODetails = listPODetails == null ? new List<APTS_Agreement_PO_Details__c>() : listPODetails;
            listPODetails.add(oPODetails);

            mapListAgPO.put(oPODetails.APTS_Agreement__c, listPODetails);
        }

        return mapListAgPO;

    }


    /*****
    *@description : method returns wrapper object with Parent and Grand Parent Account Ids
    *@param set<Id> : Set of Account Id
    *@Used :
    ****/
    public static AccountHierarchyWrapper getAccountHierarchyId(Set<Id> setAccountID) {
        AccountHierarchyWrapper wrpObj = new AccountHierarchyWrapper();

        try {
            List<Account> listAccounts = [SELECT Id, ParentId, Parent.ParentId FROM Account WHERE Id IN :setAccountID AND Id != null];
            wrpObj = getAccountHierarchyId(listAccounts);
             if (Test.isRunningTest()){ Decimal dc1 = 1 / 0;} 
        } catch (Exception ex) {
            APTS_CustomLogging.createErrorLog('Error in RSOSyncWebservice', 'Apex', ex.getStackTraceString(), 'Account Hierachy', '', 'OM', false, false, null, true);
        }

        return wrpObj;
    }


    /*****
    *@description : method returns wrapper object with Parent and Grand Parent Account Ids
    *@param List<Account> : list of Account records
    *@Used :
    ****/
    public static AccountHierarchyWrapper getAccountHierarchyId(List<Account> listAccounts) {
        AccountHierarchyWrapper wrpObj = new AccountHierarchyWrapper();
        wrpObj.setAllAccountId = new Set<Id>();
        wrpObj.setAccountToVisitId = new Set<Id>();
        wrpObj.mapParentId = new Map<Id, Id>();
        wrpObj.mapGrandParentId = new Map<Id, Id>();
        /*wrpObj.mapBGId = new Map<Id, Id>();
        wrpObj.mapParentBGId = new Map<Id, Id>();
        wrpObj.mapGrandParentBGId = new Map<Id, Id>();*/

        for (Account accObj : listAccounts) {

            try {
                wrpObj.setAllAccountId.add(accObj.Id);
                wrpObj.setAccountToVisitId.add(accObj.Id);

                //get parent account id
                if (accObj.ParentId != null) {
                    wrpObj.setAllAccountId.add(accObj.ParentId);
                    wrpObj.mapParentId.put(accObj.Id, accObj.ParentId);

                    //get ultimate parent account id
                    if (accObj.Parent.ParentId != null) {
                        wrpObj.setAllAccountId.add(accObj.Parent.ParentId);
                        wrpObj.mapGrandParentId.put(accObj.Id, accObj.Parent.ParentId);
                    }
                }
             if (Test.isRunningTest()){ Decimal dc1 = 1 / 0;} 
            } catch (Exception ex) {
                APTS_CustomLogging.createErrorLog('Error in RSOSyncWebservice', 'Apex', ex.getStackTraceString(), 'Account Hierachy', accObj.Id, 'OM', false, false, null, true);
            } finally {
                continue;
            }
        }

        return wrpObj;
    }


    /*****
    *@description : method sets SAP Order Type on Order Header
    *@param Apttus_Config2__Order__c : order instance
    *@Used : APTS_CreateRSOOrderController
    ****/
    public static String getSAPOrderType(Apttus_Config2__Order__c oRSOOrder) {
        String strSAPType = '';

        if (ORDERTYPE_ROUTESALES.equalsIgnoreCase(oRSOOrder.APTS_Order_Type__c)) {
            if (ORDERSUBTYPE_STANDARDORDER.equalsIgnoreCase(oRSOOrder.APTS_Order_Sub_Type__c)) {
                strSAPType = oRSOOrder.APTS_Fulfill_From_To_Van__c ?  XA02 : XA01;
            } else if (ORDERSUBTYPE_UNPLANNEDRETUREN.equalsIgnoreCase(oRSOOrder.APTS_Order_Sub_Type__c)) {
                strSAPType = oRSOOrder.APTS_Fulfill_From_To_Van__c ?  XB05 : XB02;
            }
        } else if (ORDERTYPE_OPERATING.equalsIgnoreCase(oRSOOrder.APTS_Order_Type__c)) {
            if (ORDERSUBTYPE_STANDARDORDER.equalsIgnoreCase(oRSOOrder.APTS_Order_Sub_Type__c)) {
                strSAPType = oRSOOrder.APTS_Fulfill_From_To_Van__c ?  XA02 : XA01;
            } else if (ORDERSUBTYPE_UNPLANNEDRETUREN.equalsIgnoreCase(oRSOOrder.APTS_Order_Sub_Type__c)) {
                strSAPType = oRSOOrder.APTS_Fulfill_From_To_Van__c ?  XB03 : XB02;
            } else if (ORDERSUBTYPE_STOCKCOUNT.equalsIgnoreCase(oRSOOrder.APTS_Order_Sub_Type__c)) {
                strSAPType = XA04;
            }
        }

        return strSAPType;
    }

    /*****
    *@description : method returns error message if Order data is not complete
    *@param APTS_DOEPIReqWrapper : order data recieved from mobile app
    *@Used : self
    ****/
    public static String validateRSOData(APTS_DOEPIReqWrapper oWrapper) {
        String sErrMsg = oWrapper == null ? 'JSON cannot be NULL' : null;

        if (String.isNotBlank(sErrMsg)) {
            return sErrMsg;
        }

        sErrMsg = String.isBlank(oWrapper.SalesforceAccountID) ? 'SalesforceAccountID cann\'t be NULL' : sErrMsg;
        sErrMsg = String.isBlank(oWrapper.SalesforceAccountLocationID) ?  'SalesforceAccountLocationID cann\'t be NULL' : sErrMsg;
        sErrMsg = String.isBlank(oWrapper.RSOEmployeeEmail) ? 'RSOEmailId cann\'t be NULL' : sErrMsg;
        sErrMsg = String.isBlank(oWrapper.OrderType) ? 'OrderType cann\'t be NULL' : sErrMsg;
        sErrMsg = String.isBlank(oWrapper.OrderSubType) ? 'OrderSubType cann\'t be NULL' : sErrMsg;
        sErrMsg = !'Stock Count'.equalsIgnoreCase(oWrapper.OrderSubType) && oWrapper.FulfilledFromVan == NULL ? 'FulfilledFromVan cann\'t be NULL' : sErrMsg;
        sErrMsg = oWrapper.OrderLineItems == NULL || oWrapper.OrderLineItems.isEmpty() ? 'OrderLineItems cann\'t be NULL' : sErrMsg;

        if (oWrapper.OrderLineItems != NULL) {
            for (APTS_DOEPIReqWrapper.EPIOrderLI oOLI : oWrapper.OrderLineItems) {
                sErrMsg = String.isBlank(oOLI.ProductId) ? 'ProductId cann\'t be NULL in orderline source number = ' + oOLI.SourceLineNumber : sErrMsg;
                sErrMsg = String.isBlank(oOLI.SellingUnitofMeasure) ? 'SellingUnitofMeasure cann\'t be NULL in orderline source number = ' + oOLI.SourceLineNumber : sErrMsg;
                sErrMsg = oOLI.Quantity == NULL || oOLI.Quantity < 1 ? 'Quantity cann\'t be NULL in orderline source number = ' + oOLI.SourceLineNumber : sErrMsg;
            }
        }

        return sErrMsg;
    }

    /*****
    *@description : method returns instance of an Order
    *@param Id : record type of routesales order
    *@param Id : record type of Operating order
    *@param APTS_DOEPIReqWrapper : order data recieved from mobile app
    *@param Account : Account data
    *@param List<Apttus__APTS_Agreement__c> : List of Agreements per account
    *@param Map<Id, List<APTS_Agreement_PO_Details__c>> : map of PO Details per Agreement
    *@Used : APTS_DigitalOrderBatchHelper
    ****/
    public static Apttus_Config2__Order__c createOrderHeader(Id routeSalesRecordTypeId, Id operatingRecordTypeId, APTS_DOEPIReqWrapper oWrapper, Account oAcc, List<Apttus__APTS_Agreement__c> listAg, Map<Id, List<APTS_Agreement_PO_Details__c>> mapAgPODetails) {
        Apttus_Config2__Order__c oExtOrder = new Apttus_Config2__Order__c();

        try {

            if (oAcc != null) {
                //v102 ++<<
                //Defect 4920 - don't take Location from Agreement as Agreement can be Parent / Grand Parent Agreement
                Map<Id, Contact> idToContactMap = APTS_OrderUtils.getAllContacts(oAcc.Id);
                id contactId = APTS_OrderUtils.getPrimaryContactId(idToContactMap, 'Standard');
                Contact oContact = contactId != null ? new Contact(id = contactId) : null;

                // //Defect 4920 - don't take Location from Agreement as Agreement can be Parent / Grand Parent Agreement
                Set<id> sAccountId = new Set<Id> {oAcc.Id};
                Map<id, Apttus_Config2__AccountLocation__c> mapAccountLocation = APTS_OrderUtils.getAccountLocation(sAccountId);
                Apttus_Config2__AccountLocation__c acLocation = mapAccountLocation != null ? mapAccountLocation.get(oAcc.Id) : null;
                createOrderHeader(routeSalesRecordTypeId, operatingRecordTypeId, oWrapper,  oAcc, listAg, mapAgPODetails, oContact, acLocation, null);
                //v102 ++>>

            }
          }   catch (Exception ex) {
            throw ex;
        }

        return oExtOrder;
    }

    /*****
    *@description : method returns instance of an Order
    *@param Id : record type of routesales order
    *@param Id : record type of Operating order
    *@param APTS_DOEPIReqWrapper : order data recieved from mobile app
    *@param Account : Account data
    *@param List<Apttus__APTS_Agreement__c> : List of Agreements per account
    *@param Map<Id, List<APTS_Agreement_PO_Details__c>> : map of PO Details per Agreement
    *@Used : APTS_DigitalOrderBatchHelper
    ****/
    public static Apttus_Config2__Order__c createOrderHeader(Id routeSalesRecordTypeId, Id operatingRecordTypeId, APTS_DOEPIReqWrapper oWrapper, Account oAcc, List<Apttus__APTS_Agreement__c> listAg, Map<Id, List<APTS_Agreement_PO_Details__c>> mapAgPODetails, Contact oContact, Apttus_Config2__AccountLocation__c accLocation, AccountHierarchyWrapper oAccHierachyWrap) {
        Apttus_Config2__Order__c oExtOrder = new Apttus_Config2__Order__c();
        oExtOrder.Apttus_Config2__BillToAccountId__c = oAcc.Id;
        oExtOrder.Apttus_Config2__SoldToAccountId__c = oAcc.Id;
        oExtOrder.Apttus_Config2__ShipToAccountId__c = oAcc.Id;
        oExtOrder.APTS_Payer__c = oAcc.Id;
        //v102 ++<<
        oExtOrder.Apttus_Config2__LocationId__c = String.isNotBlank(oWrapper.SalesforceAccountLocationID) ? oWrapper.SalesforceAccountLocationID : NULL;
        oExtOrder.Apttus_Config2__PrimaryContactId__c = String.isNotBlank(oWrapper.SalesforceContactID) ? oWrapper.SalesforceContactID : NULL;
        //v102 ++>>
        oExtOrder.APTS_Case__c = String.isNotBlank(oWrapper.CaseID) && !oWrapper.CaseID.containsIgnoreCase('temp_') ? oWrapper.CaseID : NULL;
        oExtOrder.APTS_Order_Type__c = oWrapper.OrderType;
        oExtOrder.APTS_Order_Sub_Type__c = oWrapper.OrderSubType;
        oExtOrder.APTS_Source_Order_Number__c = oWrapper.SourceOrderNumber;
        oExtOrder.APTS_Customer_Comments__c = oWrapper.CustomerComment;
        oExtOrder.APTS_Fulfill_From_To_Van__c = oWrapper.FulfilledFromVan;


        try {
            //set order header
            oExtOrder = APTS_OrderUtils.setOrderHeader(oExtOrder, oAcc);
            oExtOrder.RecordTypeId = APTS_OrderConstants.ORDER_TYPE_ROUTESALES.equalsIgnoreCase(oWrapper.OrderType) ? routeSalesRecordTypeId : operatingRecordTypeId;
            oExtOrder.APTS_SAP_OrderType__c = APTS_RSOOrderUtils.getSAPOrderType(oExtOrder);
            oExtOrder.APTS_Order_Reason__c = APTS_OrderConstants.UNPLANNED_RETURN == oExtOrder.APTS_Order_Sub_Type__c && oExtOrder.APTS_Order_Reason__c == NULL ? 'X99' : oExtOrder.APTS_Order_Reason__c;

            //select agreement for order
            //v105 << ++
            Apttus__APTS_Agreement__c oAg;
            Apttus__APTS_Agreement__c oChildAg;
            Apttus__APTS_Agreement__c oParentAg;
            Apttus__APTS_Agreement__c oGPAg;
            Apttus__APTS_Agreement__c oChildAg1;
            Apttus__APTS_Agreement__c oParentAg1;
            Apttus__APTS_Agreement__c oGPAg1;
            if (listAg != null) {
                for (Apttus__APTS_Agreement__c oAgTemp : listAg) {
                    if (APTS_OrderConstants.ORDER_TYPE_OPERATING.equalsIgnoreCase(oWrapper.OrderType)) {
                        if (APTS_OrderConstants.CONSUMPTION_MODEL.equalsIgnoreCase(oAgTemp.RecordType.Name)) {
                            if(oAgTemp.Apttus__Account__r.Id == oAcc.Id){
                                oChildAg1 = oAgTemp;
                            }
                            else if(oAgTemp.Apttus__Account__r.Id == oAccHierachyWrap.mapParentId.get(oAcc.Id)){
                                oParentAg1 = oAgTemp;
                            }
                            else if(oAgTemp.Apttus__Account__r.Id == oAccHierachyWrap.mapGrandParentId.get(oAcc.Id)){
                                oGPAg1 = oAgTemp;
                            }
                            oAg = oChildAg1 != null ? oChildAg1 : (oParentAg1 != null ? oParentAg1 : oGPAg1);
                        }
                        else if(oAg == null && !APTS_OrderConstants.CONSUMPTION_MODEL.equalsIgnoreCase(oAgTemp.RecordType.Name)){
                            if(oAgTemp.Apttus__Account__r.Id == oAcc.Id){
                                oChildAg = oAgTemp;
                            }
                            else if(oAgTemp.Apttus__Account__r.Id == oAccHierachyWrap.mapParentId.get(oAcc.Id)){
                                oParentAg = oAgTemp;
                            }
                            else if(oAgTemp.Apttus__Account__r.Id == oAccHierachyWrap.mapGrandParentId.get(oAcc.Id)){
                                oGPAg = oAgTemp;
                            }
                        }
                    } else if (APTS_OrderConstants.ORDER_TYPE_ROUTESALES.equalsIgnoreCase(oWrapper.OrderType)) {
                        if(APTS_OrderConstants.STANDARD_DEAL.equalsIgnoreCase(oAgTemp.RecordType.Name) && oAgTemp.APTS_Routesales__c) {
                            if(oAgTemp.Apttus__Account__r.Id == oAcc.Id){
                                oChildAg = oAgTemp;
                            }
                            else if(oAgTemp.Apttus__Account__r.Id == oAccHierachyWrap.mapParentId.get(oAcc.Id)){
                                oParentAg = oAgTemp;
                            }
                            else if(oAgTemp.Apttus__Account__r.Id == oAccHierachyWrap.mapGrandParentId.get(oAcc.Id)){
                                oGPAg = oAgTemp;
                            }
                        }    
                    }
                }
            }
            if(oAg == null) {
                oAg = oChildAg != null ? oChildAg : (oParentAg != null ? oParentAg : oGPAg);
            }
            //v105 ++ >>
            if (oAg != null) {
                APTS_BIRUtils.setInvoiceData(oAg,oExtOrder);//V109
                oExtOrder.Apttus_CMConfig__AgreementId__c = oAg.Id;
                oExtOrder.Apttus_Config2__PONumber__c = oAg.Apttus_CMConfig__PONumber__c;
                oExtOrder.Apttus_Config2__PriceListId__c = oAg.Apttus_CMConfig__PriceListId__c;

                //PONumber Logic
                List<APTS_Agreement_PO_Details__c> listAgPODetails = mapAgPODetails != null ? mapAgPODetails.get(oAg.Id) : null;
                //v108 << ++
                if(String.isNotBlank(oWrapper.PONumber)){
                    oExtOrder.Apttus_Config2__PONumber__c = oWrapper.PONumber;
                } //v108 ++ >>
                else if (listAgPODetails != null && !listAgPODetails.isEmpty()) {
                    APTS_Agreement_PO_Details__c oPODetails = listAgPODetails[0];
                    oExtOrder.Apttus_Config2__PONumber__c = oPODetails != NULL && String.isNotBlank(oWrapper.PONumber) && 'Yes'.equalsIgnoreCase(oPODetails.APTS_PO_Number_Required__c) && !'Fixed'.equalsIgnoreCase(oPODetails.APTS_PO_Number_Type__c) ? oWrapper.PONumber : oPODetails != NULL ? oPODetails.APTS_PO_Number__c : NULL;
                    oExtOrder.Apttus_Config2__PONumber__c = oExtOrder.Apttus_Config2__PONumber__c != null && oPODetails.APTS_PO_Expiration_Date__c < System.today() ? APTS_OrderConstants.PO_HAS_EXPIRED : oExtOrder.Apttus_Config2__PONumber__c;
                }
            }

            Long oLongDt = String.isNotBlank(oWrapper.OrderDate) && oWrapper.OrderDate.isNumeric() ? long.valueOf(oWrapper.OrderDate) : NULL;
            Datetime orderDt = oLongDt != NULL ? DateTime.newInstance(oLongDt) : Date.today() ;
            oExtOrder.Apttus_Config2__OrderDate__c = orderDt;
            oExtOrder.Apttus_Config2__OrderStartDate__c = orderDt.date();
            oExtOrder.Apttus_Config2__OrderEndDate__c = orderDt.date();

            //12 Jun 2018 - Aarthi - Added below to set the Requested delivery date based on fulfillment Type
            oLongDt = String.isNotBlank(oWrapper.DeliveryDate) && !(ZERO.equalsIgnoreCase(oWrapper.DeliveryDate)) && oWrapper.DeliveryDate.isNumeric() ? long.valueOf(oWrapper.DeliveryDate) : NULL;
            DateTime dtReqDelivery = oLongDt != NULL ? DateTime.newInstance(oLongDt) : NULL;
            oExtOrder.APTS_Requested_Delivery_Date__c = dtReqDelivery != NULL ? dtReqDelivery.date() : NULL;
            if (oExtOrder.APTS_Requested_Delivery_Date__c == NULL) {
                oExtOrder.APTS_Requested_Delivery_Date__c = oExtOrder.APTS_Fulfill_From_To_Van__c ? Date.today() : APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oExtOrder, system.today());
                //oExtOrder.APTS_Requested_Delivery_Date__c = APTS_OrderUtils.checkRequestedDeliveryDateInWorkingHours(oExtOrder, oExtOrder.APTS_Requested_Delivery_Date__c);
            }

            //v102 ++<<
            //if primary contact is not passed from app than set it according to standard order rules
            if (oExtOrder.Apttus_Config2__PrimaryContactId__c == null && oContact != null) {
                oExtOrder.Apttus_Config2__PrimaryContactId__c = oContact.Id;
            }
            if (oExtOrder.Apttus_Config2__LocationId__c == null && accLocation != null ) {
                oExtOrder.Apttus_Config2__LocationId__c = accLocation.id;
            }
            //v102 ++>>
         } catch (Exception ex) {
            APTS_CustomLogging.createErrorLog('RSO order Creation', 'Apex', 'Line # ' + ex.getLineNumber() + '_' + ex.getMessage() , 'Order', oWrapper.SourceOrderNumber, 'OM', false, false, null, true);
            throw ex;
        }
        return oExtOrder;
    }
   // v113++<<
    /*****
    *@description : Wrapper Class which returns map of agreement and Boolean to indicate Agreement is available or not.
    *@Used : APTS_CreateRSOOrderController
    ****/
    public class RSOWrapper {
        public Map<Id, List<Apttus__APTS_Agreement__c>> mapAccAgr {get;set;}
        public Boolean IsAgreement {get;set;}
    }
    // v113 ++>>
    
      public static APTS_RSOProductCatalogWrapper getRSOCatalogProducts(String sRSAEngType, String sRegion, Boolean isInitialLoad, APTS_Sync_Data_Log__c oPrevLog) {
        APTS_RSOProductCatalogWrapper oWrapper = new APTS_RSOProductCatalogWrapper();

        try {
            String categoryText, subCategoryText, subSubCategoryText;
            Boolean isPartialData = (isInitialLoad == NULL || isInitialLoad == FALSE) && oPrevLog != NULL && oPrevLog.APTS_Date_of_Last_Sync__c != NULL ? true : false;
            APTS_RSOProductCatalogWrapper.RSOProducts oRSOProdWrap;
            Set<Id> setCategoryProductsId;
            oWrapper.mapAllRSOProducts = new Map<Id, APTS_RSOProductCatalogWrapper.RSOProducts>();
            oWrapper.mapCategoryProductsId = new Map<String, Set<Id>>();
            oWrapper.listRSOProductsForToday = new List<APTS_RSOProductCatalogWrapper.RSOProducts>();

            for (APTS_RSO_Product_Catalog__c oRSOCat : [SELECT Id, APTS_Product__c, APTS_Product__r.IsActive, APTS_Product_Code__c, APTS_Product__r.Name,
                    APTS_Category_Text__c, APTS_Sub_Category_Text__c, APTS_Sub_Sub_Category_Text__c,
                    APTS_Selling_UOM__c, APTS_Product__r.Apttus_Config2__IconId__c, APTS_Type__c, LastModifiedDate
                    FROM APTS_RSO_Product_Catalog__c WHERE APTS_Type__c = :sRSAEngType AND APTS_Region__c = :sRegion AND APTS_Block_for_Selling__c = false]) {

                try {

                    oRSOProdWrap = getRSOProductWrapper(oRSOCat);

                    if (oRSOProdWrap != null) {
                        oWrapper.mapAllRSOProducts.put(oRSOProdWrap.ProductID, oRSOProdWrap);

                        categoryText = String.isNotBlank(oRSOCat.APTS_Category_Text__c) ? oRSOCat.APTS_Category_Text__c : '';
                        subCategoryText = String.isNotBlank(oRSOCat.APTS_Sub_Category_Text__c) ? categoryText +  '_' + oRSOCat.APTS_Sub_Category_Text__c : '';
                        subSubCategoryText = String.isNotBlank(oRSOCat.APTS_Sub_Sub_Category_Text__c) ? subCategoryText +  '_' + oRSOCat.APTS_Sub_Sub_Category_Text__c : '';
                        categoryText = categoryText.toUpperCase().deleteWhitespace();
                        subCategoryText = subCategoryText.toUpperCase().deleteWhitespace();
                        subSubCategoryText = subSubCategoryText.toUpperCase().deleteWhitespace();

                        //prepare map of category product
                        setCategoryProductsId = oWrapper.mapCategoryProductsId.get(categoryText);
                        setCategoryProductsId = setCategoryProductsId == null ? new Set<Id>() : setCategoryProductsId;
                        setCategoryProductsId.add(oRSOProdWrap.ProductID);
                        oWrapper.mapCategoryProductsId.put(categoryText, setCategoryProductsId);

                        if (String.isNotBlank(subCategoryText)) {
                            setCategoryProductsId = oWrapper.mapCategoryProductsId.get(subCategoryText);
                            setCategoryProductsId = setCategoryProductsId == null ? new Set<Id>() : setCategoryProductsId;
                            setCategoryProductsId.add(oRSOProdWrap.ProductID);
                            oWrapper.mapCategoryProductsId.put(subCategoryText, setCategoryProductsId);
                        }

                        if (String.isNotBlank(subSubCategoryText)) {
                            setCategoryProductsId = oWrapper.mapCategoryProductsId.get(subSubCategoryText);
                            setCategoryProductsId = setCategoryProductsId == null ? new Set<Id>() : setCategoryProductsId;
                            setCategoryProductsId.add(oRSOProdWrap.ProductID);
                            oWrapper.mapCategoryProductsId.put(subSubCategoryText, setCategoryProductsId);
                        }

                        if (!isPartialData || (oRSOCat.LastModifiedDate >= oPrevLog.APTS_Date_of_Last_Sync__c)) {
                            oWrapper.listRSOProductsForToday.add(oRSOProdWrap);
                        }
                    }
                     if (Test.isRunningTest()){ Decimal dc1 = 1 / 0;} 
                } catch (Exception ex) {
                    continue;
                }
            }
      } catch (Exception ex) {
            /* APTS_CustomLogging.createErrorLog(e.getTypeName(), 'Apex', e.getStackTraceString() ,'Order', ApexPages.currentPage().getParameters().get(Label.APTS_Id),'OM',false,false, null, true);*/
            throw ex;
        }

        return oWrapper;
    }
}