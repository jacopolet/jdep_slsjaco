/*************************************************************
@Name: APTS_RSOSyncDataWebService
@Author: Neev Shah
@CreateDate: 22-05-2018
@Description: Return Routes Info, Contracted Products
******************************************************************/
//V101 27-Feb-2020 Aarthi: RetrievedStartTime__c instead of Startdate field reference for RSO
//V102 29-Aug-2020 Aarthi Pitchai - DQ-2958 - Indicate and send blocked products to MobileApp
//V103 31-Aug-2020 Aarthi Pitchai - DQ-2465 - Refresh Products implementation

@RestResource(urlMapping = '/RSOOrder/SyncData/*')
global without sharing class APTS_RSOSyncDataWebService  {
    private static final String STATUS_DISPATCHED = 'Dispatched';
    private static final String PROD_TYPE_ROUTESALES = 'Routesales';
    private static final String TYPE_S25 = 'S25';
    private static final String SYNC_STATUS_INPROCESS = 'In Process';
    private static final String SYNC_STATUS_COMPLETE = 'Complete';
    private static final String SYNC_STATUS_ERROR = 'Error';
    private static final String STR_ROUTESALES = 'Routesales';
    private static final String STR_OPERATING = 'Operating';
    private static final String STR_EMP_EMAIL = 'EmpEmail';
    private static final String STR_INITIAL_LOAD = 'InitialLoad';
    private static final String STR_REFRESH_LOAD = 'RefreshLoad'; //V103 ++ <<>>
    private static final String STR_IS_TEST = 'IsTest';
    private static final String ACTIVATED = 'Activated';
    private static final String SYNCDATALOG = 'APTS_Sync_Data_Log__c';
    private static final String STANDARD_DEAL = 'Standard Deal';
    private static final String ORDERTYPE_ROUTESALES = 'Route Sales Order';
    private static final String ORDERTYPE_OPERATING = 'Operating Order';
    private static Boolean isNextDayRoute = false;

    public class SyncData {
        public APTS_RSOProductCatalogWrapper.UserInfo UserInfo {get; set;}
        public List<APTS_RSOProductCatalogWrapper.RoutesInfo> RoutesInfo {get; set;}
        public List<APTS_RSOProductCatalogWrapper.RSOProducts> Products {get; set;}
        public List<APTS_RSOProductCatalogWrapper.ContractedProducts> ContractedProducts {get; set;}
        public List<APTS_RSOProductCatalogWrapper.BlockedProducts> BlockedProducts {get; set;} //V102 ++ <<>>
    }

    @HttpPost
    global static void getRouteInfo() {
        String sEmpEmail;
        Boolean isTestAPICall = false;
        SyncData oSynData = new SyncData();
        APTS_Sync_Data_Log__c newSynclog = new APTS_Sync_Data_Log__c();

        try {
            //get data from HTTP Request Body
            Map<String, Object> mapJson = APTS_RSOOrderUtils.getRequestBodyJSON(RestContext.request);
            Map<Id, APTS_RSOProductCatalogWrapper.RoutesInfo> mapLocationRoute = new Map<Id, APTS_RSOProductCatalogWrapper.RoutesInfo>();
            Map<Id, Id> mapLocationAccount = new Map<Id, Id>();

            if (mapJson != NULL && mapJson.containsKey(STR_EMP_EMAIL) && String.isNotBlank((String) mapJson.get(STR_EMP_EMAIL))) {
                Boolean isInitialLoad  = (Boolean) mapJson.get(STR_INITIAL_LOAD);
                Boolean isRefreshLoad  = (Boolean) mapJson.get(STR_REFRESH_LOAD); //V103 ++ <<>>
                isRefreshLoad = (isRefreshLoad == NULL)? false : isRefreshLoad; //V103 ++ <<>>
                isInitialLoad = (isInitialLoad == NULL)? false : isInitialLoad; //V103 ++ <<>>
                sEmpEmail = (String) mapJson.get(STR_EMP_EMAIL);
                String sRegion = '';
                String userType = STR_OPERATING;
                Set<Id> soldToAccountId = new Set<Id>();
                List<WorkOrderLineItem> lstWOLI = new List<WorkOrderLineItem>();

                //Initialization
                isTestAPICall  = mapJson.containsKey(STR_IS_TEST) ? (Boolean) mapJson.get(STR_IS_TEST) : false;

                oSynData.UserInfo = new APTS_RSOProductCatalogWrapper.UserInfo();
                oSynData.RoutesInfo = new List<APTS_RSOProductCatalogWrapper.RoutesInfo>();
                oSynData.Products = new List<APTS_RSOProductCatalogWrapper.RSOProducts>();
                oSynData.ContractedProducts = new List<APTS_RSOProductCatalogWrapper.ContractedProducts>();
                oSynData.BlockedProducts = new List<APTS_RSOProductCatalogWrapper.BlockedProducts>(); //V102 ++ <<>>
                
                //create or update sync record first
                newSynclog = createSyncDataLog(sEmpEmail);
                //V103++ <<
                if(!isNextDayRoute && newSynclog != null && newSynclog.id != null && !isRefreshLoad && !isInitialLoad)
                {                    
                    newSynclog = newSynclog == NULL ? createSyncDataLog('') : newSynclog;
                    newSynclog.APTS_Status__c = SYNC_STATUS_ERROR;
                    APTS_RSOOrderUtils.setHTTPResponseData(501, 'NO_ROUTE', 'User had already synced the routes for the day');              
                }
                else
                { //V103++ >>
                
                //V101 ++<<
                //19 Jun 2018 - Aarthi - Added below line to set the start date filter in WOLI Query
                lstWOLI = APTS_RSOOrderUtils.getWorkOrderLineItem(sEmpEmail, isNextDayRoute, STATUS_DISPATCHED);
                //V101 ++>>
                if (lstWOLI.size() > 0) {
                    for (WorkOrderLineItem oWorkOLI : lstWOLI) {

                        //location can't be empty, please check data
                        if (oWorkOLI.AccountLocation__c == null) {
                            continue;
                        }

                        userType = TYPE_S25.equalsIgnoreCase(oWorkOLI.WorkOrderType__c) ? STR_ROUTESALES : STR_OPERATING;

                        //set route data
                        APTS_RSOProductCatalogWrapper.RoutesInfo oRouteInfo = getRouteInfoData(oWorkOLI);
                        if (oWorkOLI.AccountLocation__r.Apttus_Config2__AccountId__c != null) {
                            sRegion = oWorkOLI.AccountLocation__r.Apttus_Config2__AccountId__r.Sales_Organization__c;
                            soldToAccountId.add(oRouteInfo.AccountID);
                        }

                        //set user data
                        oSynData.UserInfo.ExecutingEngineer = oWorkOLI.SAPResourceNumber__c;
                        oSynData.UserInfo.WorkOrderType = oWorkOLI.WorkOrderType__c;
                        oSynData.UserInfo.AvailableUOM = System.Label.APTS_RouteSalesUOM;

                        mapLocationRoute.put(oWorkOLI.AccountLocation__c, oRouteInfo);
                        mapLocationAccount.put(oWorkOLI.AccountLocation__c, oRouteInfo.AccountID);

                        //TS doesn't check whether route has an Active agreement or not. So when we get route we need to show routes only if it has required active agreement
                        //oSynData.RoutesInfo.add(oRouteInfo);
                    }
                }


                if (mapLocationRoute != NULL && !mapLocationRoute.isEmpty()) {

                    //11-March-2019 -- get contributing Agreements (Account Hierarchy rules)
                    String orderType = PROD_TYPE_ROUTESALES.equalsIgnoreCase(userType) ? ORDERTYPE_ROUTESALES : ORDERTYPE_OPERATING;
                    Map<Id, Apttus__APTS_Agreement__c> mapContributingAgreements = APTS_RSOOrderUtils.getRSOAgreement(orderType, soldToAccountId);
                    
                    //11-Mar-2019 -- get product wrappers and list of product Id per category
                    APTS_RSOProductCatalogWrapper prodWrapper = APTS_RSOOrderUtils.getRSOCatalogProducts(userType, sRegion, isInitialLoad, newSynclog, isRefreshLoad); //V103 ++ <<>>

                    if (prodWrapper != NULL) {
                        //All Products wrapper or products modified after last
                        oSynData.Products = prodWrapper.listRSOProductsForToday;
                        oSynData.BlockedProducts = prodWrapper.listBlockedProducts; //V102 ++ <<>>

                        if (prodWrapper.mapAllRSOProducts != NULL && !prodWrapper.mapAllRSOProducts.isEmpty()) {
                            Id accId;
                            Boolean isOrderOutsideContract = true;
                            Boolean isValidRoute = false;
                            Apttus__APTS_Agreement__c oAgrTmp;
                            APTS_Agreement_PO_Details__c oPODetails;
                            APTS_RSOProductCatalogWrapper.RoutesInfo oRoute;
                            List<APTS_RSOProductCatalogWrapper.ContractedProducts> listcontractedProd;

                            //get contracted products
                            Map<Id, List<APTS_RSOProductCatalogWrapper.ContractedProducts>> mapContratedProds = APTS_RSOOrderUtils.getContractedProducts(orderType, soldToAccountId, mapContributingAgreements, prodWrapper.mapAllRSOProducts, prodWrapper.mapCategoryProductsId);


                            //get map of PODetails
                            Map<Id, APTS_Agreement_PO_Details__c> mapPODetails = new Map<Id, APTS_Agreement_PO_Details__c>();
                            for (APTS_Agreement_PO_Details__c oDetails :  [SELECT id, APTS_PO_Number__c, APTS_PO_Number_Required__c,
                                    APTS_PO_Number_Type__c, APTS_Agreement__c, APTS_Agreement__r.RecordType.Name,
                                    APTS_Agreement__r.APTS_Sold_To__c, APTS_Agreement__r.APTS_Order_Non_Contracted_Products__c, APTS_PO_Category__c
                                    FROM APTS_Agreement_PO_Details__c
                                    WHERE APTS_Agreement__r.APTS_Sold_To__c = :soldToAccountId AND APTS_Agreement__r.Apttus__Status__c = :ACTIVATED]) {
                                mapPODetails.put(oDetails.APTS_Agreement__c, oDetails);
                            }

                            for (Id locationId : mapLocationRoute.keySet()) {
                                //get Account Id
                                accId = mapLocationAccount.get(locationId);
                                //get Contract Info
                                oAgrTmp = mapContributingAgreements.get(accId);

                                //get PO Details
                                oPODetails = oAgrTmp != null ? mapPODetails.get(oAgrTmp.Id) : null;

                                //if agreement is not null than its valid route, route will be visible in app
                                //if agreement is null than route will not be visible in app
                                isValidRoute = oAgrTmp != null ? true : false;

                                //allow order outside of contract by default
                                isOrderOutsideContract = true;

                                //add contracted products of an account
                                listcontractedProd = mapContratedProds != null ? mapContratedProds.get(accId) : null;
                                if (listcontractedProd != NULL && !listcontractedProd.isEmpty()) {
                                    oSynData.ContractedProducts.addAll(listcontractedProd);

                                    //if contracted products are available check if customer is allowed to order outside of contract
                                    isOrderOutsideContract = oAgrTmp != null ? oAgrTmp.APTS_Order_Non_Contracted_Products__c : true;
                                }

                                oRoute = mapLocationRoute.get(locationId);
                                oRoute.OrderNonContractedProducts = isOrderOutsideContract;

                                if (oPODetails != NULL) {
                                    oRoute.PONumberRequired = String.isNotBlank(oPODetails.APTS_PO_Number_Required__c) && 'Ingredients'.equalsIgnoreCase(oPODetails.APTS_PO_Category__c) ? oPODetails.APTS_PO_Number_Required__c : NULL;
                                    oRoute.PONumber = 'Yes'.equalsIgnoreCase(oRoute.PONumberRequired) && 'Fixed'.equalsIgnoreCase(oPODetails.APTS_PO_Number_Type__c) ? oPODetails.APTS_PO_Number__c : NULL;
                                }

                                if (isValidRoute) {
                                    oSynData.RoutesInfo.add(oRoute);
                                }
                            }

                            //oSynData.RoutesInfo.add(mapLocationRoute.values());
                        }
                    }

                    //set sync data to completed
                    newSynclog.APTS_Status__c = SYNC_STATUS_COMPLETE;
                    newSynclog.APTS_Date_of_Last_Sync__c = System.now();

                    RestResponse res = RestContext.response;
                    res.responseBody = Blob.valueOf(JSON.serializePretty(oSynData));
                    res.statusCode = 200;
                } else {
                    newSynclog.APTS_Status__c = SYNC_STATUS_ERROR;
                    APTS_RSOOrderUtils.setHTTPResponseData(501, 'NO_ROUTE', 'No Route found for the requested RSO User');
                }
             }  
                
            } else {
                newSynclog = newSynclog == NULL ? createSyncDataLog('') : newSynclog;
                newSynclog.APTS_Status__c = SYNC_STATUS_ERROR;
                APTS_RSOOrderUtils.setHTTPResponseData(501, 'NO_EMAIL', 'No Email found for RSO');
            }
        } catch (Exception e) {
            newSynclog = newSynclog == NULL ? createSyncDataLog('') : newSynclog;
            newSynclog.APTS_Status__c = SYNC_STATUS_ERROR;
            APTS_RSOOrderUtils.setHTTPResponseData(400, 'APEX_ERROR', e.getMessage());
            APTS_CustomLogging.createErrorLog('RSO Sync Webservice for ' + sEmpEmail, 'Apex', e.getMessage() , 'Order', '', 'OM', false, false, null, true);
        } finally {
            DescribeSObjectResult objResultSyncDataLog = APTS_OTCUtil.getsObjectAccess(SYNCDATALOG); // CRUD/FLS Check
            if (objResultSyncDataLog.isUpdateable() && newSynclog != NULL && !isTestAPICall) {
                Database.upsert(newSynclog);
            }

        }
    }

    //prepare basic route info object from WORKORDERLINEITEM
    private static APTS_RSOProductCatalogWrapper.RoutesInfo getRouteInfoData(WorkOrderLineItem oWorkOLI) {
        APTS_RSOProductCatalogWrapper.RoutesInfo oRouteInfo = new APTS_RSOProductCatalogWrapper.RoutesInfo();
        oRouteInfo.ContactFirstName = oWorkOLI.ContactFirstName__c;
        oRouteInfo.ContactLastName = oWorkOLI.ContactLastName__c;
        oRouteInfo.ContactPhone = oWorkOLI.ContactPhone__c;
        oRouteInfo.ContactEmail = oWorkOLI.ContactEmail__c;
        oRouteInfo.LocationName = oWorkOLI.LocationName__c;
        oRouteInfo.SalesforceAccountLocationID = oWorkOLI.AccountLocation__c;
        oRouteInfo.Street = oWorkOLI.AccountLocationStreet__c;
        oRouteInfo.HouseNumber = oWorkOLI.AccountLocationHouseNumber__c;
        oRouteInfo.State = oWorkOLI.AccountLocationState__c;
        oRouteInfo.City = oWorkOLI.AccountLocationCity__c;
        oRouteInfo.Country = oWorkOLI.AccountLocationCountry__c ;
        oRouteInfo.PostalCode = oWorkOLI.AccountLocationPostalCode__c;
        oRouteInfo.ActualStartDate = oWorkOLI.StartDate__c;
        oRouteInfo.PONumberRequired = 'No';
        oRouteInfo.OrderNonContractedProducts = true;
        //Set Account Location related data - ADDED sap customer ID
        if (oWorkOLI.AccountLocation__r.Apttus_Config2__AccountId__c != null) {
            oRouteInfo.AccountName = oWorkOLI.AccountLocation__r.Apttus_Config2__AccountId__r.Name;
            oRouteInfo.AccountID = oWorkOLI.AccountLocation__r.Apttus_Config2__AccountId__c;
            oRouteInfo.SAPCustomerID = oWorkOLI.AccountLocation__r.Apttus_Config2__AccountId__r.SAP_Customer_ID__c;
            oRouteInfo.ContactID = oWorkOLI.AccountLocation__r.Route_Sales_Main_Contact__c;
        }
        //For mobileApp, caseID is mandatory, so sending temp value. While Order creation we need to remove such case values
        oRouteInfo.CaseID = oWorkOLI.CaseID__c == NULL ? 'temp_' + oWorkOLI.Id : oWorkOLI.CaseID__c;
        return oRouteInfo;
    }

    //create Sync request logs
    private static APTS_Sync_Data_Log__c createSyncDataLog(String sEmpId) {
        APTS_Sync_Data_Log__c oDataLog = null;

        try {
            //get previous sync record
            List<APTS_Sync_Data_Log__c> listLogs = [SELECT ID, APTS_Requested_Date__c, APTS_Date_of_Last_Sync__c FROM APTS_Sync_Data_Log__c WHERE APTS_RSA_Engineer_ID__c = : sEmpId ORDER BY LastModifiedDate  DESC ];
            
            if (listLogs != null && !listLogs.isEmpty()) {
                //set previous sync record
                oDataLog = listLogs[0];
                //oDataLog.APTS_Date_of_Last_Sync__c = oDataLog.APTS_Requested_Date__c;
                oDataLog.APTS_Requested_Date__c = System.now();
                oDataLog.APTS_Status__c = SYNC_STATUS_INPROCESS;
            } else {
                // if no previous records found then create new record
                oDataLog = new APTS_Sync_Data_Log__c();
                oDataLog.APTS_Requested_Date__c = System.now();
                oDataLog.APTS_RSA_Engineer_ID__c = sEmpId;
                oDataLog.APTS_Status__c = SYNC_STATUS_INPROCESS;
                oDataLog.APTS_Date_of_Last_Sync__c = System.now();
            }

            //19 Jun 2018 - Aarthi - Added below to check the date of last sync
            Integer hr = Integer.valueOf(System.Label.APTS_RouteDispatchedTime);
            DateTime currentDT = System.now();
            //if(CurrentDate && previous sync Time < 6 PM && current Request Time > 6 PM)
            //oDataLog.APTS_Date_of_Last_Sync__c.date() == currentDT.date() && oDataLog.APTS_Date_of_Last_Sync__c.time() < Time.newInstance(hr, 0, 0, 0)
            if (hr >= 0 && oDataLog.APTS_Date_of_Last_Sync__c != NULL && oDataLog.APTS_Date_of_Last_Sync__c.date() <= currentDT.date() && currentDT.time() > Time.newInstance(hr, 0, 0, 0)) {
                isNextDayRoute = true;
            }
            
        } catch (Exception ex) {
            throw ex;
        }

        return oDataLog;
    }

}