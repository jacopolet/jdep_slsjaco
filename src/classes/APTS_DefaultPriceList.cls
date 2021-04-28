/**********************************************************************************
 * @Author: Jason Mactal
 * @Company: Accenture
 * @Description: Handles the defaulting of Price List on Agreement
 * @Created Date: Feb 14, 2018
 * @History:
 *      <Name>              <Date>          <Description>
 *      jason.e.mactal      2.14.2018       Created
 *      jason.e.mactal      2.23.2018       Used Custom Metadata for Price List Types
 *      jason.e.mactal      2.27.2018       Used Custom Metadata for Sales Org Settings(Allow Routesales/Indirect Price List)
 *      jason.e.mactal      6.21.2018       Added Condition to not update Pricelist if it already has a value - ALM: 15821
 *      aarthi.pitchai      8.20.2018       Commented out Condition to not use RouteSales Pricelist in getDefaultPriceListId - ALM: 17815
 *      jason.e.mactal      9.13.2018       Changed the condition for fetching CSP PriceList
 *      v.shankaranarayanan 9.20.2018       Commented the old logic to populate the default Price List. Added the new logic in setDefaultPriceList method
 *      jason.e.mactal      10.26.2018      Added new method getRoutesalesPriceList - ALM: 20722
 **********************************************************************************/
//v101 27.03.2018 Galin Georgiev: create method which gets default price list for account

public with sharing class APTS_DefaultPriceList {

    private Map<String, String> priceListTypeMap = new Map<String, String>();
    private Map<String, APTS_SalesOrg_Settings__mdt> salesOrgSettingsMap = new Map<String, APTS_SalesOrg_Settings__mdt>();

    //constructor
    public APTS_DefaultPriceList() {
        priceListTypeMap = getPriceListTypes();
        salesOrgSettingsMap = getSalesOrgSettings();
    }

    /*@methodName - setDefaultPriceList
    * @description - method used to set default price list
    * @param - List<Apttus__APTS_Agreement__c>
    * @return - List<Apttus__APTS_Agreement__c>
    */
    public void setDefaultPriceList (List<Apttus__APTS_Agreement__c> newItems, Set<Id> accountIdSet) {
        
        //new logic for populating Price List in Agreement
        Set<Id> allAccountIdSet = new Set<Id>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
        Map<String, Id> priceListMap = new Map<String, Id>();
        Map<String, map<String, Apttus_Config2__PriceList__c>> priceListByCountryMap = getPriceLists();
        
        
        for(Account oAccount : [SELECT Id,
                                        Name,
                                        APTS_Price_List__c,
                                        ParentId,
                                        Partner__c,
                                        Parent.ParentId,
                                        Purchasing_Organization__c,
                                        Sales_Organization__c
                                        FROM Account
                                        WHERE Id IN: accountIdSet
                                        ]){
            accountMap.put(oAccount.Id, oAccount);
            allAccountIdSet.add(oAccount.Id);
            if(String.IsNotBlank(oAccount.ParentId)) allAccountIdSet.add(oAccount.ParentId);
            if(String.IsNotBlank(oAccount.ParentId) && String.IsNotBlank(oAccount.Parent.ParentId)) allAccountIdSet.add(oAccount.Parent.ParentId);
            if(String.IsNotBlank(oAccount.Purchasing_Organization__c)) allAccountIdSet.add(oAccount.Purchasing_Organization__c);
        }
        
        /*** PI fix # 111905 **** added the Apttus_Config2__Active__c condition in SOQL Query ***/
        for(Apttus_Config2__PriceList__c oPriceList : [SELECT Id,
                                                                APTS_SalesOrg__c
                                                                FROM Apttus_Config2__PriceList__c
                                                                WHERE APTS_SalesOrg__c != null
                                                                AND Apttus_Config2__Active__c = TRUE
                                                                ]){
            priceListMap.put(oPriceList.APTS_SalesOrg__c, oPriceList.Id);
        }
        
        for(Apttus__APTS_Agreement__c oAgg : [SELECT Id,
                                                        Apttus__Account__c,
                                                        Apttus_CMConfig__PriceListId__c
                                                        FROM Apttus__APTS_Agreement__c
                                                        WHERE Apttus__Status_Category__c = 'In Effect'
                                                        AND Apttus__Status__c = 'Activated' 
                                                        AND Apttus__Account__c IN: allAccountIdSet
                                                        ]){
            agreementMap.put(oAgg.Apttus__Account__c, oAgg);
        }
        
        Map<String, map<String, Apttus_Config2__PriceList__c>> priceListQueryMap = getPriceLists();
        
        for(Apttus__APTS_Agreement__c oAgg : newItems){
            Account oAccount = accountMap.get(oAgg.Apttus__Account__c);
            oAgg.APTS_Region__c = oAccount.Sales_Organization__c;
            
            if(oAgg.APTS_Routesales__c){
                oAgg.Apttus_CMConfig__PriceListId__c = getRoutesalesPriceList(oAccount, priceListQueryMap);
            }
            
            if (oAccount != NULL && oAccount.Sales_Organization__c != NULL && oAgg.Apttus_CMConfig__PriceListId__c == NULL || !oAgg.APTS_Routesales__c) {

                Map<String, Apttus_Config2__PriceList__c> priceListByTypeMap = priceListByCountryMap.get(oAccount.Sales_Organization__c);
                if (priceListByTypeMap != NULL && !priceListByTypeMap.isEmpty()) {

                    //Set Price List to CSP Price List
                    //Check if Account has CSP Price List
                    /**if ( oAccount.APTS_Price_List__c != NULL) {
                        oAgg.Apttus_CMConfig__PriceListId__c = oAccount.APTS_Price_List__c;
                    }**/
                    if(String.IsNotBlank(oAccount.ParentId)){
                        if(agreementMap.containsKey(oAccount.ParentId) && agreementMap.get(oAccount.ParentId) != null){
                            oAgg.Apttus_CMConfig__PriceListId__c = agreementMap.get(oAccount.ParentId).Apttus_CMConfig__PriceListId__c;
                            oAgg.Apttus__Parent_Agreement__c = agreementMap.get(oAccount.ParentId).Id;
                        }else if(String.IsNotBlank(oAccount.Parent.ParentId) && agreementMap.containsKey(oAccount.Parent.ParentId) && agreementMap.get(oAccount.Parent.ParentId) != null){
                            oAgg.Apttus_CMConfig__PriceListId__c = agreementMap.get(oAccount.Parent.ParentId).Apttus_CMConfig__PriceListId__c;
                            oAgg.Apttus__Parent_Agreement__c = agreementMap.get(oAccount.Parent.ParentId).Id;
                        }else if(agreementMap.containsKey(oAccount.Id) && agreementMap.get(oAccount.Id) != null){
                            oAgg.Apttus_CMConfig__PriceListId__c = agreementMap.get(oAccount.Id).Apttus_CMConfig__PriceListId__c;
                            oAgg.Apttus__Parent_Agreement__c = agreementMap.get(oAccount.Id).Id;
                        }else if(String.IsNotBlank(oAccount.APTS_Price_List__c)){
                            oAgg.Apttus_CMConfig__PriceListId__c = oAccount.APTS_Price_List__c;
                        }
                    }else if(String.IsNotBlank(oAccount.Purchasing_Organization__c) && agreementMap.containsKey(oAccount.Purchasing_Organization__c) && agreementMap.get(oAccount.Purchasing_Organization__c) != null){
                        oAgg.Apttus_CMConfig__PriceListId__c = agreementMap.get(oAccount.Purchasing_Organization__c).Apttus_CMConfig__PriceListId__c;
                        oAgg.Apttus__Parent_Agreement__c = agreementMap.get(oAccount.Purchasing_Organization__c).Id;
                    }else if(String.IsNotBlank(oAccount.APTS_Price_List__c)){
                        oAgg.Apttus_CMConfig__PriceListId__c = oAccount.APTS_Price_List__c;
                        if(agreementMap.containsKey(oAccount.Id)){
                            oAgg.Apttus__Parent_Agreement__c = agreementMap.get(oAccount.Id).Id;
                        }
                    }else if(oAgg.Apttus_CMConfig__PriceListId__c == NULL && priceListMap.containsKey(oAgg.APTS_Region__c)){
                        oAgg.Apttus_CMConfig__PriceListId__c = priceListMap.get(oAgg.APTS_Region__c);
                    }
                    
                    
                    //Set Price List to RouteSales Price List
                    //Check APTS_SalesOrg_Settings__mdt to determine which Sales Org Allows Routesales
                    else if (oAgg.APTS_Routesales__c && priceListByTypeMap.containsKey(priceListTypeMap.get('Routesales'))
                             && salesOrgSettingsMap.get(oAccount.Sales_Organization__c).APTS_Allow_Routesales__c) {
                        oAgg.Apttus_CMConfig__PriceListId__c = priceListByTypeMap.get(priceListTypeMap.get('Routesales')).Id;
                    }
                    //Set Price List to Indirect Price List
                    //Check APTS_SalesOrg_Settings__mdt to determine which Sales Org Allows use of Indirect Price List

                    else if (priceListByTypeMap.containsKey(priceListTypeMap.get('Indirect')) && oAccount.Partner__c
                             && salesOrgSettingsMap.get(oAccount.Sales_Organization__c).APTS_Allow_Indirect_Price_List__c) {
                        oAgg.Apttus_CMConfig__PriceListId__c = priceListByTypeMap.get(priceListTypeMap.get('Indirect')).Id;
                    }
                    //Set Price List to Direct Price List
                    else if (priceListByTypeMap.containsKey(priceListTypeMap.get('Direct'))) {
                        oAgg.Apttus_CMConfig__PriceListId__c = priceListByTypeMap.get(priceListTypeMap.get('Direct')).Id;
                    } else {}
                }
            }
        }
    }
    
    //v101++<<
    //@Description : get default price list id for account
    public Id getDefaultPriceListId(Account oAccount) {
        
        try{
            Id priceListId = null;
            Map<Id, List<Apttus_Config2__PriceList__c>> cspPriceListMap = new Map<Id, List<Apttus_Config2__PriceList__c>>();
            Map<String, Map<String, Apttus_Config2__PriceList__c>> priceListByCountryMap = getPriceLists();

            if (oAccount != null && oAccount.Sales_Organization__c != null) {


                //cspPriceListMap = getCSPPriceLists(new Set<Id> {oAccount.Id});

                Map<String, Apttus_Config2__PriceList__c> priceListByTypeMap = priceListByCountryMap.get(oAccount.Sales_Organization__c);
                if (priceListByTypeMap != NULL && !priceListByTypeMap.isEmpty()) {

                    //Set Price List to CSP Price List
                    //Check if Account has CSP Price List
                    if ( oAccount.APTS_Price_List__c != NULL) {
                        priceListId = oAccount.APTS_Price_List__c;
                    }
                    //Set Price List to RouteSales Price List
                    //Check APTS_SalesOrg_Settings__mdt to determine which Sales Org Allows Routesales
                 /*   else if (priceListByTypeMap.containsKey(priceListTypeMap.get('Routesales'))
                             && salesOrgSettingsMap.get(oAccount.Sales_Organization__c).APTS_Allow_Routesales__c) {
                        priceListId = priceListByTypeMap.get(priceListTypeMap.get('Routesales')).Id;
                    } */
                    //Set Price List to Indirect Price List
                    //Check APTS_SalesOrg_Settings__mdt to determine which Sales Org Allows use of Indirect Price List
                    else if (priceListByTypeMap.containsKey(priceListTypeMap.get('Indirect')) && oAccount.Partner__c
                             && salesOrgSettingsMap.get(oAccount.Sales_Organization__c).APTS_Allow_Indirect_Price_List__c) {
                        priceListId = priceListByTypeMap.get(priceListTypeMap.get('Indirect')).Id;
                    }
                    //Set Price List to Direct Price List
                    else if (priceListByTypeMap.containsKey(priceListTypeMap.get('Direct'))) {
                        priceListId = priceListByTypeMap.get(priceListTypeMap.get('Direct')).Id;
                    }
                }
            }

            return priceListId;
        }catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'Agreement', null,'CPQ',false,true,'cpqerror@accenture.com',true); return null;}
    }
    //v101++>>

    /*@methodName - getPriceLists
    * @description - method used to get all active pricelist,except CSP pricelist, and group based on Country and Price List Type
    * @param -
    * @return - Map<String, map<String,Apttus_Config2__PriceList__c>>
    */
    public Map<String, map<String, Apttus_Config2__PriceList__c>> getPriceLists () {
        try{
            
            Map<String, map<String, Apttus_Config2__PriceList__c>> priceListByCountryMap = new Map<String, map<String, Apttus_Config2__PriceList__c>>();
            for (Apttus_Config2__PriceList__c oPL : [SELECT Id, APTS_PriceList_Type__c, APTS_Region__c
                    FROM Apttus_Config2__PriceList__c
                    WHERE Apttus_Config2__Active__c = TRUE AND APTS_PriceList_Type__c != :priceListTypeMap.get('CSP') ]) {
                if (oPL.APTS_Region__c != NULL && oPL.APTS_PriceList_Type__c != NULL) {
                    
                    if (priceListByCountryMap.containsKey(oPL.APTS_Region__c)) {
                        priceListByCountryMap.get(oPL.APTS_Region__c).put(oPL.APTS_PriceList_Type__c, oPL);
                    } else {
                        priceListByCountryMap.put(oPL.APTS_Region__c, new Map<String, Apttus_Config2__PriceList__c> {oPL.APTS_PriceList_Type__c => oPL});
                    }
                }
            }
            return priceListByCountryMap;
        }catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'Agreement', null,'CPQ',false,true,'cpqerror@accenture.com',true); return null;}
    }
    
    /*@methodName - getCSPPriceLists
    * @description - method used to get all active CSP Price List for the specified Account/s
    * @param - Set<Id> accountIDs
    * @return - Map<Id,List<Apttus_Config2__PriceList__c>>
    */
    /*public Map<Id, List<Apttus_Config2__PriceList__c>> getCSPPriceLists (Set<Id> accountIDs) {
        try{
            Map<Id, List<Apttus_Config2__PriceList__c>> cspPriceListMap = new Map<Id, List<Apttus_Config2__PriceList__c>>();
            for (Apttus_Config2__PriceList__c oPL : [SELECT Id, Apttus_Config2__AccountId__c
                    FROM Apttus_Config2__PriceList__c
                    WHERE Apttus_Config2__Active__c = TRUE AND APTS_PriceList_Type__c = :priceListTypeMap.get('CSP') AND Apttus_Config2__AccountId__c IN :accountIDs
                            ORDER BY LastModifiedDate DESC]) {
                if (cspPriceListMap.containsKey(oPL.Apttus_Config2__AccountId__c)) {
                    cspPriceListMap.get(oPL.Apttus_Config2__AccountId__c).add(oPL);
                } else {
                    cspPriceListMap.put(oPL.Apttus_Config2__AccountId__c, new List<Apttus_Config2__PriceList__c> {oPL});
                }
            }
            return cspPriceListMap;
        }catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'Agreement', null,'CPQ',false,true,'cpqerror@accenture.com',true); return null;}
    }*/
    
    /*@methodName - getPriceListTypes
    * @description - method to get Price List Type Records on Custom Metadata
    * @param -
    * @return - Map<String, String>
    */
    public Map<String, String> getPriceListTypes() {
        try{
            
            Map<String, String> priceListTypeMap = new Map<String, String>();
            for (APTS_Price_List_Settings__mdt priceListType : [SELECT MasterLabel, APTS_Price_List_Type__c
                    FROM APTS_Price_List_Settings__mdt ]) {
                priceListTypeMap.put(priceListType.MasterLabel, priceListType.APTS_Price_List_Type__c);
            }
            return priceListTypeMap;
        }catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'Agreement', null,'CPQ',false,true,'cpqerror@accenture.com',true); return null;}
    }
    
    /*@methodName - getSalesOrgSettings
    * @description - method to get Sales Org Settings Custom Metadata
    * @param -
    * @return - Map<String, APTS_SalesOrg_Settings__mdt>
    */
    public Map<String, APTS_SalesOrg_Settings__mdt> getSalesOrgSettings() {
        try{
            Map<String, APTS_SalesOrg_Settings__mdt> salesOrgSettingsMap = new Map<String, APTS_SalesOrg_Settings__mdt>();
            
            for (APTS_SalesOrg_Settings__mdt salesOrgSettings : [SELECT MasterLabel, APTS_SAP_ID__c, APTS_Allow_Routesales__c, APTS_Allow_Indirect_Price_List__c
                    FROM APTS_SalesOrg_Settings__mdt ]) {
                salesOrgSettingsMap.put(salesOrgSettings.APTS_SAP_ID__c, salesOrgSettings);
            }
            return salesOrgSettingsMap;
        }catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'Agreement', null,'CPQ',false,true,'cpqerror@accenture.com',true); return null;}
    }
    
    /*@methodName - getRoutesalesPriceList
    * @description - method to get routesales pricelist
    * @param - Account oAccount, Map<String, map<String, Apttus_Config2__PriceList__c>> priceListByCountryMap
    * @return - Id
    */
    public Id getRoutesalesPriceList(Account oAccount, Map<String, map<String, Apttus_Config2__PriceList__c>> priceListByCountryMap) {
        Id priceListId;
        try{
            if(priceListByCountryMap != null && priceListByCountryMap.containsKey(oAccount.Sales_Organization__c)){
                Map<String, Apttus_Config2__PriceList__c> priceListByTypeMap = priceListByCountryMap.get(oAccount.Sales_Organization__c);
                if (priceListByTypeMap.containsKey(priceListTypeMap.get('Routesales'))
                    && salesOrgSettingsMap.get(oAccount.Sales_Organization__c).APTS_Allow_Routesales__c) {
                    priceListId = priceListByTypeMap.get(priceListTypeMap.get('Routesales')).Id;
                }
            }
        }catch (Exception ex) {APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString() ,'Agreement', null,'CPQ',false,true,'cpqerror@accenture.com',true); return null;}
        return priceListId;
    }
    
}