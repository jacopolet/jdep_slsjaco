/*************************************************************
@Name: APTS_CategoryBasedAdjustmentsCtrl
@Author: Raul Orozco
@CreateDate: 03-27-2018
@Description: Controller class for APTS_CategoryBasedAdjustments Vf Page. 
@UsedBy: APTS_CategoryBasedAdjustments
******************************************************************/
public without sharing class APTS_CategoryBasedAdjustmentsCtrl {

    public List<CategoryWrapper> listCategoryAdjustmentLines {get; set;}    
    public List<SubCategoryWrapper> listSubCategoryAdjustmentLines {get; set;}    
    public List<SubSubCategoryWrapper> listSubSubCategoryAdjustmentLines {get; set;}
    public Set<Id> setIdCERAdjustments {get; set;}
    
    public String agreementId;
    public Id accountId;
    public Map<Id, String> mapCategoryIdCategoryName = new Map<Id, String>();
    public Map<Id, Id> mapSubCategoryIdParentCategoryId = new Map<Id, Id>();
    public Map<Id, Id> mapSubSubCategoryIdParentCategoryId = new Map<Id, Id>();

    public Map<Id, Apttus_Config2__ClassificationHierarchy__c> mapAllCategoryIdCategory = new Map<Id, Apttus_Config2__ClassificationHierarchy__c>();
    public Map<Id, List<String>> mapSubCategoryIdListCategoryNames = new Map<Id, List<String>>();
    public Map<Id, List<String>> mapSubSubCategoryIdListCategoryNames = new Map<Id, List<String>>();
    public Map<String, Id> mapCategoryNameCategoryId = new Map<String, Id>();
    public Map<String, String> mapSubTypeLabelAndAPIName;

    private String priceListID = null;
    private String sMode;
    private Id cartId;
    private Id categoryProductId;
    private Boolean amendCERFlag;
    private String agreementRequestType;
    private Date agreementStartDate;
    private Date agreementEndDate;

    //Defect 22160
    private Map<String,Set<String>> mapAdjustmentType;

    public APTS_CategoryBasedAdjustmentsCtrl() {

        sMode = 'Cart';

        //Get configurations from metadata object
        List<APTS_Category_Discount_Settings__mdt> lstMetadata = new APTS_BatchMetadataCoverage().getMetadataCoverageRecords(
            'SELECT APTS_Adjustment_Type_Structure__c, '+
            'APTS_Category_Options__c '+
            'FROM APTS_Category_Discount_Settings__mdt '+ 
            'WHERE DeveloperName = \'General\''
        );

        //Get category product
        List<Product2> lstProduct = 
        [ 
            SELECT Id 
            FROM Product2 
            WHERE APTS_Category_Adjustments_Product__c = true 
        ];

        if(lstProduct.size() == 0){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Category product not configured.'));
        }else if(lstProduct.size() > 1){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'More than one Category product found.'));
        }else if(lstMetadata.isEmpty()){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Configuration record not found.'));
        }else{
            String strJSON = lstMetadata[0].APTS_Adjustment_Type_Structure__c;
            
            //Map containing structure of adjustment type/subtype
            mapAdjustmentType = (Map<String, Set<String>>) JSON.deserialize(strJSON, Map<String, Set<String>>.class);
            
            //Category product Id
            categoryProductId = lstProduct[0].Id;

            if (ApexPages.currentPage().getParameters().containsKey('Id')) {
            
                cartId = ApexPages.currentPage().getParameters().get('Id');
                System.Debug(LoggingLevel.ERROR,'cartId :: ' + cartId);
                List<Apttus_Config2__ProductConfiguration__c> listConfiguration = 
                [ 
                    SELECT Id, 
                    Apttus_CMConfig__AgreementId__c,
                    Apttus_Config2__AccountId__c,
                    APTS_Amendment_CER_Creation__c,
                    Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c 
                    FROM Apttus_Config2__ProductConfiguration__c 
                    WHERE Id = :cartId
                ];

                System.Debug(LoggingLevel.ERROR,'listConfiguration :: ' + listConfiguration);

                if (!listConfiguration.isEmpty()) {
            
                    agreementId = listConfiguration[0].Apttus_CMConfig__AgreementId__c;

                    //Populate variables
                    amendCERFlag = listConfiguration[0].APTS_Amendment_CER_Creation__c;
                    agreementRequestType = listConfiguration[0].Apttus_CMConfig__AgreementId__r.APTS_Agreement_Request__c;
                }

                System.Debug(LoggingLevel.ERROR,'agreementId :: ' + agreementId);
            }

            mapSubTypeLabelAndAPIName = getMapSubTypeLabelAndAPINames();

            List<Apttus__APTS_Agreement__c> listAgreements = [  SELECT Apttus_CMConfig__PriceListId__c, 
                                                                Apttus__Account__c,
                                                                Apttus__Contract_Start_Date__c,
                                                                Apttus__Contract_End_Date__c
                                                                FROM Apttus__APTS_Agreement__c
                                                                WHERE Id = : agreementId LIMIT 1];

            priceListID = listAgreements[0].Apttus_CMConfig__PriceListId__c;
            accountId = listAgreements[0].Apttus__Account__c;
            agreementStartDate = listAgreements[0].Apttus__Contract_Start_Date__c;
            agreementEndDate = listAgreements[0].Apttus__Contract_End_Date__c;

            listCategoryAdjustmentLines = new List<CategoryWrapper>();
            listSubCategoryAdjustmentLines = new List<SubCategoryWrapper>();
            listSubSubCategoryAdjustmentLines = new List<SubSubCategoryWrapper>();

            //Get list of categories
            List<String> lstCategories = lstMetadata[0].APTS_Category_Options__c.split(',');

            List<Apttus_Config2__ClassificationHierarchy__c> listCategoryHierarchies = [    SELECT Id, Name, Apttus_Config2__HierarchyId__c, 
                                                                                            Apttus_Config2__AncestorId__c, 
                                                                                            Apttus_Config2__PrimordialId__c ,
                                                                                            Apttus_Config2__HierarchyId__r.Name
                                                                                            FROM Apttus_Config2__ClassificationHierarchy__c
                                                                                            WHERE Apttus_Config2__HierarchyId__r.Apttus_Config2__Type__c IN ('Offering', 'Both')
                                                                                            AND Apttus_Config2__HierarchyId__r.Name IN :lstCategories
                                                                                            AND Apttus_Config2__HierarchyId__r.Apttus_Config2__Active__c = true
                                                                                            Order by Apttus_Config2__HierarchyId__r.Name, Name];

            if (!listCategoryHierarchies.isEmpty()) {

                for (Apttus_Config2__ClassificationHierarchy__c oCategoryHierarchy : listCategoryHierarchies) {

                    mapAllCategoryIdCategory.put(oCategoryHierarchy.Id, oCategoryHierarchy);
                    mapCategoryNameCategoryId.put(oCategoryHierarchy.Name, oCategoryHierarchy.Id);

                    if (oCategoryHierarchy.Apttus_Config2__AncestorId__c == null) {

                        mapCategoryIdCategoryName.put(oCategoryHierarchy.Id, oCategoryHierarchy.Apttus_Config2__HierarchyId__r.Name);

                    } 
                    else if (oCategoryHierarchy.Apttus_Config2__AncestorId__c == oCategoryHierarchy.Apttus_Config2__PrimordialId__c) {

                        mapSubCategoryIdParentCategoryId.put(oCategoryHierarchy.Id, oCategoryHierarchy.Apttus_Config2__PrimordialId__c);

                    } 
                    else {

                        mapSubSubCategoryIdParentCategoryId.put(oCategoryHierarchy.Id, oCategoryHierarchy.Apttus_Config2__AncestorId__c);

                    }

                }

            }

            for (Id subCategoryId : mapSubCategoryIdParentCategoryId.keySet()) {

                Id categoryId = mapSubCategoryIdParentCategoryId.get(subCategoryId);
                List<String> listCategoryNames = mapSubCategoryIdListCategoryNames.get(categoryId);

                if (listCategoryNames == null) {

                    listCategoryNames = new List<String>();
                    mapSubCategoryIdListCategoryNames.put(categoryId, listCategoryNames);

                }

                Apttus_Config2__ClassificationHierarchy__c oCategory = mapAllCategoryIdCategory.get(subCategoryId);
                listCategoryNames.add(oCategory.Name);

            }

            for (Id subSubCategoryId : mapSubSubCategoryIdParentCategoryId.keySet()) {

                Id subCategoryId = mapSubSubCategoryIdParentCategoryId.get(subSubCategoryId);
                List<String> listCategoryNames = mapSubSubCategoryIdListCategoryNames.get(subCategoryId);
                
                if (listCategoryNames == null) {

                    listCategoryNames = new List<String>();
                    mapSubSubCategoryIdListCategoryNames.put(subCategoryId, listCategoryNames);

                }

                Apttus_Config2__ClassificationHierarchy__c oCategory = mapAllCategoryIdCategory.get(subSubCategoryId);
                listCategoryNames.add(oCategory.Name);

            }

            setIdCERAdjustments = new Set<Id>();

            //Get all adjustments previously created
            //getAllCategoryAdjustments();
        }
    }

    public void addNewCategoryAdjustmentLine() {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        addNewCategoryAdjustmentLine(index);
    }

    private void addNewCategoryAdjustmentLine(Integer index) {

        Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = createAdjustmentLineItem();
        CategoryWrapper oCategoryWrapper = new CategoryWrapper(oAdjustmentLineItem, mapSubTypeLabelAndAPIName.get(oAdjustmentLineItem.Apttus_Config2__SubType__c));
        oCategoryWrapper.subTypesOptions = getSubTypeOptions(oAdjustmentLineItem.Apttus_Config2__Type__c);

        if (listCategoryAdjustmentLines.isEmpty() || index < 0 || listCategoryAdjustmentLines.size() <= index + 1) {
            
            listCategoryAdjustmentLines.add(oCategoryWrapper);

        } 
        else {

            listCategoryAdjustmentLines.add(index + 1, oCategoryWrapper);

        }
    }

    public PageReference removeCategoryAdjustmentLine() {

        try{
            String indexStr = ApexPages.currentPage().getParameters().get('index');
            Integer index = Integer.valueOf(indexStr);
            CategoryWrapper oCategoryWrapper = listCategoryAdjustmentLines.get(index);
            Boolean deletionResponse = false;

            system.debug(LoggingLevel.ERROR,'CER Id to delete:::::' + oCategoryWrapper.iCERRecordId);

            //Delete CER record if applies
            if(oCategoryWrapper.iCERRecordId != null){
                deletionResponse = deleteCERRecordAndRecoverParent(oCategoryWrapper.iCERRecordId);
            }

            system.debug(LoggingLevel.ERROR,'Deletion response:::::::::::' + deletionResponse);

            if (oCategoryWrapper.oAdjustmentLineItem.Id != null) {

                delete oCategoryWrapper.oAdjustmentLineItem;

            }

            //Remove CER record Id from set so it can be added again
            if(oCategoryWrapper.iCERRecordId != null){
                setIdCERAdjustments.remove(oCategoryWrapper.iCERRecordId);
            }

            listCategoryAdjustmentLines.remove(index);

            //If a CER record was recovered page must reloaded to reflect that change
            if(deletionResponse){
                //Set with useful parameters to redirect user
                Set<String> setParameters = new Set<String>{'id','configRequestId','flow','businessObjectId','retId'};

                //Get all the parameters
                Map<string,string> mapParameters = ApexPages.currentPage().getParameters();

                //Get the reference of the apttus create agreement page
                PageReference pr = Page.APTS_CategoryBasedAdjustments;            
                
                //Add all parameters received to the parameters list
                for(String currentPar : mapParameters.keySet()){if(setParameters.contains(currentPar)){pr.getParameters().put(currentPar, mapParameters.get(currentPar));}                    }            
                
                //Redirect to the create agreement page
                pr.setRedirect(true);
                
                return pr;
            }else{
                return null;
            }
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'An error occurred deleting the adjustment.'));
            system.debug(LoggingLevel.ERROR,'Error in adjustment deletion ::::: ' + e.getMessage() + '---' + e.getStackTraceString());
            return null;
        }        
    }

    public void addNewSubCategoryAdjustmentLine() {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        addNewSubCategoryAdjustmentLine(index);
    }

    private void addNewSubCategoryAdjustmentLine(Integer index) {

        Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = createAdjustmentLineItem();
        Set<Id> setCategoryIds = mapCategoryIdCategoryName.keySet();
        List<Id> listCategoryIds = new List<Id>(setCategoryIds);
        Id categoryId = listCategoryIds.get(0);
        List<SelectOption> subCategoryOptions = getSubCategoryOptions(categoryId, mapSubCategoryIdListCategoryNames);
        SubCategoryWrapper oSubCategoryWrapper = new SubCategoryWrapper(oAdjustmentLineItem, '', subCategoryOptions, mapSubTypeLabelAndAPIName.get(oAdjustmentLineItem.Apttus_Config2__SubType__c));
        oSubCategoryWrapper.subTypesOptions = getSubTypeOptions(oAdjustmentLineItem.Apttus_Config2__Type__c);

        if (listSubCategoryAdjustmentLines.isEmpty() || index < 0 || listSubCategoryAdjustmentLines.size() <= index + 1) {
        
            listSubCategoryAdjustmentLines.add(oSubCategoryWrapper);
        
        } 
        else {
        
            listSubCategoryAdjustmentLines.add(index + 1, oSubCategoryWrapper);
        
        }
    }

    public PageReference removeSubCategoryAdjustmentLine() {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        SubCategoryWrapper oSubCategoryWrapper = listSubCategoryAdjustmentLines.get(index);
        Boolean deletionResponse = false;

        //Delete CER record if applies
        if(oSubCategoryWrapper.iCERRecordId != null){
            deletionResponse = deleteCERRecordAndRecoverParent(oSubCategoryWrapper.iCERRecordId);
        }

        system.debug(LoggingLevel.ERROR,'Deletion response:::::::::::' + deletionResponse);

        if (oSubCategoryWrapper.oAdjustmentLineItem.Id != null) {
            delete oSubCategoryWrapper.oAdjustmentLineItem;
        }

        //Remove CER record Id from set so it can be added again
        if(oSubCategoryWrapper.iCERRecordId != null){
            setIdCERAdjustments.remove(oSubCategoryWrapper.iCERRecordId);
        }

        listSubCategoryAdjustmentLines.remove(index);

        //If a CER record was recovered page must reloaded to reflect that change
        if(deletionResponse){
            //Set with useful parameters to redirect user
            Set<String> setParameters = new Set<String>{'id','configRequestId','flow','businessObjectId','retId'};

            //Get all the parameters
            Map<string,string> mapParameters = ApexPages.currentPage().getParameters();

            //Get the reference of the apttus create agreement page
            PageReference pr = Page.APTS_CategoryBasedAdjustments;            
            
            //Add all parameters received to the parameters list
            for(String currentPar : mapParameters.keySet()){if(setParameters.contains(currentPar)){pr.getParameters().put(currentPar, mapParameters.get(currentPar));}                    }            
            
            //Redirect to the create agreement page
            pr.setRedirect(true);
            
            return pr;
        }else{
            return null;
        }       
    }

    public void addNewSubSubCategoryAdjustmentLine() {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        addNewSubSubCategoryAdjustmentLine(index);

    }

    private void addNewSubSubCategoryAdjustmentLine(Integer index) {

        Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = createAdjustmentLineItem();
        Set<Id> setCategoryIds = mapCategoryIdCategoryName.keySet();
        List<Id> listCategoryIds = new List<Id>(setCategoryIds);
        Id categoryId = listCategoryIds.get(0);

        Set<Id> setSubCategoryIds = mapSubCategoryIdListCategoryNames.keySet();
        List<Id> listSubCategoryIds = new List<Id>(setSubCategoryIds);
        Id subCategoryId = listSubCategoryIds.get(0);
        List<SelectOption> subCategoryOptions = getSubCategoryOptions(categoryId, mapSubCategoryIdListCategoryNames);
        List<SelectOption> subSubCategoryOptions = getSubCategoryOptions(subCategoryId, mapSubSubCategoryIdListCategoryNames);

        SubSubCategoryWrapper oSubSubCategoryWrapper = new SubSubCategoryWrapper(oAdjustmentLineItem, '', '',
                subCategoryOptions, subSubCategoryOptions, mapSubTypeLabelAndAPIName.get(oAdjustmentLineItem.Apttus_Config2__SubType__c));
        oSubSubCategoryWrapper.subTypesOptions = getSubTypeOptions(oAdjustmentLineItem.Apttus_Config2__Type__c);

        if (listSubSubCategoryAdjustmentLines.isEmpty() || index < 0 || listSubSubCategoryAdjustmentLines.size() <= index + 1) {

            listSubSubCategoryAdjustmentLines.add(oSubSubCategoryWrapper);

        } 
        else {

            listSubSubCategoryAdjustmentLines.add(index + 1, oSubSubCategoryWrapper);

        }

    }

    public PageReference removeSubSubCategoryAdjustmentLine() {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        SubSubCategoryWrapper oSubSubCategoryWrapper = listSubSubCategoryAdjustmentLines.get(index);
        Boolean deletionResponse = false;

         //Delete CER record if applies
        if(oSubSubCategoryWrapper.iCERRecordId != null){
            deletionResponse = deleteCERRecordAndRecoverParent(oSubSubCategoryWrapper.iCERRecordId);
        }

        system.debug(LoggingLevel.ERROR,'Deletion response:::::::::::' + deletionResponse);

        if (oSubSubCategoryWrapper.oAdjustmentLineItem.Id != null) {
            delete oSubSubCategoryWrapper.oAdjustmentLineItem;
        }

        //Remove CER record Id from set so it can be added again
        if(oSubSubCategoryWrapper.iCERRecordId != null){
            setIdCERAdjustments.remove(oSubSubCategoryWrapper.iCERRecordId);
        }

        listSubSubCategoryAdjustmentLines.remove(index);

        //If a CER record was recovered page must reloaded to reflect that change
        if(deletionResponse){
            //Set with useful parameters to redirect user
            Set<String> setParameters = new Set<String>{'id','configRequestId','flow','businessObjectId','retId'};

            //Get all the parameters
            Map<string,string> mapParameters = ApexPages.currentPage().getParameters();

            //Get the reference of the apttus create agreement page
            PageReference pr = Page.APTS_CategoryBasedAdjustments;            
            
            //Add all parameters received to the parameters list
            for(String currentPar : mapParameters.keySet()){
                if(setParameters.contains(currentPar)){
                    pr.getParameters().put(currentPar, mapParameters.get(currentPar));
                }                    
            }            
            
            //Redirect to the create agreement page
            pr.setRedirect(true);
            
            return pr;
        }else{
            return null;
        }        
    }

    public List<SelectOption> getCategoryPicklist() {

        List<SelectOption> categoryOptions = new List<SelectOption>();
        categoryOptions.add(new SelectOption('', '--Please select a value--'));
        for (Id categoryId : mapCategoryIdCategoryName.keySet()) {

            categoryOptions.add(new SelectOption(categoryId, mapCategoryIdCategoryName.get(categoryId)));
        
        }
        return categoryOptions;
    }

    public List<SelectOption> getDiscountTypes() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--Please select a value--'));

        Schema.DescribeFieldResult fieldResult = Apttus_Config2__AdjustmentLineItem__c.Apttus_Config2__Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f : ple) {

            options.add(new SelectOption(f.getValue(), f.getLabel()));
        
        }
        return options;
    }

    public List<SelectOption> getSubTypes() {

        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--Please select a value--'));

        Schema.DescribeFieldResult fieldResult = Apttus_Config2__AdjustmentLineItem__c.Apttus_Config2__SubType__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f : ple) {

            options.add(new SelectOption(f.getValue(), f.getLabel()));
            mapSubTypeLabelAndAPIName.put(f.getLabel(), f.getValue());
        
        }

        return options;
    }

    public List<SelectOption> getAdjTypes() {

        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = Apttus_Config2__AdjustmentLineItem__c.Apttus_Config2__AdjustmentType__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f : ple) {

            options.add(new SelectOption(f.getValue(), f.getLabel()));
            mapSubTypeLabelAndAPIName.put(f.getLabel(), f.getValue());
        
        }

        return options;
    }

    public Map<String, String> getMapSubTypeLabelAndAPINames() {

        Map<String, String> mapSubTypeLabelAndAPIName = new Map<String, String>();

        Schema.DescribeFieldResult fieldResult = Apttus_Config2__AdjustmentLineItem__c.Apttus_Config2__SubType__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f : ple) {

            mapSubTypeLabelAndAPIName.put(f.getLabel(), f.getValue());
        
        }

        return mapSubTypeLabelAndAPIName;
    }

    public List<SelectOption> getUomTypes() {

        List<SelectOption> options = new List<SelectOption>();

        Schema.DescribeFieldResult fieldResult = Apttus_Config2__AdjustmentLineItem__c.Apttus_Config2__AdjustmentUom__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry f : ple) {

            options.add(new SelectOption(f.getValue(), f.getLabel()));
        
        }

        return options;
    }

    public void changeSubTypeForCategoryLine() {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        CategoryWrapper oCategoryWrapper = listCategoryAdjustmentLines.get(index);
        Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = oCategoryWrapper.oAdjustmentLineItem;
        List<SelectOption> subTypeOptions = getSubTypeOptions(oAdjustmentLineItem.Apttus_Config2__Type__c);
        oCategoryWrapper.subTypesOptions = subTypeOptions;

    }

    public void changeSubTypeForSubCategoryLine() {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        SubCategoryWrapper oSubCategoryWrapper = listSubCategoryAdjustmentLines.get(index);
        Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = oSubCategoryWrapper.oAdjustmentLineItem;
        List<SelectOption> subTypeOptions = getSubTypeOptions(oAdjustmentLineItem.Apttus_Config2__Type__c);
        oSubCategoryWrapper.subTypesOptions = subTypeOptions;

    }

    public void changeSubTypeForSubSubCategoryLine() {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        SubSubCategoryWrapper oSubSubCategoryWrapper = listSubSubCategoryAdjustmentLines.get(index);
        Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = oSubSubCategoryWrapper.oAdjustmentLineItem;
        List<SelectOption> subTypeOptions = getSubTypeOptions(oAdjustmentLineItem.Apttus_Config2__Type__c);
        oSubSubCategoryWrapper.subTypesOptions = subTypeOptions;

    }

    private List<SelectOption> getSubTypeOptions(String adjType) {

        List<SelectOption> subTypeOptions = new List<SelectOption>();
        subTypeOptions.add(new SelectOption('', '--Please select a value--'));
        if (String.isNotEmpty(adjType) && mapAdjustmentType.containsKey(adjType) != null) {

            Set<String> setOptions = mapAdjustmentType.get(adjType);

            Schema.DescribeFieldResult fieldResult = Apttus_Config2__AdjustmentLineItem__c.Apttus_Config2__SubType__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

            for (Schema.PicklistEntry f : ple) {
                if(setOptions != null && !setOptions.isEmpty() && setOptions.contains(f.getValue())){
                    subTypeOptions.add(new SelectOption(f.getValue(), f.getLabel()));
                }            
            }
        }

        return subTypeOptions;

    }   

    public void changeSubCatForLine() {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        SubCategoryWrapper oSubCategoryWrapper = listSubCategoryAdjustmentLines.get(index);
        Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = oSubCategoryWrapper.oAdjustmentLineItem;
        List<SelectOption> subCategoryOptions = getSubCategoryOptions(oSubCategoryWrapper.sCategoryId, mapSubCategoryIdListCategoryNames);
        oSubCategoryWrapper.subCategoryOptions = subCategoryOptions;

    }

    public void addNewCategoryAdjustmentLineCER(List<APTS_Contract_Entitlement_Repository__c> lstCER) {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        addNewCategoryAdjustmentLineCER(index, lstCER);
    }

    private void addNewCategoryAdjustmentLineCER(Integer index, List<APTS_Contract_Entitlement_Repository__c> lstCER) {

        for(APTS_Contract_Entitlement_Repository__c currentCER : lstCER){
            //Validate that the CER adjustment hasn't been added before
            if(!setIdCERAdjustments.contains(currentCER.Id)){
                Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = createAdjustmentLineItemCER(currentCER);

                CategoryWrapper oCategoryWrapper = 
                new CategoryWrapper(
                    oAdjustmentLineItem, 
                    mapSubTypeLabelAndAPIName.get(oAdjustmentLineItem.Apttus_Config2__SubType__c), 
                    currentCER.APTS_Contributing_Agreement_Level__c == 'Child' ? 'P' : 'A',
                    currentCER.APTS_Contributing_Agreement_Level__c == 'Child' ? true : false,
                    Double.valueOf(currentCER.APTS_Adjustment_Value__c),
                    currentCER.Id,
                    currentCER.APTS_Contributing_Agreement_Level__c,
                    currentCER.APTS_CER_from_Parent__c,
                    currentCER.APTS_Category_Discount_Amendment__c
                );

                //If the record is created for a category discount in amendment, allow dates to be modified
                if(currentCER.APTS_Category_Discount_Amendment__c && oCategoryWrapper.cerStatus == 'A'){
                    oCategoryWrapper.bReadOnlyDates = false;
                }

                //Populate sub type select list
                oCategoryWrapper.subTypesOptions = getSubTypeOptions(oAdjustmentLineItem.Apttus_Config2__Type__c);

                //Populate values coming from CER
                oCategoryWrapper.agreementNumber = currentCER.APTS_Contributing_Agreement__r.Apttus__FF_Agreement_Number__c;
                
                //Find correct level Id
                for(Id current : mapCategoryIdCategoryName.keySet()){
                    if(currentCER.APTS_CategoryCER__r.Name == mapCategoryIdCategoryName.get(current)){
                        oCategoryWrapper.levelId = current;
                        break;
                    }
                }
                
                if (listCategoryAdjustmentLines.isEmpty() || index < 0 || listCategoryAdjustmentLines.size() <= index + 1) {
                    
                    listCategoryAdjustmentLines.add(oCategoryWrapper);
                    setIdCERAdjustments.add(currentCER.Id);

                } 
                else {

                    listCategoryAdjustmentLines.add(index + 1, oCategoryWrapper);
                    setIdCERAdjustments.add(currentCER.Id);

                }
            }
        }

    }

    public void addNewSubCategoryAdjustmentLineCER(List<APTS_Contract_Entitlement_Repository__c> lstCER) {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        addNewSubCategoryAdjustmentLineCER(index, lstCER);
    }

    private void addNewSubCategoryAdjustmentLineCER(Integer index, List<APTS_Contract_Entitlement_Repository__c> lstCER) {

        for(APTS_Contract_Entitlement_Repository__c currentCER : lstCER){
            //Validate that the CER adjustment hasn't been added before
            if(!setIdCERAdjustments.contains(currentCER.Id)){
                Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = createAdjustmentLineItemCER(currentCER);

                Set<Id> setCategoryIds = mapCategoryIdCategoryName.keySet();
                List<Id> listCategoryIds = new List<Id>(setCategoryIds);
                Id categoryId = listCategoryIds.get(0);
                List<SelectOption> subCategoryOptions = getSubCategoryOptions(currentCER.APTS_CategoryCER__c, mapSubCategoryIdListCategoryNames);

                SubCategoryWrapper oSubCategoryWrapper = 
                new SubCategoryWrapper(
                    oAdjustmentLineItem, 
                    currentCER.APTS_CategoryCER__c, 
                    subCategoryOptions, 
                    mapSubTypeLabelAndAPIName.get(oAdjustmentLineItem.Apttus_Config2__SubType__c), 
                    currentCER.APTS_Contributing_Agreement_Level__c == 'Child' ? 'P' : 'A',
                    currentCER.APTS_Contributing_Agreement_Level__c == 'Child' ? true : false,
                    Double.valueOf(currentCER.APTS_Adjustment_Value__c),
                    currentCER.Id,
                    currentCER.APTS_Contributing_Agreement_Level__c,
                    currentCER.APTS_CER_from_Parent__c,
                    currentCER.APTS_Category_Discount_Amendment__c
                );

                //If the record is created for a category discount in amendment, allow dates to be modified
                if(currentCER.APTS_Category_Discount_Amendment__c && oSubCategoryWrapper.cerStatus == 'A'){
                    oSubCategoryWrapper.bReadOnlyDates = false;
                }

                //Populate sub type select list
                oSubCategoryWrapper.subTypesOptions = getSubTypeOptions(oAdjustmentLineItem.Apttus_Config2__Type__c);

                //Populate values coming from CER
                oSubCategoryWrapper.sCategoryId = currentCER.APTS_CategoryCER__c;
                oSubCategoryWrapper.subLevelId = currentCER.APTS_Sub_Category__c;
                oSubCategoryWrapper.agreementNumber = currentCER.APTS_Contributing_Agreement__r.Apttus__FF_Agreement_Number__c;
                
                if (listSubCategoryAdjustmentLines.isEmpty() || index < 0 || listSubCategoryAdjustmentLines.size() <= index + 1) {
                
                    listSubCategoryAdjustmentLines.add(oSubCategoryWrapper);
                    setIdCERAdjustments.add(currentCER.Id);
                
                } 
                else {
                
                    listSubCategoryAdjustmentLines.add(index + 1, oSubCategoryWrapper);
                    setIdCERAdjustments.add(currentCER.Id);
                
                }
            }
        }

    }

    public void addNewSubSubCategoryAdjustmentLineCER(List<APTS_Contract_Entitlement_Repository__c> lstCER) {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        addNewSubSubCategoryAdjustmentLineCER(index, lstCER);

    }

    private void addNewSubSubCategoryAdjustmentLineCER(Integer index, List<APTS_Contract_Entitlement_Repository__c> lstCER) {

        for(APTS_Contract_Entitlement_Repository__c currentCER : lstCER){
            //Validate that the CER adjustment hasn't been added before
            if(!setIdCERAdjustments.contains(currentCER.Id)){
                Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = createAdjustmentLineItemCER(currentCER);

                Set<Id> setCategoryIds = mapCategoryIdCategoryName.keySet();
                List<Id> listCategoryIds = new List<Id>(setCategoryIds);
                Id categoryId = currentCER.APTS_CategoryCER__c;

                Set<Id> setSubCategoryIds = mapSubCategoryIdListCategoryNames.keySet();
                List<Id> listSubCategoryIds = new List<Id>(setSubCategoryIds);
                Id subCategoryId = currentCER.APTS_Sub_Category__c;
                List<SelectOption> subCategoryOptions = getSubCategoryOptions(categoryId, mapSubCategoryIdListCategoryNames);
                List<SelectOption> subSubCategoryOptions = getSubCategoryOptions(subCategoryId, mapSubSubCategoryIdListCategoryNames);

                SubSubCategoryWrapper oSubSubCategoryWrapper = 
                new SubSubCategoryWrapper(
                    oAdjustmentLineItem, 
                    categoryId, 
                    subCategoryId,
                    subCategoryOptions, 
                    subSubCategoryOptions, 
                    mapSubTypeLabelAndAPIName.get(oAdjustmentLineItem.Apttus_Config2__SubType__c), 
                    currentCER.APTS_Contributing_Agreement_Level__c == 'Child' ? 'P' : 'A',
                    currentCER.APTS_Contributing_Agreement_Level__c == 'Child' ? true : false,
                    Double.valueOf(currentCER.APTS_Adjustment_Value__c),
                    currentCER.Id,
                    currentCER.APTS_Contributing_Agreement_Level__c,
                    currentCER.APTS_CER_from_Parent__c,
                    currentCER.APTS_Category_Discount_Amendment__c
                );

                //If the record is created for a category discount in amendment, allow dates to be modified
                if(currentCER.APTS_Category_Discount_Amendment__c && oSubSubCategoryWrapper.cerStatus == 'A'){
                    oSubSubCategoryWrapper.bReadOnlyDates = false;
                }
                
                //Populate sub type select list
                oSubSubCategoryWrapper.subTypesOptions = getSubTypeOptions(oAdjustmentLineItem.Apttus_Config2__Type__c);
                
                //Populate values coming from CER
                oSubSubCategoryWrapper.sCategoryId = currentCER.APTS_CategoryCER__c;
                oSubSubCategoryWrapper.sSubCategoryId = currentCER.APTS_Sub_Category__c;
                oSubSubCategoryWrapper.subSubLevelId = currentCER.APTS_Sub_Sub_Category__c;
                oSubSubCategoryWrapper.agreementNumber = currentCER.APTS_Contributing_Agreement__r.Apttus__FF_Agreement_Number__c;

                if (listSubSubCategoryAdjustmentLines.isEmpty() || index < 0 || listSubSubCategoryAdjustmentLines.size() <= index + 1) {

                    listSubSubCategoryAdjustmentLines.add(oSubSubCategoryWrapper);
                    setIdCERAdjustments.add(currentCER.Id);

                } 
                else {

                    listSubSubCategoryAdjustmentLines.add(index + 1, oSubSubCategoryWrapper);
                    setIdCERAdjustments.add(currentCER.Id);

                }
            }
        }

    }

    private Apttus_Config2__AdjustmentLineItem__c createAdjustmentLineItemCER(APTS_Contract_Entitlement_Repository__c cerRecord) {

        return new Apttus_Config2__AdjustmentLineItem__c(
                    Apttus_Config2__LineNumber__c = 1,
                    Apttus_Config2__Type__c = cerRecord.APTS_Type__c,
                    Apttus_Config2__SubType__c = cerRecord.APTS_Sub_Type__c,
                    Apttus_Config2__AdjustmentType__c = cerRecord.APTS_Adjustment_Type__c,
                    Apttus_Config2__AdjustmentAmount__c = Double.valueOf(cerRecord.APTS_Adjustment_Value__c),
                    Apttus_Config2__AdjustmentAppliesTo__c = cerRecord.APTS_Adjustment_Applies_To__c,
                    Apttus_Config2__Bucket__c = cerRecord.APTS_Bucket__c,
                    Apttus_Config2__AdjustmentUom__c = cerRecord.APTS_UOM__c,
                    APTS_Start_Date__c = cerRecord.APTS_Start_Date__c,
                    APTS_End_Date__c = cerRecord.APTS_End_Date__c,
                    APTS_Adjustment_Source__c = 'Child'
                );
    }

    public void changeSSCSubCatForLine() {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        SubSubCategoryWrapper oSubSubCategoryWrapper = listSubSubCategoryAdjustmentLines.get(index);
        Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = oSubSubCategoryWrapper.oAdjustmentLineItem;
        List<SelectOption> subCategoryOptions = getSubCategoryOptions(oSubSubCategoryWrapper.sCategoryId, mapSubCategoryIdListCategoryNames);
        oSubSubCategoryWrapper.subCategoryOptions = subCategoryOptions;
        List<SelectOption> subSubCategoryOptions = getSubCategoryOptions(oSubSubCategoryWrapper.sSubCategoryId, mapSubSubCategoryIdListCategoryNames);
        oSubSubCategoryWrapper.subSubCategoryOptions = subSubCategoryOptions;

    }

    public void changeSSCSubSubCatForLine() {

        String indexStr = ApexPages.currentPage().getParameters().get('index');
        Integer index = Integer.valueOf(indexStr);
        SubSubCategoryWrapper oSubSubCategoryWrapper = listSubSubCategoryAdjustmentLines.get(index);
        Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem = oSubSubCategoryWrapper.oAdjustmentLineItem;
        List<SelectOption> subSubCategoryOptions = getSubCategoryOptions(oSubSubCategoryWrapper.sSubCategoryId, mapSubSubCategoryIdListCategoryNames);
        oSubSubCategoryWrapper.subSubCategoryOptions = subSubCategoryOptions;

    }

    public boolean isSaveSuccessful() {

        List<Apttus_Config2__AdjustmentLineItem__c> listAllAdjustmentLines = new List<Apttus_Config2__AdjustmentLineItem__c>();
        List<Apttus_Config2__LineItem__c> lstNewLI = new List<Apttus_Config2__LineItem__c>();
        List<createLIInfo> lstCreateLIInfo = new List<createLIInfo>();
        createLIInfo objLIInfo;
        Id tempId;
        Map<Id,Double> mapCERIdValue = new Map<Id,Double>();
        Map<Id,String> mapCERIdKeyADLI = new Map<Id,String>();
        Map<String,String> mapADLIKeyId = new Map<String,String>();
        Set<String> setKey = new Set<String>();
        Blob blobKey;
        String key;
        Set<Id> setAmountNotChanged = new Set<Id>();

        //Delete previous existent LI and ADLI
        cleanPreviousAdjustments();

        Map<Id,String> mapCategoryLI = new Map<Id,String>();
        Map<Id,String> mapSubCategoryLI = new Map<Id,String>();
        Map<Id,String> mapSubSubCategoryLI = new Map<Id,String>();

        //Defect 5883
        for (CategoryWrapper oCategoryWrapper : listCategoryAdjustmentLines) {
            if((oCategoryWrapper.cerStatus == 'A' && 
                oCategoryWrapper.dInitialValue != oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c) ||
                (oCategoryWrapper.cerStatus == 'A' && oCategoryWrapper.categoryDiscountAmendment) ||
                (oCategoryWrapper.cerStatus == 'P')){
                if(!mapCategoryLI.containsKey(oCategoryWrapper.levelId)){
                    objLIInfo = new createLIInfo();
                    objLIInfo.level = 'Category';
                    objLIInfo.catId = oCategoryWrapper.levelId;
                    objLIInfo.subCatId = null;
                    objLIInfo.subSubId = null;
                    lstCreateLIInfo.add(objLIInfo);
                    mapCategoryLI.put(oCategoryWrapper.levelId, null);
                }
            }
        }

        for (SubCategoryWrapper oSubCategoryWrapper : listSubCategoryAdjustmentLines) {
            if((oSubCategoryWrapper.cerStatus == 'A' && 
                oSubCategoryWrapper.dInitialValue != oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c) ||
                (oSubCategoryWrapper.cerStatus == 'A' && oSubCategoryWrapper.categoryDiscountAmendment) ||
                (oSubCategoryWrapper.cerStatus == 'P')){
                if(!mapSubCategoryLI.containsKey(oSubCategoryWrapper.subLevelId)){
                    objLIInfo = new createLIInfo();
                    objLIInfo.level = 'Sub Category';
                    objLIInfo.catId = oSubCategoryWrapper.sCategoryId;
                    objLIInfo.subCatId = oSubCategoryWrapper.subLevelId;
                    objLIInfo.subSubId = null;
                    lstCreateLIInfo.add(objLIInfo);
                    mapSubCategoryLI.put(oSubCategoryWrapper.subLevelId,null);
                }
            }
        }

        for (SubSubCategoryWrapper oSubSubCategoryWrapper : listSubSubCategoryAdjustmentLines) {
            if((oSubSubCategoryWrapper.cerStatus == 'A' && 
                oSubSubCategoryWrapper.dInitialValue != oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c) ||
                (oSubSubCategoryWrapper.cerStatus == 'A' && oSubSubCategoryWrapper.categoryDiscountAmendment) ||
                (oSubSubCategoryWrapper.cerStatus == 'P')){
                if(!mapSubSubCategoryLI.containsKey(oSubSubCategoryWrapper.subSubLevelId)){
                    objLIInfo = new createLIInfo();
                    objLIInfo.level = 'Sub Sub Category';
                    objLIInfo.catId = oSubSubCategoryWrapper.sCategoryId;
                    objLIInfo.subCatId = oSubSubCategoryWrapper.sSubCategoryId;
                    objLIInfo.subSubId = oSubSubCategoryWrapper.subSubLevelId;
                    lstCreateLIInfo.add(objLIInfo);
                    mapSubSubCategoryLI.put(oSubSubCategoryWrapper.subSubLevelId,null);
                }
            }
        }

        if(lstCreateLIInfo.size() > 0){
            lstNewLI = createMultipleLineItems(lstCreateLIInfo, cartId);

            for(Apttus_Config2__LineItem__c currentLI : lstNewLI){
                if(currentLI.APTS_Category_Level__c == 'Category'){
                    mapCategoryLI.put(currentLI.Apttus_Config2__ClassificationId__c, currentLI.Id);
                }else if(currentLI.APTS_Category_Level__c == 'Sub Category'){
                    mapSubCategoryLI.put(currentLI.APTS_Sub_Category__c, currentLI.Id);
                }else if(currentLI.APTS_Category_Level__c == 'Sub Sub Category'){
                    mapSubSubCategoryLI.put(currentLI.APTS_Sub_Sub_Category__c, currentLI.Id);
                }
            }
        }

        if (!listCategoryAdjustmentLines.isEmpty()) {

            //Associate ADLI with LI
            for (CategoryWrapper oCategoryWrapper : listCategoryAdjustmentLines) {
                //Defect 5883
                if((oCategoryWrapper.cerStatus == 'A' && 
                    oCategoryWrapper.dInitialValue != oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c) ||
                    (oCategoryWrapper.cerStatus == 'A' && oCategoryWrapper.categoryDiscountAmendment) ||
                    (oCategoryWrapper.cerStatus == 'P')){

                    oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__LineItemId__c = mapCategoryLI.get(oCategoryWrapper.levelId);
                    oCategoryWrapper.oAdjustmentLineItem.APTS_Category__c = oCategoryWrapper.levelId;
                    
                    //Determine bucket
                    if(oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'YOCI') {
                        oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 5';
                    }else if(oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'YOFT') {
                        oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 5';
                    }else if(oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'PPR') {
                        oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 3' ;oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                    }else if(oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'TPR') {
                        oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                    }else if(oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'BMC') {
                        oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 4';
                    }else if(oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'GSV') {
                        oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 1' ;oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                    }

                    //Validate if its CER from Parent
                    if(oCategoryWrapper.cerFromParent){
                        oCategoryWrapper.oAdjustmentLineItem.APTS_Adjustment_From_Parent__c = true;
                    }

                    //Validate if its Category adjustment from amendment
                    if(oCategoryWrapper.categoryDiscountAmendment){
                        oCategoryWrapper.oAdjustmentLineItem.APTS_Category_Product_Amendment__c = true;
                    }

                    //CER Update
                    if((oCategoryWrapper.cerStatus == 'A' && 
                        oCategoryWrapper.dInitialValue != oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c) ||
                        (oCategoryWrapper.cerStatus == 'A' && oCategoryWrapper.categoryDiscountAmendment)){
                        //Defect 5883
                        if(oCategoryWrapper.dInitialValue == oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c){
                            setAmountNotChanged.add(oCategoryWrapper.iCERRecordId);
                        }

                        system.debug(LoggingLevel.ERROR, 'updating cer record:::::' + oCategoryWrapper.iCERRecordId);
                        system.debug(LoggingLevel.ERROR, 'updating cer record initial value:::::' + oCategoryWrapper.dInitialValue);
                        system.debug(LoggingLevel.ERROR, 'updating cer record later value:::::' + oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c);

                        mapCERIdValue.put(oCategoryWrapper.iCERRecordId,oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c);

                        //Set the value of adjustment source field
                        //Defect #5215
                        //oCategoryWrapper.oAdjustmentLineItem.APTS_Adjustment_Source__c = oCategoryWrapper.cerLevel;
                        
                        //Temp id string
                        blobKey = crypto.generateAesKey(192);
                        key = EncodingUtil.base64encode(blobKey);
                        oCategoryWrapper.oAdjustmentLineItem.APTS_Temp_Id_String__c = key;

                        setKey.add(oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__LineItemId__c +
                            oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c +
                            oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__SubType__c);
                        mapCERIdKeyADLI.put(oCategoryWrapper.iCERRecordId, key);
                    }

                    listAllAdjustmentLines.add(oCategoryWrapper.oAdjustmentLineItem);
                }
            }

        }

        if (!listSubCategoryAdjustmentLines.isEmpty()) {

            if(mapSubCategoryLI.size() > 0){
                //Associate ADLI with LI
                for (SubCategoryWrapper oSubCategoryWrapper : listSubCategoryAdjustmentLines) {
                    //Defect 5883
                     if((oSubCategoryWrapper.cerStatus == 'A' && 
                        oSubCategoryWrapper.dInitialValue != oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c) ||
                        (oSubCategoryWrapper.cerStatus == 'A' && oSubCategoryWrapper.categoryDiscountAmendment) ||
                        (oSubCategoryWrapper.cerStatus == 'P')){
                        oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__LineItemId__c = mapSubCategoryLI.get(oSubCategoryWrapper.subLevelId);
                        oSubCategoryWrapper.oAdjustmentLineItem.APTS_Category__c = oSubCategoryWrapper.sCategoryId;
                        oSubCategoryWrapper.oAdjustmentLineItem.APTS_Sub_Category__c = oSubCategoryWrapper.subLevelId;
                    
                        //Determine bucket
                        if(oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'YOCI') {oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;
                        }else if(oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'YOFT') {
                            oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                        }else if(oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'PPR') {
                            oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 3' ;oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                        }else if(oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'TPR') {
                            oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                        }else if(oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'BMC') {
                            oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ; oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 4';
                        }else if(oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'GSV') {
                            oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 1' ;oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                        }

                        //Validate if its CER from Parent
                        if(oSubCategoryWrapper.cerFromParent){
                            oSubCategoryWrapper.oAdjustmentLineItem.APTS_Adjustment_From_Parent__c = true;
                        }

                        //Validate if its Category adjustment from amendment
                        if(oSubCategoryWrapper.categoryDiscountAmendment){
                            oSubCategoryWrapper.oAdjustmentLineItem.APTS_Category_Product_Amendment__c = true;
                        }

                        //CER Update
                        if((oSubCategoryWrapper.cerStatus == 'A' && 
                            oSubCategoryWrapper.dInitialValue != oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c) ||
                            (oSubCategoryWrapper.cerStatus == 'A' && oSubCategoryWrapper.categoryDiscountAmendment)){
                            //Defect 5883
                            if(oSubCategoryWrapper.dInitialValue == oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c){
                                setAmountNotChanged.add(oSubCategoryWrapper.iCERRecordId);
                            }
                            
                            mapCERIdValue.put(oSubCategoryWrapper.iCERRecordId,oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c);
                            
                            //Set the value of adjustment source field
                            //Defect #5215
                            //oSubCategoryWrapper.oAdjustmentLineItem.APTS_Adjustment_Source__c = oSubCategoryWrapper.cerLevel;
                            
                            //Temp id string
                            blobKey = crypto.generateAesKey(192);
                            key = EncodingUtil.base64encode(blobKey);
                            oSubCategoryWrapper.oAdjustmentLineItem.APTS_Temp_Id_String__c = key;

                            setKey.add(oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__LineItemId__c +
                                oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c +
                                oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__SubType__c);
                            mapCERIdKeyADLI.put(oSubCategoryWrapper.iCERRecordId, key);
                        }

                        listAllAdjustmentLines.add(oSubCategoryWrapper.oAdjustmentLineItem);
                    }
                }
            }
        }

        if (!listSubSubCategoryAdjustmentLines.isEmpty()) {

            if(mapSubSubCategoryLI.size() > 0){
                //Associate ADLI with LI
                for (SubSubCategoryWrapper oSubSubCategoryWrapper : listSubSubCategoryAdjustmentLines) {
                    //Defect 5883
                    if((oSubSubCategoryWrapper.cerStatus == 'A' && 
                        oSubSubCategoryWrapper.dInitialValue != oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c) ||
                        (oSubSubCategoryWrapper.cerStatus == 'A' && oSubSubCategoryWrapper.categoryDiscountAmendment) ||
                        (oSubSubCategoryWrapper.cerStatus == 'P')){
                        oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__LineItemId__c = mapSubSubCategoryLI.get(oSubSubCategoryWrapper.subSubLevelId);
                        oSubSubCategoryWrapper.oAdjustmentLineItem.APTS_Category__c = oSubSubCategoryWrapper.sCategoryId;
                        oSubSubCategoryWrapper.oAdjustmentLineItem.APTS_Sub_Category__c = oSubSubCategoryWrapper.sSubCategoryId;
                        oSubSubCategoryWrapper.oAdjustmentLineItem.APTS_Sub_Sub_Category__c = oSubSubCategoryWrapper.subSubLevelId;

                        //Determine bucket
                        if(oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'YOCI') {oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;
                        }else if(oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'YOFT') {
                            oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 6' ;oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                        }else if(oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'PPR') {
                            oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 3' ;oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 2';
                        }else if(oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'TPR') {
                            oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 4' ;oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 3';
                        }else if(oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'BMC') {
                            oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 5' ;oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Bucket 4';
                        }else if(oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c == 'GSV') {
                            oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Bucket__c = 'Bucket 1' ;oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAppliesTo__c = 'Starting Price';
                        }

                        //Validate if its CER from Parent
                        if(oSubSubCategoryWrapper.cerFromParent){
                            oSubSubCategoryWrapper.oAdjustmentLineItem.APTS_Adjustment_From_Parent__c = true;
                        }

                        //Validate if its Category adjustment from amendment
                        if(oSubSubCategoryWrapper.categoryDiscountAmendment){
                            oSubSubCategoryWrapper.oAdjustmentLineItem.APTS_Category_Product_Amendment__c = true;
                        }

                        //CER Update
                        if(oSubSubCategoryWrapper.cerStatus == 'A' && 
                            oSubSubCategoryWrapper.dInitialValue != oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c ||
                            (oSubSubCategoryWrapper.cerStatus == 'A' && oSubSubCategoryWrapper.categoryDiscountAmendment)){
                            //Defect 5883
                            if(oSubSubCategoryWrapper.dInitialValue == oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c){
                                setAmountNotChanged.add(oSubSubCategoryWrapper.iCERRecordId);
                            }
                            
                            mapCERIdValue.put(oSubSubCategoryWrapper.iCERRecordId,oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__AdjustmentAmount__c);
                            
                            //Set the value of adjustment source field
                            //Defect #5215
                            //oSubSubCategoryWrapper.oAdjustmentLineItem.APTS_Adjustment_Source__c = oSubSubCategoryWrapper.cerLevel;
                            
                            //Temp id string
                            blobKey = crypto.generateAesKey(192);
                            key = EncodingUtil.base64encode(blobKey);
                            oSubSubCategoryWrapper.oAdjustmentLineItem.APTS_Temp_Id_String__c = key;

                            setKey.add(oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__LineItemId__c +
                                oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c +
                                oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__SubType__c);
                            mapCERIdKeyADLI.put(oSubSubCategoryWrapper.iCERRecordId, key);
                        }

                        listAllAdjustmentLines.add(oSubSubCategoryWrapper.oAdjustmentLineItem);
                    }
                }
            }        
        }

        if (!listAllAdjustmentLines.isEmpty() && validateWhileSave(listAllAdjustmentLines)) {
                        List<Apttus_Config2__AdjustmentLineItem__c> tempListADLIfin1; 
                        tempListADLIfin1 = APTS_DiscountBucketizing.processAdjustmentLineItemfields(listAllAdjustmentLines);
            for(Apttus_Config2__AdjustmentLineItem__c currentAdj : tempListADLIfin1){
            
                system.debug(LoggingLevel.ERROR,'Adjusment Line Item to Insert:::::::::::' + currentAdj);
            }

            insert tempListADLIfin1;

            Set<Id> setIdADLI = (new Map<Id,Apttus_Config2__AdjustmentLineItem__c>(listAllAdjustmentLines)).keySet();

            system.debug(LoggingLevel.ERROR,'Set id ADLI::::::::::' + setIdADLI);

            List<Apttus_Config2__AdjustmentLineItem__c> lstADLI =
            [
                SELECT Id,
                Apttus_Config2__LineItemId__c,
                Apttus_Config2__AdjustmentType__c,
                Apttus_Config2__AdjustmentAmount__c,
                Apttus_Config2__LineItemId__r.APTS_AgreementId__c,
                Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Recordtype.Name,
                Apttus_Config2__Type__c,
                Apttus_Config2__SubType__c,
                Apttus_Config2__AdjustmentAppliesTo__c,
                Apttus_Config2__Bucket__c,
                Apttus_Config2__AdjustmentUom__c,
                Apttus_Config2__LineItemId__r.Apttus_Config2__LineType__c,
                Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__c,
                Apttus_Config2__LineItemId__r.Apttus_Config2__OptionId__c,
                Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Account__c,
                Apttus_Config2__LineItemId__r.APTS_Category_Level__c,
                Apttus_Config2__LineItemId__r.Apttus_Config2__ClassificationId__c,
                Apttus_Config2__LineItemId__r.APTS_Sub_Category__c,
                Apttus_Config2__LineItemId__r.APTS_Sub_Sub_Category__c,
                Apttus_Config2__LineItemId__r.Apttus_Config2__ClassificationHierarchy__c,
                APTS_Temp_Id_String__c,
                APTS_Start_Date__c,
                APTS_End_Date__c,
                APTS_Adjustment_From_Parent__c,
                APTS_Category_Product_Amendment__c
                FROM Apttus_Config2__AdjustmentLineItem__c
                WHERE Id IN :setIdADLI
            ];
           
            //Create CER temp records
            createCERRecords(lstADLI);

            //Update CER Records
            if(mapCERIdValue.size() > 0){
               updateCERRecords(mapCERIdValue,lstADLI,mapCERIdKeyADLI,setAmountNotChanged); 
            }

            return true;
        } 
        else {
            return false;
        }
        
    }

    public void updateCERRecords(Map<Id,Double> mapCERIdValue,List<Apttus_Config2__AdjustmentLineItem__c> lstADLI,
        Map<Id,String> mapCERIdKeyADLI,Set<Id> setCERAmountNotChanged){
        //Get CER Records
        List<APTS_Contract_Entitlement_Repository__c> lstCER =
        [
            SELECT Id, 
            APTS_Adjustment_Value__c, 
            APTS_Contributing_Agreement_Level__c,
            APTS_Pending_Line_Item__c,
            APTS_Pending_Adjustment_Line_Item__c,
            APTS_Start_Date__c,
            APTS_End_Date__c,
            APTS_Category_Discount_Amendment__c
            FROM APTS_Contract_Entitlement_Repository__c
            WHERE Id IN :mapCERIdValue.keySet()
        ];

        List<APTS_Contract_Entitlement_Repository__c> lstNewCER = new List<APTS_Contract_Entitlement_Repository__c>();

        Set<Id> setIdCER = new Set<Id>();
        
        //Change contributing agreement level to lower level and contributing agreement to current agreement
        for(APTS_Contract_Entitlement_Repository__c currentCER : lstCER){
            //New logic for amendment
            if(agreementRequestType == 'Amendment' && !currentCER.APTS_Category_Discount_Amendment__c){
                //Get new record to insert
                APTS_Contract_Entitlement_Repository__c newCERRecord = APTS_CategoryBasedAdjustmentsHelper.createNewCERAmendment(currentCER.Id, agreementId, mapCERIdValue.get(currentCER.Id), accountId);

                //Search the right ADLI using key
                for(Apttus_Config2__AdjustmentLineItem__c currentADLI : lstADLI){
                    if(currentADLI.APTS_Temp_Id_String__c != null &&
                        currentADLI.APTS_Temp_Id_String__c == mapCERIdKeyADLI.get(currentCER.Id)){
                        newCERRecord.APTS_Pending_Line_Item__c = currentADLI.Apttus_Config2__LineItemId__c;
                        newCERRecord.APTS_Pending_Adjustment_Line_Item__c = currentADLI.Id;                    
                    }
                }

                lstNewCER.add(newCERRecord);

                //Flag the CER record so its not shown duplicated
                currentCER.APTS_CER_Changed_Amendment__c = true;

                setIdCER.add(newCERRecord.Id);
            }else{
                currentCER.APTS_Adjustment_Value__c = mapCERIdValue.get(currentCER.Id);
                
                //Defect 5883
                if(!setCERAmountNotChanged.contains(currentCER.Id)){
                    currentCER.APTS_Contributing_Agreement_Level__c = 'Child';
                }                
                
                currentCER.APTS_Contributing_Agreement__c = agreementId;

                //This flag will be used later when a category adjustment is deleted, to determine if the CER records should be recovered
                //(originally part of father) or just deleted (created in child)
                //Doesn't apply when the CER record was created for a category adjustment as result of an amendment
                if(!currentCER.APTS_Category_Discount_Amendment__c){
                    currentCER.APTS_CER_from_Parent__c = true;
                }               

                //Search the right ADLI using key
                for(Apttus_Config2__AdjustmentLineItem__c currentADLI : lstADLI){
                    if(currentADLI.APTS_Temp_Id_String__c != null &&
                        currentADLI.APTS_Temp_Id_String__c == mapCERIdKeyADLI.get(currentCER.Id)){
                        currentCER.APTS_Pending_Line_Item__c = currentADLI.Apttus_Config2__LineItemId__c;
                        currentCER.APTS_Pending_Adjustment_Line_Item__c = currentADLI.Id;                    
                    }
                }

                setIdCER.add(currentCER.Id);
            }       
        }

        system.debug(LoggingLevel.ERROR,'CER list update:::::::::::' + lstCER);

        //Update CER list
        update lstCER;

        if(lstNewCER.size() > 0){
            update lstNewCER;
        }

        //Update CER record dates for category adjustment as result of an amendment
        List<APTS_Contract_Entitlement_Repository__c> lstCERDiscountAmendment =
        [
            SELECT Id, 
            APTS_Pending_Adjustment_Line_Item__r.APTS_Start_Date__c,
            APTS_Pending_Adjustment_Line_Item__r.APTS_End_Date__c
            FROM APTS_Contract_Entitlement_Repository__c
            WHERE Id IN :setIdCER
        ];

        system.debug(LoggingLevel.ERROR,'CER list update:::::::::::' + lstCERDiscountAmendment);

        if(lstCERDiscountAmendment.size() > 0){
            for(APTS_Contract_Entitlement_Repository__c currentCER : lstCERDiscountAmendment){
                currentCER.APTS_Start_Date__c = currentCER.APTS_Pending_Adjustment_Line_Item__r.APTS_Start_Date__c;
                currentCER.APTS_End_Date__c = currentCER.APTS_Pending_Adjustment_Line_Item__r.APTS_End_Date__c;
            }

            update lstCERDiscountAmendment;
        }
    }

    private Boolean deleteCERRecordAndRecoverParent(Id idCERRecord){
        Boolean cerRecordRecovered = false;

        //Get CER Record info
        List<APTS_Contract_Entitlement_Repository__c> lstCER =
        [
            SELECT Id,
            APTS_Contributing_Agreement_Level__c,
            APTS_CategoryCER__c,
            APTS_Sub_Category__c,
            APTS_Sub_Sub_Category__c,
            APTS_Sold_to_Party__c,
            APTS_Pending_Adjustment_Line_Item__c,
            APTS_Pending_Line_Item__c,
            APTS_CER_from_Parent__c,
            APTS_Category_Discount_Amendment__c,
            APTS_Start_Date__c,
            APTS_End_Date__c,
            APTS_Product__c,
            APTS_Type__c,
            APTS_Sub_Type__c
            FROM APTS_Contract_Entitlement_Repository__c
            WHERE Id = :idCERRecord
        ];

        system.debug(LoggingLevel.ERROR,'lstCER>>>>>>>>> ' + lstCER );

        List<Apttus_Config2__AdjustmentLineItem__c> lstADLI;
        List<Apttus_Config2__AdjustmentLineItem__c> lstRelatedADLI;
        List<Apttus_Config2__LineItem__c> lstLI;

        //Get related ADLI record for deletion
        if(lstCER[0].APTS_Pending_Adjustment_Line_Item__c != null){
            lstADLI = 
            [ 
                SELECT Id,
                APTS_Category__c,
                APTS_Sub_Category__c,
                APTS_Sub_Sub_Category__c,
                Apttus_Config2__AdjustmentAmount__c,
                APTS_Start_Date__c,
                APTS_End_Date__c
                FROM Apttus_Config2__AdjustmentLineItem__c 
                WHERE Id = :lstCER[0].APTS_Pending_Adjustment_Line_Item__c 
            ];
        }

         system.debug(LoggingLevel.ERROR,'lstADLI>>>>>>>> ' + lstADLI);

        //Get related LI record for deletion
        if(lstCER[0].APTS_Pending_Line_Item__c != null){
            lstLI =
            [
                SELECT Id,
                (
                    SELECT Id
                    FROM Apttus_Config2__AdjustmentLineItems__r
                )
                FROM Apttus_Config2__LineItem__c
                WHERE Id = :lstCER[0].APTS_Pending_Line_Item__c
            ];

             
        }

        system.debug(LoggingLevel.ERROR,'lstLI>>>>>>>>' + lstLI);

        //Check if the CER record was originally created with contributing level father, if that is the case recover original CER record
        if(lstCER[0].APTS_CER_from_Parent__c && !lstCER[0].APTS_Category_Discount_Amendment__c){
            //Get parent CER Record info
            Id parentAccountId = APTS_CERUtility.getCerRecordAccountForRelatedAccount(lstCER[0].APTS_Sold_to_Party__c,false);

            System.debug(LoggingLevel.ERROR,'CER record:::::::::' + lstCER[0]);
            System.debug(LoggingLevel.ERROR,'Sold to party id:::::::::' + lstCER[0].APTS_Sold_to_Party__c);
            System.debug(LoggingLevel.ERROR,'Parent account id:::::::::' + parentAccountId);

            String strFields = '';

            Map <String, Schema.SObjectField> fieldMap = APTS_Contract_Entitlement_Repository__c.sObjectType.getDescribe().fields.getMap();

            for(Schema.SObjectField sfield : fieldMap.Values())
            {
                schema.describefieldresult dfield = sfield.getDescribe();
                if(dfield.isCustom() && dfield.isUpdateable()){
                    strFields += dfield.getname() + ',';
                }
            }

            System.debug(LoggingLevel.ERROR,'Fields list:::::::::' + strFields);


            strFields = strFields.removeEnd(',');

            String category = lstCER[0].APTS_CategoryCER__c;
            String subCategory = lstCER[0].APTS_Sub_Category__c;
            String subSubCategory = lstCER[0].APTS_Sub_Sub_Category__c;

            String strQuery = 'SELECT ' + strFields + ' FROM APTS_Contract_Entitlement_Repository__c ' +
            'WHERE APTS_Sold_to_Party__c = :parentAccountId ';

            if(category != null){
                strQuery += ' AND APTS_CategoryCER__c = :category  ';
            }

            if(subCategory != null){
                strQuery += ' AND APTS_Sub_Category__c = :subCategory  ';
            }

            if(subSubCategory != null){
                strQuery += ' AND APTS_Sub_Sub_Category__c = :subSubCategory  ';
            }

            strQuery += ' LIMIT 1 ';
            system.debug('CERQueryshahul'+strQuery);
            List<APTS_Contract_Entitlement_Repository__c> lstCERParent = Database.query(strQuery);

            System.debug(LoggingLevel.ERROR,'List CER Parent:::::::::' + lstCERParent);

            if(lstCERParent.size() > 0){
                APTS_Contract_Entitlement_Repository__c newCERRecord = lstCERParent[0].clone(false, false, false, false);
                newCERRecord.APTS_Sold_to_Party__c = lstCER[0].APTS_Sold_to_Party__c;
                newCERRecord.APTS_Is_Pending__c = true;
                newCERRecord.APTS_Charge_Type__c='Sales Price';
                
                //Set the contributing level one level up as the record was originally
                /*if(newCERRecord.APTS_Contributing_Agreement_Level__c == 'Child'){
                    newCERRecord.APTS_Contributing_Agreement_Level__c = 'Parent';
                }else if(newCERRecord.APTS_Contributing_Agreement_Level__c == 'Parent'){
                    newCERRecord.APTS_Contributing_Agreement_Level__c = 'Grandparent';
                }else if(newCERRecord.APTS_Contributing_Agreement_Level__c == 'Grandparent'){
                    newCERRecord.APTS_Contributing_Agreement_Level__c = 'Buying Group';
                }*/

                //Insert CER Parent Record
                insert newCERRecord;

                //Set boolean value to identify that a CER record was recovered
                cerRecordRecovered = true;
            }
        }else if(lstCER[0].APTS_Category_Discount_Amendment__c && !lstCER[0].APTS_CER_from_Parent__c){//Check if the record was created as a result of new amendment logic
            //Get list of ADLI
            List<Apttus_Config2__AdjustmentLineItem__c> lstADLIAmendment =
            APTS_CategoryBasedAdjustmentsHelper.getListCERAmendment(agreementId, lstCER[0].APTS_Product__c, 
            lstCER[0].APTS_CategoryCER__c, lstCER[0].APTS_Sub_Category__c, lstCER[0].APTS_Sub_Sub_Category__c, 
            lstCER[0].APTS_Type__c, lstCER[0].APTS_Sub_Type__c);

            system.debug(LoggingLevel.ERROR,'lstADLIAmendment 2:::::::::' + lstADLIAmendment);

            if(lstCER[0].APTS_Pending_Adjustment_Line_Item__c != null){
            lstADLI = 
            [ 
                SELECT Id,
                APTS_Category__c,
                APTS_Sub_Category__c,
                APTS_Sub_Sub_Category__c,
                Apttus_Config2__AdjustmentAmount__c,
                APTS_Start_Date__c,
                APTS_End_Date__c
                FROM Apttus_Config2__AdjustmentLineItem__c 
                WHERE Id = :lstCER[0].APTS_Pending_Adjustment_Line_Item__c 
            ];

        }     Delete lstADLI;
        system.debug(LoggingLevel.ERROR,'ShahullstADLI>>>>>>>> ' + lstADLI);

        //Get related LI record for deletion
        if(lstCER[0].APTS_Pending_Line_Item__c != null){
            lstLI =
            [
                SELECT Id,
                (
                    SELECT Id
                    FROM Apttus_Config2__AdjustmentLineItems__r
                )
                FROM Apttus_Config2__LineItem__c
                WHERE Id = :lstCER[0].APTS_Pending_Line_Item__c
            ];
}
        system.debug(LoggingLevel.ERROR,'ShahullstLI>>>>>>>> ' + lstLI);
        system.debug('Thursday'+lstLI[0].Apttus_Config2__AdjustmentLineItems__r.size());

        if(lstLI != null && !lstLI.isEmpty() && lstLI[0].Apttus_Config2__AdjustmentLineItems__r.size() == 0){
            system.debug(LoggingLevel.ERROR,'ShahullstLI>>>>>>>> ' + lstLI);
            delete lstLI;}
        List<Apttus_Config2__AdjustmentLineItem__c> lstADLIAmendmentDelete =new List<Apttus_Config2__AdjustmentLineItem__c>();
        List<Apttus_Config2__LineItem__c> UpdateLI =new List<Apttus_Config2__LineItem__c>();
        List<Id> lstLIAmendmentDelete =new List<Id>();
        lstADLIAmendmentDelete=[select id,Apttus_Config2__SubType__c,APTS_Category__c,Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c,Apttus_Config2__LineItemId__c,Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__c from 
        Apttus_Config2__AdjustmentLineItem__c where Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__c=:cartId AND 
        APTS_Category__c=:lstCER[0].APTS_CategoryCER__c AND
        APTS_Sub_Category__c=:lstCER[0].APTS_Sub_Category__c AND
        APTS_Sub_Sub_Category__c=:lstCER[0].APTS_Sub_Sub_Category__c
        AND APTS_Adjustment_Source__c='Child' AND Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__c!=:lstCER[0].APTS_Product__c AND Apttus_Config2__SubType__c=:lstCER[0].APTS_Sub_Type__c];
        system.debug(LoggingLevel.ERROR,'ShahullstLI>>>>>>>> ' + lstADLIAmendmentDelete);

        for(Apttus_Config2__AdjustmentLineItem__c adj:lstADLIAmendmentDelete){
                lstLIAmendmentDelete.add(adj.Apttus_Config2__LineItemId__c);
            }
            Delete lstADLIAmendmentDelete;
            for(Apttus_Config2__LineItem__c LI:[select id,Apttus_Config2__PricingStatus__c from Apttus_Config2__LineItem__c where id in:lstLIAmendmentDelete]){
                system.debug(LoggingLevel.ERROR,'ShahullstLI>>>>>>>> ' + LI);
                           // LI.Apttus_Config2__PricingStatus__c='Pending';
                            LI.Apttus_Config2__PricingSteps__c='';
                            UpdateLI.add(LI);
            }
                system.debug(LoggingLevel.ERROR,'ShahullstLI>>>>>>>> ' + UpdateLI);

            Update UpdateLI;

            if(lstADLIAmendment.size() > 0){
                //Update CER record to revert it to original state
                /*lstCER[0].APTS_Contributing_Agreement_Level__c = 'Parent';
                lstCER[0].APTS_Start_Date__c = lstADLIAmendment[0].APTS_Start_Date__c;
                lstCER[0].APTS_End_Date__c = lstADLIAmendment[0].APTS_End_Date__c;
                lstCER[0].APTS_Adjustment_Value__c = lstADLIAmendment[0].Apttus_Config2__AdjustmentAmount__c;*/
                
                Delete lstCER;
                Update UpdateLI;

                system.debug(LoggingLevel.ERROR,'lstCER updated:::::::::' + lstCER);
            }

            //Set boolean value to identify that a CER record was recovered
            //cerRecordRecovered = true;            
        }else if(lstCER[0].APTS_Category_Discount_Amendment__c && lstCER[0].APTS_CER_from_Parent__c){
            //Get original amended agreement
            Id initialAgreementId = APTS_CategoryBasedAdjustmentsHelper.originalAgreementId(agreementId);

            system.debug(LoggingLevel.ERROR,'agreementId:::::::::::: ' + agreementId);
            system.debug(LoggingLevel.ERROR,'initialAgreementId::::::: ' + initialAgreementId);
            
            List<APTS_Contract_Entitlement_Repository__c> lstCEROriginal =
            APTS_CategoryBasedAdjustmentsHelper.getCERRecord(accountId, lstCER[0].APTS_Product__c, 
            lstCER[0].APTS_CategoryCER__c, lstCER[0].APTS_Sub_Category__c, lstCER[0].APTS_Sub_Sub_Category__c, 
            lstCER[0].APTS_Type__c, lstCER[0].APTS_Sub_Type__c);

            system.debug(LoggingLevel.ERROR,'lstCEROriginal::::::: ' + lstCEROriginal);
            
            if(lstCEROriginal.size() > 0){
                //Update CER record to revert it to original state
                lstCEROriginal[0].APTS_CER_Changed_Amendment__c = false;

                update lstCEROriginal;
            }

            //Set boolean value to identify that a CER record was recovered
            cerRecordRecovered = true;   
        }

        //Delete original CER record and related records
        if(lstADLI != null && !lstADLI.isEmpty() && !(lstCER[0].APTS_Category_Discount_Amendment__c && !lstCER[0].APTS_CER_from_Parent__c)){
            system.debug(LoggingLevel.ERROR,'Delete lstADLI');
            delete lstADLI;
        }
        

        //Validate that the LI only has one child ADLI to delete it
        if(lstLI != null && !lstLI.isEmpty() && 
            (lstLI[0].Apttus_Config2__AdjustmentLineItems__r == null || lstLI[0].Apttus_Config2__AdjustmentLineItems__r.size() == 1) &&
            !(lstCER[0].APTS_Category_Discount_Amendment__c && !lstCER[0].APTS_CER_from_Parent__c)){
             system.debug(LoggingLevel.ERROR,'Delete lstLI');
            delete lstLI;
        }      
        
        if(!(lstCER[0].APTS_Category_Discount_Amendment__c && !lstCER[0].APTS_CER_from_Parent__c)){
            system.debug(LoggingLevel.ERROR,'Delete CER');
            delete lstCER;
        }

        //Adjustments in cart should be re-calculated as a category adjustment was deleted
        Boolean result = createCategoryAdjustmentsExistingLineItems();
        system.debug(LoggingLevel.ERROR,'Create adjustments on deletion result:::::::' + result);

        return cerRecordRecovered;
    }

    public void cleanPreviousAdjustments(){
        List<Apttus_Config2__AdjustmentLineItem__c> lstADLIToDelete = new List<Apttus_Config2__AdjustmentLineItem__c>();
        List<Apttus_Config2__LineItem__c> lstLIToDelete = new List<Apttus_Config2__LineItem__c>();
        List<APTS_Contract_Entitlement_Repository__c> lstCER = new List<APTS_Contract_Entitlement_Repository__c>();

        //Get the list of LI
        List<Apttus_Config2__LineItem__c> lstLI = 
        [  
            SELECT Id,
            Apttus_Config2__ProductId__c,
            (
                SELECT Id,APTS_Copied_Category_Adjustments__c 
                FROM Apttus_Config2__AdjustmentLineItems__r
            ),
            (
                SELECT Id
                FROM Pending_LI_CER__r
                WHERE APTS_Category_Discount_Amendment__c = false
                OR (APTS_Category_Discount_Amendment__c = true AND APTS_Contributing_Agreement_Level__c = 'Child')
            ) 
            FROM Apttus_Config2__LineItem__c
            WHERE Apttus_Config2__ConfigurationId__c = :cartId
        ];

        if(lstLI.size() > 0){
            //Loop through LI records, add LI and child ADLI for deletion
            for(Apttus_Config2__LineItem__c currentLineItem : lstLI){
                if (currentLineItem.Apttus_Config2__ProductId__c == categoryProductId){
                    //Add LI for deletion
                    lstLIToDelete.add(currentLineItem);

                    if(currentLineItem.Pending_LI_CER__r.size() > 0){
                        lstCER.addAll(currentLineItem.Pending_LI_CER__r);
                    } 
                }else{
                    //Loop through ADLI and check the APTS_Copied_Category_Adjustments__c flag
                    for(Apttus_Config2__AdjustmentLineItem__c currentADLI : currentLineItem.Apttus_Config2__AdjustmentLineItems__r){
                        if(currentADLI.APTS_Copied_Category_Adjustments__c){
                            lstADLIToDelete.add(currentADLI);
                        }
                    }
                }                
            }

            //Delete CER
            if(lstCER.size() > 0){
                delete lstCER;
            }

            //Delete ADLI
            if(lstADLIToDelete.size() > 0){
                delete lstADLIToDelete;
            }

            //Delete LI
            if(lstLIToDelete.size() > 0){
                delete lstLIToDelete;
            }

        }
    }

    public List<Apttus_Config2__LineItem__c> createMultipleLineItems( List<createLIInfo> lstCreateLIInfo, string cartId){
        try{
            createLIInfo objInfo;            
            Set<String> setCategoriesId = new Set<String>();
            list<Apttus_Config2__LineItem__c> newlstLi = new list<Apttus_Config2__LineItem__c>();

            for(createLIInfo currentInfo : lstCreateLIInfo){
                if(currentInfo.catId != null){
                    setCategoriesId.add(currentInfo.catId);
                }
                
                if(currentInfo.subcatId != null){
                    setCategoriesId.add(currentInfo.subcatId);
                }

                if(currentInfo.subsubId != null){
                    setCategoriesId.add(currentInfo.subsubId);
                }
            }
            
            List<Apttus_Config2__ClassificationHierarchy__c> lstCategories = 
            [
                SELECT Id, Name, Apttus_Config2__HierarchyId__c,
                        Apttus_Config2__HierarchyId__r.Name
                FROM Apttus_Config2__ClassificationHierarchy__c
                WHERE Id IN :setCategoriesId
            ];

            Map<Id,Apttus_Config2__ClassificationHierarchy__c> mapCategories = 
            new Map<Id,Apttus_Config2__ClassificationHierarchy__c>(lstCategories);

            List <Apttus_CPQApi.CPQ.SelectedProductDO> selectedProdDOList = new List <Apttus_CPQApi.CPQ.SelectedProductDO>();
            Apttus_CPQApi.CPQ.SelectedProductDO selProdDO; 

            for(createLIInfo currentInfo : lstCreateLIInfo){
                selProdDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
                selProdDO.ProductID = categoryProductId;
                selProdDO.Quantity = 1;
                selProdDO.Comments = 'Added for Category Adjustment';
                selectedProdDOList.add(selProdDO); 
            }            
            
            Apttus_CPQApi.CPQ.AddMultiProductRequestDO request = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO ();
            request.CartId = cartId;            
            request.SelectedProducts = selectedProdDOList;
            Apttus_CPQApi.CPQ.AddMultiProductResponseDO response = Apttus_CPQApi.CPQWebService.addMultiProducts(request);

            list<Apttus_Config2__LineItem__c> lstLi = 
            [
                select Id,Name,
                Apttus_Config2__ConfigurationId__c,
                Apttus_Config2__ProductId__c,
                Apttus_Config2__ClassificationId__c,
                Apttus_Config2__ClassificationHierarchy__c
                from Apttus_Config2__LineItem__c 
                where Apttus_Config2__ConfigurationId__c = :cartId
                and Apttus_Config2__ProductId__c = :categoryProductId 

                and Apttus_Config2__ClassificationHierarchy__c = ''
            ];

            String categoryHierarchy = '';
            Integer counter = 0;

            for(Apttus_Config2__LineItem__c ali: lstLi){                
                if(ali.Apttus_Config2__ClassificationId__c == null 
                    && ali.Apttus_Config2__ProductId__c == categoryProductId){
                    objInfo = lstCreateLIInfo.get(counter);

                    if(objInfo.catId != null && objInfo.subCatId != null){
                        categoryHierarchy += mapCategoryIdCategoryName.get(objInfo.catId) + ' | ';
                    }else if(objInfo.catId != null && objInfo.subCatId == null){
                        categoryHierarchy += mapCategoryIdCategoryName.get(objInfo.catId);
                    }

                    if(objInfo.subCatId != null && objInfo.subSubId != null){
                        categoryHierarchy += mapCategories.get(objInfo.subCatId).Name + ' | ';
                    }else if(objInfo.subCatId != null && objInfo.subSubId == null){
                        categoryHierarchy += mapCategories.get(objInfo.subCatId).Name;
                    }

                    if(objInfo.subSubId != null){
                        categoryHierarchy += mapCategories.get(objInfo.subSubId).Name;
                    }

                    ali.Apttus_Config2__ClassificationId__c = objInfo.catId;
                    ali.APTS_Sub_Category__c = objInfo.subcatId;
                    ali.APTS_Sub_Sub_Category__c = objInfo.subsubId;
                    ali.APTS_Category_Level__c = objInfo.level;
                    ali.Apttus_Config2__ClassificationHierarchy__c = categoryHierarchy;
                    ali.Apttus_Config2__PriceListId__c = priceListID;
                    newlstLi.add(ali);
                    counter++;
                }
                categoryHierarchy = '';
            }
        
            if(newlstLi.size() > 0){
                update newlstLi;
            }
            
            return newlstLi;
        }catch(exception e){
            system.debug(LoggingLevel.ERROR,'Error creating line items::::::' + e.getMessage() + '---' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error in LI creation ::::: ' + e.getMessage() + '---' + e.getStackTraceString()));
            return null;
        }        
    }

    public void createCERRecords(List<Apttus_Config2__AdjustmentLineItem__c> lstADLI){
        List<APTS_Contract_Entitlement_Repository__c>  insertCERList = new List<APTS_Contract_Entitlement_Repository__c>();
        
        for(Apttus_Config2__AdjustmentLineItem__c aali : lstADLI){
            //Validation to avoid creation of CER records on existing CER update
            if(aali.APTS_Temp_Id_String__c == null){
                insertCERList.add(
                    new APTS_Contract_Entitlement_Repository__c(
                        APTS_Pending_Adjustment_Line_Item__c = aali.Id,
                        APTS_Pending_Line_Item__c = aali.Apttus_Config2__LineItemId__c,
                        APTS_Adjustment_Type__c = aali.Apttus_Config2__AdjustmentType__c,
                        APTS_Adjustment_Value__c = aali.Apttus_Config2__AdjustmentAmount__c,
                        APTS_Contributing_Agreement__c = aali.Apttus_Config2__LineItemId__r.APTS_AgreementId__c,
                        APTS_Agreement_Type__c = aali.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Recordtype.Name,
                        APTS_Contributing_Agreement_Level__c = 'Child',
                        APTS_Type__c = aali.Apttus_Config2__Type__c,
                        APTS_Sub_Type__c = aali.Apttus_Config2__SubType__c,
                        APTS_Adjustment_Applies_To__c  = aali.Apttus_Config2__AdjustmentAppliesTo__c,
                        APTS_Bucket__c = aali.Apttus_Config2__Bucket__c,
                        APTS_Product__c = 'Product/Service'.equalsIgnoreCase(aali.Apttus_Config2__LineItemId__r.Apttus_Config2__LineType__c)?aali.Apttus_Config2__LineItemId__r.Apttus_Config2__ProductId__c:aali.Apttus_Config2__LineItemId__r.Apttus_Config2__OptionId__c,
                        APTS_UOM__c = aali.Apttus_Config2__AdjustmentUom__c,
                        APTS_Sold_to_Party__c = aali.Apttus_Config2__LineItemId__r.Apttus_Config2__ConfigurationId__r.Apttus_CMConfig__AgreementId__r.Apttus__Account__c,
                        APTS_Category_Level__c = aali.Apttus_Config2__LineItemId__r.APTS_Category_Level__c,
                        APTS_CategoryCER__c = aali.Apttus_Config2__LineItemId__r.Apttus_Config2__ClassificationId__c,
                        APTS_Sub_Category__c = aali.Apttus_Config2__LineItemId__r.APTS_Sub_Category__c,
                        APTS_Sub_Sub_Category__c = aali.Apttus_Config2__LineItemId__r.APTS_Sub_Sub_Category__c,
                        APTS_Is_Pending__c = true,
                        APTS_Charge_Type__c='Sales Price',
                        APTS_Start_Date__c = aali.APTS_Start_Date__c,
                        APTS_End_Date__c = aali.APTS_End_Date__c,
                        APTS_CER_from_Parent__c = aali.APTS_Adjustment_From_Parent__c ? true : false,
                        APTS_Category_Discount_Amendment__c = aali.APTS_Category_Product_Amendment__c ? true : false
                    )
                );
            }
        }

        if(insertCERList.size() > 0){
            insert insertCERList;
        }
    }

    public void getAllCategoryAdjustments(){
        Id relatedAccountId = APTS_CERUtility.getCategoryCerRecordAccountForRelatedAccount(accountId,true);
        List<APTS_Contract_Entitlement_Repository__c> lstCER = APTS_CategoryBasedAdjustmentsHelper.getCategoryProducts(relatedAccountId, categoryProductId, null, null, null, null, true);

        if(lstCER.size() > 0){
            List<APTS_Contract_Entitlement_Repository__c> lstCERCategory = new List<APTS_Contract_Entitlement_Repository__c>();
            List<APTS_Contract_Entitlement_Repository__c> lstCERSubCategory = new List<APTS_Contract_Entitlement_Repository__c>();
            List<APTS_Contract_Entitlement_Repository__c> lstCERSubSubCategory = new List<APTS_Contract_Entitlement_Repository__c>();
            
            //Determine level and add records to the list
            for(APTS_Contract_Entitlement_Repository__c currentCER : lstCER){
                system.debug(LoggingLevel.ERROR,'CER record found' + currentCER);

                //For contributing agreement child check if the CER record is related with the present agreement
                //For not child check if the CER record was modified to create a new one
                if((currentCER.APTS_Contributing_Agreement_Level__c == 'Child' && 
                    currentCER.APTS_Contributing_Agreement__c != agreementId) ||
                    (currentCER.APTS_Contributing_Agreement_Level__c != 'Child' && 
                    currentCER.APTS_CER_Changed_Amendment__c)){
                    continue;
                }

                if(currentCER.APTS_Category_Level__c == 'Category'){
                    lstCERCategory.add(currentCER);
                }else if(currentCER.APTS_Category_Level__c == 'Sub Category'){
                    lstCERSubCategory.add(currentCER);
                }else if(currentCER.APTS_Category_Level__c == 'Sub Sub Category'){
                    lstCERSubSubCategory.add(currentCER);
                }
            }

            if(lstCERCategory.size() > 0){
                addNewCategoryAdjustmentLineCER(listCategoryAdjustmentLines.size(), lstCERCategory);
            }

            if(lstCERSubCategory.size() > 0){
                addNewSubCategoryAdjustmentLineCER(listSubCategoryAdjustmentLines.size(), lstCERSubCategory);
            }

            if(lstCERSubSubCategory.size() > 0){
                addNewSubSubCategoryAdjustmentLineCER(listSubSubCategoryAdjustmentLines.size(), lstCERSubSubCategory);
            }
        }
    }

    private Boolean createCategoryAdjustmentsExistingLineItems(){
        try{
            //Get the structure of adjustments to create
            Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapNewCategoryAdjustments =  APTS_CategoryBasedAdjustmentsHelper.getAdjustmentsStructure(cartId, categoryProductId);
            List<Apttus_Config2__AdjustmentLineItem__c> tempListADLIfin; 
            Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>> mapNewCategoryAdjustmentsfinal=new Map<Id,List<Apttus_Config2__AdjustmentLineItem__c>>();
            //tempListADLIfin = APTS_DiscountBucketizing.processAdjustmentLineItemfields(mapNewCategoryAdjustments.get(lineItemId));
             for(Id lineItemId : mapNewCategoryAdjustments.keySet()){
                tempListADLIfin = APTS_DiscountBucketizing.processAdjustmentLineItemfields(mapNewCategoryAdjustments.get(lineItemId));
                mapNewCategoryAdjustmentsfinal.put(lineItemId,tempListADLIfin);
             }

            system.debug(LoggingLevel.ERROR,'mapAdjustmentsCategoryPage::::::::' + mapNewCategoryAdjustments);
           // system.debug(LoggingLevel.ERROR,'mapNewCategoryAdjustmentsfinal::::::::' + mapNewCategoryAdjustmentsfinal);

            //Call the method to create the new adjustments
            if(!mapNewCategoryAdjustmentsfinal.isEmpty()){
                system.debug(LoggingLevel.ERROR,'mapNewCategoryAdjustmentsfinal::::::::' + mapNewCategoryAdjustmentsfinal);
                if(!APTS_CategoryBasedAdjustmentsHelper.createNewAdjustments(mapNewCategoryAdjustmentsfinal, cartId)){
                    return false;
                }
            }
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error Creating New Adjustments. Please try again.'));
            system.debug(LoggingLevel.ERROR,'Error creating new adjustments::::: ' + e.getMessage() + '---' + e.getStackTraceString());
            return false;
        }        

        return true;
    }

    public PageReference saveAndGoToCart() {

        try{
            if (validateBeforeSave() && isSaveSuccessful() && createCategoryAdjustmentsExistingLineItems()) {
                //ECDA calculation
                APTS_CategoryBasedAdjustmentsHelper.calculateECDA(accountId,cartId);

                //Redirect to cart
                PageReference pageRef;

                Map<String, String> parameterMap = ApexPages.currentPage().getParameters();
                Id tempObjectId = parameterMap.get('configRequestId');
                Id cartId = parameterMap.get('Id');
                String sFlow = parameterMap.get('flow');
                pageRef = new PageReference('/apex/Apttus_Config2__Cart?configRequestId=' + tempObjectId + '&id=' + cartId + '&flow=' + sFlow + '#!/cart');
                pageRef.setRedirect(true);

                return pageRef;

            } 
            else {

                return null;

            }
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error Saving Records. Please try again.'));
            system.debug(LoggingLevel.ERROR,'Error save::::: ' + e.getMessage() + '---' + e.getStackTraceString());
            return null;
        }
    }

    public PageReference save(){
        try{
            if (validateBeforeSave() && isSaveSuccessful() && createCategoryAdjustmentsExistingLineItems()) {
                //ECDA calculation
                APTS_CategoryBasedAdjustmentsHelper.calculateECDA(accountId,cartId);

                //Set with useful parameters to redirect user
                Set<String> setParameters = new Set<String>{'id','configRequestId','flow','businessObjectId','retId'};

                //Get all the parameters
                Map<string,string> mapParameters = ApexPages.currentPage().getParameters();

                //Get the reference of the apttus create agreement page
                PageReference pr = Page.APTS_CategoryBasedAdjustments;            
                
                //Add all parameters received to the parameters list
                for(String currentPar : mapParameters.keySet()){
                    if(setParameters.contains(currentPar)){
                        pr.getParameters().put(currentPar, mapParameters.get(currentPar));
                    }                    
                }            
                
                //Redirect to the create agreement page
                pr.setRedirect(true);
                
                return pr;

            } 
            else {

                return null;

            }
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error Saving Records. Please try again.'+e.getMessage() + '---' + e.getStackTraceString()));
            system.debug(LoggingLevel.ERROR,'Error save::::: ' + e.getMessage() + '---' + e.getStackTraceString());
            return null;
        }
    }

    private Boolean validateBeforeSave() {
        Set<String> setForDuplicates = new Set<String>();

        if (!listCategoryAdjustmentLines.isEmpty()) {
            setForDuplicates = new Set<String>();
            
            for (CategoryWrapper oCategoryWrapper : listCategoryAdjustmentLines) {
                if(oCategoryWrapper.levelId == null){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_Missing_Category_Error));
                    return false;
                }

                if(oCategoryWrapper.cerStatus != 'A' && 
                    !setForDuplicates.add(oCategoryWrapper.levelId + 
                                        oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c +
                                        oCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__SubType__c)){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_Duplicated_Category));
                    return false;
                }
            }

        }

        if (!listSubCategoryAdjustmentLines.isEmpty()) {
            setForDuplicates = new Set<String>();

            for (SubCategoryWrapper oSubCategoryWrapper : listSubCategoryAdjustmentLines) {
                if(oSubCategoryWrapper.subLevelId == null){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_Missing_Sub_Category_Error));
                    return false;
                }

                if(oSubCategoryWrapper.cerStatus != 'A' && 
                    !setForDuplicates.add(oSubCategoryWrapper.sCategoryId +
                                        oSubCategoryWrapper.subLevelId +
                                        oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c +
                                        oSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__SubType__c)){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_Duplicated_Sub_Category));
                    return false;
                }
            }

        }

        if (!listSubSubCategoryAdjustmentLines.isEmpty()) {
            setForDuplicates = new Set<String>();

            for (SubSubCategoryWrapper oSubSubCategoryWrapper : listSubSubCategoryAdjustmentLines) {
                if(oSubSubCategoryWrapper.subSubLevelId == null){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_Missing_Sub_Sub_Category_Error));
                    return false;
                }

                if(oSubSubCategoryWrapper.cerStatus != 'A' &&
                    !setForDuplicates.add(oSubSubCategoryWrapper.sCategoryId +
                                        oSubSubCategoryWrapper.sSubCategoryId +
                                        oSubSubCategoryWrapper.subSubLevelId +
                                        oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__Type__c +
                                        oSubSubCategoryWrapper.oAdjustmentLineItem.Apttus_Config2__SubType__c)){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_Duplicated_Sub_Sub_Category));
                    return false;
                }
            }
        }

        return true;

    }

    private Boolean validateWhileSave(List<Apttus_Config2__AdjustmentLineItem__c> listAllAdjustmentLines) {

        for (Apttus_Config2__AdjustmentLineItem__c adjLine : listAllAdjustmentLines) {

            if (adjLine.Apttus_Config2__Type__c == null ) {

                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_CategoryAdjustments_Error1));
                return false;
            }

            if (adjLine.Apttus_Config2__SubType__c == null ) {

                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_CategoryAdjustments_Error1));
                return false;
            }

            if (adjLine.Apttus_Config2__AdjustmentAmount__c == null) {

                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_CategoryAdjustments_Error2));
                return false;
            }

            if (adjLine.Apttus_Config2__AdjustmentUom__c == null) {

                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_CategoryAdjustments_Error3));
                return false;
            }

            if (adjLine.Apttus_Config2__SubType__c == 'TPR') {
                if (adjLine.APTS_End_Date__c == null || adjLine.APTS_End_Date__c < Date.today()) {

                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_CategoryAdjustments_Error4));
                    return false;
                }

                if (adjLine.APTS_Start_Date__c == null || adjLine.APTS_Start_Date__c > adjLine.APTS_End_Date__c) {

                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_CategoryAdjustments_Error5));
                    return false;
                }
            }

            Set<String> setDiscountNames = new Set<String> {'% Discount', '% Markup'};

            if (setDiscountNames.contains(adjLine.Apttus_Config2__AdjustmentType__c) && adjLine.Apttus_Config2__AdjustmentAmount__c > 100) {

                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, System.Label.APTS_CategoryAdjustments_Error6));
                return false;

            }

        }

        return true;

    }

    public PageReference cancel() {

        PageReference pageRef;

        if (sMode == 'Cart') {

            Map<String, String> parameterMap = ApexPages.currentPage().getParameters();
            Id tempObjectId = parameterMap.get('configRequestId');
            Id cartId = parameterMap.get('Id');
            String sFlow = parameterMap.get('flow');
            pageRef = new PageReference('/apex/Apttus_Config2__Cart?configRequestId=' + tempObjectId + '&id=' + cartId + '&flow=' + sFlow + '&launchState=cart#/catalog');
            pageRef.setRedirect(true);

        } 
        else {

            pageRef = new PageReference('/' + ApexPages.currentPage().getParameters().get('retId'));

        }

        return pageRef;

    }

    private Apttus_Config2__AdjustmentLineItem__c createAdjustmentLineItem() {

        return new Apttus_Config2__AdjustmentLineItem__c(
                Apttus_Config2__AdjustmentType__c = '% Discount',
                Apttus_Config2__LineNumber__c = 1,
                Apttus_Config2__Type__c = '',
                Apttus_Config2__SubType__c = '',
                APTS_Start_Date__c = agreementStartDate,
                APTS_End_Date__c = agreementEndDate,
                APTS_Adjustment_Source__c = 'Child'
            );

    }

    private List<SelectOption> getSubCategoryOptions(Id categoryId, Map<Id, List<String>> mapSubCategoryIdListCategoryNames) {

        List<SelectOption> subCategoryOptions = new List<SelectOption>();
        subCategoryOptions.add(new SelectOption('', '--Please select a value--'));
        if (mapSubCategoryIdListCategoryNames.get(categoryId) != null) {

            List<String> listSubCategoryNames = mapSubCategoryIdListCategoryNames.get(categoryId);

            for (String sSubCategoryNames : listSubCategoryNames) {

                Id subCategoryId = mapCategoryNameCategoryId.get(sSubCategoryNames);
                subCategoryOptions.add(new SelectOption(subCategoryId, sSubCategoryNames));

            }

        }

        return subCategoryOptions;

    }

    public void createCERAmendment(){
        if(!amendCERFlag && agreementRequestType == 'Amendment'){
            APTS_CategoryBasedAdjustmentsHelper.validateCERAmendment(cartId, agreementId);
        }

        //Get all adjustments previously created
        getAllCategoryAdjustments();
    }

    public class CategoryWrapper {

        public Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem {get; set;}
        public String sSubTypeLabel {get; set;}
        public Id levelId {get; set;}
        public String cerStatus {get; set;}
        public Boolean bReadOnly {get; set;}
        public Boolean bReadOnlyDates {get; set;}
        public Boolean bRemoveButton {get; set;}
        public Double dInitialValue {get; set;}
        public Id iCERRecordId {get; set;}
        public String agreementNumber {get; set;}
        public String disableAmountField {get; set;}
        public String cerLevel {get; set;}
        public List<SelectOption> subTypesOptions {get; set;}
        public Boolean cerFromParent {get; set;}
        public Boolean categoryDiscountAmendment {get; set;}

        public CategoryWrapper(Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem, String sSubTypeLabel) {

            this.oAdjustmentLineItem = oAdjustmentLineItem;
            this.sSubTypeLabel = sSubTypeLabel;
            this.cerStatus = 'P';
            this.bReadOnly = false;
            this.bReadOnlyDates = true;
            this.bRemoveButton = true;
            this.disableAmountField = 'N';
            this.cerFromParent = false;
            this.categoryDiscountAmendment = false;
        }

        public CategoryWrapper(Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem, String sSubTypeLabel, 
            String sStatus, Boolean parRemoveButton, Double parInitialValue, Id parCERRecordId, String parCERLevel, 
            Boolean parCERFromParent, Boolean parCategoryDiscount) {

            this.oAdjustmentLineItem = oAdjustmentLineItem;
            this.sSubTypeLabel = sSubTypeLabel;
            this.cerStatus = sStatus;
            this.bReadOnly = true;
            this.bReadOnlyDates = true;
            this.bRemoveButton = parRemoveButton;
            this.dInitialValue = parInitialValue;
            this.iCERRecordId = parCERRecordId;
            this.cerLevel = parCERLevel;
            this.cerFromParent = parCERFromParent;
            this.categoryDiscountAmendment = parCategoryDiscount;

            if(this.cerStatus == 'A'){
                this.disableAmountField = 'Y';
                this.bReadOnlyDates = true;
            }else if(this.cerStatus == 'P'){
                this.disableAmountField = 'N';
                this.bReadOnlyDates = true;
            }
        }

    }

    public class SubCategoryWrapper {

        public Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem {get; set;}
        public List<SelectOption> subCategoryOptions {get; set;}
        public String sCategoryId {get; set;}
        public Id subLevelId {get; set;}
        public String sSubTypeLabel {get; set;}
        public String cerStatus {get; set;}
        public Boolean bReadOnly {get; set;}
        public Boolean bReadOnlyDates {get; set;}
        public Boolean bRemoveButton {get; set;}
        public Double dInitialValue {get; set;}
        public Id iCERRecordId {get; set;}
        public String agreementNumber {get; set;}
        public String disableAmountField {get; set;}
        public String cerLevel {get; set;}
        public List<SelectOption> subTypesOptions {get; set;}
        public Boolean cerFromParent {get; set;}
        public Boolean categoryDiscountAmendment {get; set;}

        public SubCategoryWrapper(Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem, 
            String categoryId, List<SelectOption> subCategoryOptions, String sSubTypeLabel) {

            this.oAdjustmentLineItem = oAdjustmentLineItem;
            this.sCategoryId = categoryId;
            this.subCategoryOptions = subCategoryOptions;
            this.sSubTypeLabel = sSubTypeLabel;
            this.cerStatus = 'P';
            this.bReadOnly = false;
            this.bReadOnlyDates = false;
            this.bRemoveButton = true;
            this.disableAmountField = 'N';
            this.cerFromParent = false;
            this.categoryDiscountAmendment = false;
        }

        public SubCategoryWrapper(Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem, 
            String categoryId, List<SelectOption> subCategoryOptions, String sSubTypeLabel, 
            String sStatus, Boolean parRemoveButton, Double parInitialValue, Id parCERRecordId,
            String parCERLevel, Boolean parCERFromParent, Boolean parCategoryDiscount) {

            this.oAdjustmentLineItem = oAdjustmentLineItem;
            this.sCategoryId = categoryId;
            this.subCategoryOptions = subCategoryOptions;
            this.sSubTypeLabel = sSubTypeLabel;
            this.cerStatus = sStatus;
            this.bReadOnly = true;
            this.bReadOnlyDates = true;
            this.bRemoveButton = parRemoveButton;
            this.dInitialValue = parInitialValue;
            this.iCERRecordId = parCERRecordId;
            this.cerLevel = parCERLevel;
            this.cerFromParent = parCERFromParent;
            this.categoryDiscountAmendment = parCategoryDiscount;

            if(this.cerStatus == 'A'){
                this.disableAmountField = 'Y';
                this.bReadOnlyDates = true;
            }else if(this.cerStatus == 'P'){
                this.disableAmountField = 'N';
                this.bReadOnlyDates = true;
            }
        }

    }

    public class SubSubCategoryWrapper {

        public Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem {get; set;}
        public List<SelectOption> subCategoryOptions {get; set;}
        public String sCategoryId {get; set;}
        public List<SelectOption> subSubCategoryOptions {get; set;}
        public String sSubCategoryId {get; set;}
        public String sSubTypeLabel {get; set;}
        public Id subSubLevelId {get; set;}
        public String cerStatus {get; set;}
        public Boolean bReadOnly {get; set;}
        public Boolean bReadOnlyDates {get; set;}
        public Boolean bRemoveButton {get; set;}
        public Double dInitialValue {get; set;}
        public Id iCERRecordId {get; set;}
        public String agreementNumber {get; set;}
        public String disableAmountField {get; set;}
        public String cerLevel {get; set;}
        public List<SelectOption> subTypesOptions {get; set;}
        public Boolean cerFromParent {get; set;}
        public Boolean categoryDiscountAmendment {get; set;}

        public SubSubCategoryWrapper(Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem, String categoryId, String subCategoryId,
                                     List<SelectOption> subCategoryOptions, List<SelectOption> subSubCategoryOptions, String sSubTypeLabel) {
            
            this.oAdjustmentLineItem = oAdjustmentLineItem;
            this.sCategoryId = categoryId;
            this.sSubCategoryId = subCategoryId;
            this.subCategoryOptions = subCategoryOptions;
            this.subSubCategoryOptions = subSubCategoryOptions;
            this.sSubTypeLabel = sSubTypeLabel;
            this.cerStatus = 'P';
            this.bReadOnly = false;
            this.bReadOnlyDates = false;
            this.bRemoveButton = true;
            this.disableAmountField = 'N';
            this.cerFromParent = false;
            this.categoryDiscountAmendment = false;
        }

        public SubSubCategoryWrapper(Apttus_Config2__AdjustmentLineItem__c oAdjustmentLineItem, String categoryId, 
                                    String subCategoryId, List<SelectOption> subCategoryOptions, List<SelectOption> subSubCategoryOptions, 
                                    String sSubTypeLabel, String sStatus, Boolean parRemoveButton, 
                                    Double parInitialValue, Id parCERRecordId, String parCERLevel, 
                                    Boolean parCERFromParent, Boolean parCategoryDiscount) {
            
            this.oAdjustmentLineItem = oAdjustmentLineItem;
            this.sCategoryId = categoryId;
            this.sSubCategoryId = subCategoryId;
            this.subCategoryOptions = subCategoryOptions;
            this.subSubCategoryOptions = subSubCategoryOptions;
            this.sSubTypeLabel = sSubTypeLabel;
            this.cerStatus = sStatus;
            this.bReadOnly = true;
            this.bRemoveButton = parRemoveButton;
            this.dInitialValue = parInitialValue;
            this.iCERRecordId = parCERRecordId;
            this.cerLevel = parCERLevel;
            this.cerFromParent = parCERFromParent;
            this.categoryDiscountAmendment = parCategoryDiscount;

            if(this.cerStatus == 'A'){
                this.disableAmountField = 'Y';
                this.bReadOnlyDates = true;
            }else if(this.cerStatus == 'P'){
                this.disableAmountField = 'N';
                this.bReadOnlyDates = true;
            }            
        }
    }

    public class createLIInfo{
        public string level{get;set;}
        public string catId{get;set;}        
        public string subcatId{get;set;}
        public string subsubId{get;set;}
    }
}