/**
 * @Name: APTS_InitiateAgreementController
 * @Author: Renuka G
 * @CreateDate: 12-04-2021
 */
public with sharing class APTS_InitiateAgreementController {
    
    
    public class AgreementWrapper{
        @AuraEnabled public string oppId {get;set;}
        @AuraEnabled public String accId {get;set;}
        @AuraEnabled public String conId {get;set;}
        @AuraEnabled public String dealType {get;set;}
        @AuraEnabled public String subType {get;set;}
        @AuraEnabled public Decimal contractPeriod {get;set;}
        @AuraEnabled public Date startDate {get;set;}
        @AuraEnabled public Date endDate {get;set;}
        @AuraEnabled public Boolean autoRenew {get;set;}
        @AuraEnabled public Boolean routeSales {get;set;}
        @AuraEnabled public String priceListId {get;set;}
        @AuraEnabled public String delivery {get;set;}
        @AuraEnabled public String ordering {get;set;}
        @AuraEnabled public Id routeSalesPriceListId {get;set;}
        @AuraEnabled public Id parentPriceListId {get;set;}
        @AuraEnabled public Map<Id,Id> generalCSPPriceListIdMap {get;set;}
        public AgreementWrapper(){

        }
        public AgreementWrapper(string oppId, string accId, String conId, String dealType, String subType, 
                                Decimal contractPeriod, Date startDate, Date endDate, Boolean autoRenew, 
                                Boolean routeSales, string priceListId, string delivery, string ordering, 
                                Id routeSalesPriceListId,Id parentPriceListId,Map<id,id> generalCSPPriceListIdMap){
            
            this.oppId = oppId;                    
            this.accId = accId;                    
            this.conId = conId;                    
            this.dealType = dealType;                    
            this.subType = subType;                    
            this.contractPeriod = contractPeriod;                    
            this.startDate = startDate;                    
            this.endDate = endDate;                    
            this.autoRenew = autoRenew;                    
            this.routeSales = routeSales;                    
            this.priceListId = priceListId;  
            this.delivery = delivery;
            this.ordering = ordering; 
            this.routeSalesPriceListId = routeSalesPriceListId;   
            this.parentPriceListId=parentPriceListId; 
            this.generalCSPPriceListIdMap=generalCSPPriceListIdMap;          
        }
    }
    public class Categories{
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public boolean expanded {get;set;}
        //@AuraEnabled public Integer sequence {get;set;}
        //@AuraEnabled public String isLeaf {get;set;}
        @AuraEnabled public List<item> items{get;set;}
        @AuraEnabled public List<ProductClassInfo> products {get;set;}
    }
    public class item{
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String name {get;set;}
        //@AuraEnabled public String isLeaf {get;set;}
        //@AuraEnabled public Integer sequence {get;set;}
        @AuraEnabled public boolean expanded {get;set;}
        @AuraEnabled public List<item> items{get;set;}
        @AuraEnabled public List<ProductClassInfo> products {get;set;}
    }
    public class ProductClassInfo{
        @AuraEnabled public String productImage {get;set;}
        @AuraEnabled public String productid {get;set;}
        @AuraEnabled public String productLink {get;set;}
        @AuraEnabled public String productName {get;set;}
        @AuraEnabled public String configurationType {get;set;}
        @AuraEnabled public Integer quantity {get;set;}
        @AuraEnabled public String productCode {get;set;}
        @AuraEnabled public String description {get;set;}
        //@AuraEnabled public String hierarchyId {get;set;}
        @AuraEnabled public String replacedProductCode {get;set;}
        //@AuraEnabled public String buttonName {get;set;}
    }
    @AuraEnabled(cacheable=true)
    public static AgreementWrapper getAgreementfields(string recordId, string accountId){ 
        AgreementWrapper agrWrapper = new AgreementWrapper();
        AgreementWrapper agrWrap;
        system.debug('recordID'+recordId);
        system.debug('accountId'+accountId);
        Account oAccount = new Account();
        Contact primaryContact = new Contact();
        List<Apttus_Config2__PriceList__c> priceList;
        Map<Id,Id> generalCSPPriceListIdMap = new Map<Id,Id>();
        if(string.isNotBlank(accountId)){
            agrWrap = getDefaultPriceList(Id.valueOf(accountId),agrWrap);
            List<Contact> conList = [Select Id From Contact Where Main_Commercial_Person__c=true and AccountId =: accountId];
            if(conList.size()>0 || conList.size()==1){
                primaryContact = conList[0];
            }
        }
        system.debug('conId'+primaryContact.Id);
        For(Apttus_Config2__PriceList__c pricelistObj: [select id,Apttus_Config2__BasedOnPriceListId__c,Apttus_Config2__Type__c,APTS_PriceList_Type__c 
                                                    from Apttus_Config2__PriceList__c 
                                                    where Apttus_Config2__Active__c = true and Apttus_Config2__BasedOnPriceListId__c!=null]){
            if(generalCSPPriceListIdMap.get(pricelistObj.id)==null){
                generalCSPPriceListIdMap.put(pricelistObj.id,pricelistObj.Apttus_Config2__BasedOnPriceListId__c);
            }
        }
        if(!generalCSPPriceListIdMap.isEmpty() && generalCSPPriceListIdMap.get(agrWrap.priceListId)!=null){
            agrWrap.parentPriceListId = generalCSPPriceListIdMap.get(agrWrap.priceListId);
        }
        Date endDt = Date.today().addmonths(60).addDays(-1);
        agrWrapper = new AgreementWrapper(recordId,accountId,primaryContact.Id,'Standard','Regular',60,Date.today(),
                                            endDt,true,false,agrWrap.priceListId,'','',agrWrap.routeSalesPriceListId,agrWrap.parentPriceListId,generalCSPPriceListIdMap);
        return agrWrapper;
    }
    
    public static AgreementWrapper getDefaultPriceList(ID accountID, AgreementWrapper agrWrap){
        Map<String, String> priceListTypeMap = new Map<String, String>();
        AgreementWrapper agrWrap1 = new AgreementWrapper();
        Set<Id> accountIdSet = new Set<Id>();
        Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>();
        for (APTS_Price_List_Settings__mdt priceListType : [SELECT MasterLabel, APTS_Price_List_Type__c
                FROM APTS_Price_List_Settings__mdt ]) {
            priceListTypeMap.put(priceListType.MasterLabel, priceListType.APTS_Price_List_Type__c);
        }
        Account oAccount = [Select Id,APTS_Price_List__c,APTS_Price_List__r.APTS_SalesOrg__c,
                        Parent.APTS_Price_List__c, Parent.APTS_Price_List__r.APTS_SalesOrg__c,
                        parent.parent.APTS_Price_List__c, parent.parent.APTS_Price_List__r.APTS_SalesOrg__c,
                        ParentId, Partner__c, Parent.ParentId, Purchasing_Organization__c, Sales_Organization__c,
                        Purchasing_Organization__r.APTS_Price_List__c, 
                        Purchasing_Organization__r.APTS_Price_List__r.APTS_SalesOrg__c
                        From Account Where Id =: accountID];
        if(oAccount.Parent != null){
            accountIdSet.add(oAccount.ParentID);
            accountIdSet.add(oAccount.Id);
        }else{
            accountIdSet.add(oAccount.Id);
        }
        if(oAccount.Parent != null && oAccount.Parent.Parent != null){
            accountIdSet.add(oAccount.Parent.ParentID);
        }
        if(oAccount.Purchasing_Organization__c != null){
            accountIdSet.add(oAccount.Purchasing_Organization__r.Id);
        }
        for(Apttus__APTS_Agreement__c oAgg : [SELECT Id,
                                                        Apttus__Account__c,
                                                        Apttus_CMConfig__PriceListId__c,Apttus_CMConfig__PriceListId__r.Id
                                                        FROM Apttus__APTS_Agreement__c
                                                        WHERE Apttus__Status_Category__c = 'In Effect'
                                                        AND Apttus__Status__c = 'Activated' 
                                                        AND Apttus__Account__c IN: accountIdSet
                                                        ]){
            agreementMap.put(oAgg.Apttus__Account__c, oAgg);
        }
        Map<String, APTS_SalesOrg_Settings__mdt> salesOrgSettingsMap = new Map<String, APTS_SalesOrg_Settings__mdt>();
        for (APTS_SalesOrg_Settings__mdt salesOrgSettings : [SELECT MasterLabel, APTS_SAP_ID__c, APTS_Allow_Routesales__c, APTS_Allow_Indirect_Price_List__c
                FROM APTS_SalesOrg_Settings__mdt Where APTS_SAP_ID__c =: oAccount.Sales_Organization__c]) {
            salesOrgSettingsMap.put(salesOrgSettings.APTS_SAP_ID__c, salesOrgSettings);
        }
        Map<String, Apttus_Config2__PriceList__c> priceListByTypeMap = new Map<String, Apttus_Config2__PriceList__c>();
        for (Apttus_Config2__PriceList__c oPL : [SELECT Id, APTS_PriceList_Type__c, APTS_Region__c
                FROM Apttus_Config2__PriceList__c
                WHERE Apttus_Config2__Active__c = TRUE AND APTS_PriceList_Type__c != :priceListTypeMap.get('CSP') 
                AND APTS_Region__c =: oAccount.Sales_Organization__c]) {
            if (oPL.APTS_Region__c != NULL && oPL.APTS_PriceList_Type__c != NULL) {
                priceListByTypeMap.put(oPL.APTS_PriceList_Type__c, oPL);
            }
        }
        if(string.isNotBlank(oAccount.ParentId)){
            if(agreementMap.containsKey(oAccount.ParentId) && agreementMap.get(oAccount.ParentId) != null){
                agrWrap1.priceListId = String.valueOf(agreementMap.get(oAccount.ParentId).Apttus_CMConfig__PriceListId__r.Id);
            }else if(String.IsNotBlank(oAccount.Parent.ParentId) && agreementMap.containsKey(oAccount.Parent.ParentId) && agreementMap.get(oAccount.Parent.ParentId) != null){
                agrWrap1.priceListId = String.valueOf(agreementMap.get(oAccount.Parent.ParentId).Apttus_CMConfig__PriceListId__r.Id);
            }else If(agreementMap.containsKey(oAccount.Id) && agreementMap.get(oAccount.Id) != null){
                agrWrap1.priceListId = String.valueOf(agreementMap.get(oAccount.Id).Apttus_CMConfig__PriceListId__r.Id);
            }else if(String.IsNotBlank(oAccount.APTS_Price_List__c)){
                agrWrap1.priceListId = String.valueOf(oAccount.APTS_Price_List__r.Id);
            } 
        }else if(String.IsNotBlank(oAccount.Purchasing_Organization__c) && agreementMap.containsKey(oAccount.Purchasing_Organization__c) && agreementMap.get(oAccount.Purchasing_Organization__c) != null){
            agrWrap1.priceListId = String.valueOf(agreementMap.get(oAccount.Purchasing_Organization__c).Apttus_CMConfig__PriceListId__r.Id);
        }else if(string.isNotBlank(oAccount.APTS_Price_List__c)){
            agrWrap1.priceListId = String.valueOf(oAccount.APTS_Price_List__r.Id);
        }else if (priceListByTypeMap.containsKey('Indirect') && oAccount.Partner__c
                    && salesOrgSettingsMap.get(oAccount.Sales_Organization__c).APTS_Allow_Indirect_Price_List__c) {
            agrWrap1.priceListId = String.valueOf(priceListByTypeMap.get('Indirect').Id);
        }else if(priceListByTypeMap.containsKey('Direct')) {
            agrWrap1.priceListId = String.valueOf(priceListByTypeMap.get('Direct').Id);
        }
        if(priceListByTypeMap.containsKey('Routesales') && salesOrgSettingsMap.get(oAccount.Sales_Organization__c).APTS_Allow_Routesales__c) {
            agrWrap1.routeSalesPriceListId = String.valueOf(priceListByTypeMap.get('Routesales').Id);
        }
        return agrWrap1;
    }
    @AuraEnabled
    public static AgreementWrapper getDuration(String startDate, String endDate, 
                                                    Decimal duration, String text){
        try {
            AgreementWrapper dateChangeValues = new AgreementWrapper();
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            String returnValue;
            if(text == 'EndDate'){
                endDt = startDt.addmonths(Integer.valueOf(Math.round(duration))).addDays(-1);
                dateChangeValues.endDate = endDt;
            }else if(text == 'Duration'){
                //Decimal sellingTerm;
                Integer startYear = startDt.year();
                Integer startMonth = startDt.Month();
                Integer startDay = startDt.Day();
                Integer startDaysInMonth = date.daysInMonth(startYear,startMonth);   
                Integer endYear = endDt.year();
                Integer endMonth = endDt.Month();
                Integer endDay = endDt.Day();
                Integer endDaysInMonth = date.daysInMonth(endYear,endMonth);                       
                Integer sellingMonths = startDt.monthsBetween(endDt)-1;
                Decimal sellingProratedStart = ((date.daysInMonth(startYear,startMonth)-startDay+1.00)*1.00)/(1.00*date.daysInMonth(startYear,startMonth));
                Decimal sellingProratedEnd = (endDay*1.00)/(1.00*date.daysInMonth(endYear,endMonth));
                Decimal calculatedSellingTermMonth = sellingProratedStart+sellingMonths+sellingProratedEnd;
                dateChangeValues.contractPeriod = calculatedSellingTermMonth.setScale(2);
                system.debug('SellingTerm=>'+calculatedSellingTermMonth);
                System.debug('expectedEndDate===========>'+endDt);
            }
            return dateChangeValues;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static AgreementWrapper setAgreementfields(string agreementInput){ 
        List<Apttus_Config2__SearchFilter__c> searchFilter = new List<Apttus_Config2__SearchFilter__c>();
        List<Apttus_Config2__ClassificationName__c> categoryList = new List<Apttus_Config2__ClassificationName__c>();
        Map<Id,Apttus_Config2__ClassificationName__c> categoryMap;
        List<Apttus_Config2__ClassificationHierarchy__c> categoryHier1 = new List<Apttus_Config2__ClassificationHierarchy__c>();
        List<Apttus_Config2__ClassificationHierarchy__c> categoryHierReturnMap = new List<Apttus_Config2__ClassificationHierarchy__c>();
        AgreementWrapper agreementValues = (AgreementWrapper)JSON.deserializeStrict(agreementInput, AgreementWrapper.class);
        system.debug('AgreementWrapper values'+agreementValues);
        return agreementValues;
    }
    @AuraEnabled(cacheable=true)
    public static List<Categories> getAllCategoryDetails(String agreementwrapper){ 
        List<Categories> categoriesWrapperList = new List<Categories>();
        Map<Id,List<item>> categoryHierarchyl1Map = new Map<Id,List<item>>();
        Map<Id,List<item>> categoryHierarchyL2Map = new Map<Id,List<item>>();
        AgreementWrapper agreementWrapperObj;
        List<ProductClassInfo> allProductClassList = new List<ProductClassInfo>();
        ID pricelistId;
        //
        Map<id,List<ProductClassInfo>> categioryLevelProdMap = new Map<id,List<ProductClassInfo>>();
        Map<id,List<ProductClassInfo>> hierarchyLevel1ProdMap = new Map<id,List<ProductClassInfo>>();
        Map<id,List<ProductClassInfo>> hierarchyLevel2ProdMap = new Map<id,List<ProductClassInfo>>();
        System.debug('agreementwrapper================>'+agreementwrapper);
        if(agreementwrapper!=null){
            agreementWrapperObj = (AgreementWrapper)JSON.deserializeStrict(agreementWrapper,AgreementWrapper.class);
            if(agreementWrapperObj.parentPriceListId!=null){
                pricelistId=agreementWrapperObj.parentPriceListId;
            }else{
                pricelistId=agreementWrapperObj.pricelistId;
            }
        }
        for(Apttus_Config2__ProductClassification__c productClass : [select id,
            Apttus_Config2__ProductId__c,
            Apttus_Config2__ProductId__r.name,
            Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c,
            Apttus_Config2__ProductId__r.Description,
            Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c, 
            Apttus_Config2__ProductId__r.ProductCode, 
            Apttus_Config2__ProductId__r.APTS_Replaced_by__c,
            Apttus_Config2__ClassificationId__c,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.name,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__Label__c,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__Level__c,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__Label__c,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c,
            Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__r.name
            from Apttus_Config2__ProductClassification__c where Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c IN ('Standalone','Bundle') order by Apttus_Config2__Sequence__c]){
                if(productClass.Apttus_Config2__ClassificationId__c!=null && productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__Level__c==2){
                    if(hierarchyLevel2ProdMap.get(productClass.Apttus_Config2__ClassificationId__c)==null){
                        List<ProductClassInfo> productClassList = new List<ProductClassInfo>();
                        ProductClassInfo prodInfo = new ProductClassInfo();
                        prodInfo.productImage = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c;
                        prodInfo.productid = productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productLink = '/'+productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productName = productClass.Apttus_Config2__ProductId__r.name;
                        prodInfo.configurationType = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c;
                        prodInfo.quantity = 1;
                        prodInfo.productCode = productClass.Apttus_Config2__ProductId__r.ProductCode;
                        prodInfo.description = productClass.Apttus_Config2__ProductId__r.Description;
                        if(productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c!=null){
                            prodInfo.replacedProductCode = productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c;
                        }
                        //prodInfo.buttonName='AddedToCart';
                        //prodInfo.hierarchyId = productClass.
                        productClassList.add(prodInfo);
                        hierarchyLevel2ProdMap.put(productClass.Apttus_Config2__ClassificationId__c,productClassList);
                    }else{
                        List<ProductClassInfo> productClassList = hierarchyLevel2ProdMap.get(productClass.Apttus_Config2__ClassificationId__c);
                        ProductClassInfo prodInfo = new ProductClassInfo();
                        prodInfo.productImage = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c;
                        prodInfo.productid = productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productLink = '/'+productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productName = productClass.Apttus_Config2__ProductId__r.name;
                        prodInfo.configurationType = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c;
                        prodInfo.quantity = 1;
                        prodInfo.productCode = productClass.Apttus_Config2__ProductId__r.ProductCode;
                        prodInfo.description = productClass.Apttus_Config2__ProductId__r.Description;
                        if(productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c!=null){
                            prodInfo.replacedProductCode = productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c;
                        }
                        //prodInfo.buttonName='AddedToCart';
                        productClassList.add(prodInfo);
                        hierarchyLevel2ProdMap.put(productClass.Apttus_Config2__ClassificationId__c,productClassList);
                    }
                }
				if(productClass.Apttus_Config2__ClassificationId__c!=null && productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__Level__c==1){
                    if(hierarchyLevel1ProdMap.get(productClass.Apttus_Config2__ClassificationId__c)==null){
                        List<ProductClassInfo> productClassList = new List<ProductClassInfo>();
                        ProductClassInfo prodInfo = new ProductClassInfo();
                        prodInfo.productImage = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c;
                        prodInfo.productid = productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productLink = '/'+productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productName = productClass.Apttus_Config2__ProductId__r.name;
                        prodInfo.configurationType = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c;
                        prodInfo.quantity = 1;
                        prodInfo.productCode = productClass.Apttus_Config2__ProductId__r.ProductCode;
                        prodInfo.description = productClass.Apttus_Config2__ProductId__r.Description;
                        if(productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c!=null){
                            prodInfo.replacedProductCode = productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c;
                        }
                        //prodInfo.buttonName='AddedToCart';
                        //prodInfo.hierarchyId = productClass.
                        productClassList.add(prodInfo);
                        hierarchyLevel1ProdMap.put(productClass.Apttus_Config2__ClassificationId__c,productClassList);
                    }else{
                        List<ProductClassInfo> productClassList = hierarchyLevel1ProdMap.get(productClass.Apttus_Config2__ClassificationId__c);
                        ProductClassInfo prodInfo = new ProductClassInfo();
                        prodInfo.productImage = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c;
                        prodInfo.productid = productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productLink = '/'+productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productName = productClass.Apttus_Config2__ProductId__r.name;
                        prodInfo.configurationType = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c;
                        prodInfo.quantity = 1;
                        prodInfo.productCode = productClass.Apttus_Config2__ProductId__r.ProductCode;
                        prodInfo.description = productClass.Apttus_Config2__ProductId__r.Description;
                        if(productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c!=null){
                            prodInfo.replacedProductCode = productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c;
                        }
                        //prodInfo.buttonName='AddedToCart';
                        productClassList.add(prodInfo);
                        hierarchyLevel1ProdMap.put(productClass.Apttus_Config2__ClassificationId__c,productClassList);
                    }
                }
				if(productClass.Apttus_Config2__ClassificationId__c!=null && productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__Level__c==0 && productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c!=null){
                    if(categioryLevelProdMap.get(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c)==null){
                        List<ProductClassInfo> productClassList = new List<ProductClassInfo>();
                        ProductClassInfo prodInfo = new ProductClassInfo();
                        prodInfo.productImage = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c;
                        prodInfo.productid = productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productLink = '/'+productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productName = productClass.Apttus_Config2__ProductId__r.name;
                        prodInfo.configurationType = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c;
                        prodInfo.quantity = 1;
                        prodInfo.productCode = productClass.Apttus_Config2__ProductId__r.ProductCode;
                        prodInfo.description = productClass.Apttus_Config2__ProductId__r.Description;
                        if(productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c!=null){
                            prodInfo.replacedProductCode = productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c;
                        }
                        //prodInfo.buttonName='AddedToCart';
                        //prodInfo.hierarchyId = productClass.
                        productClassList.add(prodInfo);
                       categioryLevelProdMap.put(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c,productClassList);
                    }else{
                        List<ProductClassInfo> productClassList = categioryLevelProdMap.get(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c);
                        ProductClassInfo prodInfo = new ProductClassInfo();
                        prodInfo.productImage = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c;
                        prodInfo.productid = productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productLink = '/'+productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productName = productClass.Apttus_Config2__ProductId__r.name;
                        prodInfo.configurationType = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c;
                        prodInfo.quantity = 1;
                        prodInfo.productCode = productClass.Apttus_Config2__ProductId__r.ProductCode;
                        prodInfo.description = productClass.Apttus_Config2__ProductId__r.Description;
                        if(productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c!=null){
                            prodInfo.replacedProductCode = productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c;
                        }
                        //prodInfo.buttonName='AddedToCart';
                        productClassList.add(prodInfo);
                       categioryLevelProdMap.put(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__c,productClassList);
                    }
                }
                if(productClass.Apttus_Config2__ClassificationId__c!=null && productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c!=null){
                    if(hierarchyLevel1ProdMap.get(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c)==null){
                        List<ProductClassInfo> productClassList = new List<ProductClassInfo>();
                        ProductClassInfo prodInfo = new ProductClassInfo();
                        prodInfo.productImage = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c;
                        prodInfo.productid = productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productLink = '/'+productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productName = productClass.Apttus_Config2__ProductId__r.name;
                        prodInfo.configurationType = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c;
                        prodInfo.quantity = 1;
                        prodInfo.productCode = productClass.Apttus_Config2__ProductId__r.ProductCode;
                        prodInfo.description = productClass.Apttus_Config2__ProductId__r.Description;
                        if(productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c!=null){
                            prodInfo.replacedProductCode = productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c;
                        }
                        //prodInfo.buttonName='AddedToCart';
                        //prodInfo.hierarchyId = productClass.
                        productClassList.add(prodInfo);
                        hierarchyLevel1ProdMap.put(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c,productClassList);
                    }else{
                        List<ProductClassInfo> productClassList = hierarchyLevel1ProdMap.get(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c);
                        ProductClassInfo prodInfo = new ProductClassInfo();
                        prodInfo.productImage = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c;
                        prodInfo.productid = productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productLink = '/'+productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productName = productClass.Apttus_Config2__ProductId__r.name;
                        prodInfo.configurationType = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c;
                        prodInfo.quantity = 1;
                        prodInfo.productCode = productClass.Apttus_Config2__ProductId__r.ProductCode;
                        prodInfo.description = productClass.Apttus_Config2__ProductId__r.Description;
                        if(productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c!=null){
                            prodInfo.replacedProductCode = productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c;
                        }
                        //prodInfo.buttonName='AddedToCart';
                        productClassList.add(prodInfo);
                        hierarchyLevel1ProdMap.put(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c,productClassList);
                    }
                }
                if(productClass.Apttus_Config2__ClassificationId__c!=null && productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c!=null && productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c!=null){
                    if(categioryLevelProdMap.get(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c)==null){
                        List<ProductClassInfo> productClassList = new List<ProductClassInfo>();
                        ProductClassInfo prodInfo = new ProductClassInfo();
                        prodInfo.productImage = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c;
                        prodInfo.productid = productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productLink = '/'+productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productName = productClass.Apttus_Config2__ProductId__r.name;
                        prodInfo.configurationType = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c;
                        prodInfo.quantity = 1;
                        prodInfo.productCode = productClass.Apttus_Config2__ProductId__r.ProductCode;
                        prodInfo.description = productClass.Apttus_Config2__ProductId__r.Description;
                        if(productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c!=null){
                            prodInfo.replacedProductCode = productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c;
                        }
                        //prodInfo.buttonName='AddedToCart';
                        //prodInfo.hierarchyId = productClass.
                        productClassList.add(prodInfo);
                        categioryLevelProdMap.put(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c,productClassList);
                    }else{
                        List<ProductClassInfo> productClassList = categioryLevelProdMap.get(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c);
                        ProductClassInfo prodInfo = new ProductClassInfo();
                        prodInfo.productImage = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c;
                        prodInfo.productid = productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productLink = '/'+productClass.Apttus_Config2__ProductId__c;
                        prodInfo.productName = productClass.Apttus_Config2__ProductId__r.name;
                        prodInfo.configurationType = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c;
                        prodInfo.quantity = 1;
                        prodInfo.productCode = productClass.Apttus_Config2__ProductId__r.ProductCode;
                        prodInfo.description = productClass.Apttus_Config2__ProductId__r.Description;
                        if(productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c!=null){
                            prodInfo.replacedProductCode = productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c;
                        }
                        //prodInfo.buttonName='AddedToCart';
                        productClassList.add(prodInfo);
                        categioryLevelProdMap.put(productClass.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c,productClassList);
                    }
                }
                ProductClassInfo prodInfo = new ProductClassInfo();
                prodInfo.productImage = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__IconId__c;
                prodInfo.productid = productClass.Apttus_Config2__ProductId__c;
                prodInfo.productLink = '/'+productClass.Apttus_Config2__ProductId__c;
                prodInfo.productName = productClass.Apttus_Config2__ProductId__r.name;
                prodInfo.configurationType = productClass.Apttus_Config2__ProductId__r.Apttus_Config2__ConfigurationType__c;
                prodInfo.quantity = 1;
                prodInfo.productCode = productClass.Apttus_Config2__ProductId__r.ProductCode;
                prodInfo.description = productClass.Apttus_Config2__ProductId__r.Description;
                if(productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c!=null){
                    prodInfo.replacedProductCode = productClass.Apttus_Config2__ProductId__r.APTS_Replaced_by__c;
                }
                allProductClassList.add(prodInfo);
         }
        System.debug('hierarchyLevel2ProdMap=========>'+hierarchyLevel2ProdMap);
        System.debug('hierarchyLevel1ProdMap=========>'+hierarchyLevel1ProdMap);
        System.debug('categioryLevelProdMap=========>'+categioryLevelProdMap);
        for(Apttus_Config2__ClassificationHierarchy__c catHierarchy : [select id,
            name,
            Apttus_Config2__Level__c,
            Apttus_Config2__Label__c,
            Apttus_Config2__HierarchyId__c,
            Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c,
            Apttus_Config2__AncestorId__r.name,         
            Apttus_Config2__HierarchyId__r.name,
            Apttus_Config2__HierarchyId__r.Apttus_Config2__Type__c 
            from Apttus_Config2__ClassificationHierarchy__c 
            where Apttus_Config2__HierarchyId__c!=null and 
            Apttus_Config2__AncestorId__c!=null and 
            Apttus_Config2__HierarchyId__r.Apttus_Config2__Type__c='Offering'and 
            Apttus_Config2__Level__c = 2 order by APTS_CategoryHierarchyOfferingExtId__c]){
            if(categoryHierarchyL2Map.get(catHierarchy.Apttus_Config2__AncestorId__c)==null){
                List<item> hierarchyList = new List<item>();
                item hierarchy = new item();
                hierarchy.label=catHierarchy.Apttus_Config2__Label__c;
                hierarchy.name=catHierarchy.id;
                hierarchy.expanded=false;
                if(hierarchyLevel2ProdMap.get(catHierarchy.id)!=null){
                    hierarchy.products=hierarchyLevel2ProdMap.get(catHierarchy.id);
                }
                System.debug('L2 Label===1===>'+ hierarchy.label);
                System.debug('L2 Products===1===>'+ hierarchy.products);
                hierarchyList.add(hierarchy);
                categoryHierarchyL2Map.put(catHierarchy.Apttus_Config2__AncestorId__c,hierarchyList);
            }else{
                List<item> hierarchyList = categoryHierarchyL2Map.get(catHierarchy.Apttus_Config2__AncestorId__c);
                item hierarchy = new item();
                hierarchy.label=catHierarchy.Apttus_Config2__Label__c;
                hierarchy.name=catHierarchy.id;
                hierarchy.expanded=false;
                if(hierarchyLevel2ProdMap.get(catHierarchy.id)!=null){
                    hierarchy.products=hierarchyLevel2ProdMap.get(catHierarchy.id);
                }
                System.debug('L2 Label===2===>'+ hierarchy.label);
                System.debug('L2 Products===2===>'+ hierarchy.products);
                hierarchyList.add(hierarchy);
                categoryHierarchyL2Map.put(catHierarchy.Apttus_Config2__AncestorId__c,hierarchyList);
            }
        }
        System.debug('categoryHierarchyL2Map==========>'+categoryHierarchyL2Map);
        for(Apttus_Config2__ClassificationHierarchy__c catHierarchy : [select id,
            name,
            Apttus_Config2__Level__c,
            Apttus_Config2__Label__c,
            Apttus_Config2__HierarchyId__c,
            Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c,
            Apttus_Config2__AncestorId__r.name,         
            Apttus_Config2__HierarchyId__r.name,
            Apttus_Config2__HierarchyId__r.Apttus_Config2__Type__c 
            from Apttus_Config2__ClassificationHierarchy__c 
            where Apttus_Config2__HierarchyId__c!=null and 
            Apttus_Config2__AncestorId__c!=null and 
            Apttus_Config2__HierarchyId__r.Apttus_Config2__Type__c='Offering'and 
            Apttus_Config2__Level__c = 1 order by APTS_CategoryHierarchyOfferingExtId__c]){
            if(categoryHierarchyl1Map.get(catHierarchy.Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c)==null){
                List<item> hierarchyList = new List<item>();
                item hierarchy = new item();
                hierarchy.label=catHierarchy.Apttus_Config2__Label__c;
                hierarchy.name=catHierarchy.id;
                hierarchy.expanded=false;
                if(hierarchyLevel1ProdMap.get(catHierarchy.id)!=null){
                    hierarchy.products=hierarchyLevel1ProdMap.get(catHierarchy.id);
                }
                if(categoryHierarchyL2Map.get(catHierarchy.id)!=null){
                    hierarchy.items=categoryHierarchyL2Map.get(catHierarchy.id);
                    System.debug('L1 Label===1===>'+ hierarchy.label);
                    System.debug('L1 Products===1===>'+ hierarchy.products);
                }
                hierarchyList.add(hierarchy);
                categoryHierarchyl1Map.put(catHierarchy.Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c,hierarchyList);
            }else{
                List<item> hierarchyList = categoryHierarchyl1Map.get(catHierarchy.Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c);
                item hierarchy = new item();
                hierarchy.label=catHierarchy.Apttus_Config2__Label__c;
                hierarchy.name=catHierarchy.id;
                hierarchy.expanded=false;
                if(hierarchyLevel1ProdMap.get(catHierarchy.id)!=null){
                    hierarchy.products=hierarchyLevel1ProdMap.get(catHierarchy.id);
                    System.debug('L1 Label===2===>'+ hierarchy.label);
                    System.debug('L1 Products===2===>'+ hierarchy.products);
                }
                if(categoryHierarchyL2Map.get(catHierarchy.id)!=null){
                    hierarchy.items=categoryHierarchyL2Map.get(catHierarchy.id);
                }
                hierarchyList.add(hierarchy);
                categoryHierarchyl1Map.put(catHierarchy.Apttus_Config2__AncestorId__r.Apttus_Config2__HierarchyId__c,hierarchyList);
            }
        }
        System.debug('categoryHierarchyl1Map==========>'+categoryHierarchyl1Map);
        System.debug('categioryLevelProdMap====LAST======>'+categioryLevelProdMap.size());

        for(Apttus_Config2__PriceListCategory__c priceListCat: [select id,Apttus_Config2__HierarchyId__c,Apttus_Config2__HierarchyId__r.name,Apttus_Config2__Sequence__c,Apttus_Config2__PriceListId__c 
                                                                from Apttus_Config2__PriceListCategory__c 
                                                                where Apttus_Config2__HierarchyId__r.Apttus_Config2__Type__c ='Offering' and 
                                                                Apttus_Config2__HierarchyId__r.Apttus_Config2__Active__c = true and 
                                                                Apttus_Config2__PriceListId__c =: pricelistId 
                                                                order by Apttus_Config2__Sequence__c]){
            Categories catWrapper= new Categories();
            catWrapper.label= priceListCat.Apttus_Config2__HierarchyId__r.name;
            catWrapper.name = priceListCat.Apttus_Config2__HierarchyId__c;
            catWrapper.expanded=false;
            catWrapper.items=categoryHierarchyl1Map.get(priceListCat.Apttus_Config2__HierarchyId__c);
            if(categioryLevelProdMap.get(priceListCat.Apttus_Config2__HierarchyId__c)!=null){
                catWrapper.products=categioryLevelProdMap.get(priceListCat.Apttus_Config2__HierarchyId__c);
                System.debug('L0 Label======>'+ catWrapper.label);
                System.debug('L0 Products======>'+ catWrapper.products.size());
            }
			/*if(cat.Apttus_Config2__PriceLists__r!=null){
				for(Apttus_Config2__PriceListCategory__c pricelistCategory : cat.Apttus_Config2__PriceLists__r){
					if(pricelistCategory.Apttus_Config2__PriceListId__c,equalsIgnoreCase()){
						catWrapper.sequence=pricelistCategory.Apttus_Config2__Sequence__c;
					}
				}
			}*/
            //categoryIdSet.add(cat.Id);
            categoriesWrapperList.add(catWrapper);
        }
        if(!allProductClassList.isEmpty()){
            Categories catWrapper= new Categories();
            catWrapper.label= 'All';
            catWrapper.name = 'All';
            catWrapper.expanded=false;
            catWrapper.products = allProductClassList;
            categoriesWrapperList.add(catWrapper);
        }
        System.debug('categoriesWrapperList====>'+categoriesWrapperList);
        return categoriesWrapperList;
    }
}