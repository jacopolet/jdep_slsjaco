/*
*************************************************************************************
Class Name     :  APTS_AssetLineCallBack 
Purpose        :  Custom Asset Line item Callback class 
History:                                                            
-------                                                            
VERSION  AUTHOR             DATE            DETAIL                
   01   Aftab   01-Jun-2017     Created Class filtering assets
**************************************************************************************
*/
//v100 20-1-2021 Sneha: DQ4891 Unsuccessful Trial - Normal de-installation process/different SAP order type (XB23)


global with sharing class APTS_AssetLineCallBack implements  Apttus_Config2.CustomClass.IAssetLineItemCallback3{
    private String assetSearchFilter = null;
    private List<String> assetSearchScope = null;
    private Apttus_Config2__ProductConfiguration__c productConfiguration;
    private String agreementNumber = null;
    private String accId = null;
    private String BusinessObjectType = null;
    private String sapOrder = null;
    public Boolean isTrialOrder =false;
    /**
     * Callback at the beginning of the asset selection call.
     * Use the start method to initialize state
     * @param cart the cart object or null if there is no cart context
     * @param assetSearchFilter the preset static filter used in the asset search or null if there is no preset filter
     * @param assetSearchScope the list of asset fields to match the search text or empty to use the default list of fields
     */
     
    public void start(Apttus_Config2.ProductConfiguration cart,String assetSearchFilter, List<String> assetSearchScope){
            
            System.debug('***AssetLineItemCB: start()-1: ' + assetSearchScope);
            //System.debug('***AssetLineItemCB: start()-2: ' + cart);
            System.debug('***AssetLineItemCB: start()-3: ' + assetSearchFilter);
            
            Set<ID> assetIDs = new Set<ID>();
            
            this.assetSearchFilter = assetSearchFilter;
            this.assetSearchScope = assetSearchScope;
            
            this.productConfiguration = cart.getConfigSO();
            
            if(productConfiguration!=null && productConfiguration.Apttus_Config2__AccountId__c != null){/*
                //AgreementId = productConfiguration.Apttus_CMConfig__AgreementId__c;
                BusinessObjectType = productConfiguration.Apttus_Config2__BusinessObjectType__c;
                if(BusinessObjectType.equalsIgnoreCase('Agreement')){
                    //agreementNumber = productConfiguration.Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c;
                    Apttus__APTS_Agreement__c newAgr = [Select Id, Apttus__Agreement_Number__c from Apttus__APTS_Agreement__c where Id = :productConfiguration.Apttus_CMConfig__AgreementId__c];
                    agreementNumber = newAgr.Apttus__Agreement_Number__c;
                }else{
                    accId = productConfiguration.Apttus_Config2__AccountId__c;
                }*/
                accId = productConfiguration.Apttus_Config2__AccountId__c;
                //v100++<<
                sapOrder = productConfiguration.Apttus_Config2__OrderId__c;
                string query1 = 'Select APTS_SAP_OrderType__c from Apttus_Config2__Order__c where id=:sapOrder ';
                List<Apttus_Config2__Order__c> lstorder = Database.query(query1);
                for(Apttus_Config2__Order__c ord:lstorder){
                if(ord.APTS_SAP_OrderType__c =='XB23'){
                isTrialOrder=true;
                }
                }
                //v100++>>
            }
        system.debug('$$$$ agreementNumber '+agreementNumber);
        system.debug('$$$$ accId '+accId);
            
    }
    
    /******************************************************************************
     * Gets the asset search scope
     * @return the asset search scope or null to use the default asset search scope
    ******************************************************************************* */
    public List<String> getAssetSearchScope(){
    
           System.debug('***AssetLineItemCB: getAssetSearchScope()-returning: ' + this.assetSearchScope);
           return this.assetSearchScope; 
    }
    
    /*******************************************************************************
     * Callback to return the filter expression for the asset query where clause
     * This filter is used in listing installed products
     * @param params the parameters for the method
     * @return the filter expression or null to use the default filter.
     * e.g. Name LIKE 'A%' AND Quantity__c > 100
     *         Id IN ('000123', '000124') 
    ***************************************************************************** */
    public String getFilterExpr(Apttus_Config2.CustomClass.ActionParams params){
        
        System.debug('***AssetLineItemCB: getFilterExpr()-params: ' + params);
        Id AccountId = params.AccountId;
        String whereClause = null;
        //if(BusinessObjectType.equalsIgnoreCase('Account')){
           /*whereClause = 'Apttus_CMConfig__AgreementId__r.Apttus__Agreement_Number__c = \'' + agreementNumber + '\'';
          whereClause = 'Apttus_Config2__AccountId__c = \'' + accId + '\'';     
          whereClause += ' AND Apttus_Config2__AssetStatus__c = \'Activated\''; 
            /*whereClause += ' AND (NOT(APTS_Type_Of_Contract__c = \'Subscription\')) ';
            whereClause += ' AND (NOT(Apttus_Config2__LineType__c = \'Product/Service\'';
            whereClause += ' AND Apttus_Config2__IsPrimaryLine__c = true';   
            whereClause += ' AND Apttus_Config2__ProductId__r.Apttus_Config2__HasOptions__c = false';
            whereClause += ' AND Apttus_Config2__OptionId__c = null AND Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c != \'0703\'))';*/
    //v100++<<    
    if(isTrialOrder){
            whereClause = 'Apttus_Config2__AccountId__c = \'' + accId + '\'';     
          whereClause += ' AND Apttus_Config2__AssetStatus__c = \'Activated\'';
          whereClause += ' AND APTS_Type_Of_Contract__c = \'Trial\'';
            whereClause += ' AND (NOT(Apttus_Config2__LineType__c = \'Product/Service\'';
            whereClause += ' AND Apttus_Config2__IsPrimaryLine__c = true';   
            whereClause += ' AND Apttus_Config2__ProductId__r.Apttus_Config2__HasOptions__c = false';
            whereClause += ' AND Apttus_Config2__OptionId__c = null AND Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c != \'0703\'))';
         }
//v100++>>       
         else{
         whereClause = 'Apttus_Config2__AccountId__c = \'' + accId + '\'';     
          whereClause += ' AND Apttus_Config2__AssetStatus__c = \'Activated\'';
          whereClause += ' AND (APTS_Type_Of_Contract__c NOT IN(\'Subscription\',\'Trial\')) ';
            whereClause += ' AND (NOT(Apttus_Config2__LineType__c = \'Product/Service\'';
            whereClause += ' AND Apttus_Config2__IsPrimaryLine__c = true';   
            whereClause += ' AND Apttus_Config2__ProductId__r.Apttus_Config2__HasOptions__c = false';
            whereClause += ' AND Apttus_Config2__OptionId__c = null AND Apttus_Config2__ProductId__r.APTS_Sales_Catalog__c != \'0703\'))';
         }
         
        System.debug('***AssetLineItemCB: getFilterExpr()-whereClause' + whereClause);
        
        return whereClause;      
    }
    /*******************************************************************************
     * Callback to return part of SOQL filter clause
     * This filter is used in listing installed products
     * @param accountId is the context account id 
     * @return The query filter is like the following.
     *         Name LIKE 'A%' AND Quantity__c > 100
     *         Id IN ('000123', '000124') 
    ***************************************************************************** */
     
    public String getQueryFilter(ID accountId){
        System.debug('***AssetLineItemCB: getQueryFilter()-accountId: ' + accountId);
        return '';
    }
    
    /*******************************************************************************
     * Callback after the filter is used
     * Use the finish method to release state
    ***************************************************************************** */
    public void finish(){
        System.debug('***AssetLineItemCB: finish()');
    }
    
     global Boolean validateAssetTermination(Set<ID> assetIds, Set<ID> accountIds, Date effectiveDate) {
        return true;
    }
}