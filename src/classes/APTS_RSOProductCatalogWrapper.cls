/*************************************************************
@Name: APTS_RSOProductCatalogWrapper
@Author: Neev Shah
@CreateDate: 22-05-2018
@Description: Wrapper class
******************************************************************/
global with sharing class APTS_RSOProductCatalogWrapper {
  public Id ProductID {get; set;}
  public String ProductCode {get; set;}
  public String ProductName {get; set;}
  public String ProductImage {get; set;}
  public String Category {get; set;}
  public String SubCategory {get; set;}
  public String SubSubCategory {get; set;}
  public String UOM {get; set;}
  public Boolean RouteSales {get; set;}
  public Boolean IsActive {get; set;}

  public List<RSOProducts> listRSOProductsForToday {get; set;}
  public Map<Id, RSOProducts> mapRSOProducts {get; set;}
  public Map<Id, RSOProducts> mapAllRSOProducts {get; set;}
  public Map<String, List<RSOProducts>> mapCategoryCatalog {get; set;}
  public Map<String, Set<Id>> mapCategoryProductsId {get; set;}
  public Map<String, List<RSOProducts>> mapSubCategoryCatalog {get; set;}
  public Map<String, List<RSOProducts>> mapSubSubCategoryCatalog {get; set;}
  public List<BlockedProducts> listBlockedProducts {get; set;}

  public class UserInfo {
    public String ExecutingEngineer {get; set;}
    public String WorkOrderType {get; set;}
    public string AvailableUOM {get; set;}
  }

  public class RoutesInfo {
    public Id AccountID {get; set;}
    public String AccountName {get; set;}
    public String SAPCustomerID {get; set;}
    public Id SalesforceAccountLocationID {get; set;}
    public String LocationName {get; set;}
    public String HouseNumber {get; set;}
    public String Street {get; set;}
    public String City {get; set;}
    public String State {get; set;}
    public String Country {get; set;}
    public String PostalCode {get; set;}
    public String ContactFirstName {get; set;}
    public String ContactLastName {get; set;}
    public String ContactPhone {get; set;}
    public String ContactEmail {get; set;}
    public Id ContactID {get; set;}
    public String CaseID {get; set;}
    public Datetime ActualStartDate {get; set;}
    public String PONumber {get; set;}
    public String PONumberRequired {get; set;}
    public Boolean OrderNonContractedProducts {get; set;}
  }

  public class ContractedProducts {
    public ID AccountID {get; set;}
    public ID ProductID {get; set;}
    public String ProductCode {get; set;}
    public String ProductName {get; set;}
    public String ProductImage {get; set;}
    public String UOM {get; set;}
    public String SubSubCategory {get; set;}
    public String SubCategory {get; set;}
    public String Category {get; set;}
    public Boolean Consignment {get; set;}
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

  public class RSOProducts {
    public Id ProductID {get; set;}
    public String ProductCode {get; set;}
    public String ProductName {get; set;}
    public String ProductImage {get; set;}
    public String Category {get; set;}
    public String SubCategory {get; set;}
    public String SubSubCategory {get; set;}
    public String UOM {get; set;}
    public Boolean RouteSales {get; set;}
    public Boolean IsActive {get; set;}
  }

  public class CERData {
    public Map<Id, APTS_Contract_Entitlement_Repository__c> mapContributingAg {get; set;}
    public Map<String, List<APTS_Contract_Entitlement_Repository__c>> mapContractedProduct {get; set;}
    public Map<Id, Set<String>> mapConsignmentCategories {get; set;}    
  }

  public class Products {
    public Id ProductID {get; set;}
    public String ProductCode {get; set;}
    public String ProductName {get; set;}
    public String ProductImage {get; set;}
    public String Category {get; set;}
    public String SubCategory {get; set;}
    public String SubSubCategory {get; set;}
    public String UOM {get; set;}
    public Boolean IsActive {get; set;}
  }
  
  public class BlockedProducts {
    public Id ProductID {get; set;}
    public String ProductCode {get; set;}
    public String ProductName {get; set;}
    public Boolean IsActive {get; set;}
    public Boolean BlockedForSelling {get; set;}
  }
  
}