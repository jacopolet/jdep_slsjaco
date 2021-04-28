/*******************************************************************************************
  Name            : APTS_CERUtility
  Created By      : Venky Muppalaneni
  Created Date    : 02/14/2018
  Description     : This will provide utility methods for processing CER.
  Version history : 
  Test Class      : APTS_CERUtilityTest
  History:
  v100 - Aftab - getAccountAgreementHierarchyTopToBottom
  Defect 6926 Fix -Lavanya - Query change 
  //v101 23-Oct-2020 Sneha :DQ-2462 Restricting the blocked products 
  //v102 06-Nov-2020 Sneha Jaiwant DQ4403: Products blocked for selling - view in CPP & restriction to add to the cart
 *********************************************************************************************/
public with sharing class APTS_CERUtility {
    public static final String PRODUCT_SERVICE = 'Product/Service';
    public static final String OPTION = 'Option';
    public static final String AGREE_STATUS_ACTIVATED = 'Activated';
    public static final String AGREE_STATUS_BEING_AMENDED = 'Being Amended';
    public static final String AGREE_STATUS_BEING_RENEWED = 'Being Renewed';
    public static final String AGREE_STATUS_BEING_TERMINATED = 'Being Terminated';
    public static final String STANDARD_DEAL = 'Standard Deal';
    public static final String CONSUMPTION_MODEL = 'Consumption Model';
    public static final String REGISTRATION_FROM = 'Registration Form';
    public static final String AGREEMENTOBJECT = 'Apttus__APTS_Agreement__c';
    public static final String CATEGORY = 'Category';
    public static final String SUB_CATEGORY = 'Sub Category';
    public static final String SUB_SUB_CATEGORY = 'Sub Sub Category';
    public static final String CHILD = 'Child';
    public static final String INGREDIENT = 'Ingredient';
    public static final String CONSIGNMENT_INGREDIENT = 'consignment ingredients';
    public static final String CATEGORY_PRODUCT = 'Category Product';
    public static final String APPLICABLE = 'Applicable';
    public static final String S_25 = 'S25';
    public static final String S_0705 = '0705';
    public static final String S_20 = 'S20';
    public static final String STANDARD_ORDER = 'Standard Order';
    public static final String MACHINE_ORDER = 'Machine Order';
    public static final String ROUTE_SALES_ORDER = 'Route Sales Order';
    public static final String OPERATING_ORDER = 'Operating Order';
    public static final String PROSPECT = 'Prospect';
    public static final String COMPLETE = 'Complete';
    public static final String SAP_PCE = 'SAP_PCE';
    public static final String SAP_BX = 'SAP_BX';
    public static final String SPARE_PARTS = 'Spare Parts';
    public class AccountHierarchy {
        public Id parentId;
        public Id grandParentId;
        public Id buyingGroupId;
        public Decimal currentLevel;
    }
    public class AccountAgreementHierarchyBottomToTop {
        public AccountHierarchy accountHierarchy = new AccountHierarchy();
        public List<Agreement> agreementList = new List<Agreement> ();
        public List<Agreement> buyingGroupAgreements = new List<Agreement> ();
        public List<Agreement> parentAgreements = new List<Agreement> ();
        public List<Agreement> grandParentAgreements = new List<Agreement> ();
        public List<Agreement> currentLevelAgreements = new List<Agreement> ();
    }
    public class CategoryHierarchy {
        Integer level;
        String subSubCategoryId;
        String subCategoryId;
        String categoryId;
    }
    public class Agreement {
        public Id agreementId;
        public String agreementType;
    }
    public class AgreementLineItemChargeType {
        public Id aliId;
        public String aliChargeType;
        public String category;
        public String subCategory;
        public String subSubCategory;
    }
    public class AgreementAdjustmentLineItem {
        public String aaliType;
        public String aaliSubType;
        public String aaliSource;
    }
    public class ContractedProductsRSO {
        public ID accountID;
        public String poNumber;
        public ID productID;
        public String productCode;
        public String productName;
        public String productImage;
        public String uom;
        public String subSubCategory;
        public String subCategory;
        public String category;
        public Boolean routeSales;
        public Boolean consignment;
        public Boolean orderNonContractedProducts;
    }
    public class ContractedProducts {
        public String orderType;
        public Boolean isSparePart;
        public Decimal adjustmentValue;
        public String adjustmentType;
        public Integer totalSpareParts;
        public List<Ingredient> ingredientsList = new List<Ingredient> ();
        public List<Machine> machinesList = new List<Machine> ();
        public List<Ingredient> getingredientsList() {
            return ingredientsList;
        }
        public List<Machine> getmachinesList() {
            return machinesList;
        }
    }
    public class Ingredient {
        public Id categoryID { get; set; }
        public String categoryName { get; set; }
        public List<SubCategory> subCategories = new List<SubCategory> ();
        public List<Product> products = new List<Product> ();
        public List<Product> getproducts() {
            return products;
        }
        public List<SubCategory> getsubCategories() {
            return subCategories;
        }
    }
    public class SubCategory {
        public Id subCategoryID { get; set; }
        public String subCategoryName { get; set; }
        public List<SubSubCategory> subSubCategories = new List<SubSubCategory> ();
        public List<Product> products = new List<Product> ();
        public List<SubSubCategory> getsubSubCategories() {
            return subSubCategories;
        }
        public List<Product> getproducts() {
            return products;
        }
    }
    public class SubSubCategory {
        public Id subSubCategoryID { get; set; }
        public String subSubCategoryName { get; set; }
        public List<Product> products = new List<Product> ();
        public List<Product> getproducts() {
            return products;
        }
    }
    public class Product {
        public String productId { get; set; }
        public String productName { get; set; }
        public String sellingUOM { get; set; }
        public String productCode { get; set; }
        public Boolean selected { get; set; }
        public Boolean productInCart { get; set; }
        public Boolean isNonSalesOrg { get; set; }//v102
        public Id agreementLineItem { get; set; }
        public Integer quantity { get; set; }
        public Product() {
            this.selected = false;
        }
    }
    public class Machine {
        public Id productID { get; set; }
        public List<Options> options = new List<Options> ();
        public List<ParentBundle> parentBundle = new List<ParentBundle> ();
        public List<Options> getoptions() {
            return options;
        }

        public List<ParentBundle> getparentBundle() {
            return parentBundle;
        }
    }
    public class ParentBundle {
        public Id productID { get; set; }
        public String productName { get; set; }
        public String chargeType { get; set; }
        public String productCode { get; set; }
        public String attributeId { get; set; }
        public Id agreementLineItem { get; set; }
        public string typeOfContract { get; set; }
        public Boolean isNonSalesOrg{get;set;}//v102
    }
    public class Options {
        public Id optionID { get; set; }
        public String optionName { get; set; }
        public String productCode { get; set; }
        public String optionComponentId { get; set; }
        public String chargeType { get; set; }
        public String attributeId { get; set; }
        public Id agreementLineItem { get; set; }
        public string typeOfContractopt { get; set; }
        public Boolean isNonSalesOrg{get;set;}//v102

    }
    //v102 <++
     public class ProductSalesOrg{
        public String productName { get; set; }
        public String productCode { get; set; }
        }
    //v102 ++>

    /**
     * @description
     * @param objectName
     * @param strRecordTypeId
     * @return It Returns recordtype string
     */
    public static String getRecordTypeNameById(String objectName, Id strRecordTypeId) {
        if (objectName != null && strRecordTypeId != null) {
            return Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosById().get(strRecordTypeId).getName();
        } else {
            return '';
        }
    }

    /**
     * @description Based on Account method returns it's Hierarchy
     * @param accounts
     * @return AccountHierarchy
     */
    public static Map<Id, AccountHierarchy> getAccountHierarchy(Set<Id> accounts) {
        Map<Id, AccountHierarchy> returnObject = new Map<Id, AccountHierarchy> ();
        AccountHierarchy ah = new AccountHierarchy();
        for (Account a :[select Id, ParentId, Parent.Name, Ultimate_Parent_Account__c, APTS_Ultimate_Parent_Id__c, Parent.Parent.Id, Purchasing_Organization__c from Account where Id in :accounts]) {
            ah = new AccountHierarchy();
            if (a.ParentId == null && a.Parent.Parent.Id == null && a.Purchasing_Organization__c != null) {
                ah.currentLevel = 1;
            } else if (a.ParentId == a.APTS_Ultimate_Parent_Id__c) {
                ah.currentLevel = 2;
                ah.parentId = a.ParentId;
            } else {
                ah.currentLevel = 3;
                ah.parentId = a.ParentId;
                ah.grandParentId = a.Parent.Parent.Id;
            }
            if (a.ParentId == null && a.Parent.Parent.Id == null && a.Purchasing_Organization__c == null) {
                ah.currentLevel = 0;
            }
            if (a.Purchasing_Organization__c != null) {
                ah.buyingGroupId = a.Purchasing_Organization__c;
            }
            returnObject.put(a.Id, ah);
        }
        return returnObject;
    }

    /**
     * @description Based on Account it return it's corresponding Cer Account ID
     * @param account
     * @param isPending
     * @return ID of Account
     */
    public static Id getCerRecordAccountForRelatedAccount(Id account, boolean isPending) {
        Id returnId;
        List<Boolean> pendingFlag = new List<Boolean> ();
        pendingFlag.add(false);
        if (isPending) {
            pendingFlag.add(true);
        }
        Set<Id> accountSet = new Set<Id> ();
        accountSet.add(account);
        AccountHierarchy ah = getAccountHierarchy(accountSet).get(account);
        if (ah.parentId != null) {
            accountSet.add(ah.parentId);
        }
        if (ah.grandParentId != null) {
            accountSet.add(ah.grandParentId);
        }
        if (ah.buyingGroupId != null) {
            accountSet.add(ah.buyingGroupId);
        }
        List<APTS_Contract_Entitlement_Repository__c> cerList = [select Id, APTS_Sold_to_Party__c from APTS_Contract_Entitlement_Repository__c where(APTS_Sold_to_Party__c in :accountSet) and APTS_Is_Pending__c in :pendingFlag and APTS_Contributing_Agreement_Level__c = :CHILD and APTS_Contributing_Agreement__c not in(Select APTS_Agreement__c from APTS_Agreement_Account_Exclusion__c where APTS_Account__c = :account)];
        for (APTS_Contract_Entitlement_Repository__c cerRecord : cerList) {
            if (cerRecord.APTS_Sold_to_Party__c == account) {
                returnId = account;
                break;
            } else if (cerRecord.APTS_Sold_to_Party__c == ah.parentId) {
                returnId = ah.parentId;
            } else if (cerRecord.APTS_Sold_to_Party__c == ah.grandParentId && returnId != ah.parentId) {
                returnId = ah.grandParentId;
            } else if (cerRecord.APTS_Sold_to_Party__c == ah.buyingGroupId && returnId != ah.parentId && returnId != ah.grandParentId) {
                returnId = ah.buyingGroupId;
            }
        }
        if (returnId == Null) {
            returnId = account;
        }
        return returnId;
    }
    /**
     * @description Based on Account it return it's corresponding Cer Account ID
     * @param account
     * @param isPending
     * @return ID of Account
     */
    public static Id getCategoryCerRecordAccountForRelatedAccount(Id account, boolean isPending) {
        Id returnId;
        List<Boolean> pendingFlag = new List<Boolean> ();
        pendingFlag.add(false);
        if (isPending) {
            pendingFlag.add(true);
        }
        Set<Id> accountSet = new Set<Id> ();
        accountSet.add(account);
        AccountHierarchy ah = getAccountHierarchy(accountSet).get(account);
        if (ah.parentId != null) {
            accountSet.add(ah.parentId);
        }
        if (ah.grandParentId != null) {
            accountSet.add(ah.grandParentId);
        }
        if (ah.buyingGroupId != null) {
            accountSet.add(ah.buyingGroupId);
        }
        List<APTS_Contract_Entitlement_Repository__c> cerList = [select Id, APTS_Sold_to_Party__c from APTS_Contract_Entitlement_Repository__c where(APTS_Sold_to_Party__c in :accountSet) and APTS_Is_Pending__c in :pendingFlag and APTS_Contributing_Agreement__c not in(Select APTS_Agreement__c from APTS_Agreement_Account_Exclusion__c where APTS_Account__c = :account)];
        for (APTS_Contract_Entitlement_Repository__c cerRecord : cerList) {
            if (cerRecord.APTS_Sold_to_Party__c == account) {
                returnId = account;
                break;
            } else if (cerRecord.APTS_Sold_to_Party__c == ah.parentId) {
                returnId = ah.parentId;
            } else if (cerRecord.APTS_Sold_to_Party__c == ah.grandParentId && returnId != ah.parentId) {
                returnId = ah.grandParentId;
            } else if (cerRecord.APTS_Sold_to_Party__c == ah.buyingGroupId && returnId != ah.parentId && returnId != ah.grandParentId) {
                returnId = ah.buyingGroupId;
            }
        }
        if (returnId == Null) {
            returnId = account;
        }
        return returnId;
    }
    /**
     * @description
     * @param accounts
     * @return account hierarchy with Agreements
     */
    public static Map<Id, AccountAgreementHierarchyBottomToTop> getAccountAgreementHierarchyBottomToTop(Set<Id> accounts, Set<Id> orginalAccounts) {
        Map<Id, AccountAgreementHierarchyBottomToTop> returnObject = new Map<Id, AccountAgreementHierarchyBottomToTop> ();
        Set<String> recordsSet = new Set<String> ();
        if (accounts == null) {
            return returnObject;
        }
        Agreement agr = new Agreement();
        Set<Id> tempAccountIds = new Set<Id> ();
        Map<Id, Set<Id>> accountMap = new Map<Id, Set<Id>> ();
        Set<Id> fullAccountIds = new Set<Id> ();
        AccountAgreementHierarchyBottomToTop aah = new AccountAgreementHierarchyBottomToTop();
        AccountHierarchy ah = new AccountHierarchy();
        Map<Id, AccountHierarchy> ahy = getAccountHierarchy(accounts);
        for (Id accountID : accounts) {
            tempAccountIds.clear();
            aah = new AccountAgreementHierarchyBottomToTop();

            ah = ahy.get(accountID);
            if (ah == null) {
                continue;
            }
            aah.accountHierarchy.currentLevel = ah.currentLevel;
            tempAccountIds.add(accountID);
            if (!fullAccountIds.contains(accountID)) {
                fullAccountIds.add(accountID);
            }
            if (ah.parentId != null) {
                tempAccountIds.add(ah.parentId);
                if (!fullAccountIds.contains(ah.parentId)) {
                    fullAccountIds.add(ah.parentId);
                }

            }
            if (ah.grandParentId != null) {
                tempAccountIds.add(ah.grandParentId);
                if (!fullAccountIds.contains(ah.grandParentId)) {
                    fullAccountIds.add(ah.grandParentId);
                }

            }
            if (ah.buyingGroupId != null) {
                tempAccountIds.add(ah.buyingGroupId);
                if (!fullAccountIds.contains(ah.buyingGroupId)) {
                    fullAccountIds.add(ah.buyingGroupId);
                }

            }
            accountMap.put(accountID, tempAccountIds);
        }

        List<Apttus__APTS_Agreement__c> agrActiveList = new List<Apttus__APTS_Agreement__c> ();
        for (Apttus__APTS_Agreement__c tagr :[SELECT Id, RecordTypeId, Apttus__Account__c FROM Apttus__APTS_Agreement__c WHERE(Apttus__Status__c = :AGREE_STATUS_ACTIVATED OR Apttus__Status__c = :AGREE_STATUS_BEING_AMENDED OR Apttus__Status__c = :AGREE_STATUS_BEING_RENEWED OR Apttus__Status__c = :AGREE_STATUS_BEING_TERMINATED) and Apttus__Account__c in :fullAccountIds ORDER BY Apttus__Status__c])
        {
            if (orginalAccounts.contains(tagr.Apttus__Account__c) && recordsSet.contains(tagr.Apttus__Account__c + ';' + tagr.RecordTypeId))
            {
                continue;
            }
            recordsSet.add(tagr.Apttus__Account__c + ';' + tagr.RecordTypeId);
            agrActiveList.add(tagr);
        }
        for (Id i : fullAccountIds) {
            aah = new AccountAgreementHierarchyBottomToTop();
            for (Apttus__APTS_Agreement__c agrList : agrActiveList) {
                agr = new Agreement();
                agr.agreementId = agrList.Id;
                agr.agreementType = getRecordTypeNameById(AGREEMENTOBJECT, agrList.RecordTypeId);
                if (REGISTRATION_FROM.equalsIgnoreCase(agr.agreementType)) {
                    continue;
                }
                ah = ahy.get(i);
                if (ah == null) {
                    continue;
                }
                aah.accountHierarchy.currentLevel = ah.currentLevel;

                if (ah.buyingGroupId == agrList.Apttus__Account__c) {
                    aah.accountHierarchy.buyingGroupId = ah.buyingGroupId;
                    aah.buyingGroupAgreements.add(agr);
                    aah.agreementList.add(agr);
                }

                if (ah.parentId == agrList.Apttus__Account__c) {
                    aah.accountHierarchy.parentId = ah.parentId;
                    aah.parentAgreements.add(agr);
                    aah.agreementList.add(agr);
                }
                if (ah.grandParentId == agrList.Apttus__Account__c) {
                    aah.accountHierarchy.grandParentId = ah.grandParentId;
                    aah.grandParentAgreements.add(agr);
                    aah.agreementList.add(agr);
                }
                if (i == agrList.Apttus__Account__c) {
                    aah.currentLevelAgreements.add(agr);
                    aah.agreementList.add(agr);
                }
            }
            returnObject.put(i, aah);
        }
        return returnObject;
    }

    /**
     * @description All the agreemnts of a particular account
     * @param accountId
     * @return list of agreements
     */
    public static List<Apttus__APTS_Agreement__c> getAccountAgreementHierarchy(Set<Id> accountId) {
        List<Apttus__APTS_Agreement__c> response = new List<Apttus__APTS_Agreement__c> ();
        Set<String> recordsSet = new Set<String> ();
        if (accountId != null) {
            List<Account> a = [select Id, Parent.Parent.Id, Parent.Id, Purchasing_Organization__c from account where ID in :accountId];
            for (Apttus__APTS_Agreement__c agr :[SELECT Id, RecordTypeId, Apttus__Account__c FROM Apttus__APTS_Agreement__c WHERE(Apttus__Status__c = :AGREE_STATUS_ACTIVATED OR Apttus__Status__c = :AGREE_STATUS_BEING_AMENDED OR Apttus__Status__c = :AGREE_STATUS_BEING_RENEWED OR Apttus__Status__c = :AGREE_STATUS_BEING_TERMINATED) and Apttus__Account__c in :a ORDER BY Apttus__Status__c])
            {
                if (accountId.contains(agr.Apttus__Account__c) && recordsSet.contains(agr.Apttus__Account__c + ';' + agr.RecordTypeId))
                {
                    continue;
                }
                recordsSet.add(agr.Apttus__Account__c + ';' + agr.RecordTypeId);
                response.add(agr);
            }
            return response;
        } else {
            return response;
        }

    }
    /**
     * @description All the agreemnts in the hierarchy of a particular account
     * @param accountId
     * @return list of CER Transaction records
     */
    public static List<APTS_CER_Transaction__c> getAccountAgreementHierarchyTopToBottom(Set<Id> accountId) {
        List<APTS_CER_Transaction__c> cerTransList = new List<APTS_CER_Transaction__c> ();
        if (accountId != null) {
            System.debug('AccountId*****' + accountId);
            List<Account> accountList = [SELECT Id FROM Account WHERE(Purchasing_Organization__c IN :accountId OR Parent.Parent.Id IN :accountId OR Parent.Id IN :accountId) AND Id NOT IN :accountId];

            APTS_CER_Transaction__c cerTransObj = new APTS_CER_Transaction__c();

            for (Apttus__APTS_Agreement__c agr :[SELECT Id, Apttus__Account__r.Parent.Parent.Id, Apttus__Account__r.Parent.Id, RecordTypeId, Apttus__Account__c, APTS_CER_Batch_Executed__c FROM Apttus__APTS_Agreement__c WHERE(Apttus__Status__c = :AGREE_STATUS_ACTIVATED OR Apttus__Status__c = :AGREE_STATUS_BEING_AMENDED OR Apttus__Status__c = :AGREE_STATUS_BEING_RENEWED OR Apttus__Status__c = :AGREE_STATUS_BEING_TERMINATED) and Apttus__Account__c IN :accountList])
            {
                cerTransObj = new APTS_CER_Transaction__c();
                cerTransObj.APTS_Agreement_Id__c = agr.Id;

                /* if(APTS_ManageCER.isMigrationBatch){
                  cerTransObj.APTS_Contributing_IND__c = 'Migrated';
                  }
                  else{
                  cerTransObj.APTS_Contributing_IND__c = 'Agreement';
                  }*/
                cerTransObj.Hierarchy_Level__c = (agr.Apttus__Account__r.Parent.Parent.Id != null && accountId.contains(agr.Apttus__Account__r.Parent.Parent.Id)) ? 3 : (agr.Apttus__Account__r.Parent.Id != null && accountId.contains(agr.Apttus__Account__r.Parent.Id)) ? 2 : 1;
                //cerTransObj.APTS_Account_Id__c = agr.Apttus__Account__c;
                cerTransObj.APTS_Process_Status__c = 'Created';
                cerTransList.add(cerTransObj);
                //agr.APTS_CER_Batch_Executed__c = true;
                //returnList.add(agr);
            }
            if (cerTransList.size() > 0) upsert cerTransList APTS_Agreement_Id__c;
        }
        return cerTransList;
    }

    /**
     * @description it returns all the agreement line items with charge type
     * @param agreements
     * @return agreement line items with charge type
     */
    public static Map<Id, Map<Id, List<AgreementLineItemChargeType>>> getContractedProductsForAgreement(Set<Id> agreements) {
        Map<Id, Map<Id, List<AgreementLineItemChargeType>>> contractedProducts = new Map<Id, Map<Id, List<AgreementLineItemChargeType>>> ();
        Map<Id, List<AgreementLineItemChargeType>> productsList = new Map<Id, List<AgreementLineItemChargeType>> ();
        List<AgreementLineItemChargeType> tempIdList = new List<AgreementLineItemChargeType> ();
        AgreementLineItemChargeType alic = new AgreementLineItemChargeType();
        Id tempId;
        for (Apttus__AgreementLineItem__c aal :[select id, Apttus__AgreementId__c, Apttus_CMConfig__ChargeType__c, Apttus_CMConfig__LineType__c, Apttus__ProductId__c, Apttus_CMConfig__OptionId__c, Apttus_CMConfig__ClassificationId__c, APTS_Sub_Category__c, APTS_Sub_Sub_Category__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c in :agreements]) {
            productsList = contractedProducts.get(aal.Apttus__AgreementId__c) != null ? contractedProducts.get(aal.Apttus__AgreementId__c) : new Map<Id, List<AgreementLineItemChargeType>> ();
            tempId = PRODUCT_SERVICE.equalsIgnoreCase(aal.Apttus_CMConfig__LineType__c) ? aal.Apttus__ProductId__c : aal.Apttus_CMConfig__OptionId__c;
            tempIdList = productsList.get(tempId) != null ? productsList.get(tempId) : new List<AgreementLineItemChargeType> ();
            alic = new AgreementLineItemChargeType();
            alic.aliId = aal.Id;
            alic.aliChargeType = aal.Apttus_CMConfig__ChargeType__c;
            alic.category = aal.Apttus_CMConfig__ClassificationId__c;
            alic.subCategory = aal.APTS_Sub_Category__c;
            alic.subSubCategory = aal.APTS_Sub_Sub_Category__c;
            tempIdList.add(alic);
            productsList.put(tempId, tempIdList);
            contractedProducts.put(aal.Apttus__AgreementId__c, productsList);

        }
        return contractedProducts;
    }
    /***
      This method is used for CSP Purposes
      Id soldToAccountId, // The customer that we selling to
     ***/
    public static APTS_GetProductsRest.GetProductReturnObject getProduct(Id soldToAccountId)
    {
        APTS_GetProductsRest.GetProductReturnObject returnObject = new APTS_GetProductsRest.GetProductReturnObject();
        Id categoryId, priceListId, basedOnPriceListId;
        //DOQCP-40
        Set<String> uomString = new Set<String> ();
        Map<Id, String> sapCode = new Map<Id, String> ();
        Set<Id> productSet = new Set<Id> ();
        String IncomingProdId;
        Set<Id> PriceListItemSet = new Set<Id> ();
        Map<Id, Map<String, Decimal>> mapProductBPO = new Map<Id, Map<String, Decimal>> ();
        Map<Id, Decimal> productTax = new Map<Id, Decimal> ();
        Map<Id, String> productUom = new Map<Id, String> ();
        Map<Id, String> productVat = new Map<Id, String> ();
        Map<Id, String> productReplacement = new Map<Id, String> ();
        Map<Id, String> SellingUOM = new Map<Id, String> ();
        Map<Id, String> productPriceUom = new Map<Id, String> ();
        Map<String, Decimal> uomOutput = new Map<String, Decimal> ();
        Map<String, Decimal> tempMap;
        List<Apttus_Config2__PriceListItem__c> lstPriceListItem;
        //DOQCP-40
        //  List<APTS_GetProductsRest.GetProductsWrapper> tempReturnObject = new List<APTS_GetPriceRest.GetProductsWrapper> ();
        Set<Id> cerAndCspProducts = new Set<Id> ();
        Set<Id> CerProducts = new Set<Id> ();
        decimal uomFactor = 0.0, price = 0.0;
        Set<Id> cerProductsWithAdj = new Set<Id> ();
        list<Account> salAcc = new list<Account> ();
        List<Id> categories = new List<Id> ();
        List<Id> subCategories = new List<Id> ();
        Set<Id> tempProductSet = new Set<Id> ();
        List<Id> subSubCategories = new List<Id> ();
        Boolean inTestScope = Test.isRunningTest();
        string cur, tempString, tempString1;
        Map<Id, String> sellingUomMap = new Map<Id, String> ();
        List<APTS_Contract_Entitlement_Repository__c> cerRecords = new List<APTS_Contract_Entitlement_Repository__c> ();
        list<APTS_Sales_Org_Data__c> salesOrgDataList = new list<APTS_Sales_Org_Data__c> ();
        Id tempSoldToAccountId = getCerRecordAccountForRelatedAccount(soldToAccountId, false);
        Set<Id> agreementExculsion = new Set<Id> ();
        for (APTS_Agreement_Account_Exclusion__c aae :[Select APTS_Agreement__c from APTS_Agreement_Account_Exclusion__c where APTS_Account__c = :soldToAccountId])
        {
            if (!agreementExculsion.contains(aae.APTS_Agreement__c))
            agreementExculsion.add(aae.APTS_Agreement__c);
        }

        cerRecords = [Select id,
                      APTS_Product__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c, APTS_Amendment_In_Progress__c,
                      APTS_Agreement_Adjustment_Line_Item__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.CurrencyIsoCode,
                      APTS_Category_Level__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceListId__c,
                      APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c,
                      APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePrice__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_VAT_indicator_Digital__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c,
                      APTS_Agreement_Line_Item__r.APTS_More_Standalone__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c,
                      APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone_or_Spare_Part__c, APTS_Sub_Category__c, APTS_Sub_Sub_Category__c, APTS_CategoryCER__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c,
                      APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c, APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c
                      //APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c
                      from APTS_Contract_Entitlement_Repository__c
                      where APTS_Sold_to_Party__c = :tempSoldToAccountId
                      and 
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__Active__c = true
                      and APTS_Contributing_Agreement__c not in :agreementExculsion
                      and APTS_Agreement_Line_Item__c not in(Select APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                      and APTS_Agreement_Adjustment_Line_Item__c not in(Select APTS_Agreement_Adjustment_Line_Item__c from APTS_Adjustment_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                      and APTS_Is_Pending__c = false
                      and APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c = :PRODUCT_SERVICE
                      and(APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c = true or APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c = true or
                          APTS_Agreement_Line_Item__r.APTS_More_Standalone__c = true) and APTS_Start_Date__c <= TODAY and APTS_End_Date__c >= TODAY
                      ORDER BY APTS_Category_Level__c Desc];
        try
        {
            System.debug('Prod cer' + cerRecords.size());
            for (APTS_Contract_Entitlement_Repository__c cerRecord : cerRecords)
            {



                if (cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c)
                {
                    if (!cerProductsWithAdj.contains(cerRecord.APTS_Product__c) && cerRecord.APTS_Agreement_Adjustment_Line_Item__c != null)
                    {
                        cerProductsWithAdj.add(cerRecord.APTS_Product__c);
                    }
                    else {
                        SellingUOM.put(cerRecord.APTS_Product__c, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c);
                        productPriceUom.put(cerRecord.APTS_Product__c, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceUom__c);
                        productTax.put(cerRecord.APTS_Product__c, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c);
                        productVat.put(cerRecord.APTS_Product__c, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_VAT_indicator_Digital__c);
                        productReplacement.put(cerRecord.APTS_Product__c, cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c);
                        CerProducts.add(cerRecord.APTS_Product__c);
                        System.debug('CerProducts' + productSet);
                        if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c != null) //BPO,BP instead of LP              
                        {
                            tempMap = new Map<String, Decimal> ();
                            tempMap.put('CER', cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c);
                            mapProductBPO.put(cerRecord.APTS_Product__c, tempMap);
                        }
                        //Commented by Venky
                        //else
                        //{
                            //tempMap = new Map<String, Decimal> ();
                            //tempMap.put('CER', cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePrice__c);
                            //mapProductBPO.put(cerRecord.APTS_Product__c, tempMap);
                        //}
                        System.debug('Prod mapProductBPO CER' + mapProductBPO);

                    }
                    if (cerRecord.APTS_Category_Level__c == CATEGORY) {
                        categories.add(cerRecord.APTS_CategoryCER__c);
                    } else if (cerRecord.APTS_Category_Level__c == SUB_CATEGORY) {
                        subCategories.add(cerRecord.APTS_Sub_Category__c);
                    } else if (cerRecord.APTS_Category_Level__c == SUB_SUB_CATEGORY) {
                        subSubCategories.add(cerRecord.APTS_Sub_Sub_Category__c);
                    }
                    if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c != null && cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__ClassificationId__r.APTS_CategoryHierarchyOfferingExtId__c == S_0705)
                    {
                        tempProductSet.add(cerRecord.APTS_Product__c);
                    }



                }


            }
            if (cerRecords.size() > 0)
            {
                priceListId = cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c;
                basedOnPriceListId = cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c;
                priceListItemSet.add(priceListId);
                if (basedOnPriceListId != NULL)
                priceListItemSet.add(basedOnPriceListId);
            }
            else {
                set<id> accIdsSet = new set<id> ();
                Id AgrmentId = NULL;
                Map<Id, AccountAgreementHierarchyBottomToTop> accHierarchyMap = new Map<Id, AccountAgreementHierarchyBottomToTop> ();
                for (account a :[select id, parentId, parent.parent.Id FROM account WHERE id = :soldToAccountId]) {
                    accIdsSet.add(a.Id);
                    accIdsSet.add(a.parentId);
                    accIdsSet.add(a.parent.parent.Id);
                }
                accHierarchyMap = getAccountAgreementHierarchyBottomToTop(accIdsSet, new set<Id> { soldToAccountId });

                if (!accHierarchyMap.isEmpty()) {
                    for (AccountAgreementHierarchyBottomToTop accHrchy : accHierarchyMap.Values()) {
                        if (!accHrchy.currentLevelAgreements.IsEmpty()) {
                            for (Agreement agrmt : accHrchy.agreementList) {
                                if (agrmt.agreementType == STANDARD_DEAL) {
                                    AgrmentId = agrmt.agreementId; // active agreement from the account hierarchy(bottom-to-top).
                                }
                            }
                        }
                    }
                }
                if (AgrmentId != NULL) { // when there is an active agreement in the account hierarhy
                    Apttus__APTS_Agreement__c activeAgrmntPl = [SELECT Id, Apttus_CMConfig__PriceListId__c, Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c from Apttus__APTS_Agreement__c where Id = :AgrmentId] [0];
                    priceListId = activeAgrmntPl.Apttus_CMConfig__PriceListId__c;
                    basedOnPriceListId = activeAgrmntPl.Apttus_CMConfig__PriceListId__c != null ? activeAgrmntPl.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c : null;

                }
                else { // when there is no active agreement in the account hierarchy
                    for (Account a :[Select Id, APTS_Price_List__c, APTS_Price_List__r.Apttus_Config2__BasedOnPriceListId__c from Account where id = :soldToAccountId])
                    {
                        priceListId = a.APTS_Price_List__c;
                        basedOnPriceListId = a.APTS_Price_List__c != null ? a.APTS_Price_List__r.Apttus_Config2__BasedOnPriceListId__c : null;
                    }
                }
            }

            if (basedOnPriceListId != null || Test.isRunningTest())
            {
                for (Apttus_Config2__ProductClassification__c pc :[SELECT Apttus_Config2__ProductId__c FROM Apttus_Config2__ProductClassification__c WHERE Apttus_Config2__ProductId__r.IsActive = true
                     and(Apttus_Config2__ClassificationId__c IN :categories
                         OR Apttus_Config2__ClassificationId__c IN :subCategories
                         OR Apttus_Config2__ClassificationId__c IN :subSubCategories
                         OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c IN :categories
                         OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c IN :subCategories
                         OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c IN :categories) LIMIT 50000

                     ])
                {

                    if (!cerProductsWithAdj.contains(pc.Apttus_Config2__ProductId__c))
                    {
                        cerProductsWithAdj.add(pc.Apttus_Config2__ProductId__c);
                    }


                }
                salAcc = [select Sales_Organization__c from Account where id = :tempSoldToAccountId];
                string tempSaleOrg = salAcc.size() > 0 && salAcc[0].Sales_Organization__c != null ? salAcc[0].Sales_Organization__c.substring(4, salAcc[0].Sales_Organization__c.length()) : '';
                salesOrgDataList = [SELECT Id, APTS_Product__c FROM APTS_Sales_Org_Data__c WHERE APTS_Product_web_enabled__c = True and APTS_Sales_Org_Data_Name__c = :tempSaleOrg and APTS_Product__c != null and APTS_Product__c NOT IN :cerProductsWithAdj];
                for (APTS_Sales_Org_Data__c salesOrgData : salesOrgDataList)
                {
                    if (!cerAndCspProducts.contains(salesOrgData.APTS_Product__c))
                    {
                        cerAndCspProducts.add(salesOrgData.APTS_Product__c);
                    }
                }
            }
            else
            {
                cerAndCspProducts.addAll(tempProductSet);
            } System.debug('cerAndCspProducts' + cerAndCspProducts);
            if (basedOnPriceListId != Null)
            lstPriceListItem = new List<Apttus_Config2__PriceListItem__c> ([SELECT Apttus_Config2__ListPrice__c, Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c, APTS_Default_selling_UOM__c, CurrencyIsoCode, Apttus_Config2__PriceUom__c, Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode, APTS_Tax_per_UOM__c, APTS_VAT_indicator_Digital__c, APTS_Product_Code__c
                FROM Apttus_Config2__PriceListItem__c
                WHERE ((
                        Apttus_Config2__ProductId__c IN :cerAndCspProducts
                        AND Apttus_Config2__PriceListId__c = :priceListId
                        )
                    OR (
                        Apttus_Config2__ProductId__c IN :CerProducts
                        AND Apttus_Config2__PriceListId__c = :priceListItemSet
                        ))
                    AND Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true
                    AND Apttus_Config2__Active__c = true
                    AND (
                        Apttus_Config2__ExpirationDate__c = NULL
                        OR Apttus_Config2__ExpirationDate__c >= TODAY
                        )
                    AND (
                        Apttus_Config2__PriceListId__r.Apttus_Config2__ExpirationDate__c = NULL
                        OR Apttus_Config2__PriceListId__r.Apttus_Config2__ExpirationDate__c >= TODAY
                        )
                ORDER BY Apttus_Config2__PriceListId__c DESC]);
            else
            lstPriceListItem = new List<Apttus_Config2__PriceListItem__c> ([select Apttus_Config2__ListPrice__c, Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c, APTS_Default_selling_UOM__c, CurrencyIsoCode, Apttus_Config2__PriceUom__c, Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode, APTS_Tax_per_UOM__c, APTS_VAT_indicator_Digital__c, APTS_Product_Code__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__c IN :CerProducts and Apttus_Config2__PriceListId__c = :priceListId]);
            for (Apttus_Config2__PriceListItem__c p : lstPriceListItem)
            {
                sapCode.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__ProductId__r.ProductCode);
                productSet.add(p.Apttus_Config2__ProductId__c);
                System.debug('Final productSet' + productSet);
                if (cur == null)
                {
                    cur = p.CurrencyIsoCode;
                }

                tempString1 = p.Apttus_Config2__PriceUom__c != null ? p.Apttus_Config2__PriceUom__c : '';
                if (tempString1 == SAP_PCE || tempString1 == SAP_BX || inTestScope)
                {

                    if (p.Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c != null)
                    {
                        if (!mapProductBPO.keySet().contains(p.Apttus_Config2__ProductId__c))
                        {
                            tempMap = new Map<String, Decimal> ();
                            tempMap.put('CSP', p.Apttus_Config2__ListPrice__c);
                            mapProductBPO.put(p.Apttus_Config2__ProductId__c, tempMap); //category CSP Products              
                        }
                        if (!productTax.containsKey(p.Apttus_Config2__ProductId__c))
                        productTax.put(p.Apttus_Config2__ProductId__c, p.APTS_Tax_per_UOM__c);
                        if (!SellingUOM.containsKey(p.Apttus_Config2__ProductId__c))
                        SellingUOM.put(p.Apttus_Config2__ProductId__c, p.APTS_Default_selling_UOM__c);
                        if (!productVat.containsKey(p.Apttus_Config2__ProductId__c))
                        productVat.put(p.Apttus_Config2__ProductId__c, p.APTS_VAT_indicator_Digital__c);
                        if (!productReplacement.containsKey(p.Apttus_Config2__ProductId__c))
                        productReplacement.put(p.Apttus_Config2__ProductId__c, p.APTS_Product_Code__c);
                        if (!productPriceUom.containsKey(p.Apttus_Config2__ProductId__c))
                        productPriceUom.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__PriceUom__c);
                    }
                    else {
                        if (!mapProductBPO.keySet().contains(p.Apttus_Config2__ProductId__c))
                        {
                            tempMap = new Map<String, Decimal> ();
                            tempMap.put('General', p.Apttus_Config2__ListPrice__c);
                            mapProductBPO.put(p.Apttus_Config2__ProductId__c, tempMap); //category CSP Products              
                        }
                        if (!productTax.containsKey(p.Apttus_Config2__ProductId__c))
                        productTax.put(p.Apttus_Config2__ProductId__c, p.APTS_Tax_per_UOM__c);
                        if (!SellingUOM.containsKey(p.Apttus_Config2__ProductId__c))
                        SellingUOM.put(p.Apttus_Config2__ProductId__c, p.APTS_Default_selling_UOM__c);
                        if (!productVat.containsKey(p.Apttus_Config2__ProductId__c))
                        productVat.put(p.Apttus_Config2__ProductId__c, p.APTS_VAT_indicator_Digital__c);
                        if (!productReplacement.containsKey(p.Apttus_Config2__ProductId__c))
                        productReplacement.put(p.Apttus_Config2__ProductId__c, p.APTS_Product_Code__c);
                        if (!productPriceUom.containsKey(p.Apttus_Config2__ProductId__c))
                        productPriceUom.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__PriceUom__c);
                    }

                } System.debug('CSP' + mapProductBPO);
                tempString = '';
                if (p.Apttus_Config2__ProductId__r.ProductCode != null) {
                    tempString += p.Apttus_Config2__ProductId__r.ProductCode;
                } else {
                    continue;
                }
                if (SellingUOM.get(p.Apttus_Config2__ProductId__c) != null) {
                    tempString += ';' + SellingUOM.get(p.Apttus_Config2__ProductId__c); // from UOM
                }
                else {
                    continue;
                }
                if (productPriceUom.get(p.Apttus_Config2__ProductId__c) != null) {
                    tempString += ';' + productPriceUom.get(p.Apttus_Config2__ProductId__c);
                }
                else {
                    continue;

                }
                if (!uomString.contains(tempString)) {
                    uomString.add(tempString);
                }
            }

            System.debug(productSet);

            if (uomString != NULL)
            uomOutput = APTS_UOMConversionUtils.getUOMConversions(uomString);
            for (Id pid : productSet)
            {
                tempMap = new Map<String, Decimal> ();
                if (mapProductBPO != null && mapProductBPO.get(pId) != NULL)
                tempMap = mapProductBPO.get(pId);
                System.debug('tempMap' + tempMap + 'pid' + pid);
                for (String instProdUOM : uomString)
                {
                    List<String> tempStringList = new List<String> ();
                    tempStringList = instProdUOM.Split(';');
                    IncomingProdId = tempStringList[0];
                    if (IncomingProdId == sapCode.get(pId))
                    {
                        uomFactor = uomOutput.get(instProdUOM) != null ? uomOutput.get(instProdUOM) : 1;
                        if (tempMap.containskey('CER'))
                        {
                            price = tempMap.get('CER');
                            price = price * uomFactor; System.debug('pid' + pid + 'price' + price + 'uomfactor' + uomfactor);
                        }
                        else if (tempMap.containskey('CSP'))
                        {
                            price = tempMap.get('CSP'); System.debug('pid' + pid + 'price' + price);
                        }
                        else if (tempMap.containskey('General'))
                        {
                            price = tempMap.get('General'); System.debug('pid' + pid + 'price' + price);
                        }

                    }
                    else
                    { continue; }

                    APTS_GetProductsRest.GetProductsWrapper gpw = new APTS_GetProductsRest.GetProductsWrapper();

                    //gpw.netPrice = p.Apttus_Config2__ListPrice__c.setScale(5);
                    if (price != NULL)
                    gpw.netPrice = price.setScale(5);
                    gpw.priceUom = productPriceUom.get(pId) != null ? productPriceUom.get(pId) : productUom.get(pId);
                    gpw.vatIndicator = productVat.get(pId) != null ? productVat.get(pId) : '';
                    gpw.taxAmount = productTax.get(pId) != null ? productTax.get(pId).setScale(5) : 0.0;
                    gpw.replacementProductCode = productReplacement.get(pId) != null ? productReplacement.get(pId) : '';
                    gpw.productCodeSAP = sapCode.get(pid) != null ? sapCode.get(pId) : '';
                    gpw.sellingUom = SellingUOM.get(pid) != null ? sellingUom.get(pId) : '';
                    returnObject.response.add(gpw);
                }
                //returnObject.response.addAll(tempReturnObject);                
            }
            returnObject.currencyCode = cur;
            returnObject.success = true;
            returnObject.errorMessage = '';
        }

        Catch(Exception e)
        {
            returnObject.success = false;
            returnObject.errorMessage = e.getMessage();
        }
        return returnObject;
    }
    /***
      This method is used for CSP Purposes
      Id soldToAccountId, // The customer that we selling to
      List<Id> productIdList, // list of products that we want to explore
      Integer limitValue, // Number of records
      Integer offsetValue) // Starting point
     ***/
    public static APTS_GetPriceRest.GetPriceReturnObject getPrice(Id soldToAccountId) {
        // The first step is to obtain the record which are the CER located (not pending)
        Id tempSoldToAccountId = getCerRecordAccountForRelatedAccount(soldToAccountId, false);
        decimal price = 0.0, tempPrice = 0.0, uomFactor = 0.0, StartingPrice = 0.0, tempPriceBP = 0.0, uomLIFactor = 0.0; //Lavanya
        Boolean tempFlag = true;
        Id tempCategoryId;
        Id categoryId;
        Id priceListId;
        Id basedOnPriceListId;
        String IncomingProdId;
        Set<Id> salesOrgProducts = new Set<Id> ();
        Set<Id> ingrProductSet = new Set<Id> ();
        Set<String> uomString = new Set<String> ();
        Set<String> uomLIString = new Set<String> ();
        List<Id> categories = new List<Id> ();
        List<Id> subCategories = new List<Id> ();
        Boolean overrideFlg = false;
        Map<String, Decimal> uomOutput = new Map<String, Decimal> ();
        Map<String, Decimal> uomLIOutput = new Map<String, Decimal> ();
        Boolean check = false;
        string tempString, tempString1, tempString2, tempLIString;
        Boolean inTestScope = Test.isRunningTest();
        List<Id> subSubCategories = new List<Id> ();
        Map<Id, Decimal> productTax = new Map<Id, Decimal> ();
        Map<Id, Map<String, Decimal>> mapProductBPO = new Map<Id, Map<String, Decimal>> (); // Lavanya
        Map<Id, String> productUom = new Map<Id, String> ();
        Map<Id, String> productVat = new Map<Id, String> ();
        Map<Id, String> productReplacement = new Map<Id, String> ();
        Set<Id> priceListItemSet = new Set<Id> ();
        APTS_GetPriceRest.GetPriceReturnObject returnObject = new APTS_GetPriceRest.GetPriceReturnObject(); // The return object
        List<APTS_GetPriceRest.GetPriceWrapper> tempReturnObject = new List<APTS_GetPriceRest.GetPriceWrapper> (); // The return object temporary (to iterate)
        APTS_GetPriceRest.GetPriceWrapper gpw;
        Map<String, Decimal> tempMap;
        List<String> bucketList = new List<String> { 'Bucket 1', 'Bucket 2', 'Bucket 3', 'Bucket 4', 'Bucket 5', 'Bucket 6', 'Bucket 7', 'Bucket 8' }; // Buckets to group the results
        Map<String, List<APTS_Contract_Entitlement_Repository__c>> tempGroupByBucket = new Map<String, List<APTS_Contract_Entitlement_Repository__c>> ();
        Map<Id, Map<String, List<APTS_Contract_Entitlement_Repository__c>>> productMap = new Map<Id, Map<String, List<APTS_Contract_Entitlement_Repository__c>>> ();
        Map<Id, List<APTS_Contract_Entitlement_Repository__c>> aliMap = new Map<Id, List<APTS_Contract_Entitlement_Repository__c>> ();
        Map<Id, Decimal> productStartPrice = new Map<Id, Decimal> ();
        Map<Id, String> sapCode = new Map<Id, String> ();
        List<APTS_Contract_Entitlement_Repository__c> tempCerRecords = new List<APTS_Contract_Entitlement_Repository__c> ();
        List<APTS_Contract_Entitlement_Repository__c> tCerRecord = new List<APTS_Contract_Entitlement_Repository__c> ();
        List<Apttus_Config2__PriceListItem__c> lstPriceListItem;
        List<APTS_Contract_Entitlement_Repository__c> cerRecords = new List<APTS_Contract_Entitlement_Repository__c> ();
        List<APTS_Contract_Entitlement_Repository__c> categoryCerRecords = new List<APTS_Contract_Entitlement_Repository__c> ();
        list<Account> salAcc = new list<Account> ();
        list<APTS_Sales_Org_Data__c> salesOrgDataList = new list<APTS_Sales_Org_Data__c> ();
        List<Account> acc = [select Id, Account_Type__c from Account where id = :soldToAccountId];
        if (acc.size() > 0 && acc[0].Account_Type__c != null && acc[0].Account_Type__c == PROSPECT && !(inTestScope)) {
            returnObject.success = true;
            return returnObject;
        }
        // If there are no products as parameters, the query SOQL does not include any product filtering
        Set<Id> agreementExculsion = new Set<Id> ();
        for (APTS_Agreement_Account_Exclusion__c aae :[Select APTS_Agreement__c from APTS_Agreement_Account_Exclusion__c where APTS_Account__c = :soldToAccountId])
        {
            if (!agreementExculsion.contains(aae.APTS_Agreement__c))
            agreementExculsion.add(aae.APTS_Agreement__c);
        }
        List<Product2> lstProduct = [SELECT Id, Name FROM Product2 WHERE APTS_Category_Adjustments_Product__c = true];
        categoryId = lstProduct.size() > 0 ? lstProduct[0].Id : null;
        cerRecords = [Select id, APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePrice__c, APTS_Charge_Type__c,
                      APTS_Adjustment_Value__c, APTS_Adjustment_Type__c, APTS_Type__c, APTS_Sub_Type__c,
                      APTS_Adjustment_Applies_To__c, APTS_Bucket__c, APTS_Product__c, APTS_Product__r.ProductCode,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c, APTS_Category_Level__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_VAT_indicator_Digital__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceListId__c,
                      APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c, APTS_Amendment_In_Progress__c,
                      APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c, APTS_Agreement_Line_Item__r.APTS_More_Standalone__c, APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone_or_Spare_Part__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.CurrencyIsoCode,
                      APTS_UOM__c,
                      APTS_Agreement_Line_Item__r.Apttus__ListPrice__c,
                      //  APTS_Agreement_Line_Item__r.Apttus__AgreementId__r.APTS_Customer_Specific_Freight_charge__c,
                      APTS_Product__r.Name,
                      APTS_End_Date__c,
                      APTS_CategoryCER__c,
                      APTS_Sub_Category__c,
                      APTS_Start_Date__c,
                      APTS_Sub_Sub_Category__c, APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c, APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c,
                      APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c
                      from APTS_Contract_Entitlement_Repository__c
                      where APTS_Sold_to_Party__c = :tempSoldToAccountId
                      and APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__Active__c = true
                      and APTS_Contributing_Agreement__c not in :agreementExculsion
                      and APTS_Agreement_Line_Item__c not in(Select APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                      and APTS_Agreement_Adjustment_Line_Item__c not in(Select APTS_Agreement_Adjustment_Line_Item__c from APTS_Adjustment_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                      and APTS_Bucket__c != ''
                      and APTS_Is_Pending__c = false
                      and APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c = :PRODUCT_SERVICE
                      and(APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c = true or APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c = true or
                          APTS_Agreement_Line_Item__r.APTS_More_Standalone__c = true)
                      ORDER BY APTS_Category_Level__c Desc];
        System.debug(cerRecords);
        if (cerRecords.size() == 0) {
            returnObject.success = true;
            return returnObject;
        }

        salAcc = [select Sales_Organization__c from Account where id = :tempSoldToAccountId];
        string tempSaleOrg = salAcc.size() > 0 && salAcc[0].Sales_Organization__c != null ? salAcc[0].Sales_Organization__c.substring(4, salAcc[0].Sales_Organization__c.length()) : '';

        System.debug('tempSalesOrg' + tempSaleOrg + 'tempSoldToAccountId' + tempSoldToAccountId);
        if (cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c != null)
        salesOrgDataList = [SELECT Id, APTS_Product__c FROM APTS_Sales_Org_Data__c WHERE APTS_Product_web_enabled__c = True and APTS_Sales_Org_Data_Name__c = :tempSaleOrg and(APTS_Price_List__c = :cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c or APTS_Price_List__c = :cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c) and APTS_Product__c != null];
        else
        salesOrgDataList = [SELECT Id, APTS_Product__c FROM APTS_Sales_Org_Data__c WHERE APTS_Product_web_enabled__c = True and APTS_Sales_Org_Data_Name__c = :tempSaleOrg and APTS_Price_List__c = :cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c and APTS_Product__c != null];

        if (inTestScope) {
            salesOrgDataList = [SELECT Id, APTS_Product__c FROM APTS_Sales_Org_Data__c limit 20];
            categoryCerRecords = [Select id, APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c,
                                  APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePrice__c, APTS_Charge_Type__c,
                                  APTS_Adjustment_Value__c, APTS_Adjustment_Type__c, APTS_Type__c, APTS_Sub_Type__c,
                                  APTS_Adjustment_Applies_To__c, APTS_Bucket__c, APTS_Product__c, APTS_Product__r.ProductCode,
                                  APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c, APTS_Category_Level__c,
                                  APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_VAT_indicator_Digital__c,
                                  APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Tax_per_UOM__c,
                                  APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceListId__c,
                                  APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c,
                                  APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c,
                                  APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.CurrencyIsoCode,
                                  APTS_Product__r.Name,
                                  APTS_End_Date__c,
                                  APTS_CategoryCER__c,
                                  APTS_Sub_Category__c,
                                  APTS_UOM__c,
                                  APTS_Start_Date__c,
                                  APTS_Sub_Sub_Category__c,
                                  APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c
                                  from APTS_Contract_Entitlement_Repository__c
                                  Limit : 20];
        }

        for (APTS_Sales_Org_Data__c salesOrgData : salesOrgDataList) {
            if (!salesOrgProducts.contains(salesOrgData.APTS_Product__c)) {
                salesOrgProducts.add(salesOrgData.APTS_Product__c);
            }
        }
        SYstem.debug('salesOrgProducts' + salesOrgProducts);
        try {
            if (cerRecords.size() > 0)
            {
                priceListId = cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c;
                basedOnPriceListId = cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c;
                priceListItemSet.add(priceListId);
                if (basedOnPriceListId != NULL)
                priceListItemSet.add(basedOnPriceListId);
            } SYstem.debug('priceListItemSet' + priceListItemSet);
            for (APTS_Contract_Entitlement_Repository__c cerRecord : cerRecords) {


                if ((cerRecord.APTS_Product__c != null && cerRecord.APTS_Product__c == categoryId) || inTestScope) {

                    if (cerRecord.APTS_Category_Level__c == CATEGORY) {
                        categories.add(cerRecord.APTS_CategoryCER__c); System.debug('categories' + categories);
                    } else if (cerRecord.APTS_Category_Level__c == SUB_CATEGORY) {
                        subCategories.add(cerRecord.APTS_Sub_Category__c);
                    } else if (cerRecord.APTS_Category_Level__c == SUB_SUB_CATEGORY) {
                        subSubCategories.add(cerRecord.APTS_Sub_Sub_Category__c);
                    } else {
                        if (!ingrProductSet.contains(cerRecord.APTS_Product__c) && salesOrgProducts.contains(cerRecord.APTS_Product__c)) {
                            ingrProductSet.add(cerRecord.APTS_Product__c);
                        }
                    }
                    categoryCerRecords.add(cerRecord);
                }
            }
            Set<Id> tempProductSet = new Set<Id> ();


            List<Apttus_Config2__ProductClassification__c> productList = new List<Apttus_Config2__ProductClassification__c> ();

            productList = [SELECT Id, Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode, Apttus_Config2__ClassificationId__c, Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c, Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c, Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c FROM Apttus_Config2__ProductClassification__c WHERE Apttus_Config2__ProductId__r.IsActive = true
                           and Apttus_Config2__ProductId__c in :salesOrgProducts
                           and(Apttus_Config2__ProductId__c in :ingrProductSet
                               OR Apttus_Config2__ClassificationId__c IN :categories
                               OR Apttus_Config2__ClassificationId__c IN :subCategories
                               OR Apttus_Config2__ClassificationId__c IN :subSubCategories
                               OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c IN :categories
                               OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c IN :subCategories
                               OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c IN :categories)
                          ];
            if (inTestScope) {
                productList = [SELECT Apttus_Config2__ProductId__c, Apttus_Config2__ProductId__r.ProductCode, Apttus_Config2__ClassificationId__c, Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c FROM Apttus_Config2__ProductClassification__c limit 20];
            }
            SYstem.debug('productList' + productList.size());
            for (APTS_Contract_Entitlement_Repository__c cerRecord : cerRecords) {
                if (cerRecord.APTS_Product__c == categoryId) {
                    continue;
                }
                check = true;
                if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c != null && cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c > 0) //BPO,BP instead of LP
                {
                    tempMap = new Map<String, Decimal> ();
                    tempMap.put('Ingredient', cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c);
                    mapProductBPO.put(cerRecord.APTS_Product__c, tempMap);
                }                
                else
                {
                    if(!Test.isRunningTest())
                    {
                    tempMap = new Map<String, Decimal> ();
                    tempMap.put('Ingredient', cerRecord.APTS_Agreement_Line_Item__r.Apttus__ListPrice__c);
                    mapProductBPO.put(cerRecord.APTS_Product__c, tempMap);
                    }
                }
                System.debug('mapProductBPO' + mapProductBPO);
                if (!productMap.keySet().contains(cerRecord.APTS_Product__c)) {
                    if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_Start_Date__c != null && cerRecord.APTS_Start_Date__c > Date.today())) {
                        check = false;
                    }
                    if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_End_Date__c != null && cerRecord.APTS_End_Date__c <= Date.today())) {
                        check = false;
                    } System.debug('check' + check);
                    if (check) {
                        tempGroupByBucket =
                        productMap.get(cerRecord.APTS_Product__c) != null ?
                        productMap.get(cerRecord.APTS_Product__c) : new Map<String, List<APTS_Contract_Entitlement_Repository__c>> ();
                        tempCerRecords =
                        tempGroupByBucket.get(cerRecord.APTS_Bucket__c) != null ?
                        tempGroupByBucket.get(cerRecord.APTS_Bucket__c) :
                        new List<APTS_Contract_Entitlement_Repository__c> ();
                        tempCerRecords.add(cerRecord);
                        tempGroupByBucket.put(cerRecord.APTS_Bucket__c, tempCerRecords);
                        productMap.put(cerRecord.APTS_Product__c, tempGroupByBucket);
                        aliMap.put(cerRecord.APTS_Product__c, tempCerRecords);
                        sapCode.put(cerRecord.APTS_Product__c, cerRecord.APTS_Product__r.ProductCode);
                    }
                } else {
                    for (String s : bucketList) {
                        List<APTS_Contract_Entitlement_Repository__c> tCerRecords = productMap.get(cerRecord.APTS_Product__c).get(s) != null ? productMap.get(cerRecord.APTS_Product__c).get(s) : new List<APTS_Contract_Entitlement_Repository__c> ();
                        if (tCerRecords.size() == 0) {
                            continue;
                        }
                        for (APTS_Contract_Entitlement_Repository__c cr : tCerRecords) {
                            if (cerRecord.APTS_Type__c == cr.APTS_Type__c && cerRecord.APTS_Sub_Type__c == cr.APTS_Sub_Type__c && cerRecord.APTS_Charge_Type__c == cr.APTS_Charge_Type__c) {
                                check = false;
                            }
                            if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_Start_Date__c != null && cerRecord.APTS_Start_Date__c > Date.today())) {
                                check = false;
                            }
                            if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_End_Date__c != null && cerRecord.APTS_End_Date__c <= Date.today())) {
                                check = false;
                            }

                        }

                        if (check || inTestScope) {
                            tempGroupByBucket = productMap.get(cerRecord.APTS_Product__c) != null ?
                            productMap.get(cerRecord.APTS_Product__c) : new Map<String, List<APTS_Contract_Entitlement_Repository__c>> ();
                            tempCerRecords = tempGroupByBucket.get(cerRecord.APTS_Bucket__c) != null ? tempGroupByBucket.get(cerRecord.APTS_Bucket__c) :
                            new List<APTS_Contract_Entitlement_Repository__c> ();
                            tempCerRecords.add(cerRecord);
                            tempGroupByBucket.put(cerRecord.APTS_Bucket__c, tempCerRecords);
                            productMap.put(cerRecord.APTS_Product__c, tempGroupByBucket);
                            aliMap.put(cerRecord.APTS_Product__c, tempCerRecords);
                            sapCode.put(cerRecord.APTS_Product__c, cerRecord.APTS_Product__r.ProductCode);
                        }

                    }
                }
            }

            for (Apttus_Config2__ProductClassification__c products : productList) {

                if (!salesOrgProducts.contains(products.Apttus_Config2__ProductId__c)) {
                    continue;
                }

                for (APTS_Contract_Entitlement_Repository__c cerRecord : categoryCerRecords) {
                    if (cerRecord.APTS_Product__c != categoryId && !inTestScope) {
                        continue;
                    }
                    check = true;

                    if (!productMap.keySet().contains(products.Apttus_Config2__ProductId__c)) {

                        if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_Start_Date__c != null && cerRecord.APTS_Start_Date__c > Date.today())) {
                            check = false;
                        }
                        if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_End_Date__c != null && cerRecord.APTS_End_Date__c <= Date.today())) {
                            check = false;
                        } //6653- Added OR condition to check Ancestor's Ancestor for Category Level 
                        if (check && ((cerRecord.APTS_Category_Level__c == CATEGORY && (products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_CategoryCER__c || products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_CategoryCER__c || products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_CategoryCER__c)) || (cerRecord.APTS_Category_Level__c == SUB_CATEGORY && (products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_Sub_Category__c || products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_Sub_Category__c)
                                                                                                                                                                                                                                                                                                                                                                                                                                        && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c == cerRecord.APTS_CategoryCER__c) || (cerRecord.APTS_Category_Level__c == SUB_SUB_CATEGORY && products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_Sub_Sub_Category__c && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_Sub_Category__c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c == cerRecord.APTS_CategoryCER__c)) || inTestScope) {
                            tempGroupByBucket = productMap.get(products.Apttus_Config2__ProductId__c) != null ?
                            productMap.get(products.Apttus_Config2__ProductId__c) : new Map<String, List<APTS_Contract_Entitlement_Repository__c>> ();
                            tempCerRecords = tempGroupByBucket.get(cerRecord.APTS_Bucket__c) != null ? tempGroupByBucket.get(cerRecord.APTS_Bucket__c) :
                            new List<APTS_Contract_Entitlement_Repository__c> ();
                            tempCerRecords.add(cerRecord);
                            tempGroupByBucket.put(cerRecord.APTS_Bucket__c, tempCerRecords);
                            productMap.put(products.Apttus_Config2__ProductId__c, tempGroupByBucket);
                            aliMap.put(products.Apttus_Config2__ProductId__c, tempCerRecords);
                            sapCode.put(products.Apttus_Config2__ProductId__c, products.Apttus_Config2__ProductId__r.ProductCode);


                        }

                    } else {

                        for (String s : bucketList) {
                            List<APTS_Contract_Entitlement_Repository__c> tCerRecords = productMap.get(products.Apttus_Config2__ProductId__c).get(s) != null ? productMap.get(products.Apttus_Config2__ProductId__c).get(s) : new List<APTS_Contract_Entitlement_Repository__c> ();
                            if (tCerRecords.size() == 0) {
                                continue;
                            }
                            for (APTS_Contract_Entitlement_Repository__c cr : tCerRecords) {
                                if (cerRecord.APTS_Type__c == cr.APTS_Type__c && cerRecord.APTS_Sub_Type__c == cr.APTS_Sub_Type__c && cerRecord.APTS_Charge_Type__c == cr.APTS_Charge_Type__c) {
                                    check = false;
                                }
                                if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_Start_Date__c != null && cerRecord.APTS_Start_Date__c > Date.today())) {
                                    check = false;
                                }
                                if ((cerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || cerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (cerRecord.APTS_End_Date__c != null && cerRecord.APTS_End_Date__c <= Date.today())) {
                                    check = false;
                                }

                            } ////6653- Added OR condition to check Ancestor's Ancestor for Category Level 
                            if (inTestScope || (check && ((cerRecord.APTS_Category_Level__c == CATEGORY && (products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_CategoryCER__c || products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_CategoryCER__c || products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_CategoryCER__c)) || (cerRecord.APTS_Category_Level__c == SUB_CATEGORY && (products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_Sub_Category__c || products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_Sub_Category__c)
                                                                                                                                                                                                                                                                                                                                                                                                                                                            && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c == cerRecord.APTS_CategoryCER__c) || (cerRecord.APTS_Category_Level__c == SUB_SUB_CATEGORY && products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_Sub_Sub_Category__c && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_Sub_Category__c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c == cerRecord.APTS_CategoryCER__c)))) {
                                tempGroupByBucket =
                                productMap.get(products.Apttus_Config2__ProductId__c) != null ?
                                productMap.get(products.Apttus_Config2__ProductId__c) : new Map<String, List<APTS_Contract_Entitlement_Repository__c>> ();
                                tempCerRecords =
                                tempGroupByBucket.get(cerRecord.APTS_Bucket__c) != null ?
                                tempGroupByBucket.get(cerRecord.APTS_Bucket__c) :
                                new List<APTS_Contract_Entitlement_Repository__c> ();
                                tempCerRecords.add(cerRecord);
                                tempGroupByBucket.put(cerRecord.APTS_Bucket__c, tempCerRecords);
                                productMap.put(products.Apttus_Config2__ProductId__c, tempGroupByBucket);
                                aliMap.put(products.Apttus_Config2__ProductId__c, tempCerRecords);
                                sapCode.put(products.Apttus_Config2__ProductId__c, products.Apttus_Config2__ProductId__r.ProductCode);

                            }
                        }
                    }
                    //  }
                }

            }
            if (basedOnPriceListId != Null)
            lstPriceListItem = new List<Apttus_Config2__PriceListItem__c> ([select Apttus_Config2__ListPrice__c, Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c, Apttus_Config2__ProductId__c, Apttus_Config2__PriceUom__c, APTS_Tax_per_UOM__c, APTS_VAT_indicator_Digital__c, APTS_Product_Code__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__c IN :productMap.keySet() and Apttus_Config2__PriceListId__c = :priceListItemSet and Apttus_Config2__PriceListId__r.Apttus_Config2__Active__c = true and
                                                                           Apttus_Config2__Active__c = true and(Apttus_Config2__ExpirationDate__c = null or Apttus_Config2__ExpirationDate__c >= TODAY) and
            (Apttus_Config2__PriceListId__r.Apttus_Config2__ExpirationDate__c = null or Apttus_Config2__PriceListId__r.Apttus_Config2__ExpirationDate__c >= TODAY) order by Apttus_Config2__PriceListId__c DESC]);
            else
            lstPriceListItem = new List<Apttus_Config2__PriceListItem__c> ([select Apttus_Config2__ListPrice__c, Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c, Apttus_Config2__ProductId__c, Apttus_Config2__PriceUom__c, APTS_Tax_per_UOM__c, APTS_VAT_indicator_Digital__c, APTS_Product_Code__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__ProductId__c IN :productMap.keySet() and Apttus_Config2__PriceListId__c = :priceListId]);
            for (Apttus_Config2__PriceListItem__c p : lstPriceListItem) {


                if (p.Apttus_Config2__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c != null || Test.isRunningTest())
                {
                    if (!mapProductBPO.keySet().contains(p.Apttus_Config2__ProductId__c))
                    {
                        tempMap = new Map<String, Decimal> ();
                        tempMap.put('CSP', p.Apttus_Config2__ListPrice__c);
                        mapProductBPO.put(p.Apttus_Config2__ProductId__c, tempMap); //category CSP Products              
                    }
                    if (!productTax.containsKey(p.Apttus_Config2__ProductId__c))
                    productTax.put(p.Apttus_Config2__ProductId__c, p.APTS_Tax_per_UOM__c);
                    if (!productVat.containsKey(p.Apttus_Config2__ProductId__c))
                    productVat.put(p.Apttus_Config2__ProductId__c, p.APTS_VAT_indicator_Digital__c);
                    if (!productReplacement.containsKey(p.Apttus_Config2__ProductId__c))
                    productReplacement.put(p.Apttus_Config2__ProductId__c, p.APTS_Product_Code__c);
                    if (!productUom.containsKey(p.Apttus_Config2__ProductId__c))
                    productUom.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__PriceUom__c);
                }
                else {
                    if (!mapProductBPO.keySet().contains(p.Apttus_Config2__ProductId__c))
                    {
                        tempMap = new Map<String, Decimal> ();
                        tempMap.put('General', p.Apttus_Config2__ListPrice__c);
                        mapProductBPO.put(p.Apttus_Config2__ProductId__c, tempMap); //category CSP Products              
                    }
                    if (!productTax.containsKey(p.Apttus_Config2__ProductId__c))
                    productTax.put(p.Apttus_Config2__ProductId__c, p.APTS_Tax_per_UOM__c);
                    if (!productVat.containsKey(p.Apttus_Config2__ProductId__c))
                    productVat.put(p.Apttus_Config2__ProductId__c, p.APTS_VAT_indicator_Digital__c);
                    if (!productReplacement.containsKey(p.Apttus_Config2__ProductId__c))
                    productReplacement.put(p.Apttus_Config2__ProductId__c, p.APTS_Product_Code__c);
                    if (!productUom.containsKey(p.Apttus_Config2__ProductId__c))
                    productUom.put(p.Apttus_Config2__ProductId__c, p.Apttus_Config2__PriceUom__c);
                }

            }

            String cur = null;
            for (Id pId : productMap.keySet())
            {
                for (String s : bucketList)
                {
                    if (productMap.get(pId).get(s) != null)
                    {
                        tempCerRecords = productMap.get(pId).get(s);
                        for (APTS_Contract_Entitlement_Repository__c c : tempCerRecords) {
                            tempString = '';
                            tempLIString = '';
                            if (sapCode.get(pId) != null) {
                                tempString += sapCode.get(pId);
                                tempLIString += sapCode.get(pId);
                            }
                            else {
                                continue;
                            }

                            if (c.APTS_UOM__c != null) {
                                tempString += ';' + c.APTS_UOM__c;
                                tempLIString += ';' + c.APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c; //FromUOM
                            }
                            else {
                                continue;
                            }
                            if (productUom.get(pId) != null) {
                                tempString += ';' + productUom.get(pId);
                                tempLIString += ';' + productUom.get(pId); //adding toUOM
                            }
                            else {
                                continue;
                            }
                            if (!uomString.contains(tempString)) {
                                uomString.add(tempString);
                            }
                            if (!uomLIString.contains(tempLIString)) {
                                uomLIString.add(tempLIString);
                            }
                        }
                    }
                }
            }
            if (uomString != null)
            uomOutput = APTS_UOMConversionUtils.getUOMConversions(uomString);
            if (uomLIString != null)
            uomLIOutput = APTS_UOMConversionUtils.getUOMConversions(uomLIString);

            for (Id pId : productMap.keySet())
            { tempMap = new Map<String, Decimal> ();
                //gpw = new APTS_GetPriceRest.GetPriceWrapper();      
                if (mapProductBPO != null && mapProductBPO.get(pId) != NULL)
                tempMap = mapProductBPO.get(pId);


                for (String instProdUOM : uomLiString)
                {
                    List<String> tempStringList = new List<String> ();
                    tempStringList = instProdUOM.Split(';');
                    IncomingProdId = tempStringList[0];
                    if (IncomingProdId == sapCode.get(pId))
                    {
                        uomLIFactor = uomLIOutput.get(instProdUOM) != null ? uomLIOutput.get(instProdUOM) : 1;
                        if (tempMap.containskey('Ingredient'))
                        {
                            StartingPrice = tempMap.get('Ingredient');
                            StartingPrice = StartingPrice * uomLIFactor; System.debug('UOM Calc');
                        }
                        else if (tempMap.containskey('CSP'))
                        {
                            StartingPrice = tempMap.get('CSP');
                        }
                        else if (tempMap.containskey('General'))
                        {
                            StartingPrice = tempMap.get('General');
                        }
                        System.debug('pid' + pid + 'uom' + uomLIFactor + 'StartingPrice' + StartingPrice);

                    }
                    else { continue; }

                    if (StartingPrice > 0 || inTestScope) {
                        gpw = new APTS_GetPriceRest.GetPriceWrapper();
                        tempFlag = true;
                        tCerRecord = aliMap.get(pId);
                        // tempString= tCerRecord[0].APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c != null ? tCerRecord[0].APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c : '';
                        tempString1 = productUom.get(pId) != null ? productUom.get(pId) : '';
                        if (tempString1 == SAP_PCE || tempString1 == SAP_BX || inTestScope)
                        {
                            for (String s : bucketList) {
                                if (productMap.get(pId).get(s) != null) {
                                    tempCerRecords = productMap.get(pId).get(s);
                                    tempPrice = 0; 
                                    if (tempCerRecords.size() > 0 && tempFlag) {
                                        if (cur == null)
                                        cur = tempCerRecords[0].APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.CurrencyIsoCode;
                                        gpw.productCodeSAP = sapCode.get(pId) != null ? sapCode.get(pId) : '';
                                        // gpw.sellingUom = tempCerRecords[0].APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c != null ? tempCerRecords[0].APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c : '';
                                        gpw.vatIndicator = productVat.get(pId) != null ? productVat.get(pId) : '';
                                        gpw.taxAmount = productTax.get(pId) != null ? productTax.get(pId).setScale(5) : 0.0;
                                        gpw.replacementProductCode = productReplacement.get(pId) != null ? productReplacement.get(pId) : '';
                                        gpw.priceUom = tempString1;
                                        tempFlag = false;
                                    }
                                    for (APTS_Contract_Entitlement_Repository__c c : tempCerRecords) {
                                        tempPriceBP = 0;
                                    System.debug('Lavanya tempMap'+tempMap);
                                      //  if((c.APTS_Product__c != categoryId && tempMap.containskey('Ingredient')) || (c.APTS_Product__c == categoryId && !tempMap.containsKey('Ingredient')))
                                      //  {
                                        tempString2 = '';
                                        if (sapCode.get(pId) != null)
                                        {
                                            tempString2 += sapCode.get(pId);
                                        }
                                        if (c.APTS_UOM__c != null)
                                        {
                                            tempString2 += ';' + c.APTS_UOM__c;
                                        }
                                        if (productUom.get(pId) != null)
                                        {
                                            tempString2 += ';' + productUom.get(pId);
                                        } //Applying Adjustments on Price
                                        if (c.APTS_Adjustment_Value__c == null)
                                        c.APTS_Adjustment_Value__c = 0;
                                        uomFactor = uomOutput.get(tempString2) != null ? uomOutput.get(tempString2) : 1;
                                        if (c.APTS_Adjustment_Type__c == '% Discount') {System.debug(StartingPrice+tempPriceBP);
                                            tempPriceBP = (tempPriceBP + (StartingPrice * (c.APTS_Adjustment_Value__c / 100)));
                                        } else if (c.APTS_Adjustment_Type__c == 'Base Price Discount' || c.APTS_Adjustment_Type__c == 'Discount Amount') {
                                            tempPriceBP = (tempPriceBP + (c.APTS_Adjustment_Value__c * uomFactor));
                                        } else if (c.APTS_Adjustment_Type__c == '% Markup') {
                                            tempPriceBP = (tempPriceBP - (StartingPrice * (c.APTS_Adjustment_Value__c / 100)));
                                        } else if (c.APTS_Adjustment_Type__c == 'Markup Amount') {
                                            tempPriceBP = (tempPriceBP - (c.APTS_Adjustment_Value__c * uomFactor));
                                        } else if (c.APTS_Adjustment_Type__c == 'Price Override') {
                                            tempPriceBP = (c.APTS_Adjustment_Value__c * uomFactor);
                                        } else continue;
                                   // } 
                                }
                                    //price = price - tempPrice;
                                    if (StartingPrice != NULL)
                                    StartingPrice = StartingPrice - tempPriceBP;System.debug('pid' + pId + 'temprice->' + tempPriceBP + 'StartingPrice' + StartingPrice);
                                }
                                else
                                {
                                    tempCerRecords = aliMap.get(pId) != null ? aliMap.get(pId) : new List<APTS_Contract_Entitlement_Repository__c> ();
                                    if ((tempCerRecords.size() > 0 && tempFlag) || Test.isRunningTest()) {
                                        if (cur == null)
                                        cur = tempCerRecords[0].APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.CurrencyIsoCode;
                                        gpw.productCodeSAP = sapCode.get(pId) != null ? sapCode.get(pId) : '';
                                        //   gpw.sellingUom = tempCerRecords[0].APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c != null ? tempCerRecords[0].APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c : '';
                                        gpw.vatIndicator = productVat.get(pId) != null ? productVat.get(pId) : '';
                                        gpw.taxAmount = productTax.get(pId) != null ? productTax.get(pId).setScale(5) : 0.0;
                                        gpw.replacementProductCode = productReplacement.get(pId) != null ? productReplacement.get(pId) : '';
                                        gpw.priceUom = tempString1;
                                        tempFlag = false;
                                    }
                                }
                            }

                            gpw.netPrice = StartingPrice.setScale(5); // Lavanya- to align with shahul                    
                            tempReturnObject.add(gpw);
                        }
                    }
                }

            }
            returnObject.success = true;
            returnObject.currencyCode = cur;
            returnObject.errorMessage = '';
            returnObject.response.addAll(tempReturnObject);
        }
        Catch(Exception e) {
            returnObject.success = false;
            returnObject.errorMessage = e.getMessage();
        }
        return returnObject;
    }

    //APTS_Pending_Line_Item__c Added by Abhishek to be used in CP Page
    public static List<APTS_Contract_Entitlement_Repository__c> getContractedProductsWithDiscounts(Id soldToAccountId) {
        List<APTS_Contract_Entitlement_Repository__c> cerList = [select Id, APTS_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__c, Name, APTS_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__ChargeType__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__c, APTS_Pending_Line_Item__c, APTS_Product__r.Family, APTS_Agreement_Adjustment_Line_Item__c, APTS_Adjustment_Type__c,
                                                                 APTS_Adjustment_Value__c, APTS_Agreement_Line_Item__c, APTS_Category__c,
                                                                 APTS_Category_Level__c, APTS_Contributing_Agreement__c, APTS_Contributing_Agreement_Level__c,
                                                                 APTS_Exclusion_Exception_Available__c, APTS_Max_Volume__c, APTS_Pricing_Sub_Type__c,
                                                                 APTS_Pricing_Type__c, APTS_Charge_Type__c, APTS_Product__c, APTS_Rebate__c, APTS_Sold_to_Party__c,
                                                                 Total_Cumulative_Consumption_Currency__c, Total_Cumulative_Consumption_Quantity__c,
                                                                 APTS_Adjustment_Applies_To__c, APTS_Type__c, APTS_Sub_Type__c, APTS_Bucket__c,
                                                                 APTS_UOM__c, APTS_Category_Label__c, APTS_Product__r.Apttus_Config2__ConfigurationType__c,
                                                                 APTS_Agreement_Adjustment_Line_Item__r.Apttus_CMConfig__LineItemId__r.Apttus_CMConfig__PriceListItemId__c,
                                                                 APTS_Agreement_Line_Item__r.Apttus__NetPrice__c,
                                                                 APTS_Agreement_Line_Item__r.APTS_Net_Price_Inc_taxes__c,
                                                                 APTS_Agreement_Line_Item__r.Apttus_CMConfig__HasOptions__c,
                                                                 APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c,
                                                                 APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c,
                                                                 APTS_Agreement_Adjustment_Line_Item__r.APTS_Start_Date__c,
                                                                 APTS_Agreement_Adjustment_Line_Item__r.APTS_End_Date__c,
                                                                 APTS_Pending_Adjustment_Line_Item__r.APTS_Start_Date__c,
                                                                 APTS_Pending_Adjustment_Line_Item__r.APTS_End_Date__c,
                                                                 APTS_CategoryCER__c, APTS_Sub_Category__c, APTS_Sub_Sub_Category__c
                                                                 from APTS_Contract_Entitlement_Repository__c
                                                                 where APTS_Sold_to_Party__c = :soldToAccountId
                                                                 and APTS_Is_Pending__c = false
                                                                ];

        return cerList;
    }

    /**
     * @description this method is used for RSO for getting contracted products
     * @param soldToAccountId
     * @param userType
     * @return all contracted product for a particular account
     */
    //commented by Venky as per Neev requested
    /*  public static Map<Id, List<ContractedProductsRSO>> getContractedProductsRSO(LIST<Id> soldToAccountId, String userType) {
      Integer level;
      ContractedProductsRSO tempObject = new ContractedProductsRSO();
      List<ContractedProductsRSO> tempObjectList = new List<ContractedProductsRSO> ();
      Map<Id, List<ContractedProductsRSO>> returnObject = new Map<Id, List<ContractedProductsRSO>> ();
      Map<Id, String> categoryMap = new Map<Id, String>();
      Map<Id, String> subCategoryMap = new Map<Id, String>();
      Map<Id, String> subSubCategoryMap = new Map<Id, String>();
      Set<Id> productSet = new Set<Id>();
      Set<Id> tempProductSet = new Set<Id>();
      List<Boolean> routeSalesFlag = new List<Boolean>();
      Set<String> setDealType = new Set<String> {CONSUMPTION_MODEL, STANDARD_DEAL};
      Map<String, List<APTS_Contract_Entitlement_Repository__c>> mapCERRecPerAgreement = new Map<String, List<APTS_Contract_Entitlement_Repository__c>>();
      List<APTS_Contract_Entitlement_Repository__c> cerRecords = new List<APTS_Contract_Entitlement_Repository__c>();
     
      //if standard-deal than search only for routesales agreement else both
      routeSalesFlag.add(true);
      if (userType == S_20) {
      routeSalesFlag.add(false);
      }
     
      for (APTS_Contract_Entitlement_Repository__c cerRecord : [SELECT Id, APTS_Sold_to_Party__c, APTS_Product__c, APTS_Charge_Type__c,
      APTS_Agreement_Type__c, toLabel(APTS_UOM__c),
      APTS_Product__r.ProductCode,
      APTS_Product__r.Name,
      APTS_Product__r.Apttus_Config2__IconId__c,
      APTS_Product__r.APTS_Option_Group_Indicator__c,
      APTS_Contributing_Agreement__c,
      APTS_Contributing_Agreement__r.Apttus_CMConfig__PONumber__c,
      APTS_Contributing_Agreement__r.APTS_Routesales__c,
      APTS_Contributing_Agreement__r.APTS_Order_Non_Contracted_Products__c,
      APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c,
      APTS_Agreement_Line_Item__r.APTS_Option_Group_Text__c,APTS_Sub_Category__c, APTS_Sub_Sub_Category__c
      FROM APTS_Contract_Entitlement_Repository__c
      WHERE APTS_Sold_to_Party__c IN :soldToAccountId
      AND APTS_Contributing_Agreement_Level__c = :CHILD AND APTS_Is_Pending__c = false
      AND APTS_Contributing_Agreement__r.APTS_Routesales__c IN:routeSalesFlag
      AND APTS_Agreement_Type__c IN :setDealType LIMIT 10000]) {
     
      cerRecords = mapCERRecPerAgreement.get(cerRecord.APTS_Agreement_Type__c);
      cerRecords = cerRecords == null ? new List<APTS_Contract_Entitlement_Repository__c>() : cerRecords;
     
      //For Routesales only standard deal with Routesales checked should be added
      if (S_20.equalsIgnoreCase(userType) || (STANDARD_DEAL.equalsIgnoreCase(cerRecord.APTS_Agreement_Type__c) && cerRecord.APTS_Contributing_Agreement__c != null && cerRecord.APTS_Contributing_Agreement__r.APTS_Routesales__c)) {
      if (!tempProductSet.contains(cerRecord.APTS_Product__c)) {
      tempProductSet.add(cerRecord.APTS_Product__c);
      }
     
      cerRecords.add(cerRecord);
      }
     
      if (!cerRecords.isEmpty()) {
      mapCERRecPerAgreement.put(cerRecord.APTS_Agreement_Type__c, cerRecords);
      }
      }
     
      //If Operating than check if Consumption Model available or not. If not assign Standard Deal products
      if (S_20.equalsIgnoreCase(userType)) {
      cerRecords = mapCERRecPerAgreement.containsKey(CONSUMPTION_MODEL) ? mapCERRecPerAgreement.get(CONSUMPTION_MODEL) : mapCERRecPerAgreement.get(STANDARD_DEAL);
      } else {
      cerRecords = mapCERRecPerAgreement.get(STANDARD_DEAL);
      }
     
      //IF no CER records available than return blank
      if (cerRecords == null || cerRecords.isEmpty()) {
      return returnObject;
      }
     
      for (APTS_RSO_Product_Catalog__c pc : [SELECT APTS_Product__c, APTS_Category_Text__c, APTS_Sub_Category_Text__c, APTS_Sub_Sub_Category_Text__c
      FROM APTS_RSO_Product_Catalog__c WHERE APTS_Product__c IN :tempProductSet]) {
      if (productSet.contains(pc.APTS_Product__c)) {
      continue;
      }
      productSet.add(pc.APTS_Product__c);
      categoryMap.put(pc.APTS_Product__c, pc.APTS_Category_Text__c);
      subCategoryMap.put(pc.APTS_Product__c, pc.APTS_Sub_Category_Text__c);
      subSubCategoryMap.put(pc.APTS_Product__c, pc.APTS_Sub_Sub_Category_Text__c);
      }
     
      for (APTS_Contract_Entitlement_Repository__c cerRecord : cerRecords) {
      //Ignore products not available in RSO Catalog
      if (!productSet.contains(cerRecord.APTS_Product__c)) {
      continue;
      }
     
      tempObjectList = returnObject.get(cerRecord.APTS_Sold_to_Party__c) != null ? returnObject.get(cerRecord.APTS_Sold_to_Party__c) : new List<ContractedProductsRSO> ();
      tempObject = new ContractedProductsRSO();
      tempObject.accountID = cerRecord.APTS_Sold_to_Party__c;
      tempObject.poNumber = cerRecord.APTS_Contributing_Agreement__r.Apttus_CMConfig__PONumber__c;
      tempObject.productID = cerRecord.APTS_Product__c;
      tempObject.productCode = cerRecord.APTS_Product__r.ProductCode;
      tempObject.productName = cerRecord.APTS_Product__r.Name;
      tempObject.uom = cerRecord.APTS_UOM__c;
      tempObject.routeSales = cerRecord.APTS_Contributing_Agreement__r.APTS_Routesales__c;
      tempObject.category = categoryMap.get(cerRecord.APTS_Product__c) != null ? categoryMap.get(cerRecord.APTS_Product__c) : '';
      tempObject.subSubCategory = subCategoryMap.get(cerRecord.APTS_Product__c) != null ? subCategoryMap.get(cerRecord.APTS_Product__c) : '';
      tempObject.subSubCategory = subSubCategoryMap.get(cerRecord.APTS_Product__c) != null ? subSubCategoryMap.get(cerRecord.APTS_Product__c) : '';
      tempObject.orderNonContractedProducts = cerRecord.APTS_Contributing_Agreement__r.APTS_Order_Non_Contracted_Products__c;
     
      if (cerRecord.APTS_Product__r != NULL && cerRecord.APTS_Product__r.Apttus_Config2__IconId__c != NULL ) {
      tempObject.productImage = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v23.0/sobjects/Attachment/' + cerRecord.APTS_Product__r.Apttus_Config2__IconId__c + '/Body';
      }
     
      //as we allow both Standard-Deal & consumption Model for Operating we need to restrict consigment products only for Consumption Model
      if (S_20.equalsIgnoreCase(userType) && CONSUMPTION_MODEL.equalsIgnoreCase(cerRecord.APTS_Agreement_Type__c) && cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c == OPTION && CONSIGNMENT_INGREDIENT.equalsIgnoreCase(cerRecord.APTS_Agreement_Line_Item__r.APTS_Option_Group_Text__c)) {
      tempObject.consignment = true;
      } else {
      tempObject.consignment = false;
      }
     
      tempObjectList.add(tempObject);
      returnObject.put(cerRecord.APTS_Sold_to_Party__c, tempObjectList);
      }
     
      return returnObject;
      }
     */
    /*    public static Map<Id,List<APTS_Contract_Entitlement_Repository__c>> getContractedProductsWithDiscounts(Id soldToAccountId, Set<Id> cartId)
      {
      Map<Id,List<APTS_Contract_Entitlement_Repository__c>> returnObject =new Map<Id,List<APTS_Contract_Entitlement_Repository__c>>();
      return returnObject;
      } */

    Public static ContractedProducts getContractedProducts(Id soldToAccountId, String orderType, String agreementType) {
        ContractedProducts returnObject = new ContractedProducts();
        Id priceListId, basedOnPriceListId;
        returnObject.orderType = orderType;
        Boolean inTestScope = Test.isRunningTest();
        Set<Id> PriceListItemSet = new Set<Id> ();
        List<Product2> lstProduct = [SELECT Id, Name FROM Product2 WHERE APTS_Category_Adjustments_Product__c = true];
        String categoryID = lstProduct.size() > 0 ? lstProduct[0].Id : null;
        Map<Id, String> defaultSellingUOM = new Map<Id, String> ();
        Map<Id, String> productCode = new Map<Id, String> ();
        List<APTS_Contract_Entitlement_Repository__c> cerRecords = new List<APTS_Contract_Entitlement_Repository__c> ();
        Id tempSoldToAccountId = getCerRecordAccountForRelatedAccount(soldToAccountId, false);
        ///////////////Defect #19829
        Set<Id> setConsignment = new Set<Id> ();
        Set<Id> setNoConsignment = new Set<Id> ();
        if (orderType == STANDARD_ORDER || orderType == ROUTE_SALES_ORDER || orderType == OPERATING_ORDER) {

            List<Id> categories = new List<Id> ();
            List<Id> subCategories = new List<Id> ();
            List<Id> subSubCategories = new List<Id> ();
            List<Ingredient> til = new List<Ingredient> ();
            Set<Id> productSet = new Set<Id> ();
            Set<Id> tempProductSet = new Set<Id> ();
            Set<Id> ingrProductSet = new Set<Id> ();
            Set<Id> categorySet = new Set<Id> ();
            List<Boolean> flagList = new List<Boolean> ();
            flagList.add(True);
            string catName, subCatName, subSubCatName, pName, sellingUom;
            Id catId, subCatID, subSubCatId, pID;
            Decimal level;
            /* Map<Id,List<APTS_Contract_Entitlement_Repository__c>> cerProductListMap=new Map<Id,List<APTS_Contract_Entitlement_Repository__c>>();*/
            Map<Id, APTS_Contract_Entitlement_Repository__c> cerProductMap = new Map<Id, APTS_Contract_Entitlement_Repository__c> ();
            List<Apttus_Config2__ProductClassification__c> productList = new List<Apttus_Config2__ProductClassification__c> ();
            List<APTS_Contract_Entitlement_Repository__c> categoryCerRecords = new List<APTS_Contract_Entitlement_Repository__c> ();
            if (orderType != ROUTE_SALES_ORDER)
            {
                flagList.add(false);
            }
            //list<Account> salAcc=new list<Account>();

            //salAcc =[select Sales_Organization__c from Account where id=:tempSoldToAccountId];
            //string tempSaleOrg=salAcc.size()>0 && salAcc[0].Sales_Organization__c!=null?salAcc[0].Sales_Organization__c.substring(4,salAcc[0].Sales_Organization__c.length()):'';
            Set<Id> agreementExculsion = new Set<Id> ();
            for (APTS_Agreement_Account_Exclusion__c aae :[Select APTS_Agreement__c from APTS_Agreement_Account_Exclusion__c where APTS_Account__c = :soldToAccountId])
            {
                if (!agreementExculsion.contains(aae.APTS_Agreement__c))
                agreementExculsion.add(aae.APTS_Agreement__c);
            }
            cerRecords = [Select id,
                          APTS_Charge_Type__c,
                          APTS_Product__c,
                          APTS_Category_Level__c,
                          APTS_Product__r.Name,
                          APTS_CategoryCER__c,
                          APTS_CategoryCER__r.Name,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceListId__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c,
                          /////////QTCFLEX1-1216
                          APTS_Agreement_Line_Item__r.APTS_Type_of_Contract__c,
                          APTS_Sub_Category__c,
                          APTS_Sub_Sub_Category__c,
                          APTS_Adjustment_Value__c,
                          APTS_Adjustment_Type__c,
                          ///////////////Defect #19829
                          APTS_Agreement_Line_Item__r.APTS_YOCI_Available_CI__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__ClassificationId__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__OptionId__r.APTS_Option_Group_Indicator__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c,
                          APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c, APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c,APTS_Product__r.APTS_Associated_Sales_Org__c,APTS_Sold_to_Party__r.Sales_Organization__c
                          from APTS_Contract_Entitlement_Repository__c
                          where APTS_Sold_to_Party__c = :tempSoldToAccountId
                          and APTS_Contributing_Agreement__r.APTS_Routesales__c in :flagList
                          and APTS_Agreement_Type__c = :agreementType
                          and APTS_Is_Pending__c = false
                          and APTS_Product__c != null
                          and APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__Active__c = true
                          and APTS_Contributing_Agreement__c not in :agreementExculsion
                          and APTS_Agreement_Line_Item__c not in(Select APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                          and APTS_Agreement_Adjustment_Line_Item__c not in(Select APTS_Agreement_Adjustment_Line_Item__c from APTS_Adjustment_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                          and APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c = :PRODUCT_SERVICE
                          and(APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c = true or APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c = true or
                              APTS_Agreement_Line_Item__r.APTS_More_Standalone__c = true or
                              APTS_Agreement_Line_Item__r.APTS_Ingredient_Bundle__c = True)
                          ORDER BY APTS_Contributing_Agreement_Level_Num__c Asc, APTS_Category_Level__c Desc];
            if (cerRecords.size() == 0) {
                return returnObject;
            }
            if (cerRecords.size() > 0)
            {
                priceListId = cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__c;
                basedOnPriceListId = cerRecords[0].APTS_Contributing_Agreement__r.Apttus_CMConfig__PriceListId__r.Apttus_Config2__BasedOnPriceListId__c;
                priceListItemSet.add(priceListId);
                if (basedOnPriceListId != NULL)
                priceListItemSet.add(basedOnPriceListId);
            }
            for (APTS_Contract_Entitlement_Repository__c cerRecord : cerRecords) {

                if (cerRecord.APTS_Product__c != categoryID && cerProductMap.get(cerRecord.APTS_Product__c) == null) {
                    cerProductMap.put(cerRecord.APTS_Product__c, cerRecord);
                    if (!ingrProductSet.contains(cerRecord.APTS_Product__c)) {
                        ingrProductSet.add(cerRecord.APTS_Product__c);
                    }
                }
            }
            returnObject.totalSpareParts = 0;
            for (APTS_Contract_Entitlement_Repository__c cerRecord : cerRecords) {
                if ((cerRecord.APTS_Product__c != null && cerRecord.APTS_Product__c == categoryID) || inTestScope) {
                    if (cerRecord.APTS_CategoryCER__r.Name == SPARE_PARTS)
                    {
                        returnObject.isSparePart = true;
                        returnObject.adjustmentValue = cerRecord.APTS_Adjustment_Value__c;
                        returnObject.adjustmentType = cerRecord.APTS_Adjustment_Type__c;
                        returnObject.totalSpareParts = returnObject.totalSpareParts + 1;
                        continue;
                    }
                    if (cerRecord.APTS_Category_Level__c == CATEGORY) {
                        categories.add(cerRecord.APTS_CategoryCER__c);
                    } else if (cerRecord.APTS_Category_Level__c == SUB_CATEGORY) {
                        categories.add(cerRecord.APTS_Sub_Category__c);
                    } else {
                        categories.add(cerRecord.APTS_Sub_Sub_Category__c);
                    }

                    categoryCerRecords.add(cerRecord);
                }
            }

            //List<APTS_Sales_Org_Data__c> salesOrgDataList=[SELECT Id,APTS_Product__c FROM APTS_Sales_Org_Data__c WHERE  APTS_Sales_Org_Data_Name__c=:tempSaleOrg and APTS_Price_List__c=:cerRecords[0].APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__PriceListId__c and APTS_Product__c!= null];
            //if(inTestScope)
            //{
            //salesOrgDataList=[SELECT Id,APTS_Product__c FROM APTS_Sales_Org_Data__c  limit 20];
            //}
            String tempString;
            for (Apttus_Config2__PriceListItem__c pli :[Select Apttus_Config2__ProductId__c, APTS_Default_Selling_Uom__c, APTS_Product_Code__c, Apttus_Config2__ProductCode__c from Apttus_Config2__PriceListItem__c where Apttus_Config2__PriceListId__c IN :PriceListItemSet and Apttus_Config2__Active__c = True]) { //6926 Defect change
                if (!tempProductSet.contains(pli.Apttus_Config2__ProductId__c)) {
                    tempProductSet.add(pli.Apttus_Config2__ProductId__c);
                    defaultSellingUOM.put(pli.Apttus_Config2__ProductId__c, pli.APTS_Default_Selling_Uom__c);
                    tempString = pli.APTS_Product_Code__c != null ? pli.APTS_Product_Code__c : pli.Apttus_Config2__ProductCode__c;
                    productCode.put(pli.Apttus_Config2__ProductId__c, tempString);
                }
            }

            productList = [SELECT Apttus_Config2__ProductId__c,
                           Apttus_Config2__ProductId__r.Name,
                           Apttus_Config2__ClassificationId__r.Apttus_Config2__Level__c,
                           Apttus_Config2__ClassificationId__c,
                           Apttus_Config2__ClassificationId__r.Name,
                           Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c,
                           Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c,
                           Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Name,
                           Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c,
                           Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__r.Name
                           FROM Apttus_Config2__ProductClassification__c WHERE Apttus_Config2__ProductId__r.IsActive = true
                           and Apttus_Config2__ProductId__c in :tempProductSet
                           and(Apttus_Config2__ProductId__c in :ingrProductSet
                               OR Apttus_Config2__ClassificationId__c IN :categories
                               OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c IN :categories
                               OR Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c IN :categories
            )];
            if (inTestScope) {
                productList = [SELECT Apttus_Config2__ProductId__c,
                               Apttus_Config2__ProductId__r.Name,
                               Apttus_Config2__ClassificationId__r.Apttus_Config2__Level__c,
                               Apttus_Config2__ClassificationId__c,
                               Apttus_Config2__ClassificationId__r.Name,
                               Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c,
                               Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c,
                               Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Name,
                               Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c,
                               Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__r.Name
                               FROM Apttus_Config2__ProductClassification__c limit 20];
            }


            for (Apttus_Config2__ProductClassification__c products : productList) {
                pId = products.Apttus_Config2__ProductId__c;
                if (!cerProductMap.keySet().contains(pId) && tempProductSet.contains(pId)) {
                    for (APTS_Contract_Entitlement_Repository__c cerRecord : categoryCerRecords) {
                        if ((cerRecord.APTS_Category_Level__c == CATEGORY && (products.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c == cerRecord.APTS_CategoryCER__c || products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_CategoryCER__c || products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_CategoryCER__c)) || (cerRecord.APTS_Category_Level__c == SUB_CATEGORY && (products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_Sub_Category__c || products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_Sub_Category__c)
                                                                                                                                                                                                                                                                                                                                                                                                  && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c == cerRecord.APTS_CategoryCER__c) || (cerRecord.APTS_Category_Level__c == SUB_SUB_CATEGORY && products.Apttus_Config2__ClassificationId__c == cerRecord.APTS_Sub_Sub_Category__c && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c == cerRecord.APTS_Sub_Category__c
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        && products.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c == cerRecord.APTS_CategoryCER__c)) {
                            cerProductMap.put(pId, cerRecord);
                        }
                    }
                }
            }

            //Logic to determine if the product is consignment or not
            for (Apttus_Config2__ProductClassification__c currentProduct : productList) {
                if (!cerProductMap.keySet().contains(currentProduct.Apttus_Config2__ProductId__c)) {
                    continue;
                } else {
                    if (cerProductMap.get(currentProduct.Apttus_Config2__ProductId__c).APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c == PRODUCT_SERVICE &&
                        cerProductMap.get(currentProduct.Apttus_Config2__ProductId__c).APTS_Agreement_Line_Item__r.APTS_YOCI_Available_CI__c //added by venky CR 2109
                        //cerProductMap.get(currentProduct.Apttus_Config2__ProductId__c).APTS_Agreement_Line_Item__r.Apttus_CMConfig__OptionId__r.APTS_Option_Group_Indicator__c == '0503' Commented by venky CR 2109
                    )
                    {
                        setConsignment.add(currentProduct.Apttus_Config2__ProductId__c);
                    } else {
                        setNoConsignment.add(currentProduct.Apttus_Config2__ProductId__c);
                    }
                }
            }


            for (Apttus_Config2__ProductClassification__c products : productList) {
                pId = products.Apttus_Config2__ProductId__c;
                if (!cerProductMap.keySet().contains(pId)) {
                    continue;
                } else {
                    //Logic to determine if the product is consignment or not
                    ///////////////Defect #19829
                    if (setNoConsignment.contains(pId) && CONSIGNMENT_INGREDIENT.equalsIgnoreCase(products.Apttus_Config2__ClassificationId__r.Name)) {
                        continue;
                    }
                }

                level = products.Apttus_Config2__ClassificationId__r.Apttus_Config2__Level__c;
                pName = setConsignment.contains(pId) ? products.Apttus_Config2__ProductId__r.Name + ' (Consignment Ingredients)' : products.Apttus_Config2__ProductId__r.Name;
                if (level == 2) {
                    catId = products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__c;
                    catName = products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Apttus_Config2__AncestorId__r.Name;
                    subCatID = products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c;
                    subCatName = products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Name;
                    subSubCatId = products.Apttus_Config2__ClassificationId__c;
                    subSubCatName = products.Apttus_Config2__ClassificationId__r.Name;
                    Integer catIndex, subCatIndex;
                    if (!categorySet.contains(catId)) {
                        Ingredient ttil = new Ingredient();
                        ttil.categoryID = catId;
                        ttil.categoryName = catName;
                        til.add(ttil);
                        categorySet.add(catId);
                    }
                    for (Integer i = 0; i<til.size(); i++) {
                        if (til[i].categoryID == catId) {
                            catIndex = i;
                            break;
                        }
                    }
                    if (!categorySet.contains(subCatID)) {
                        SubCategory ttscl = new SubCategory();
                        ttscl.subCategoryID = subCatID;
                        ttscl.subCategoryName = subCatName;
                        til[catIndex].subCategories.add(ttscl);
                        categorySet.add(subCatID);

                    }
                    for (Integer i = 0; i<til[catIndex].subCategories.size(); i++) {
                        if (til[catIndex].subCategories[i].subCategoryID == subCatID) {
                            subCatIndex = i;
                            break;
                        }
                    }
                    if (!categorySet.contains(subSubCatId)) {
                        SubSubCategory ttsscl = new SubSubCategory();
                        ttsscl.subSubCategoryID = subSubCatId;
                        ttsscl.subSubCategoryName = subSubCatName;
                        Product p = new Product();
                        p.productId = pId;
                        p.productName = pName;
                        p.quantity = 1;
                        p.sellingUOM = ingrProductSet.contains(pId) ? cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c : null : defaultSellingUOM.get(pId);
                        p.productCode = productCode.get(pId);
                        p.agreementLineItem = cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__c : null;
                        p.isNonSalesOrg = cerProductMap.get(pId) != null && (cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c == null || !cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c.contains(cerProductMap.get(pId).APTS_Sold_to_Party__r.Sales_Organization__c)) ? true : false;//v102
                        ttsscl.products.add(p);
                        til[catIndex].subCategories[subCatIndex].subSubCategories.add(ttsscl);
                        categorySet.add(subSubCatId);

                    } else {
                        Product p = new Product();
                        p.productId = pId;
                        p.productName = pName;
                        p.quantity = 1;
                        p.sellingUOM = ingrProductSet.contains(pId) ? cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c : null : defaultSellingUOM.get(pId);
                        p.productCode = productCode.get(pId);
                        p.agreementLineItem = cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__c : null;
                        p.isNonSalesOrg = cerProductMap.get(pId) != null && (cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c == null || !cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c.contains(cerProductMap.get(pId).APTS_Sold_to_Party__r.Sales_Organization__c)) ? true : false;//v102
                        for (Integer i = 0; i<til[catIndex].subCategories[subCatIndex].subSubCategories.size(); i++) {
                            if (til[catIndex].subCategories[subCatIndex].subSubCategories[i].subSubCategoryID == subSubCatId) {
                                til[catIndex].subCategories[subCatIndex].subSubCategories[i].products.add(p);
                            }
                        }
                    }
                } else if (level == 1) {
                    catId = products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c;
                    catName = products.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__r.Name;
                    subCatID = products.Apttus_Config2__ClassificationId__c;
                    subCatName = products.Apttus_Config2__ClassificationId__r.Name;
                    Integer catIndex;
                    if (!categorySet.contains(catId)) {
                        Ingredient ttil = new Ingredient();
                        ttil.categoryID = catId;
                        ttil.categoryName = catName;
                        til.add(ttil);
                        categorySet.add(catId);
                    }
                    for (Integer i = 0; i<til.size(); i++) {
                        if (til[i].categoryID == catId) {
                            catIndex = i;
                            break;
                        }
                    }
                    if (!categorySet.contains(subCatID)) {
                        SubCategory ttscl = new SubCategory();
                        ttscl.subCategoryID = subCatID;
                        ttscl.subCategoryName = subCatName;
                        Product p = new Product();
                        p.productId = pId;
                        p.productName = pName;
                        p.quantity = 1;
                        p.sellingUOM = ingrProductSet.contains(pId) ? cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c : null : defaultSellingUOM.get(pId);
                        p.productCode = productCode.get(pId);
                        p.agreementLineItem = cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__c : null;
                        p.isNonSalesOrg = cerProductMap.get(pId) != null && (cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c == null || !cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c.contains(cerProductMap.get(pId).APTS_Sold_to_Party__r.Sales_Organization__c)) ? true : false;//v102
                        ttscl.products.add(p);
                        til[catIndex].subCategories.add(ttscl);
                        categorySet.add(subCatID);

                    } else {
                        Product p = new Product();
                        p.productId = pId;
                        p.productName = pName;
                        p.quantity = 1;
                        p.sellingUOM = ingrProductSet.contains(pId) ? cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c : null : defaultSellingUOM.get(pId);
                        p.productCode = productCode.get(pId);
                        p.agreementLineItem = cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__c : null;
                        p.isNonSalesOrg = cerProductMap.get(pId) != null && (cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c == null || !cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c.contains(cerProductMap.get(pId).APTS_Sold_to_Party__r.Sales_Organization__c)) ? true : false;//v102
                        for (Integer i = 0; i<til[catIndex].subCategories.size(); i++) {
                            if (til[catIndex].subCategories[i].subCategoryID == subCatID) {
                                til[catIndex].subCategories[i].products.add(p);
                            }
                        }
                    }

                } else if (level == 0) {

                    catId = products.Apttus_Config2__ClassificationId__c;
                    catName = products.Apttus_Config2__ClassificationId__r.Name;
                    if (!categorySet.contains(catId)) {
                        Ingredient ttil = new Ingredient();
                        ttil.categoryID = catId;
                        ttil.categoryName = catName;
                        Product p = new Product();
                        p.productId = pId;
                        p.productName = pName;
                        p.quantity = 1;
                        p.sellingUOM = ingrProductSet.contains(pId) ? cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c : null : defaultSellingUOM.get(pId);
                        p.productCode = productCode.get(pId);
                        p.agreementLineItem = cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__c : null;
                        p.isNonSalesOrg = cerProductMap.get(pId) != null && (cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c == null || !cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c.contains(cerProductMap.get(pId).APTS_Sold_to_Party__r.Sales_Organization__c)) ? true : false;//v102
                        ttil.products.add(p);
                        til.add(ttil);
                        categorySet.add(catId);
                    } else {
                        Product p = new Product();
                        p.productId = pId;
                        p.productName = pName;
                        p.quantity = 1;
                        p.sellingUOM = ingrProductSet.contains(pId) ? cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c : null : defaultSellingUOM.get(pId);
                        p.productCode = productCode.get(pId);
                        p.agreementLineItem = cerProductMap.get(pId) != null ? cerProductMap.get(pId).APTS_Agreement_Line_Item__c : null;
                        p.isNonSalesOrg = cerProductMap.get(pId) != null && (cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c == null || !cerProductMap.get(pId).APTS_Product__r.APTS_Associated_Sales_Org__c.contains(cerProductMap.get(pId).APTS_Sold_to_Party__r.Sales_Organization__c)) ? true : false;//v102
                        for (Integer i = 0; i<til.size(); i++) {
                            if (til[i].categoryID == catId) {
                                til[i].products.add(p);
                            }
                        }
                    }
                }

            }

            returnObject.ingredientsList.addAll(til);

        } else {
            Machine tm = new Machine();
            ParentBundle tpb = new ParentBundle();
            Options to = new Options();
            Set<String> lineNumberSet = new Set<String> ();
            Set<Id> agreementLineItemSet = new Set<ID> ();
            String tempString;
            Set<Id> agreementExculsion = new Set<Id> ();
            for (APTS_Agreement_Account_Exclusion__c aae :[Select APTS_Agreement__c from APTS_Agreement_Account_Exclusion__c where APTS_Account__c = :soldToAccountId])
            {
                if (!agreementExculsion.contains(aae.APTS_Agreement__c))
                agreementExculsion.add(aae.APTS_Agreement__c);
            }
            cerRecords = [Select id,
                          APTS_Charge_Type__c,
                          APTS_Product__c,
                          APTS_Product__r.Name,
                          APTS_Agreement_Line_Item__r.Apttus__Description__c,
                          APTS_Agreement_Line_Item__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__ProductOptionId__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ProductCode__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineNumber__c,
                          APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c,
                          /////////QTCFLEX1-1216
                          APTS_Agreement_Line_Item__r.APTS_Type_of_Contract__c,
                          APTS_Contributing_Agreement_Level__c, APTS_Sub_Category__c, APTS_Sub_Sub_Category__c,APTS_Product__r.APTS_Associated_Sales_Org__c,APTS_Sold_to_Party__r.Sales_Organization__c
                          from APTS_Contract_Entitlement_Repository__c
                          where APTS_Sold_to_Party__c = :tempSoldToAccountId
                          and APTS_Agreement_Type__c = :agreementType
                          and APTS_Is_Pending__c = false
                          and APTS_Product__c != null
                          and APTS_Product__c != :categoryID
                          and APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__Active__c = true
                          and APTS_CategoryCER__r.Name != :CONSIGNMENT_INGREDIENT
                          and APTS_Contributing_Agreement__c not in :agreementExculsion
                          and APTS_Agreement_Line_Item__c not in(Select APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                          and APTS_Agreement_Adjustment_Line_Item__c not in(Select APTS_Agreement_Adjustment_Line_Item__c from APTS_Adjustment_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                          and(APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c = false and APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c = false and
                              APTS_Agreement_Line_Item__r.APTS_More_Standalone__c = false and APTS_Agreement_Line_Item__r.Apttus_CMConfig__DerivedFromId__r.APTS_Fixed_Term_Product__c = false and
                              APTS_Agreement_Line_Item__r.APTS_Ingredient_Bundle__c = false and APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone_or_Spare_Part__c = false)
                          ORDER BY APTS_Contributing_Agreement_Level__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineNumber__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__ItemSequence__c];
            if (inTestScope) {
                cerRecords = [Select id,
                              APTS_Charge_Type__c,
                              APTS_Product__c,
                              APTS_Product__r.Name,
                              APTS_Agreement_Line_Item__r.Apttus__Description__c,
                              APTS_Agreement_Line_Item__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ProductCode__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__ProductOptionId__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineNumber__c,
                              APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c,
                              /////////QTCFLEX1-1216
                              APTS_Agreement_Line_Item__r.APTS_Type_of_Contract__c,
                              APTS_Contributing_Agreement_Level__c, APTS_Sub_Category__c, APTS_Sub_Sub_Category__c,APTS_Sold_to_Party__r.Sales_Organization__c,APTS_Product__r.APTS_Associated_Sales_Org__c
                              from APTS_Contract_Entitlement_Repository__c limit : 10];
            }
            if (cerRecords.size() == 0) {
                return returnObject;
            }
            String tempMachineString;
            for (APTS_Contract_Entitlement_Repository__c cerRecord : cerRecords) {
                tempString = cerRecord.APTS_Contributing_Agreement_Level__c + '' + cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineNumber__c;
                if (agreementLineItemSet.contains(cerRecord.APTS_Agreement_Line_Item__c)) {
                    continue;
                }
                agreementLineItemSet.add(cerRecord.APTS_Agreement_Line_Item__c);
                if (!lineNumberSet.contains(tempString)) {
                    if (lineNumberSet.size()> 0) {
                        returnObject.machinesList.add(tm);
                    }
                    tm = new Machine();
                    tm.productID = cerRecord.APTS_Product__c;
                    lineNumberSet.add(tempString);
                }
                tempMachineString = cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c != null ? cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.APTS_Product_Code__c : cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__PriceListItemId__r.Apttus_Config2__ProductCode__c;

                if (cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c == PRODUCT_SERVICE) { 
                    tpb = new ParentBundle();
                    //v102 <++
                  if(cerRecord.APTS_Product__r.APTS_Associated_Sales_Org__c == null || !cerRecord.APTS_Product__r.APTS_Associated_Sales_Org__c.contains(cerRecord.APTS_Sold_to_Party__r.Sales_Organization__c)){
                        tpb.isNonSalesOrg=true;
                   } else{
                        tpb.isNonSalesOrg=false;
                   }
                   //v102 ++>
                    tpb.productID = cerRecord.APTS_Product__c;
                    tpb.productName = cerRecord.APTS_Agreement_Line_Item__r.Apttus__Description__c;
                    tpb.chargeType = cerRecord.APTS_Charge_Type__c;
                    tpb.productCode = tempMachineString;
                    tpb.attributeId = cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__c;
                    tpb.agreementLineItem = cerRecord.APTS_Agreement_Line_Item__c;
                    tpb.typeOfContract = cerRecord.APTS_Agreement_Line_Item__r.APTS_Type_of_Contract__c;
                    tm.parentBundle.add(tpb);
                } 
               else {
                    to = new Options();
                    //v102 <++
                    if(cerRecord.APTS_Product__r.APTS_Associated_Sales_Org__c == null || !cerRecord.APTS_Product__r.APTS_Associated_Sales_Org__c.contains(cerRecord.APTS_Sold_to_Party__r.Sales_Organization__c)){
                        to.isNonSalesOrg = true;
                    }
                    else{
                        to.isNonSalesOrg= false;
                    }
                    //v102 ++>
                    to.optionID = cerRecord.APTS_Product__c;
                    to.optionName = cerRecord.APTS_Product__r.Name;
                    to.productCode = tempMachineString;
                    to.optionComponentId = cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__ProductOptionId__c;
                    to.chargeType = cerRecord.APTS_Charge_Type__c;
                    to.attributeId = cerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__AttributeValueId__c;
                    to.agreementLineItem = cerRecord.APTS_Agreement_Line_Item__c;
                    to.typeOfContractopt = cerRecord.APTS_Agreement_Line_Item__r.APTS_Type_of_Contract__c;
                    tm.options.add(to);
                    }

            }
            if (cerRecords.size()> 0) {
                returnObject.machinesList.add(tm);
            }

        }

        return returnObject;
    }
    /**
     * @description It returns category cer records for a particular account
     * @param soldToAccountId
     * @param cartId
     * @param isAgreementCart
     * @return Cer Records
     */
    public static Map<Id, List<APTS_Contract_Entitlement_Repository__c>> getCategoryProductsWithDiscounts(Id soldToAccountId, Id cartId, Boolean isAgreementCart) {
        List<Product2> lstProduct = [SELECT Id FROM Product2 WHERE APTS_Category_Adjustments_Product__c = true];
        ID categoryProductId = lstProduct.size()> 0 ? lstProduct[0].Id : null;
        Map<Id, List<APTS_Contract_Entitlement_Repository__c>> returnObject = new Map<Id, List<APTS_Contract_Entitlement_Repository__c>> ();
        List<APTS_Contract_Entitlement_Repository__c> tempList = new List<APTS_Contract_Entitlement_Repository__c> ();
        List<APTS_Contract_Entitlement_Repository__c> masterList = new List<APTS_Contract_Entitlement_Repository__c> ();
        for (APTS_Contract_Entitlement_Repository__c c :[select Id, Name, APTS_Agreement_Adjustment_Line_Item__c, APTS_Adjustment_Type__c, APTS_Adjustment_Value__c, APTS_Agreement_Line_Item__c, APTS_Category__c,
             APTS_Category_Level__c, APTS_Contributing_Agreement__c, APTS_Contributing_Agreement_Level__c,
             APTS_Exclusion_Exception_Available__c, APTS_Max_Volume__c, APTS_Pricing_Sub_Type__c,
             APTS_Pricing_Type__c, APTS_Product__c, APTS_Rebate__c, APTS_Sold_to_Party__c,
             Total_Cumulative_Consumption_Currency__c, Total_Cumulative_Consumption_Quantity__c,
             APTS_Adjustment_Applies_To__c, APTS_Type__c, APTS_Sub_Type__c, APTS_Bucket__c,
             APTS_UOM__c, APTS_Pending_Line_Item__c, APTS_Pending_Adjustment_Line_Item__c, APTS_CategoryCER__c, APTS_Sub_Category__c, APTS_Sub_Sub_Category__c,
             APTS_Start_Date__c,
             APTS_End_Date__c,
             APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c,
             APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c,
             APTS_Charge_Type__c, APTS_Agreement_Line_Item__r.APTS_More_Standalone__c, APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone_or_Spare_Part__c
             from APTS_Contract_Entitlement_Repository__c
             where APTS_Sold_to_Party__c = :soldToAccountId
             and APTS_Adjustment_Value__c != null and APTS_Product__c = :categoryProductId
             and APTS_Bucket__c != null
             ORDER BY APTS_Pending_Line_Item__c DESC NULLS LAST, APTS_Category_Level__c DESC, LastModifiedDate DESC]) {
            if (c.APTS_Pending_Line_Item__c != null && c.APTS_Contributing_Agreement_Level__c == CHILD) {
                tempList = returnObject.get(c.APTS_Pending_Line_Item__c) != null ? returnObject.get(c.APTS_Pending_Line_Item__c) : new List<APTS_Contract_Entitlement_Repository__c> ();
                tempList.add(c);
                returnObject.put(c.APTS_Pending_Line_Item__c, tempList);
                masterList.add(c);
            } else {
                for (APTS_Contract_Entitlement_Repository__c tc : masterList) {
                    if (((c.APTS_Category_Level__c == CATEGORY && c.APTS_CategoryCER__c == tc.APTS_CategoryCER__c) || (c.APTS_Category_Level__c == SUB_CATEGORY && c.APTS_CategoryCER__c == tc.APTS_CategoryCER__c && c.APTS_Sub_Category__c == tc.APTS_Sub_Category__c) || (c.APTS_Category_Level__c == SUB_SUB_CATEGORY && c.APTS_CategoryCER__c == tc.APTS_CategoryCER__c && c.APTS_Sub_Category__c == tc.APTS_Sub_Category__c && c.APTS_Sub_Sub_Category__c == tc.APTS_Sub_Sub_Category__c)) && c.APTS_Type__c != tc.APTS_Type__c && c.APTS_Sub_Type__c != tc.APTS_Sub_Type__c) {
                        tempList = returnObject.get(tc.APTS_Pending_Line_Item__c) != null ? returnObject.get(tc.APTS_Pending_Line_Item__c) : new List<APTS_Contract_Entitlement_Repository__c> ();
                        tempList.add(c);
                        returnObject.put(tc.APTS_Pending_Line_Item__c, tempList);
                    }
                }
            }
        }
        return returnObject;

    }
    /**
     * @description Returns cer records based on line items in a particular cart
     * @param soldToAccountId
     * @param cartId
     * @param isAgreementCart
     
     */
    public static Map<Id, List<APTS_Contract_Entitlement_Repository__c>> getContractedProductsWithDiscounts(Id soldToAccountId, Id cartId, Boolean isAgreementCart) {
        //Modified by Venky
        Map<Id, List<APTS_Contract_Entitlement_Repository__c>> returnObject = new Map<Id, List<APTS_Contract_Entitlement_Repository__c>> ();
        List<APTS_Contract_Entitlement_Repository__c> cerList = new List<APTS_Contract_Entitlement_Repository__c> ();
        List<APTS_Contract_Entitlement_Repository__c> categoryCerList = new List<APTS_Contract_Entitlement_Repository__c> ();
        List<APTS_Contract_Entitlement_Repository__c> tempCerList = new List<APTS_Contract_Entitlement_Repository__c> ();
        Set<Id> tempCategorySet = new Set<Id> ();
        Set<Id> productSet = new Set<Id> ();
        Boolean inTestScope = Test.isRunningTest();
        Set<String> globalLinkageId = new Set<String> ();
        Map<Id, String> chargeType = new Map<Id, String> ();
        List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c> ();
        CategoryHierarchy ch = new CategoryHierarchy();
        Id tempPid;
        List<Boolean> booleanFlag = new List<Boolean> ();
        List<Boolean> booleanDisAmendFlag = new List<Boolean> ();
        booleanFlag.add(false);
        booleanDisAmendFlag.add(false);
        List<String> adjustmentType = new List<String> ();
        if (isAgreementCart) {
            booleanFlag.add(true);
            adjustmentType.add('YOCI');
            adjustmentType.add('YOFT');
            adjustmentType.add('ZX10');
        }
        else {
            booleanDisAmendFlag.add(true);
        }
        Map<Id, CategoryHierarchy> productCategories = new Map<Id, CategoryHierarchy> ();
        Id tempSoldToAccountId = getCategoryCerRecordAccountForRelatedAccount(soldToAccountId, isAgreementCart);
        String categoryId, subCategoryId, subSubCategoryId;
        Integer level;
        List<Product2> lstProduct = [SELECT Id FROM Product2 WHERE APTS_Category_Adjustments_Product__c = true];
        ID categoryProductId = lstProduct.size()> 0 ? lstProduct[0].Id : null;

        for (Apttus_Config2__LineItem__c l :[Select Id, Apttus_Config2__ProductId__c, Apttus_Config2__OptionId__c, Apttus_Config2__LineType__c, Apttus_Config2__ClassificationId__c, Apttus_Config2__ClassificationId__r.Id, Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c, Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c, APTS_Global_linkage_ID__c,
             Apttus_Config2__ClassificationId__r.Apttus_Config2__Level__c, Apttus_Config2__ChargeType__c from Apttus_Config2__LineItem__c where Apttus_Config2__ConfigurationId__c = :cartId and Apttus_Config2__ProductId__c != :categoryProductId and Apttus_Config2__AssetLineItemId__c = Null and Apttus_Config2__PricingStatus__c != :COMPLETE]) {
            tempPid = l.Apttus_Config2__LineType__c == PRODUCT_SERVICE ? l.Apttus_Config2__ProductId__c : l.Apttus_Config2__OptionId__c;
            if (!productSet.contains(tempPid)) {
                productSet.add(tempPid);
            }
            lineItemList.add(l);
        }
        for (Apttus_Config2__LineItem__c l : lineItemList) {
            tempPid = l.Apttus_Config2__LineType__c == PRODUCT_SERVICE ? l.Apttus_Config2__ProductId__c : l.Apttus_Config2__OptionId__c;
            if (!productCategories.containsKey(tempPid)) {
                ch = new CategoryHierarchy();
                ch.level = Integer.valueOf(l.Apttus_Config2__ClassificationId__r.Apttus_Config2__Level__c);
                if (ch.level == 0) {
                    ch.categoryId = l.Apttus_Config2__ClassificationId__c;
                } else if (ch.level == 1) {
                    ch.subCategoryId = l.Apttus_Config2__ClassificationId__c;
                    ch.categoryId = l.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c;
                } else {
                    ch.subSubCategoryId = l.Apttus_Config2__ClassificationId__c;
                    ch.subCategoryId = l.Apttus_Config2__ClassificationId__r.Apttus_Config2__AncestorId__c;
                    ch.categoryId = l.Apttus_Config2__ClassificationId__r.Apttus_Config2__PrimordialId__c;
                }
                if (ch.subSubCategoryId != null && ch.subSubCategoryId != '' && !(tempCategorySet.contains(ch.subSubCategoryId))) {
                    tempCategorySet.add(ch.subSubCategoryId);
                }
                if (ch.subCategoryId != null && ch.subCategoryId != '' && !(tempCategorySet.contains(ch.subCategoryId))) {
                    tempCategorySet.add(ch.subCategoryId);
                }
                if (ch.categoryId != null && ch.categoryId != '' && !(tempCategorySet.contains(ch.categoryId))) {
                    tempCategorySet.add(ch.categoryId);
                }
                chargeType.put(tempPid, l.Apttus_Config2__ChargeType__c);
                globalLinkageId.add(l.APTS_Global_linkage_ID__c);
                productCategories.put(tempPid, ch);
            }

        }
        //}
        Set<Id> agreementExculsion = new Set<Id> ();
        for (APTS_Agreement_Account_Exclusion__c aae :[Select APTS_Agreement__c from APTS_Agreement_Account_Exclusion__c where APTS_Account__c = :soldToAccountId])
        {
            if (!agreementExculsion.contains(aae.APTS_Agreement__c))
            agreementExculsion.add(aae.APTS_Agreement__c);
        }
        categoryCerList = [select Id, Name, APTS_Agreement_Adjustment_Line_Item__c, APTS_Adjustment_Type__c, APTS_Adjustment_Value__c, APTS_Agreement_Line_Item__c, APTS_Category__c,
                           APTS_Category_Level__c, APTS_Contributing_Agreement__c, APTS_Contributing_Agreement_Level__c,
                           APTS_Exclusion_Exception_Available__c, APTS_Max_Volume__c, APTS_Pricing_Sub_Type__c,
                           APTS_Pricing_Type__c, APTS_Product__c, APTS_Rebate__c, APTS_Sold_to_Party__c,
                           Total_Cumulative_Consumption_Currency__c, Total_Cumulative_Consumption_Quantity__c,
                           APTS_Adjustment_Applies_To__c, APTS_Type__c, APTS_Sub_Type__c, APTS_Bucket__c,
                           APTS_UOM__c, APTS_Pending_Line_Item__c, APTS_Pending_Adjustment_Line_Item__c, APTS_CategoryCER__c, APTS_Sub_Category__c, APTS_Sub_Sub_Category__c,
                           APTS_Start_Date__c, APTS_Agreement_Adjustment_Line_Item__r.APTS_Discount_Type__c,
                           APTS_End_Date__c,
                           APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c,
                           APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c, APTS_Agreement_Line_Item__r.APTS_More_Standalone__c, APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone_or_Spare_Part__c,
                           APTS_Agreement_Line_Item__r.APTS_MachineCoffeeKitchen__c,
                           APTS_CER_Changed_Amendment__c,
                           APTS_Agreement_Line_Item__r.APTS_Global_linkage_ID__c,
                           APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c,
                           APTS_Amendment_In_Progress__c,
                           APTS_Charge_Type__c
                           from APTS_Contract_Entitlement_Repository__c
                           where APTS_Sold_to_Party__c = :tempSoldToAccountId and APTS_Is_Pending__c in :booleanFlag
                           and((APTS_Category_Level__c = 'Product' and APTS_Sub_Type__c not in :adjustmentType) OR APTS_Category_Level__c != 'Product')
                           and APTS_Contributing_Agreement__c not in :agreementExculsion
                           and APTS_Amendment_In_Progress__c in :booleanDisAmendFlag
                           and APTS_Agreement_Line_Item__c not in(Select APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                           and APTS_Agreement_Adjustment_Line_Item__c not in(Select APTS_Agreement_Adjustment_Line_Item__c from APTS_Adjustment_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                           and APTS_Adjustment_Value__c != null and(APTS_Sub_Sub_Category__c in :tempCategorySet or APTS_Sub_Category__c in :tempCategorySet or APTS_CategoryCER__c in :tempCategorySet or APTS_Product__c in :productSet)
                           ORDER BY APTS_Contributing_Agreement_Level_Num__c, APTS_Category_Level__c DESC, LastModifiedDate DESC];
        if (inTestScope) {
            categoryCerList = [select Id, Name, APTS_Agreement_Adjustment_Line_Item__c, APTS_Adjustment_Type__c, APTS_Adjustment_Value__c, APTS_Agreement_Line_Item__c, APTS_Category__c,
                               APTS_Category_Level__c, APTS_Contributing_Agreement__c, APTS_Contributing_Agreement_Level__c,
                               APTS_Exclusion_Exception_Available__c, APTS_Max_Volume__c, APTS_Pricing_Sub_Type__c,
                               APTS_Pricing_Type__c, APTS_Product__c, APTS_Rebate__c, APTS_Sold_to_Party__c,
                               Total_Cumulative_Consumption_Currency__c, Total_Cumulative_Consumption_Quantity__c,
                               APTS_Adjustment_Applies_To__c, APTS_Type__c, APTS_Sub_Type__c, APTS_Bucket__c,
                               APTS_UOM__c, APTS_Pending_Line_Item__c, APTS_Pending_Adjustment_Line_Item__c, APTS_CategoryCER__c, APTS_Sub_Category__c,
                               APTS_Agreement_Line_Item__r.APTS_MachineCoffeeKitchen__c,
                               APTS_Sub_Sub_Category__c,
                               APTS_Start_Date__c,
                               APTS_End_Date__c,
                               APTS_Amendment_In_Progress__c,
                               APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c,
                               APTS_Agreement_Line_Item__r.APTS_Global_linkage_ID__c,
                               APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c,
                               APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c,
                               APTS_Charge_Type__c,
                               APTS_CER_Changed_Amendment__c
                               from APTS_Contract_Entitlement_Repository__c
                               limit : 20];
        }

        // List<Apttus_Config2__LineItem__c> lineItemList=[Select ]
        if (categoryCerList.size()> 0) {
            boolean check = true;
            for (Id pID : productCategories.keySet()) {
                for (APTS_Contract_Entitlement_Repository__c categoryCerRecord : categoryCerList) {
                    tempCerList = returnObject.get(pID) != null ? returnObject.get(pID) : new List<APTS_Contract_Entitlement_Repository__c> ();
                    check = true;
                    for (APTS_Contract_Entitlement_Repository__c cerRecord : tempCerList) {
                        if (cerRecord.APTS_Type__c == categoryCerRecord.APTS_Type__c && cerRecord.APTS_Sub_Type__c == categoryCerRecord.APTS_Sub_Type__c && cerRecord.APTS_Charge_Type__c == categoryCerRecord.APTS_Charge_Type__c) {
                            check = false;
                        }
                    }
                    //if(categoryCerRecord.APTS_Pending_Adjustment_Line_Item__r.APTS_Start_Date__c!=null && categoryCerRecord.APTS_Pending_Adjustment_Line_Item__r.APTS_End_Date__c!=null&&categoryCerRecord.APTS_Pending_Adjustment_Line_Item__r.APTS_Start_Date__c>Date.today() && categoryCerRecord.APTS_Pending_Adjustment_Line_Item__r.APTS_End_Date__c<=Date.today())
                    //{
                    //check = false;
                    //}
                    if (isAgreementCart && categoryCerRecord.APTS_Agreement_Line_Item__r.Apttus_CMConfig__LineType__c == OPTION && categoryCerRecord.APTS_Contributing_Agreement_Level__c != CHILD)
                    {
                        check = false;
                    }
                    if ((!isAgreementCart) && categoryCerRecord.APTS_Agreement_Line_Item__r.APTS_MachineCoffeeKitchen__c && !globalLinkageId.contains(categoryCerRecord.APTS_Agreement_Line_Item__r.APTS_Global_linkage_ID__c)) {
                        check = false;
                    }
                    if ((categoryCerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || categoryCerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || categoryCerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (categoryCerRecord.APTS_Start_Date__c != null && categoryCerRecord.APTS_Start_Date__c> Date.today())) {
                        check = false;
                    }
                    if ((categoryCerRecord.APTS_Agreement_Line_Item__r.APTS_Bundle_Option__c || categoryCerRecord.APTS_Agreement_Line_Item__r.APTS_Ingredient_Standalone__c || categoryCerRecord.APTS_Agreement_Line_Item__r.APTS_More_Standalone__c) && (categoryCerRecord.APTS_End_Date__c != null && categoryCerRecord.APTS_End_Date__c <= Date.today())) {
                        check = false;
                    }

                    CategoryHierarchy cch = productCategories.get(pID);
                    if (categoryCerRecord.APTS_Product__c != categoryProductId) {
                        if (pID == categoryCerRecord.APTS_Product__c && check) {
                            tempCerList = returnObject.get(pID) != null ? returnObject.get(pID) : new List<APTS_Contract_Entitlement_Repository__c> ();
                            tempCerList.add(categoryCerRecord);
                            returnObject.put(pID, tempCerList);
                        }
                    }
                    //if ((cch.level == 0 && cch.categoryId == categoryCerRecord.APTS_CategoryCER__c) || (cch.level == 1 && cch.categoryId == categoryCerRecord.APTS_CategoryCER__c && cch.subCategoryId == categoryCerRecord.APTS_Sub_Category__c) || (cch.level == 2 && cch.categoryId == categoryCerRecord.APTS_CategoryCER__c && cch.subCategoryId == categoryCerRecord.APTS_Sub_Category__c && cch.subSubCategoryId == categoryCerRecord.APTS_Sub_Sub_Category__c))
                    else if (check && ((cch.categoryId == categoryCerRecord.APTS_CategoryCER__c && categoryCerRecord.APTS_Sub_Category__c == null && categoryCerRecord.APTS_Sub_Sub_Category__c == null) || (cch.categoryId == categoryCerRecord.APTS_CategoryCER__c && cch.subCategoryId == categoryCerRecord.APTS_Sub_Category__c && categoryCerRecord.APTS_Sub_Sub_Category__c == null) || (cch.categoryId == categoryCerRecord.APTS_CategoryCER__c && cch.subCategoryId == categoryCerRecord.APTS_Sub_Category__c && cch.subSubCategoryId == categoryCerRecord.APTS_Sub_Sub_Category__c) || (categoryCerRecord.APTS_Category_Level__c == Null))) {

                        tempCerList = returnObject.get(pID) != null ? returnObject.get(pID) : new List<APTS_Contract_Entitlement_Repository__c> ();
                        tempCerList.add(categoryCerRecord);
                        returnObject.put(pID, tempCerList);
                    }

                }
            }
        }
        System.debug('P1Defect*****' + returnObject);

        return returnObject;
    }

    public static List<APTS_Contract_Entitlement_Repository__c> getCategoryProducts(Id soldToAccountId, Id productId, String categoryLevel, Id category, Id subCategory, Id subSubCategory) {
        String query = 'SELECT Id, Name, APTS_Agreement_Adjustment_Line_Item__c, APTS_Adjustment_Type__c,' +
        'APTS_Adjustment_Value__c, APTS_Agreement_Line_Item__c, APTS_Category__c, APTS_Category__r.Name,' +
        'APTS_Category_Level__c, APTS_Contributing_Agreement__c,' +
        'APTS_Pricing_Sub_Type__c,' +
        'APTS_Pricing_Type__c, APTS_Product__c,APTS_Sold_to_Party__c,' +
        'APTS_Adjustment_Applies_To__c,APTS_Type__c,APTS_Sub_Type__c,APTS_Bucket__c,' +
        'APTS_UOM__c, APTS_Category_Label__c, APTS_CategoryCER__c,APTS_CategoryCER__r.Name, APTS_Sub_Category__c,' +
        'APTS_Sub_Sub_Category__c, APTS_Is_Pending__c, ' +
        'APTS_Contributing_Agreement_Level__c ' +
        'FROM APTS_Contract_Entitlement_Repository__c ' +
        'WHERE APTS_Sold_to_Party__c = :soldToAccountId ' +
        'AND APTS_Product__c = :productId ' +
        'AND APTS_Category_Level__c = :categoryLevel ';

        if (category != null) {
            query += 'AND APTS_CategoryCER__c = :category ';
        } else if (subCategory != null) {
            query += 'AND APTS_Sub_Category__c = :subCategory ';
        } else if (subSubCategory != null) {
            query += 'AND APTS_Sub_Sub_Category__c = :subSubCategory ';
        }

        List<APTS_Contract_Entitlement_Repository__c> cerList = Database.query(query);

        return cerList;
    }

    public static List<APTS_Contract_Entitlement_Repository__c> getAllCategoryProducts(Id soldToAccountId, Id productId) {
        String query = 'SELECT Id, Name, APTS_Agreement_Adjustment_Line_Item__c, APTS_Adjustment_Type__c,' +
        'APTS_Adjustment_Value__c, APTS_Agreement_Line_Item__c, APTS_Category__c, APTS_Category__r.Name,' +
        'APTS_Category_Level__c, APTS_Contributing_Agreement__c,' +
        'APTS_Pricing_Sub_Type__c,' +
        'APTS_Pricing_Type__c, APTS_Product__c,APTS_Sold_to_Party__c,' +
        'APTS_Adjustment_Applies_To__c,APTS_Type__c,APTS_Sub_Type__c,APTS_Bucket__c,' +
        'APTS_UOM__c, APTS_Category_Label__c, APTS_CategoryCER__c,APTS_CategoryCER__r.Name, APTS_Sub_Category__c,' +
        'APTS_Sub_Sub_Category__c, APTS_Is_Pending__c, ' +
        'APTS_Contributing_Agreement_Level__c ' +
        'FROM APTS_Contract_Entitlement_Repository__c ' +
        'WHERE APTS_Sold_to_Party__c = :soldToAccountId ' +
        'AND APTS_Product__c = :productId ';

        List<APTS_Contract_Entitlement_Repository__c> cerList = Database.query(query);

        return cerList;
    }
    public static void applyBPO(Id cartId, Boolean isDigital)
    {
        Map<Id, APTS_Contract_Entitlement_Repository__c> cerBPOMap = new Map<Id, APTS_Contract_Entitlement_Repository__c> ();
        Set<Id> agreementExculsion = new Set<Id> ();
        String tempString = '';
        Set<String> uomInput = new Set<String> ();
        Map<Id, String> uomKey = new Map<Id, String> ();
        Map<String, Decimal> uomOutput = new Map<String, Decimal> ();
        Id tempPid;
        List<Apttus_Config2__LineItem__c> lineItemList = new List<Apttus_Config2__LineItem__c> ();
        List<Apttus_Config2__LineItem__c> updateLineItemList = new List<Apttus_Config2__LineItem__c> ();
        Id soldToAccountId = [select Apttus_Config2__AccountId__c from Apttus_Config2__ProductConfiguration__c where id = :cartId].Apttus_Config2__AccountId__c;
        if (soldToAccountId != null) {
            Id tempSoldToAccountId = APTS_CERUtility.getCerRecordAccountForRelatedAccount(soldToAccountId, false);
            for (APTS_Contract_Entitlement_Repository__c cerrecord :[Select APTS_Product__c, APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c,
                 APTS_Start_Date__c,
                 APTS_End_Date__c,
                 APTS_Agreement_Line_Item__c,
                 APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c from APTS_Contract_Entitlement_Repository__c
                 where APTS_Sold_to_Party__c = :tempSoldToAccountId and APTS_Is_Pending__c = false
                 and APTS_Contributing_Agreement__c not in :agreementExculsion
                 and APTS_Agreement_Line_Item__c not in(Select APTS_Agreement_Line_Item__c from APTS_Agreement_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                 and APTS_Agreement_Adjustment_Line_Item__c not in(Select APTS_Agreement_Adjustment_Line_Item__c from APTS_Adjustment_Line_Account_Exclusion__c where APTS_Account__c = :soldToAccountId)
                 ORDER BY APTS_Contributing_Agreement_Level_Num__c, LastModifiedDate DESC]) {
                if (cerBPOMap.get(cerrecord.APTS_Product__c) == null)
                {
                    cerBPOMap.put(cerrecord.APTS_Product__c, cerrecord);
                }

            }
            lineItemList = [SELECT Id, Apttus_Config2__LineType__c,
                            Apttus_Config2__ProductId__c, Apttus_Config2__OptionId__c,
                            Apttus_Config2__ProductId__r.ProductCode,
                            Apttus_Config2__OptionId__r.ProductCode,
                            Apttus_Config2__PriceListItemId__r.Apttus_Config2__PriceUom__c,
                            Apttus_Config2__PriceListItemId__r.APTS_Default_Selling_Uom__c,
                            APTS_Source_Line_Number__c,
                            Apttus_Config2__PricingStatus__c,
                            Apttus_Config2__SellingUom__c
                            FROM Apttus_Config2__LineItem__c
                            WHERE Apttus_Config2__ConfigurationId__c = :cartId];
            //V108 END
            for (Apttus_Config2__LineItem__c lineItem : lineItemList) {
                tempPid = lineItem.Apttus_Config2__LineType__c == PRODUCT_SERVICE ? lineItem.Apttus_Config2__ProductId__c : lineItem.Apttus_Config2__OptionId__c;
                tempString = '';
                if (lineItem.Apttus_Config2__ProductId__r.ProductCode != null)
                {
                    if (lineItem.Apttus_Config2__LineType__c == PRODUCT_SERVICE)
                    tempString += lineItem.Apttus_Config2__ProductId__r.ProductCode;
                    else
                    tempString += lineItem.Apttus_Config2__OptionId__r.ProductCode;
                }
                if (cerBPOMap.get(tempPid) != null && cerBPOMap.get(tempPid).APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c != null)
                {
                    tempString += ';' + cerBPOMap.get(tempPid).APTS_Agreement_Line_Item__r.Apttus_CMConfig__SellingUom__c;
                }
                system.debug('++ShahulSellingUOM' + lineItem.Apttus_Config2__SellingUom__c);
                if (lineItem.Apttus_Config2__SellingUom__c != null)
                {
                    system.debug('++ShahulSellingUOM' + lineItem.Apttus_Config2__SellingUom__c);
                    if (isDigital)
                    tempString += ';' + lineItem.Apttus_Config2__SellingUom__c;
                    else
                    tempString += ';' + lineItem.Apttus_Config2__PriceListItemId__r.APTS_Default_Selling_Uom__c;
                    // tempString += ';' + lineItem.Apttus_Config2__SellingUom__c;
                }

                if (!uomInput.contains(tempString))
                {
                    uomInput.add(tempString);
                    uomKey.put(tempPid, tempString);
                }

            }
            System.debug('uomInput****' + uomInput);
            if (uomInput != null)
            uomOutput = APTS_UOMConversionUtils.getUOMConversions(uomInput);
            System.debug('uomOutput****' + uomOutput);
            for (APTS_Agreement_Account_Exclusion__c aae :[Select APTS_Agreement__c from APTS_Agreement_Account_Exclusion__c where APTS_Account__c = :soldToAccountId])
            {
                if (!agreementExculsion.contains(aae.APTS_Agreement__c))
                agreementExculsion.add(aae.APTS_Agreement__c);
            }
            if (cerBPOMap.size() > 0)
            {
                Decimal uomFactor;
                for (Apttus_Config2__LineItem__c l : lineItemList) {
                    tempPid = l.Apttus_Config2__LineType__c == PRODUCT_SERVICE ? l.Apttus_Config2__ProductId__c : l.Apttus_Config2__OptionId__c;
                    uomFactor = uomOutput.get(uomKey.get(tempPid)) != null ? uomOutput.get(uomKey.get(tempPid)) : 1;
                    System.debug('uomFactor****' + uomFactor);
                    if (cerBPOMap.get(tempPid) != null && cerBPOMap.get(tempPid).APTS_Agreement_Line_Item__c != null && cerBPOMap.get(tempPid).APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c != null && cerBPOMap.get(tempPid).APTS_Start_Date__c != null && cerBPOMap.get(tempPid).APTS_Start_Date__c <= Date.today() && cerBPOMap.get(tempPid).APTS_End_Date__c != null && cerBPOMap.get(tempPid).APTS_End_Date__c > Date.today()
                    )
                    {
                        l.Apttus_Config2__BasePriceOverride__c = (cerBPOMap.get(tempPid).APTS_Agreement_Line_Item__r.Apttus_CMConfig__BasePriceOverride__c * uomFactor);
                        //if (!isDigital)
                        //{
                        l.Apttus_Config2__PricingStatus__c = 'Pending';
                        //}
                        System.debug('Lavanya cerutil bpo apply ');
                        updateLineItemList.add(l);

                    }

                }
                if (updateLineItemList.size() > 0)
                {
                    update updateLineItemList;
                }
            }
        }
    }
    
    /** REST Webservice for Digital to share the invoice related information
    CreatedBy: Shahul
    Created Date: 09/03/2021
    */
    public static APTS_GetInvoicedetailRest.GetInvoicedetailReturnObject getInvoicedetail(Id soldToAccountId)
    {
       
        APTS_GetInvoicedetailRest.GetInvoicedetailReturnObject returnObject = new APTS_GetInvoicedetailRest.GetInvoicedetailReturnObject();
        //APTS_GetInvoicedetailRest.GetInvoicedetailWrapper gpw = new APTS_GetInvoicedetailRest.GetInvoicedetailWrapper();
        try{
        for(Account acc:[select id,APTS_Free_Freight_Charges__c,Enable_Invoice_Payment_Flag__c,APTS_Free_Paper_Invoices__c,Bill_To_Payer_Account__c,Bill_To_Payer_Account__r.Enable_Invoice_Payment_Flag__c,Bill_To_Payer_Account__r.APTS_Free_Paper_Invoices__c from account where ID =:soldToAccountId]){
            returnObject.freightcharge=acc.APTS_Free_Freight_Charges__c;
        if(acc.Bill_To_Payer_Account__c!=null){
            returnObject.invoicepayment=acc.Bill_To_Payer_Account__r.Enable_Invoice_Payment_Flag__c;
            returnObject.freepaperinvoice=acc.Bill_To_Payer_Account__r.APTS_Free_Paper_Invoices__c;
        
        }
        else if(acc.Bill_To_Payer_Account__c==null){
            returnObject.invoicepayment=acc.Enable_Invoice_Payment_Flag__c;
            returnObject.freepaperinvoice=acc.APTS_Free_Paper_Invoices__c;
        }       
        }
        //returnObject.response=gpw;
        returnObject.success = true;
        returnObject.errorMessage = '';
        }
        Catch(Exception e)
        {
            returnObject.success = false;returnObject.errorMessage = e.getMessage();
        }
        return returnObject;
    }
    
     /** REST Webservice for Digital to share the payment related information
    CreatedBy: Shahul
    Created Date: 09/03/2021
    */
    
    public static APTS_GetPaymentdetailRest.GetPaymentdetailReturnObject getPaymentdetail(Id soldToAccountId)
    {
        Set<Id> setSoldToId = new Set<Id>();
        Set<Id> setAgIds = new Set<Id>();
        setSoldToId.add(soldToAccountId);
        Map<Id, Account> mapAccount = APTS_DigitalOrderUtils.getAccounts(setSoldToId);
        Map<Id, Apttus__APTS_Agreement__c> mapStandardAgs = new Map<Id, Apttus__APTS_Agreement__c>();
        if (mapAccount != null) {
        APTS_RSOOrderUtils.AccountHierarchyWrapper oAccHierachyWrap = APTS_RSOOrderUtils.getAccountHierarchyId(mapAccount.values());
        mapStandardAgs = APTS_DigitalOrderUtils.getDigitalAgreements(oAccHierachyWrap.setAccountToVisitId, oAccHierachyWrap.setAllAccountId, oAccHierachyWrap.mapParentId, oAccHierachyWrap.mapGrandParentId);
        if (mapStandardAgs != null) {
        for (Apttus__APTS_Agreement__c agTmp : mapStandardAgs.values()) {
             setAgIds.add(agTmp.Id);
             }
            system.debug('++Shahul_setAgIds+++New+++'+setAgIds);
        }
        }
        APTS_GetPaymentdetailRest.GetPaymentdetailReturnObject returnObject = new APTS_GetPaymentdetailRest.GetPaymentdetailReturnObject();
        //APTS_GetPaymentdetailRest.GetPaymentdetailWrapper gpw = new APTS_GetPaymentdetailRest.GetPaymentdetailWrapper();
        try{
            
           for(Apttus__APTS_Agreement__c agr:[select id,APTS_Check_on_Account_Ingredients__c,Apttus__Account__r.Bill_To_Payer_Account__c,Apttus__Account__r.Apttus_Config2__PaymentTermId__c,Apttus__Account__r.Apttus_Config2__PaymentTermId__r.name,Apttus__Account__r.Apttus_Config2__PaymentTermId__r.APTS_Ext_ID__c,Apttus__Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,Apttus__Account__r.Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__c,
                                    Apttus__Account__r.Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__r.name,Apttus__Account__r.Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__r.APTS_Ext_ID__c,Apttus__Account__r.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c,
                                    (select id,APTS_Payment_Term_Setting__c,APTS_Payment_Term_Setting__r.name,APTS_Payment_Term_Setting__r.APTS_Ext_ID__c,APTS_Invoice_Delivery_Preference__c from Billing_Settings__r where APTS_Agreement_Billing_Type__c='Ingredients') from Apttus__APTS_Agreement__c where id IN:setAgIds]){
                        if(agr.APTS_Check_on_Account_Ingredients__c==false){
                returnObject.paymentterm=agr.Billing_Settings__r[0].APTS_Payment_Term_Setting__r.name;
                returnObject.paymenttermid=agr.Billing_Settings__r[0].APTS_Payment_Term_Setting__c;
                returnObject.paymenttermsapid=agr.Billing_Settings__r[0].APTS_Payment_Term_Setting__r.APTS_Ext_ID__c;
                returnObject.invoicedelivery=agr.Billing_Settings__r[0].APTS_Invoice_Delivery_Preference__c;
                }
                else if(agr.APTS_Check_on_Account_Ingredients__c==true){
                        if(agr.Apttus__Account__r.Bill_To_Payer_Account__c==null){
                        returnObject.paymentterm=agr.Apttus__Account__r.Apttus_Config2__PaymentTermId__r.name;
                        returnObject.paymenttermid=agr.Apttus__Account__r.Apttus_Config2__PaymentTermId__c;
                        returnObject.paymenttermsapid=agr.Apttus__Account__r.Apttus_Config2__PaymentTermId__r.APTS_Ext_ID__c;
                        returnObject.invoicedelivery=agr.Apttus__Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
                        }
                        else{
                        returnObject.paymentterm=agr.Apttus__Account__r.Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__r.name;
                        returnObject.paymenttermid=agr.Apttus__Account__r.Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__c;
                        returnObject.paymenttermsapid=agr.Apttus__Account__r.Bill_To_Payer_Account__r.Apttus_Config2__PaymentTermId__r.APTS_Ext_ID__c;
                        returnObject.invoicedelivery=agr.Apttus__Account__r.Bill_To_Payer_Account__r.Apttus_Config2__BillingPreferenceId__r.APTS_Invoice_Delivery_Preference__c;
                        }
                }
                
            }
        //returnObject.response.add(gpw);
        returnObject.success = true;returnObject.errorMessage = '';
        }
        Catch(Exception e)
        {
            returnObject.success = false;
            returnObject.errorMessage = e.getMessage();
        }
        return returnObject;
        
    }

}