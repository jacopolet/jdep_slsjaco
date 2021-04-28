/*************************************************************
@Name: APTS_DeInstallAdminOrderController
@Author: V. Shankaranarayanan
@CreateDate: 01-06-2018
@Description: Controller for APTS_DeInstallAdminOrder VF page
@UsedBy: APTS_DeInstallAdminOrder VF page
******************************************************************/
public with sharing class APTS_DeInstallAdminOrderController{

    private final Apttus_Config2__AssetLineItem__c oAssetLineItem;
    private Id orderId;
    private String orderSubType;
    private static final String ADMIN = System.Label.APTS_AdminOrder;
    private static final String ID = System.Label.APTS_Id;
    private static final String CONVERSION = System.Label.APTS_ConversionOrder;
    private static final String ACTIVATED = System.Label.APTS_Activated;
    private static final String INSTALLATION = System.Label.APTS_Installation;
    private static final String DEINSTALLATION = System.Label.APTS_De_installation;
    private static final String RENEWAL = System.Label.APTS_Renewal;
    private static final String TEMPDEACTIVATED = System.Label.APTS_TemporaryDeactivated;
    private static final String CANCELLED = System.Label.APTS_Cancelled;
    private static final String OPTION = System.Label.APTS_Option;
    private static List<Apttus_Config2__Order__c> orderList = new List<Apttus_Config2__Order__c>();
    private static Set<Id> installphysicalasset = new set<Id>();
    private static Set<Id> deinstallphysicalasset = new set<Id>();
    private static final String ASSETLINEITEM = 'Apttus_Config2__AssetLineItem__c';
    private static final String PHYASSET = 'PhysicalAsset__c ';


    
    public Apttus_Config2__Order__c oOrder {get; set;}
    public List<AssetLineItemWrapper> assetLineItemWrapperList {get; set;}
    Map<Id, Id> aLIIdToDerivedFromIdMap = new Map<Id, Id>();
    Map<Id, Apttus__AgreementLineItem__c> aLIIdToAggLIMap = new Map<Id, Apttus__AgreementLineItem__c>();
    public Boolean bShowInstalledAssets {get; set;}
    public Boolean bShowDeinstalledAssets {get; set;}
    public Boolean bShowRenewedAssets {get; set;}
    
    public APTS_DeInstallAdminOrderController(){
        orderId = ApexPages.currentPage().getParameters().get(ID);
        bShowInstalledAssets = false;
        bShowDeinstalledAssets = false;
        bShowRenewedAssets = false;
    }
    
    
    public PageReference getAssets(){
        try{
            orderList = [SELECT Id, APTS_Order_Sub_Type__c, Apttus_Config2__SoldToAccountId__c, Apttus_CMConfig__AgreementId__c FROM Apttus_Config2__Order__c WHERE Id =: orderId LIMIT 1];
            if(orderList.size() > 0){
                oOrder = orderList[0];
                orderSubType = oOrder.APTS_Order_Sub_Type__c;
                String accountId = oOrder.Apttus_Config2__SoldToAccountId__c;
                String lineType = 'Product/Service';
                String renewed = 'Renewed';
                String agreementId = oOrder.Apttus_CMConfig__AgreementId__c;
                assetLineItemWrapperList = new List<AssetLineItemWrapper>();
                String query;
                Set<Id> aLIIdSet = new Set<Id>();
                
                if(oOrder != null){
                    if(RENEWAL.equalsIgnoreCase(orderSubType)){
                        for(Apttus__AgreementLineItem__c aggLI : [SELECT Id, Apttus__AgreementId__c, Apttus_CMConfig__DerivedFromId__c, Apttus_CMConfig__LineStatus__c, Apttus_CMConfig__AssetLineItemId__c, Apttus_CMConfig__StartDate__c, Apttus_CMConfig__EndDate__c FROM Apttus__AgreementLineItem__c WHERE Apttus__AgreementId__c =: agreementId AND Apttus_CMConfig__LineStatus__c =: renewed AND Apttus_CMConfig__AssetLineItemId__c != null LIMIT 50000]){
                            aLIIdToDerivedFromIdMap.put(aggLI.Apttus_CMConfig__AssetLineItemId__c, aggLi.Apttus_CMConfig__DerivedFromId__c);
                            aLIIdSet.add(aggLI.Apttus_CMConfig__AssetLineItemId__c);
                            aLIIdToAggLIMap.put(aggLI.Apttus_CMConfig__AssetLineItemId__c, aggLI);
                        }               
                        
                        query = 'SELECT Id, Name, Apttus_Config2__AssetStatus__c, Apttus_Config2__ProductId__c, Apttus_Config2__ParentAssetId__c, Apttus_Config2__BundleAssetId__c, Apttus_Config2__AccountId__r.Name, Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c, APTS_Sub_Status__c, APTS_Sub_Status_Update_Date__c, APTS_Physical_Asset__c FROM Apttus_Config2__AssetLineItem__c WHERE Id IN: aLIIdSet AND Apttus_Config2__IsPrimaryLine__c=true AND Apttus_Config2__LineType__c=: lineType LIMIT 50000'; 
                        bShowRenewedAssets = true;
                        
                    }else if(INSTALLATION.equalsIgnoreCase(orderSubType) || DEINSTALLATION.equalsIgnoreCase(orderSubType)){
                        query = 'SELECT Id, Name, Apttus_Config2__AssetStatus__c, Apttus_Config2__ProductId__c, Apttus_Config2__ParentAssetId__c, Apttus_Config2__BundleAssetId__c, Apttus_Config2__AccountId__r.Name, Apttus_Config2__StartDate__c, Apttus_Config2__EndDate__c, APTS_Sub_Status__c, APTS_Sub_Status_Update_Date__c, APTS_Physical_Asset__c FROM Apttus_Config2__AssetLineItem__c WHERE Apttus_Config2__AccountId__c =: accountId AND Apttus_Config2__LineType__c =: lineType AND APTS_Sub_Status__c = null AND Apttus_Config2__BundleAssetId__c = null AND Apttus_Config2__ParentAssetId__c = null LIMIT 50000';
                        if(INSTALLATION.equalsIgnoreCase(orderSubType)){
                            //query = query.replace('=: ACTIVATED', '!=: ACTIVATED');
                            query = query.replace('APTS_Sub_Status__c = null','APTS_Sub_Status__c =:TEMPDEACTIVATED');
                        }
                        bShowInstalledAssets = (INSTALLATION.equalsIgnoreCase(orderSubType) ? true : false);
                        bShowDeinstalledAssets = (DEINSTALLATION.equalsIgnoreCase(orderSubType) ? true : false);
        
                    }
                    for(Apttus_Config2__AssetLineItem__c assetLineItem : Database.query(query)){
                        AssetLineItemWrapper oAssetLineItemWrapper = new AssetLineItemWrapper(false, assetLineItem);
                        assetLineItemWrapperList.add(oAssetLineItemWrapper);
                    }
                }
            }
        }catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Exception occurred : '+ex.getMessage()));
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), '', '', 'CLM', false, false, null, true);
        }
        return null;
    }
    
    public PageReference deinstallAssets(){
        try{
            if(Apttus_Config2__AssetLineItem__c.sObjectType.getDescribe().isUpdateable()){//Performance issue fixes by Ajith
            List<Apttus_CPQApi.CPQ.AddBundleRequestDO> addBundleRequestDO = new List<Apttus_CPQApi.CPQ.AddBundleRequestDO>();
            List<Apttus_Config2__AssetLineItem__c> aLIList = new List<Apttus_Config2__AssetLineItem__c>();
            PageReference pageRef;
            List<Id> assetIdList = new List<Id>();
            Set<Id> idSet = new Set<Id>();
            Id cartId = APTS_OrderUtils.createCart(orderId);
            
            for(AssetLineItemWrapper aLIWrapper : assetLineItemWrapperList){
                if(aLIWrapper.selected){
                    assetIdList.add(aLIWrapper.oAssetLineItem.Id);
                    aLIList.add(aLIWrapper.oAssetLineItem);
                }
            }
            
            for(Id id : aLIIdToDerivedFromIdMap.values()){
                idSet.add(id);
            }
            
            if(RENEWAL.equalsIgnoreCase(orderSubType)){
                for(Apttus_Config2__AssetLineItem__c asset : aLIList){
                    Apttus_CPQApi.CPQ.AddBundleRequestDO request = new Apttus_CPQApi.CPQ.AddBundleRequestDO();
                    request.CartId = cartId;
                    request.SelectedBundle = new Apttus_CPQApi.CPQ.SelectedBundleDO();
                    request.SelectedBundle.SelectedProduct = new Apttus_CPQApi.CPQ.SelectedProductDO();
                    request.SelectedBundle.SelectedProduct.ProductId = asset.Apttus_Config2__ProductId__c;
                    request.SelectedBundle.SelectedProduct.StartDate = aLIIdToAggLIMap.get(asset.Id).Apttus_CMConfig__StartDate__c;
                    request.SelectedBundle.SelectedProduct.EndDate = aLIIdToAggLIMap.get(asset.Id).Apttus_CMConfig__EndDate__c;
                    request.SelectedBundle.SelectedProduct.Quantity = 1;
                    
                    Map<Id, Apttus_Config2__LineItem__c> oliMap = APTS_OrderUtils.getLineItemDataAll(idSet);
                    Apttus_Config2__LineItem__c oLineItem = oliMap.get(aLIIdToDerivedFromIdMap.get(asset.Id));
                    request.SelectedBundle.SelectedProduct.CustomData = oLineItem;
                    request.SelectedBundle.SelectedProduct.CustomFields = APTS_OrderUtils.setLineItemFieldList();
                    
                    Apttus_CPQApi.CPQ.AddBundleResponseDO response = Apttus_CPQApi.CPQWebService.addBundle(request);
                }
            }else if(INSTALLATION.equalsIgnoreCase(orderSubType)) {
                aLIList = getAssetstoupdate(aLIList);
                for(Apttus_Config2__AssetLineItem__c asset : aLIList){
                    asset.APTS_Sub_Status__c = null;
                    asset.APTS_Sub_Status_Update_Date__c = null;
                    if(asset.APTS_Physical_Asset__c != null) {
                        installphysicalasset.add(asset.APTS_Physical_Asset__c);
                    }
                }
                DescribeSObjectResult objResultALI = APTS_OTCUtil.getsObjectAccess(ASSETLINEITEM);
                if(objResultALI != null &&  objResultALI.isUpdateable() )
                {
                    update aLIList;
                }
                if(!installphysicalasset.isEmpty()) {
                    updatephysicalassets(installphysicalasset, ACTIVATED);    
                }
                
            }
            else if(DEINSTALLATION.equalsIgnoreCase(orderSubType)){
                //Map<Id, Apttus_Config2__LineItem__c> cancelAssetsMap = APTS_OrderUtils.cancelAssets(cartId, assetIdList);
                aLIList = getAssetstoupdate(aLIList);
                for(Apttus_Config2__AssetLineItem__c asset : aLIList){
                    asset.APTS_Sub_Status__c = TEMPDEACTIVATED;
                    asset.APTS_Sub_Status_Update_Date__c = system.today();
                    if(asset.APTS_Physical_Asset__c != null) {
                        deinstallphysicalasset.add(asset.APTS_Physical_Asset__c);
                    }
                }
                DescribeSObjectResult objResultALI = APTS_OTCUtil.getsObjectAccess(ASSETLINEITEM);
                if(objResultALI != null &&  objResultALI.isUpdateable() )
                {
                    update aLIList;
                }
                if(!deinstallphysicalasset.isEmpty()) {
                    updatephysicalassets(deinstallphysicalasset, CANCELLED);
                }
            }}
            //APTS_OrderUtils.repriceCart(cartId);
            //APTS_OrderUtils.finalizeCart(cartId);
            //APTS_OrderUtils.syncCart(cartId);

            return new PageReference('/' + orderId);
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Exception occurred : '+ex.getMessage()));
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Admin Order', orderId , 'CLM', false, false, null, true);
            return null;
        }
    }
    

    public PageReference back(){
        return new PageReference('/' + orderId);
    }

    public void updatephysicalassets(Set<Id> physicalasset, string status) {
        List<PhysicalAsset__c> phassetlist = new List<PhysicalAsset__c>();
        try{
            if(PhysicalAsset__c.sObjectType.getDescribe().isUpdateable()){//Performance issue fixes by Ajith
                for(Id phassetid: physicalasset) {
                    PhysicalAsset__c oPhAsset = new PhysicalAsset__c(id=phassetid, AssetStatus__c = status);
                    phassetlist.add(oPhAsset);
                }
                DescribeSObjectResult objResultPA = APTS_OTCUtil.getsObjectAccess(PHYASSET);
                if(objResultPA != null && objResultPA.isUpdateable() )
                {
                    update phassetlist;
                }
            }
        }catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Exception occurred : '+ex.getMessage()));
            APTS_CustomLogging.createErrorLog(ex.getTypeName(), 'Apex', ex.getStackTraceString(), 'Physical Asset', phassetlist[0].Id, 'CLM', false, false, null, true);
        }
    }

    public List<Apttus_Config2__AssetLineItem__c> getAssetstoupdate(List<Apttus_Config2__AssetLineItem__c> assetList) {
        Set<Id> assetidset = new Set<Id>();
        for(Apttus_Config2__AssetLineItem__c oASL : assetList) {
            assetidset.add(oASL.Id);
        }
        for(Apttus_Config2__AssetLineItem__c oASLI : [select id,name,APTS_Sub_Status__c,APTS_Sub_Status_Update_Date__c,APTS_Physical_Asset__c from Apttus_Config2__AssetLineItem__c where Apttus_Config2__LineType__c =: OPTION and Apttus_Config2__BundleAssetId__c IN: assetidset]) {
            assetList.add(oASLI);
        }
        return assetList;
    }
   
    public with sharing class AssetLineItemWrapper{
        public Boolean selected {get; set;}
        public Apttus_Config2__AssetLineItem__c oAssetLineItem {get; set;}

        public AssetLineItemWrapper(Boolean selected, Apttus_Config2__AssetLineItem__c oAssetLineItem) {
            this.selected = selected;
            this.oAssetLineItem = oAssetLineItem;
        }
    }

}