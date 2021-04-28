/* 
@Author : Amit
@Description : class to claculate Assumption, Oligation, Rebate Payout assumption based at Category / Sub Category / Sub Sub Category
@Version 2 : Vigitha Add Logic for Assumption and Rebate payout calculation based on Rebate Payout
@version 3: Modifications by Ariel Quesada to support change 1969
@version 4 : v1.4 Modified by Beulah Thomas. Changes made for CR2123
@Revision V105 - Renuka - JIRA : DQ-2059 : Fix P4 - List has more than 1 row for assignment to SObject 
//v5 - Lavanya - DQ-2134 Category Hierarchy Text for VO record for Contract Output Purpose 
*/
public  with sharing class APTS_VolumeAssumptionObligation{

    public map<Id,String> mapCategory{get;set;}
    public map<Id, map<Id,String>> mapCatSubCat{get;set;}
    public map<Id, map<Id,String>> mapSubCatSubSubCat{get;set;}
    public map<Id,Id> subCategoryMaplocal{get;set;}
    public map<String,String> mapActionPicklist{get;set;}
    public Map<String, Map<String, APTS_Agreement_Volume_Obligation_Line__c>> voliMap = new Map<String, Map<String, APTS_Agreement_Volume_Obligation_Line__c>>();

    public list<SelectOption> catlist{get;set;}{catlist = new list<SelectOption>();} // Category list
    public list<SelectOption> subcatlist{get;set;}{subcatlist = new list<SelectOption>();} // Subcategory list
    public list<SelectOption> subsubcatlist{get;set;}{subsubcatlist = new list<SelectOption>();} // subsubcategory list
    public list<SelectOption> prodlist{get;set;}{prodlist = new list<SelectOption>();} // product list

    public list<SubSubCategoryWrapper> subsubwrap{get;set;}
    public list<categoryWrapper> categorywrap{get;set;}
    public list<subcategoryWrapper>subcatWrapper{get;set;}
    public list<ProductWrapper> prdWrapper{get;set;}

    public static List<product2> productList{get;set;}
    public integer rowToRemove{get;set;}
    public static String agreementId;
    public String agreementLanguage;
    public String agreementPreferredWayIngredientDelivery;
    public String accountsalesorganization;
    public List<String> errorList;
    public String agreementRecordType{get;set;}
    public boolean isStandard{get;set;}
    public boolean isStandardDealProduct{get;set;}
    
    public map<Id,String> validProducts; 
    public List<APTS_Agreement_Volume_Obligation_Line__c> existingLineItems = new List<APTS_Agreement_Volume_Obligation_Line__c>();

    private static String TYPE_CATEGORY = system.label.APTS_category;
    private static final String EMPTY_STRING = '';
    public static final String APEX = 'Apex';
    private static String TYPE_SUBCATEGORY = system.label.APTS_subCategory;
    private static String TYPE_SUBSUBCATEGORY = system.label.APTS_subSubCategory;
    private static String TYPE_PRODUCT = system.label.APTS_product;
    private static String BENEFIT = system.label.APTS_Benefit;
    private static String BENEFITAMT= system.label.APTS_BenefitAmt;
    private static String BENEFITPERUNIT='Benefit Per Unit';
    private static String CONSUMPTION = system.label.APTS_Consumption;
    private static String DRINKS = system.label.APTS_Drinks;
    private static String INDEX = system.label.APTS_index;
    private static String GRAM = system.label.APTS_Gram;
    private static String CUBICCENT = system.label.APTS_CC;
    private static String ID=system.label.APTS_Id;
    private static String LISTPRICE = system.label.APTS_ListPrice;
    private static String NETPRICE = system.label.APTS_NetPrice;
    private static String REVENUE = system.label.APTS_Revenue;
    private static String VOLUME = system.label.APTS_Volume;
    private static String KILOGRAM = system.label.APTS_Kilogram;
    private static String LITER= system.label.APTS_Liter;
    private static String HIGHRATETIER = system.label.APTS_HighRate;
    private static String RATEPERTIER = system.label.APTS_RatePerEach;
    private list<APTS_AgreementTotalVolumeObligation__c> lstToDel;
    private static String SELVAL = system.label.APTS_selvalue;
    private static String INDXCAT =system.label.APTS_IndCat;
    private static String SELVALCAT = system.label.APTS_selvaluecat;
    private static String PERCENT = system.label.APTS_percent;
    private static String OFFERING= system.label.APTS_Offering;
    private static String BOTH = system.label.APTS_Both;
    private static String NONE = '--None--';
    private static String NOTCONVERSIONFOUND = 'No Conversion data found. Please select Piece as unit of measure';
    private static String NOTPREFERREDWAYFOUND = 'No preferred way of ingredient delivery in the agreement. If will affect the calculation of gross sales and net sales';
    private static string STANDARDDEAL = 'Standard Deal';
    /*
    Constructor : Method will be invoked on initial load of page it will initialize the existing data and build category 
    hierarchy relation.
    */
    public APTS_VolumeAssumptionObligation(){
        // list of errors
        errorList = new List<String>();
        // Other variables  
        mapCategory = new map<Id,String>();
        mapCatSubCat = new map<Id, map<Id,String>>();
        mapSubCatSubSubCat = new map<Id, map<Id,String>>();
        subCategoryMaplocal = new map<Id,Id>();
        categorywrap = new list<categoryWrapper>();
        subcatWrapper = new list<subcategoryWrapper>();
        subsubwrap = new list<SubSubCategoryWrapper>();
        prdWrapper = new list<ProductWrapper>();
        APTS_AgreementTotalVolumeObligation__c volobg = new APTS_AgreementTotalVolumeObligation__c();        
        List<Apttus_Config2__ClassificationHierarchy__c> categoryHierarchies;
        string agreementId = ApexPages.currentPage().getParameters().get(ID);
        // Query basic information from the agreement to know the type
        Apttus__APTS_Agreement__c agree =[SELECT id,RecordType.name,APTS_Language__c,APTS_Preferred_way_of_ingredient_deliver__c,
                                    Apttus__Account__r.Sales_Organization__c
                                    FROM Apttus__APTS_Agreement__c WHERE id =:agreementId];
        agreementRecordType = agree.RecordType.Name;
        isStandard = (agreementRecordType == CONSUMPTION)?false:true;
        isStandardDealProduct = (agreementRecordType == STANDARDDEAL)?true:false;
        if (isStandard)
        {
            categoryHierarchies = 
                [SELECT Id, Apttus_Config2__HierarchyId__r.Name, Apttus_Config2__AncestorId__c,
                        Apttus_Config2__AncestorId__r.Name,Apttus_Config2__PrimordialId__c,
                        Apttus_Config2__PrimordialId__r.Name, Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c 
                        WHERE Apttus_Config2__HierarchyId__r.Apttus_Config2__Active__c = true
                        AND ((Apttus_Config2__HierarchyId__r.Name = 'Coffee')  OR 
                            (Apttus_Config2__HierarchyId__r.Name = 'Tea') OR
                            (Apttus_Config2__HierarchyId__r.Name = '&More'))
                        AND (Apttus_Config2__HierarchyId__r.Apttus_Config2__Type__c in (:OFFERING,:BOTH)) limit 50000];

            mapActionPicklist = new Map<String,String>();
            Schema.DescribeFieldResult field = APTS_AgreementTotalVolumeObligation__c.APTS_Action__c.getDescribe();
            for (Schema.PicklistEntry f : field.getPicklistValues())
            {
                mapActionPicklist.put(f.getLabel(), f.getValue());
            }
        }
        else
        {
            categoryHierarchies = 
                [SELECT Id, Apttus_Config2__HierarchyId__r.Name, Apttus_Config2__AncestorId__c,
                        Apttus_Config2__AncestorId__r.Name,Apttus_Config2__PrimordialId__c,
                        Apttus_Config2__PrimordialId__r.Name, Apttus_Config2__Label__c from Apttus_Config2__ClassificationHierarchy__c 
                        WHERE Apttus_Config2__HierarchyId__r.Apttus_Config2__Active__c = true
                        AND (
                            (Apttus_Config2__HierarchyId__r.Name = 'Coffee')  OR 
                            (Apttus_Config2__HierarchyId__r.Name = 'Tea') OR 
                            (Apttus_Config2__HierarchyId__r.Name = '&More') OR
                            (Apttus_Config2__HierarchyId__r.Name = 'Consumption Categories'))
                        AND (Apttus_Config2__HierarchyId__r.Apttus_Config2__Type__c in (:OFFERING,:BOTH)) 
                        limit 50000];
            
            mapActionPicklist = new Map<String,String>();
            Schema.DescribeFieldResult field = APTS_AgreementTotalVolumeObligation__c.APTS_Action__c.getDescribe();
            for (Schema.PicklistEntry f : field.getPicklistValues())
            {
                if (f.getLabel() != 'Invoice Customer')
                {
                    mapActionPicklist.put(f.getLabel(), f.getValue());
                }
            }
        }

        for(Apttus_Config2__ClassificationHierarchy__c hierarchy : categoryHierarchies){
            if(hierarchy.Apttus_Config2__HierarchyId__c != null && hierarchy.Apttus_Config2__AncestorId__c == null && hierarchy.Apttus_Config2__PrimordialId__c == null ){
                mapCategory.put(hierarchy.id,hierarchy.Apttus_Config2__Label__c);
                catlist.add(new SelectOption(hierarchy.id,hierarchy.Apttus_Config2__Label__c)); 
            }                   
        }
        catList.add(new SelectOption(NONE,NONE));
        Map<Id,Map<Id,String>> subCategoriesMap = new Map<Id,Map<Id,String>>();
        if(!categoryHierarchies.isEmpty()){
            for(Apttus_Config2__ClassificationHierarchy__c hierarchy : categoryHierarchies){
                if(hierarchy.Apttus_Config2__AncestorId__c != null &&  hierarchy.Apttus_Config2__PrimordialId__c == hierarchy.Apttus_Config2__AncestorId__c){
                    if(!subCategoriesMap.containsKey(hierarchy.Apttus_Config2__AncestorId__c)){
                        subCategoriesMap.put(hierarchy.Apttus_Config2__AncestorId__c, new Map<Id,String>{hierarchy.Id=>hierarchy.Apttus_Config2__Label__c});
                    }
                    else if(subCategoriesMap.containsKey(hierarchy.Apttus_Config2__AncestorId__c)){
                        Map<Id,String> subCategoriesMap2 = subCategoriesMap.get(hierarchy.Apttus_Config2__AncestorId__c);
                        subCategoriesMap2.put(hierarchy.Id, hierarchy.Apttus_Config2__Label__c);
                        subCategoriesMap.put(hierarchy.Apttus_Config2__AncestorId__c, subCategoriesMap2);
                    }
                    if(!mapCatSubCat.containsKey(hierarchy.Apttus_Config2__AncestorId__c)){
                        mapCatSubCat.put(hierarchy.Apttus_Config2__AncestorId__c, subCategoriesMap.get(hierarchy.Apttus_Config2__AncestorId__c));
                    }else if(mapCatSubCat.containsKey(hierarchy.Apttus_Config2__AncestorId__c)){
                        Map<Id,String> subCategoriesMap1 = mapCatSubCat.get(hierarchy.Apttus_Config2__AncestorId__c);
                        subCategoriesMap1.put(hierarchy.Id, hierarchy.Apttus_Config2__Label__c);
                        mapCatSubCat.put(hierarchy.Apttus_Config2__AncestorId__c, subCategoriesMap1);
                    }
                    subCategoryMaplocal.put(hierarchy.Id,hierarchy.Id); 
                    subcatlist.add(new SelectOption(hierarchy.id,hierarchy.Apttus_Config2__Label__c));  
                } 
                if(hierarchy.Apttus_Config2__PrimordialId__c!=null && hierarchy.Apttus_Config2__PrimordialId__c!= hierarchy.Apttus_Config2__AncestorId__c){                        
                    if(!mapSubCatSubSubCat.containsKey(hierarchy.Apttus_Config2__AncestorId__c)){
                        Map<Id,String> subsubCategoriesMap = new Map<Id,String>();
                        subsubCategoriesMap.put(hierarchy.Id, hierarchy.Apttus_Config2__Label__c);                            
                        mapSubCatSubSubCat.put(hierarchy.Apttus_Config2__AncestorId__c,subsubCategoriesMap);                            
                    }
                    else{
                        Map<Id,String> subsubCategoriesMap = new Map<Id,String>();
                        subsubCategoriesMap = mapSubCatSubSubCat.get(hierarchy.Apttus_Config2__AncestorId__c);
                        subsubCategoriesMap.put(hierarchy.Id, hierarchy.Apttus_Config2__Label__c);
                        mapSubCatSubSubCat.put(hierarchy.Apttus_Config2__AncestorId__c,subsubCategoriesMap);                            
                    }
                    subsubcatlist.add(new SelectOption(hierarchy.id,hierarchy.Apttus_Config2__Label__c));  
                }
            }
        }  
        InitializeObligation();
     
    }
    /*
    Method to prepopulate the data on page 
    */
    public void InitializeObligation()
    {
        Id fromAgree;
        string agreementId = ApexPages.currentPage().getParameters().get(ID);
        // Query basic information from the agreement
        Apttus__APTS_Agreement__c agree =[SELECT id,RecordType.name,APTS_Language__c,APTS_Preferred_way_of_ingredient_deliver__c,
                                    Apttus__Account__r.Sales_Organization__c,Apttus__FF_Agreement_Number__c
                                    FROM Apttus__APTS_Agreement__c WHERE id =:agreementId];
        agreementRecordType = agree.RecordType.Name;
        isStandard = (agreementRecordType == CONSUMPTION)?false:true;
        agreementLanguage = agree.APTS_Language__c;
        agreementPreferredWayIngredientDelivery = agree.APTS_Preferred_way_of_ingredient_deliver__c;
        accountsalesorganization = agree.Apttus__Account__r.Sales_Organization__c;
        // Query information about Agreement Line Items to define allowed products
        validProducts = new Map<Id,String>();
        List<Apttus__AgreementLineItem__c > agls;
        if (isStandard)
        {
            agls = [SELECT Id,Apttus__ProductId__c, Apttus_CMConfig__HasOptions__c, Apttus_CMConfig__LineType__c,
                            Apttus__ProductId__r.Name, Apttus__Description__c,
                            Apttus_CMConfig__OptionId__r.APTS_Option_Group_Indicator__c,
                            Apttus_CMConfig__OptionId__r.APTS_Material_Type__c
                                                        FROM Apttus__AgreementLineItem__c WHERE Apttus__agreementId__c=: agreementId
                                                        AND Apttus_CMConfig__LineType__c != 'Option'
                                                        AND (Apttus__ProductId__r.Family = 'SAP_01' OR Apttus__ProductId__r.Family = 'SAP_02'
                                                        OR Apttus__ProductId__r.Family = 'SAP_03')];
        }
        else
        {
            agls = [SELECT Id,Apttus__ProductId__c, Apttus_CMConfig__HasOptions__c, Apttus_CMConfig__LineType__c,
                            Apttus__ProductId__r.Name, Apttus__Description__c,
                            Apttus_CMConfig__OptionId__r.APTS_Option_Group_Indicator__c,
                            Apttus_CMConfig__OptionId__r.APTS_Material_Type__c
                            FROM Apttus__AgreementLineItem__c
                            WHERE Apttus_CMConfig__LineType__c = 'Option'
                            AND Apttus__agreementId__c=: agreementId
                            AND Apttus_CMConfig__HasOptions__c = false
                            AND Apttus_CMConfig__OptionId__r.APTS_Option_Group_Indicator__c = '06'
                            AND Apttus_CMConfig__OptionId__r.APTS_Material_Type__c = 'ZCBB'];
        }

        if (isStandard)
        {
            for (Apttus__AgreementLineItem__c agl : agls)
            {
                validProducts.put(agl.Apttus__ProductId__c, agl.Apttus__ProductId__r.Name);
                prodList.add(new SelectOption(agl.Apttus__ProductId__c, agl.Apttus__ProductId__r.Name));
            }
        }
        else
        {
            for (Apttus__AgreementLineItem__c agl : agls)
            {
                validProducts.put(agl.Apttus__ProductId__c, agl.Apttus__ProductId__r.Name);
                prodList.add(new SelectOption(agl.Apttus__ProductId__c, agl.Apttus__ProductId__r.Name + ' ' + agl.Apttus__Description__c));
            }
        }
        prodList.add(new SelectOption(NONE, NONE));
        
        if(String.isNotBlank(agree.Apttus__FF_Agreement_Number__c)){
            Integer versionIndex = agree.Apttus__FF_Agreement_Number__c.indexOf('.');
            String version = agree.Apttus__FF_Agreement_Number__c.subString(versionIndex+1,agree.Apttus__FF_Agreement_Number__c.length());
            if(version != '0')
                fromAgree = [Select Id, Apttus__APTS_Contract_From__c From Apttus__APTS_Related_Agreement__c Where Apttus__APTS_Contract_To__c = :agreementId Limit 1]. Apttus__APTS_Contract_From__c;//V105
        }
        
        if(fromAgree!=null){
            existingLineItems = [Select Id, APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Type__c ,
                                            APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c, 
                                            APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_SubCategoryName__c,
                                            APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Volume_Obligation__c 
                                            From APTS_Agreement_Volume_Obligation_Line__c where APTS_Agreement__c=:fromAgree];
        }

        if(!existingLineItems.isEmpty()){
            for(APTS_Agreement_Volume_Obligation_Line__c voli: existingLineItems){
                if(voliMap.containsKey(voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Type__c)){
                    voliMap.get(voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Type__c).put(voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c+voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Volume_Obligation__c, voli);
                }else{
                    voliMap.put(voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Type__c,new Map<String,APTS_Agreement_Volume_Obligation_Line__c>{voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Value__c+voli.APTS_Agreement_Volume_Obligation__r.APTS_Agreement_Total_Volume_Obligation__r.APTS_Volume_Obligation__c=> voli}); 
                }
            }
        }
        //system.debug('@@@'+voliMap);
        integer catcounter=0;
        integer subcounter=0;
        integer subsubcnt=0;
        integer prdcnt =0;
        for(APTS_AgreementTotalVolumeObligation__c obligationLine : [SELECT Id, APTS_Agreement__c, APTS_Value_Name__c, APTS_Type__c,APTS_Action__c,APTS_Volume_Obligation__c, APTS_Value__c, 
                                                                    APTS_Unit_of_Measure__c, APTS_Malus_per_Unit__c,APTS_SubCategoryValue__c,APTS_Rebate_Payout__c,APTS_Agreement__r.RecordType.Name,
                                                                    APTS_Categoryvalue__c,APTS_VolumeAssumption__c,APTS_VolumeObligationPercentage__c,APTS_NumberofDrinks__c,
                                                                    APTS_IncludeSelloutData__c,APTS_GrossSale__c,APTS_NetSale__c,APTS_SubCategoryName__c,APTS_CategoryName__c,APTS_Close__c
                                                                             from APTS_AgreementTotalVolumeObligation__c
                                                                             where APTS_Type__c in (:TYPE_CATEGORY,:TYPE_SUBCATEGORY,:TYPE_SUBSUBCATEGORY,:TYPE_PRODUCT)
                                                                             AND APTS_Agreement__c= :agreementId limit 50000] ) {

            //system.debug(obligationLine.APTS_Type__c+':'+TYPE_SUBCATEGORY+',:,'+TYPE_SUBSUBCATEGORY);
            //system.debug(obligationLine.APTS_Type__c+',:,'+obligationLine.APTS_Value__c+obligationLine.APTS_Volume_Obligation__c);
            
            if(obligationLine.APTS_Type__c == TYPE_CATEGORY)
            {
                //System.debug('Category obligationLine: ' + obligationLine);
                categorywrap.add(new categoryWrapper(catcounter,catlist,obligationLine));                
                catcounter++;
            }    
            else if(obligationLine.APTS_Type__c == TYPE_SUBCATEGORY && voliMap.containsKey(obligationLine.APTS_Type__c))
            {
                //System.debug('SubCategory obligationLine: ' + obligationLine);
                if(voliMap.get(obligationLine.APTS_Type__c).containsKey(obligationLine.APTS_Value__c+obligationLine.APTS_Volume_Obligation__c)){
                    if(obligationLine.APTS_Close__c){
                        subcatWrapper.add(new subcategoryWrapper(subcounter,catlist,subcatlist,obligationLine,true,true));
                    }else{
                        subcatWrapper.add(new subcategoryWrapper(subcounter,catlist,subcatlist,obligationLine,true,false)); 
                    }
                    subcounter++;
                }else{
                    subcatWrapper.add(new subcategoryWrapper(subcounter,catlist,subcatlist,obligationLine,false,false));
                    subcounter++;
                }
                
            }
            else if(obligationLine.APTS_Type__c == TYPE_SUBCATEGORY && !voliMap.containsKey(obligationLine.APTS_Type__c))
            {
                //System.debug('SubCategory obligationLine: ' + obligationLine);
                subcatWrapper.add(new subcategoryWrapper(subcounter,catlist,subcatlist,obligationLine,false,false));
                subcounter++;
            }
            else if(obligationLine.APTS_Type__c == TYPE_SUBSUBCATEGORY && voliMap.containsKey(obligationLine.APTS_Type__c))
            {
                //System.debug('SubSubCategory obligationLine: ' + obligationLine);
                if(voliMap.get(obligationLine.APTS_Type__c).containsKey(obligationLine.APTS_Value__c+obligationLine.APTS_Volume_Obligation__c)){
                    if(obligationLine.APTS_Close__c){
                        subsubwrap.add(new SubSubCategoryWrapper(subsubcnt,catlist,subcatlist,subsubcatlist,obligationLine,true,true));
                    }else{
                        subsubwrap.add(new SubSubCategoryWrapper(subsubcnt,catlist,subcatlist,subsubcatlist,obligationLine,true,false));
                    }
                    subsubcnt++;
                }else{
                    subsubwrap.add(new SubSubCategoryWrapper(subsubcnt,catlist,subcatlist,subsubcatlist,obligationLine,false,false));
                    subsubcnt++;
                }
            }
            else if(obligationLine.APTS_Type__c == TYPE_SUBSUBCATEGORY && !voliMap.containsKey(obligationLine.APTS_Type__c))
            {
                //System.debug('SubSubCategory obligationLine: ' + obligationLine);
                subsubwrap.add(new SubSubCategoryWrapper(subsubcnt,catlist,subcatlist,subsubcatlist,obligationLine,false,false));
                subsubcnt++;
            }
            else if(obligationLine.APTS_Type__c == TYPE_PRODUCT && voliMap.containsKey(obligationLine.APTS_Type__c))
            {
                //System.debug('Product obligationLine: ' + obligationLine);
                if(voliMap.get(obligationLine.APTS_Type__c).containsKey(obligationLine.APTS_Value__c+obligationLine.APTS_Volume_Obligation__c)){
                    if(obligationLine.APTS_Close__c){
                        prdWrapper.add(new ProductWrapper(prdcnt,prodList, obligationLine,true,true)); 
                    }else{
                        prdWrapper.add(new ProductWrapper(prdcnt,prodList, obligationLine,true,false)); 
                    }
                    
                }else{
                    prdWrapper.add(new ProductWrapper(prdcnt,prodList, obligationLine,false,false)); 
                }
                
            }
            else if(obligationLine.APTS_Type__c == TYPE_PRODUCT && !voliMap.containsKey(obligationLine.APTS_Type__c))
            {
                //System.debug('Product obligationLine: ' + obligationLine);
                prdWrapper.add(new ProductWrapper(prdcnt,prodList, obligationLine,false,false));
            }
        }
    }
     /*
    Method to add New row for Sub - Category level.
    */
    public void addNewRowTosubCatList()
    {
        //System.debug('Subcatwrapper before the addition: ' + subcatWrapper);
        APTS_AgreementTotalVolumeObligation__c volobg = new APTS_AgreementTotalVolumeObligation__c();
        if (agreementRecordType == CONSUMPTION)
        {
            volobg.APTS_Unit_of_Measure__c = 'SAP_DRKS';            
        }
        
        Subcategorywrapper wrp = new subcategoryWrapper(subcatWrapper.size(),catlist,subcatlist,volobg,false,false);
        // Initialize different info in NONE values for subcategories
        list<SelectOption> subcatopt = new list<SelectOption>();
        subcatopt.add(new SelectOption(NONE, NONE));        
        wrp.volAsmpOlg.APTS_SubCategoryValue__c = NONE;
        wrp.volAsmpOlg.APTS_SubCategoryName__c = NONE;
        wrp.volasmpOlg.APTS_CategoryName__c = NONE;
        wrp.volasmpolg.APTS_Categoryvalue__c = NONE;
        wrp.subCategory = subcatopt;
        // Initialize different info in NONE for initial category

        subcatWrapper.add(wrp);        
        //System.debug('Subcatwrapper after the addition: ' + subcatWrapper);
    }

     /*
    Method to add New row for Sub - Sub - Category level.
    */
    public void addNewRowTosubsubList()
    {
        APTS_AgreementTotalVolumeObligation__c volobg = new APTS_AgreementTotalVolumeObligation__c();
        volobg.APTS_Categoryvalue__c = NONE;
        if (agreementRecordType == CONSUMPTION)
        {
            volobg.APTS_Unit_of_Measure__c = 'SAP_DRKS';            
        }
        SubSubCategoryWrapper wrp = new SubSubCategoryWrapper(subsubwrap.size(),catlist,subcatlist,subsubcatlist,volobg,false,false);            
        // Initialize different info in NONE values for subsubcategories
        list<SelectOption> subsubcatopt = new list<SelectOption>();
        subsubcatopt.add(new SelectOption(NONE, NONE));        
        wrp.volAsmpOlg.APTS_Value__c = NONE;
        wrp.volAsmpOlg.APTS_Value_Name__c = NONE;
        wrp.subsubCategory = subsubcatopt;
        // Initialize different info in NONE values for subcategories
        list<SelectOption> subcatopt = new list<SelectOption>();
        subcatopt.add(new SelectOption(NONE, NONE));        
        wrp.volAsmpOlg.APTS_SubCategoryValue__c = NONE;
        wrp.volAsmpOlg.APTS_SubCategoryName__c = NONE;
        wrp.subCategory = subcatopt;

        subsubwrap.add(wrp);        
    }
     /*
    Method to add New row for Product level.
    */
    public void addNewRowToPrdList()
    {
        APTS_AgreementTotalVolumeObligation__c volobg = new APTS_AgreementTotalVolumeObligation__c();
        if (agreementRecordType == CONSUMPTION)
        {
            volobg.APTS_Unit_of_Measure__c = 'SAP_DRKS';
        }
        else
        {            
            volobg.APTS_NumberofDrinks__c = 0.0;
            volobg.APTS_Value__c = NONE;
        }
        if(prdWrapper.size()>0)
            prdWrapper.add(new ProductWrapper(prdWrapper.size(),prodList, volobg,false,false));
        else
            prdWrapper.add(new ProductWrapper(0,prodList, volobg,false,false));        
    }
       
    /*
    Method to remove row from Category level.
    */
    public void getremoveRowFromsubCatList()
    {
        categorywrap = toRemoveCatList(rowToRemove,categorywrap);
    }
    /*
    Method to remove row from sub - Category level.
    */
    public void getremoveRowFromsubList()
    {
        //subcatWrapper = toRemoveSubCatList(rowToRemove,subcatWrapper);
        lstToDel = new list<APTS_AgreementTotalVolumeObligation__c>();
        subcategoryWrapper wrp = subcatWrapper[Integer.valueof(rowToRemove)];
        if(wrp.existing){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Tracking is done for this Volume Assumption on the previous version of agreement. You can close this by enabling the close checkbox and create a new Volume Assumption.');
            ApexPages.addMessage(myMsg);
        }else if(null != wrp.volAsmpOlg.Id){
            lstToDel.add(wrp.volAsmpOlg);
        }
        subcatWrapper.remove(rowToRemove);
        delete lstToDel;
    }
    public void disableSub(){
        String rowToClose = ApexPages.currentPage().getParameters().get(INDEX);
        //system.debug('rowToClose: '+rowToClose);
        subcategoryWrapper wrp = subcatWrapper[Integer.valueof(rowToClose)];
        if(wrp.volAsmpOlg.APTS_Close__c){
            wrp.disable = true;
        }else{
            wrp.disable=false;
        }
        //system.debug('Disable wrapper: '+wrp);
    }
    public void disableSubSub(){
        String rowToClose = ApexPages.currentPage().getParameters().get(INDEX);
        //system.debug('rowToClose: '+rowToClose);
        SubSubCategoryWrapper wrp = subsubwrap[Integer.valueof(rowToClose)];
        if(wrp.volAsmpOlg.APTS_Close__c){
            wrp.disable = true;
        }else{
            wrp.disable=false;
        }
        //system.debug('Disable wrapper: '+wrp);
    }
    public void disablePrd(){
        String rowToClose = ApexPages.currentPage().getParameters().get(INDEX);
        //system.debug('rowToClose: '+rowToClose);
        ProductWrapper wrp = prdWrapper[Integer.valueof(rowToClose)];
        if(wrp.volAsmpOlg.APTS_Close__c){
            wrp.disable = true;
        }else{
            wrp.disable=false;
        }
        //system.debug('Disable wrapper: '+wrp);
    }
    /*
    Method to remove row from sub - sub - Category level.
    */
    public void getremoveRowFromsubsubList()
    {
        //subsubwrap = toRemove(rowToRemove,subsubwrap);
        lstToDel = new list<APTS_AgreementTotalVolumeObligation__c>();
        //system.debug('rownum'+rowToRemove+','+subsubwrap.size());
        SubSubCategoryWrapper wrp = subsubwrap[Integer.valueof(rowToRemove)];
         if(wrp.existing){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Tracking is done for this Volume Assumption on the previous version of agreement. You can close this by enabling the close checkbox and create a new Volume Assumption.');
            ApexPages.addMessage(myMsg);
        }else if(null != wrp.volAsmpOlg.Id){
            lstToDel.add(wrp.volAsmpOlg);
        }
        subsubwrap.remove(rowToRemove);
        delete lstToDel;
    }
    /*
    Method to remove row from Product level.
    */
    public void getremoveRowFromPrdList()
    {
        //prdWrapper = toRemovePrdList(rowToRemove,prdWrapper);
        lstToDel = new list<APTS_AgreementTotalVolumeObligation__c>();
        ProductWrapper wrp =  prdWrapper[Integer.valueof(rowToRemove)];
         if(wrp.existing){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Tracking is done for this Volume Assumption on the previous version of agreement. You can close this by enabling the close checkbox and create a new Volume Assumption.');
            ApexPages.addMessage(myMsg);
        }else if(null != wrp.volAsmpOlg.Id){
            lstToDel.add(wrp.volAsmpOlg);
        }
        prdWrapper.remove(rowToRemove);
        delete lstToDel;
    }
    private list<categoryWrapper> toRemoveCatList(integer rownum,list<categoryWrapper> catwrpTodel){
        lstToDel = new list<APTS_AgreementTotalVolumeObligation__c>();
        categoryWrapper wrp = catwrpTodel[Integer.valueof(rownum)];
        if(null != wrp.volAsmpOlg.Id)
            lstToDel.add(wrp.volAsmpOlg);
        catwrpTodel.remove(rownum);            
        delete lstToDel;        
        return catwrpTodel;
    }

    /*private list<subcategoryWrapper> toRemoveSubCatList(integer rownum,list<subcategoryWrapper> subwrapTodel)
    {
        lstToDel = new list<APTS_AgreementTotalVolumeObligation__c>();
        subcategoryWrapper wrp = subwrapTodel[Integer.valueof(rownum)];
        if(wrp.existing){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Tracking is done for this Volume Assumption on the previous version of agreement. You can close this by enabling the close checkbox and create a new Volume Assumption.');
            ApexPages.addMessage(myMsg);
        }else if(null != wrp.volAsmpOlg.Id){
            lstToDel.add(wrp.volAsmpOlg);
            subwrapTodel.remove(rownum);
            delete lstToDel;
        }
        return subwrapTodel;
    }
    private list<SubSubCategoryWrapper> toRemove(integer rownum,list<SubSubCategoryWrapper> subsubwrapTodel)
    {
            lstToDel = new list<APTS_AgreementTotalVolumeObligation__c>();
            system.debug('rownum'+rownum+','+subsubwrapTodel.size());
            SubSubCategoryWrapper wrp = subsubwrapTodel[Integer.valueof(rownum)];
            if(null != wrp.volAsmpOlg.Id)
                lstToDel.add(wrp.volAsmpOlg);
            subsubwrapTodel.remove(rownum);
            delete lstToDel;
            return subsubwrapTodel;
    }
    private list<ProductWrapper> toRemovePrdList(integer rownum,list<ProductWrapper> prdwrpTodel){
            lstToDel = new list<APTS_AgreementTotalVolumeObligation__c>();
            ProductWrapper wrp =  prdwrpTodel[Integer.valueof(rownum)];
            if(null != wrp.volAsmpOlg.Id)
                lstToDel.add(wrp.volAsmpOlg);       
            prdwrpTodel.remove(rownum);
            delete lstToDel;
            return prdwrpTodel;
    }*/
    /*
    Method to get dependent sub category based on category
    */
    public void getDependentsubcat()
    {
        //System.debug('Start of getDependentsubcat.');
        String indexStr = ApexPages.currentPage().getParameters().get(INDEX);
        string selValue=  ApexPages.currentPage().getParameters().get(SELVAL);
        //system.debug('indexStr sub '+indexStr);
        //system.debug('selValue sub '+selValue);
        SubSubCategoryWrapper wrp = subsubwrap[Integer.valueof(indexStr)];
        map<Id,String> SubCat = mapCatSubCat.get(selValue);        
        list<SelectOption> subcatopt = new list<SelectOption>();
        for(Id key : SubCat.keySet()){
            subcatopt.add(new selectoption(key,SubCat.get(key)));
        }
        wrp.subCategory = subcatopt;
        // Selection of first sub subcategory
        map<Id,String> subsubcat = mapSubCatSubSubCat.get(subcatopt.get(0).getvalue());        
        list<SelectOption> subsubcatopt = new list<SelectOption>();
        boolean bSubSubFound = false;
        if (subsubcat != null )
        {
            for(Id key : subsubcat.keySet()){
                subsubcatopt.add(new selectoption(key,subsubcat.get(key)));
            }            
            bSubSubFound = true;
            wrp.volAsmpOlg.APTS_Value__c = subsubcatopt.get(0).getvalue();
        }        
        else
        {
            subsubcatopt.add(new SelectOption(NONE, NONE));
            wrp.volAsmpOlg.APTS_Value__c = NONE;
            bSubSubFound = false;
        }
        wrp.subSubCategory= subsubcatopt;
        // Fill data of volAsmpOlg
        wrp.volAsmpOlg.APTS_Categoryvalue__c=selValue;
        wrp.volAsmpOlg.APTS_SubCategoryValue__c= subcatopt.get(0).getvalue();
        // Restart values
        wrp.volAsmpOlg.APTS_NumberofDrinks__c = 0.0;
        wrp.volAsmpOlg.APTS_VolumeAssumption__c = 0.0;
        wrp.volAsmpOlg.APTS_NetSale__c = 0.0; // to be filled by the API Method
        wrp.volAsmpOlg.APTS_GrossSale__c = 0.0; // to be filled by the API
    }
    /*
    Method to get dependent sub sub category based on sub category
    */
    public void getDependentsubcatsec()
    {
        String indexStr = ApexPages.currentPage().getParameters().get(INDEX);
        string selValue=  ApexPages.currentPage().getParameters().get(SELVAL);
        subcategoryWrapper wrp = subcatWrapper[Integer.valueof(indexStr)];
        map<Id,String> SubCat = mapCatSubCat.get(selValue);
        
        list<SelectOption> subcatopt = new list<SelectOption>();
        for(Id key : SubCat.keySet()){
            subcatopt.add(new selectoption(key,SubCat.get(key)));
        }
        wrp.subCategory = subcatopt;
    }

    public void getDependentsubsubcat(){        
        String indexStr = ApexPages.currentPage().getParameters().get(INDEX);
        string selValue=  ApexPages.currentPage().getParameters().get(SELVAL);
        
        SubSubCategoryWrapper wrp = subsubwrap[Integer.valueof(indexStr)];
        map<Id,String> subsubcat = mapSubCatSubSubCat.get(selValue);
        
        list<SelectOption> subsubcatopt = new list<SelectOption>();
        boolean bSubSubFound = false;
        if (subsubcat != null )
        {
            for(Id key : subsubcat.keySet()){
                subsubcatopt.add(new selectoption(key,subsubcat.get(key)));
            }    
            bSubSubFound = true;
            wrp.volAsmpOlg.APTS_Value__c = subsubcatopt.get(0).getvalue();
        }
        else
        {
            subsubcatopt.add(new SelectOption(NONE, NONE));    
            bSubSubFound = false;
            wrp.volAsmpOlg.APTS_Value__c = NONE;
        }
        wrp.subSubCategory= subsubcatopt;
        // Restart values
        wrp.volAsmpOlg.APTS_NumberofDrinks__c = 0.0;
        wrp.volAsmpOlg.APTS_VolumeAssumption__c = 0.0;
        wrp.volAsmpOlg.APTS_NetSale__c = 0.0; // to be filled by the API Method
        wrp.volAsmpOlg.APTS_GrossSale__c = 0.0; // to be filled by the API
        // Fill data of volAsmpOlg
        wrp.volAsmpOlg.APTS_SubCategoryValue__c= selValue;
        callVolumeCalculation(indexStr);             
    }

    public void callVolumeCalculation(String indexStr)
    {
        SubSubCategoryWrapper wrp = subsubwrap[Integer.valueof(indexStr)];
        Id agreementId = ApexPages.currentPage().getParameters().get(ID);
        // Call Methods in the Volume Calculation Engine
        // Assumption
        APTS_VolumeCalculationEngine.VolumeAssumptionRequest request = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
        request.category =  mapCategory.get(wrp.volAsmpOlg.APTS_Categoryvalue__c);                    
        request.subcategory = mapCatSubCat.get(wrp.volAsmpOlg.APTS_Categoryvalue__c).get(wrp.volAsmpOlg.APTS_SubCategoryValue__c);  
        if (wrp.volAsmpOlg.APTS_Value__c == NONE)
        {
            request.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;
            request.subSubCategory = NONE;
        }
        else
        {
            request.subSubCategory = mapSubCatSubSubCat.get(wrp.volAsmpOlg.APTS_SubCategoryValue__c).get(wrp.volAsmpOlg.APTS_Value__c);
            request.familyLevel = APTS_VolumeCalculationEngine.SUBSUBCATEGORY_LEVEL;   
        }
        request.agreementId = agreementId;
        request.unitfromUOM = wrp.volAsmpOlg.APTS_NumberofDrinks__c;
        request.fromUOM = 'SAP_DRKS';
        request.toUOM = wrp.volAsmpOlg.APTS_Unit_of_Measure__c;
        decimal assumption = APTS_VolumeCalculationEngine.getAssumption (request);        
        if (assumption != -1.0&&wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c!=null&&wrp.volAsmpOlg.APTS_VolumeAssumption__c!=null)
        {
            wrp.volAsmpOlg.APTS_VolumeAssumption__c = assumption;            
            wrp.volAsmpOlg.APTS_Volume_Obligation__c=  (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c * wrp.volAsmpOlg.APTS_VolumeAssumption__c)/100;
        }
        else
        {
            wrp.volAsmpOlg.APTS_VolumeAssumption__c = 0.0;           
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,NOTCONVERSIONFOUND);
            ApexPages.addMessage(myMsg);
        }
        // wrp.volAsmpOlg.APTS_Rebate_Payout__c = getRebate(agreementId,wrp.volAsmpOlg.APTS_VolumeAssumption__c,wrp.volAsmpOlg.APTS_SubCategoryValue__c,wrp.volAsmpOlg.APTS_GrossSale__c,wrp.volAsmpOlg.APTS_NetSale__c);
    }    
    /*
    Method to calculate volume assumption at Sub - Category level
    */
    public void getVolumeAssumptiosubcategory()
    {
        try
        {
            String indexStr = ApexPages.currentPage().getParameters().get(INDXCAT);
            string selValue=  ApexPages.currentPage().getParameters().get(SELVALCAT);        
            subcategoryWrapper wrp = subcatWrapper[Integer.valueof(indexStr)];
            Id agreementId = ApexPages.currentPage().getParameters().get(ID);
            // Call the engine for assumption
            APTS_VolumeCalculationEngine.VolumeAssumptionRequest request = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
            request.category =  mapCategory.get(wrp.volAsmpOlg.APTS_Categoryvalue__c);                    
            request.subcategory = mapCatSubCat.get(wrp.volAsmpOlg.APTS_Categoryvalue__c).get(wrp.volAsmpOlg.APTS_SubCategoryValue__c);  
            request.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;
            request.subSubCategory = NONE;            
            request.agreementId = agreementId;
            request.unitfromUOM = wrp.volAsmpOlg.APTS_NumberofDrinks__c;
            request.fromUOM = 'SAP_DRKS';
            request.toUOM = wrp.volAsmpOlg.APTS_Unit_of_Measure__c; 
            
            // Calculation of Gross Sales and Net Sales
            if (agreementPreferredWayIngredientDelivery != null)
            {
                APTS_VolumeCalculationEngine.GrossAndNetSalesRequest gsnsRequest = new APTS_VolumeCalculationEngine.GrossAndNetSalesRequest();
                gsnsRequest.salesorganization = accountsalesorganization;
                gsnsRequest.PreferredWayOfIngredientDelivery = agreementPreferredWayIngredientDelivery;
                gsnsRequest.category = mapCategory.get(wrp.volAsmpOlg.APTS_Categoryvalue__c);                    
                gsnsRequest.subcategory = mapCatSubCat.get(wrp.volAsmpOlg.APTS_Categoryvalue__c).get(wrp.volAsmpOlg.APTS_SubCategoryValue__c);  
                gsnsRequest.subsubcategory = null;
                gsnsRequest.familyLevel = 2; // Subcategory level
                gsnsRequest.UOM = wrp.volAsmpOlg.APTS_Unit_of_Measure__c;
                APTS_VolumeCalculationEngine.GrossAndNetSalesResponse gsnsResponse = APTS_VolumeCalculationEngine.getGrossAndNetValues(gsnsRequest);
                wrp.volasmpolg.APTS_GrossSale__c = gsnsResponse.grossSales;
                // wrp.volasmpolg.APTS_NetSale__c = gsnsResponse.netSales; (Commented because the net sales it not used anymore)
            }
            else
            {
                wrp.volasmpolg.APTS_GrossSale__c = 0.0;
                wrp.volasmpolg.APTS_NetSale__c = 0.0;
            }
            // Calculation of volume assumption
            decimal assumption = APTS_VolumeCalculationEngine.getAssumption (request);
            if (assumption != -1.0)
            {
                wrp.volAsmpOlg.APTS_VolumeAssumption__c = assumption;
                wrp.volasmpolg.APTS_GrossSale__c = wrp.volasmpolg.APTS_GrossSale__c*assumption;
                if (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c != null)
                {
                    wrp.volAsmpOlg.APTS_Volume_Obligation__c=  (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c * wrp.volAsmpOlg.APTS_VolumeAssumption__c)/100;
                }
            }
            else
            {
                wrp.volAsmpOlg.APTS_VolumeAssumption__c = 0.0;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,NOTCONVERSIONFOUND);
                ApexPages.addMessage(myMsg);
            }
            // wrp.volAsmpOlg.APTS_Rebate_Payout__c = getRebate(agreementId,wrp.volAsmpOlg.APTS_VolumeAssumption__c,wrp.volAsmpOlg.APTS_SubCategoryValue__c,wrp.volAsmpOlg.APTS_GrossSale__c,wrp.volAsmpOlg.APTS_NetSale__c);
        }
        Catch(Exception e)
        {
            system.debug(e.getMessage()+ e.getLineNumber());
            //APTS_BIRUtils.logError(null,null,null,e,APEX,'getVolumeAssumptiosubcategory() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
        }
    }

    public void getDrinksSubcategory()
    {
        try
        {
            String indexStr = ApexPages.currentPage().getParameters().get(INDXCAT);
            string selValue=  ApexPages.currentPage().getParameters().get(SELVALCAT);
            subcategoryWrapper wrp = subcatWrapper[Integer.valueof(indexStr)];
            Id agreementId = ApexPages.currentPage().getParameters().get(ID);
            
            if (wrp.volAsmpOlg.APTS_Unit_of_Measure__c!=null)
            {
                //Reverse calculation: From Volume Assumption to Drinks
                APTS_VolumeCalculationEngine.DrinksRequest reverseRequest = new APTS_VolumeCalculationEngine.DrinksRequest();
                reverseRequest.agreementId = agreementId;
                reverseRequest.volumeAssumption = wrp.volAsmpOlg.APTS_VolumeAssumption__c;
                reverseRequest.originalUOM = wrp.volAsmpOlg.APTS_Unit_of_Measure__c;
                reverseRequest.category = mapCategory.get(wrp.volAsmpOlg.APTS_Categoryvalue__c);                    
                reverseRequest.subcategory = mapCatSubCat.get(wrp.volAsmpOlg.APTS_Categoryvalue__c).get(wrp.volAsmpOlg.APTS_SubCategoryValue__c);  
                reverseRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;
                reverseRequest.subSubCategory = NONE;            
                decimal drinks = APTS_VolumeCalculationEngine.getDrinks(reverseRequest);
                if (drinks != -1.0 )
                {
                    wrp.volAsmpOlg.APTS_NumberofDrinks__c = drinks;
                    wrp.volAsmpOlg.APTS_Volume_Obligation__c=  (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c * wrp.volAsmpOlg.APTS_VolumeAssumption__c)/100;
                }
                else
                {
                    wrp.volAsmpOlg.APTS_NumberofDrinks__c = 0;
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,NOTCONVERSIONFOUND);
                    ApexPages.addMessage(myMsg);
                }
            }
        }
        Catch(Exception e)
        {
            system.debug(e.getMessage()+ e.getLineNumber());
            //APTS_BIRUtils.logError(null,null,null,e,APEX,'getVolumeAssumptiosubcategory() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
        }
    }
    /*
    Method to calculate volume assumption at Sub -Sub - Category level
    */
    public void getVolumeAssumptiosubsubcategory()
    {
        try
        {
            String indexStr = ApexPages.currentPage().getParameters().get(INDXCAT);
            string selValue=  ApexPages.currentPage().getParameters().get(SELVALCAT);
            Id agreementId = ApexPages.currentPage().getParameters().get(ID);
            SubSubCategoryWrapper wrp = subsubwrap[Integer.valueof(indexStr)];
            // Call the engine for assumption            
            APTS_VolumeCalculationEngine.VolumeAssumptionRequest request = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
            request.category =  mapCategory.get(wrp.volAsmpOlg.APTS_Categoryvalue__c);                    
            request.subcategory = mapCatSubCat.get(wrp.volAsmpOlg.APTS_Categoryvalue__c).get(wrp.volAsmpOlg.APTS_SubCategoryValue__c);  
            if (wrp.volAsmpOlg.APTS_Value__c == NONE)
            {
                request.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;
                request.subSubCategory = NONE;
            }
            else
            {
                request.subSubCategory = mapSubCatSubSubCat.get(wrp.volAsmpOlg.APTS_SubCategoryValue__c).get(wrp.volAsmpOlg.APTS_Value__c);
                request.familyLevel = APTS_VolumeCalculationEngine.SUBSUBCATEGORY_LEVEL;   
            }
            request.agreementId = agreementId;
            request.unitfromUOM = wrp.volAsmpOlg.APTS_NumberofDrinks__c;
            request.fromUOM = 'SAP_DRKS';
            request.toUOM = wrp.volAsmpOlg.APTS_Unit_of_Measure__c; 
            // Calculation of Gross Sales and Net Sales
            if (agreementPreferredWayIngredientDelivery != null)
            {
                APTS_VolumeCalculationEngine.GrossAndNetSalesRequest gsnsRequest = new APTS_VolumeCalculationEngine.GrossAndNetSalesRequest();
                gsnsRequest.salesorganization = accountsalesorganization;
                gsnsRequest.PreferredWayOfIngredientDelivery = agreementPreferredWayIngredientDelivery;
                gsnsRequest.category = mapCategory.get(wrp.volAsmpOlg.APTS_Categoryvalue__c);                    
                gsnsRequest.subcategory = mapCatSubCat.get(wrp.volAsmpOlg.APTS_Categoryvalue__c).get(wrp.volAsmpOlg.APTS_SubCategoryValue__c);  
                gsnsRequest.subsubcategory = mapSubCatSubSubCat.get(wrp.volAsmpOlg.APTS_SubCategoryValue__c).get(wrp.volAsmpOlg.APTS_Value__c);
                gsnsRequest.familyLevel = 3; // SubSubcategory level
                gsnsRequest.UOM = wrp.volAsmpOlg.APTS_Unit_of_Measure__c;
                APTS_VolumeCalculationEngine.GrossAndNetSalesResponse gsnsResponse = APTS_VolumeCalculationEngine.getGrossAndNetValues(gsnsRequest);
                wrp.volasmpolg.APTS_GrossSale__c = gsnsResponse.grossSales;
                // wrp.volasmpolg.APTS_NetSale__c = gsnsResponse.netSales; (Commented because the net sales it not used anymore)
            }
            else
            {
                wrp.volasmpolg.APTS_GrossSale__c = 0.0;
                wrp.volasmpolg.APTS_NetSale__c = 0.0;
            }
            wrp.volAsmpOlg.APTS_VolumeAssumption__c = APTS_VolumeCalculationEngine.getAssumption (request);
            wrp.volasmpolg.APTS_GrossSale__c = wrp.volasmpolg.APTS_GrossSale__c*wrp.volAsmpOlg.APTS_VolumeAssumption__c;
            wrp.volAsmpOlg.APTS_Volume_Obligation__c = wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c*wrp.volAsmpOlg.APTS_VolumeAssumption__c;
            // wrp.volAsmpOlg.APTS_VolumeAssumption__c = getAssumption(wrp.volAsmpOlg.APTS_SubCategoryValue__c,wrp.volAsmpOlg.APTS_NumberofDrinks__c,agreementId,selValue);
            // Rebate
            APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
            rebateRequest.agreementId = agreementId;
            rebateRequest.volAssumption = wrp.volAsmpOlg.APTS_VolumeAssumption__c;
            rebateRequest.category = wrp.volAsmpOlg.APTS_SubCategoryValue__c;
            rebateRequest.grossSale = wrp.volAsmpOlg.APTS_GrossSale__c;
            rebateRequest.netSale = wrp.volAsmpOlg.APTS_NetSale__c;

            wrp.volAsmpOlg.APTS_Rebate_Payout__c = APTS_VolumeCalculationEngine.getRebate(rebateRequest);

            // wrp.volAsmpOlg.APTS_Rebate_Payout__c = getRebate(agreementId,wrp.volAsmpOlg.APTS_VolumeAssumption__c,wrp.volAsmpOlg.APTS_SubCategoryValue__c,wrp.volAsmpOlg.APTS_GrossSale__c,wrp.volAsmpOlg.APTS_NetSale__c);    
        }
        Catch(Exception e)
        {
            system.debug(e.getMessage()+ e.getLineNumber());
            //APTS_BIRUtils.logError(null,null,null,e,APEX,'getVolumeAssumptiosubsubcategory() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
        }
    }

    public void getDrinksSubSubcategory()
    {
        String indexStr = ApexPages.currentPage().getParameters().get(INDXCAT);
        string selValue=  ApexPages.currentPage().getParameters().get(SELVALCAT);
        SubSubCategoryWrapper wrp = subsubwrap[Integer.valueof(indexStr)];
        Id agreementId = ApexPages.currentPage().getParameters().get(ID);
        
        if (wrp.volAsmpOlg.APTS_Unit_of_Measure__c!=null)
        {
            //Reverse calculation: From Volume Assumption to Drinks
            APTS_VolumeCalculationEngine.DrinksRequest reverseRequest = new APTS_VolumeCalculationEngine.DrinksRequest();
            reverseRequest.agreementId = agreementId;
            reverseRequest.volumeAssumption = wrp.volAsmpOlg.APTS_VolumeAssumption__c;
            reverseRequest.originalUOM = wrp.volAsmpOlg.APTS_Unit_of_Measure__c;
            reverseRequest.category = mapCategory.get(wrp.volAsmpOlg.APTS_Categoryvalue__c);                    
            reverseRequest.subcategory = mapCatSubCat.get(wrp.volAsmpOlg.APTS_Categoryvalue__c).get(wrp.volAsmpOlg.APTS_SubCategoryValue__c);  
            if (wrp.volAsmpOlg.APTS_Value__c == NONE)
            {
                reverseRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;
                reverseRequest.subSubCategory = NONE;
            }
            else
            {
                reverseRequest.subSubCategory = mapSubCatSubSubCat.get(wrp.volAsmpOlg.APTS_SubCategoryValue__c).get(wrp.volAsmpOlg.APTS_Value__c);
                reverseRequest.familyLevel = APTS_VolumeCalculationEngine.SUBSUBCATEGORY_LEVEL;   
            }
            wrp.volAsmpOlg.APTS_NumberofDrinks__c = APTS_VolumeCalculationEngine.getDrinks(reverseRequest);
            /* ---------- Start of PI fix # 190421----------------------- */
            if (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c != null && wrp.volAsmpOlg.APTS_VolumeAssumption__c!=null)
            {
                wrp.volAsmpOlg.APTS_Volume_Obligation__c=  (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c * wrp.volAsmpOlg.APTS_VolumeAssumption__c)/100;
            }
            /* ---------- End of PI fix # 190421----------------------- */
        }
    }
    /*
    Method to calculate volume assumption at Product level
    */
    public void getVolumeAssumptioproduct()
    {
        try
        {
            String indexStr = ApexPages.currentPage().getParameters().get(INDXCAT);
            string selValue=  ApexPages.currentPage().getParameters().get(SELVALCAT);            
            ProductWrapper wrp = prdWrapper[Integer.valueof(indexStr)];
            String prdId= wrp.volAsmpOlg.APTS_Value__c;            
            // Query information from the agreement
            Id agreementId = ApexPages.currentPage().getParameters().get(ID);
            List<Apttus__APTS_Agreement__c> infoAgreement = [SELECT Id, APTS_Agreement_Duration_Months__c 
                                                            FROM Apttus__APTS_Agreement__c
                                                            WHERE Id =: agreementId];
            
            // Query information from agreement Line Items
            list<Apttus__AgreementLineItem__c> lstArgLnItm = [select Id,Apttus_CMConfig__ClassificationId__c,
                                                                APTS_Product_Category__c, APTS_Product_SubCategory__c, APTS_Product_SubSubCategory__c,
                                                                Apttus_CMConfig__BaseExtendedPrice__c,
                                                                Apttus__NetPrice__c, 
                                                                APTS_Expected_Category_Discount_Amount__c, Apttus__Quantity__c,
                                                                Apttus_CMConfig__PriceListItemId__c,
                                                                APTS_Discount__c
                                                            from Apttus__AgreementLineItem__c 
                                                            where Apttus__agreementId__c =:agreementId and Apttus__ProductId__c =:prdId];
            
            if (isStandard)
            {
                decimal durationContract = infoAgreement[0].APTS_Agreement_Duration_Months__c;
                
                if (!lstArgLnItm.isEmpty())
                {            
                    // Information from PLI
                    List<Apttus_Config2__PriceListItem__c> PLI = [Select APTS_ListPriceDigital_inclAllTaxes_exVAT__c,
                                                                    Apttus_Config2__Cost__c FROM Apttus_Config2__PriceListItem__c
                                                                    WHERE Id =: lstArgLnItm[0].Apttus_CMConfig__PriceListItemId__c];                    
                    decimal listPrice = 0.0;
                    decimal costPrice = 0.0;
                    if (!PLI.isEmpty())
                    {   
                        // List price and cost price are in pieces                    
                        listPrice =  PLI[0].APTS_ListPriceDigital_inclAllTaxes_exVAT__c;
                        costPrice =  PLI[0].Apttus_Config2__Cost__c;
                    }                    
                    // Call the engine for assumption
                    APTS_VolumeCalculationEngine.VolumeAssumptionRequest request = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
                    request.category =  lstArgLnItm[0].APTS_Product_Category__c;                  
                    request.subcategory =  lstArgLnItm[0].APTS_Product_SubCategory__c;
                    if (lstArgLnItm[0].APTS_Product_SubSubCategory__c == '')
                    {
                        request.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;
                        request.subSubCategory = NONE;
                    }
                    else
                    {
                        request.subSubCategory = lstArgLnItm[0].APTS_Product_SubSubCategory__c;
                        request.familyLevel = APTS_VolumeCalculationEngine.SUBSUBCATEGORY_LEVEL;   
                    }                
                    request.productId = prdId;
                    request.agreementId = agreementId;
                    request.unitfromUOM = wrp.volAsmpOlg.APTS_NumberofDrinks__c;
                    request.fromUOM = 'SAP_DRKS';
                    request.toUOM = wrp.volAsmpOlg.APTS_Unit_of_Measure__c; 
                    request.familyLevel = 4;

                    wrp.volAsmpOlg.APTS_VolumeAssumption__c = APTS_VolumeCalculationEngine.getAssumption (request);
                    if (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c!= null)
                    {
                        wrp.volAsmpOlg.APTS_Volume_Obligation__c=  (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c * wrp.volAsmpOlg.APTS_VolumeAssumption__c)/100;
                        APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
                        rebateRequest.agreementId = agreementId;
                        rebateRequest.volAssumption = wrp.volAsmpOlg.APTS_VolumeAssumption__c;
                        rebateRequest.category = lstArgLnItm[0].Apttus_CMConfig__ClassificationId__c;
                        rebateRequest.grossSale = wrp.volAsmpOlg.APTS_GrossSale__c;
                        rebateRequest.netSale = wrp.volAsmpOlg.APTS_NetSale__c;

                        wrp.volAsmpOlg.APTS_Rebate_Payout__c = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
                    }

                    // Call the engine to convert pieces to the toUOM for listPrice and costPrice
                    APTS_VolumeCalculationEngine.VolumeAssumptionRequest requestPieces = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
                    requestPieces.category =  lstArgLnItm[0].APTS_Product_Category__c;                  
                    requestPieces.subcategory =  lstArgLnItm[0].APTS_Product_SubCategory__c;
                    if (lstArgLnItm[0].APTS_Product_SubSubCategory__c == '')
                    {
                        requestPieces.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;
                        requestPieces.subSubCategory = NONE;
                    }
                    else
                    {
                        requestPieces.subSubCategory = lstArgLnItm[0].APTS_Product_SubSubCategory__c;
                        requestPieces.familyLevel = APTS_VolumeCalculationEngine.SUBSUBCATEGORY_LEVEL;   
                    }                
                    requestPieces.productId = prdId;
                    requestPieces.agreementId = agreementId;                    
                    requestPieces.fromUOM = 'SAP_PCE';
                    requestPieces.toUOM = wrp.volAsmpOlg.APTS_Unit_of_Measure__c; 
                    requestPieces.familyLevel = 4;

                    requestPieces.unitfromUOM = listPrice;
                    decimal ListPriceConverted = APTS_VolumeCalculationEngine.getAssumption(requestPieces);
                    requestPieces.unitfromUOM = costPrice;
                    decimal costPriceConverted = APTS_VolumeCalculationEngine.getAssumption(requestPieces);
                    
                    // Calculate gross sale and net sales from the agreement line item 
                    wrp.volAsmpOlg.APTS_GrossSale__c = ListPriceConverted*wrp.volasmpOlg.APTS_VolumeAssumption__c;
                    
                    decimal discount = 0.0;
                    If (lstArgLnItm[0].APTS_Discount__c != null)
                    {
                        discount = lstArgLnItm[0].APTS_Discount__c;
                    }
                    
                    wrp.volAsmpOlg.APTS_NetSale__c = wrp.volAsmpOlg.APTS_GrossSale__c*(1-discount/100);
                    
                    // Calculate Total Expected Discount Amount 
                    wrp.volAsmpOlg.APTS_Total_Expected_Discount_Amount__c = 
                        ((wrp.volAsmpOlg.APTS_GrossSale__c - wrp.volAsmpOlg.APTS_NetSale__c)/12)*durationContract;
                    wrp.volasmpOlg.APTS_Total_Expected_Cost_Amount__c = ((costPriceConverted*wrp.volasmpOlg.APTS_VolumeAssumption__c)/12)*durationContract;
                    
                    // Calculate Price per KG, Liter and Drink
                    requestPieces.unitfromUOM = listPrice;
                    requestPieces.toUOM = 'SAP_KGM';
                    wrp.volAsmpOlg.APTS_Price_per_KG__c = APTS_VolumeCalculationEngine.getAssumption(requestPieces);
                    requestPieces.toUOM = 'SAP_LTR';
                    wrp.volAsmpOlg.APTS_Price_per_Liter__c = APTS_VolumeCalculationEngine.getAssumption(requestPieces);
                    requestPieces.toUOM = 'SAP_DRKS';
                    wrp.volAsmpOlg.APTS_Price_per_Drink__c = APTS_VolumeCalculationEngine.getAssumption(requestPieces);
                    // Calculate cost per KG, Liter and Drink
                    requestPieces.unitfromUOM = costPrice;
                    requestPieces.toUOM = 'SAP_KGM';
                    wrp.volAsmpOlg.APTS_Cost_per_KG__c = APTS_VolumeCalculationEngine.getAssumption(requestPieces);
                    requestPieces.toUOM = 'SAP_LTR';
                    wrp.volAsmpOlg.APTS_Cost_per_Liter__c = APTS_VolumeCalculationEngine.getAssumption(requestPieces);
                    requestPieces.toUOM = 'SAP_DRKS';
                    wrp.volAsmpOlg.APTS_Cost_per_Drink__c = APTS_VolumeCalculationEngine.getAssumption(requestPieces);

                }
            }
            else
            {
                // Consumption model
                if (!lstArgLnItm.isEmpty())
                {         
                    // Call the engine for assumption
                    APTS_VolumeCalculationEngine.VolumeAssumptionRequest request = new APTS_VolumeCalculationEngine.VolumeAssumptionRequest();
                    request.category =  lstArgLnItm[0].APTS_Product_Category__c;                  
                    request.subcategory =  lstArgLnItm[0].APTS_Product_SubCategory__c;
                    if (lstArgLnItm[0].APTS_Product_SubSubCategory__c == '')
                    {
                        request.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;
                        request.subSubCategory = NONE;
                    }
                    else
                    {
                        request.subSubCategory = lstArgLnItm[0].APTS_Product_SubSubCategory__c;
                        request.familyLevel = APTS_VolumeCalculationEngine.SUBSUBCATEGORY_LEVEL;   
                    }                
                    request.productId = prdId;
                    request.agreementId = agreementId;
                    request.unitfromUOM = wrp.volAsmpOlg.APTS_NumberofDrinks__c;
                    request.fromUOM = 'SAP_DRKS';
                    request.toUOM = wrp.volAsmpOlg.APTS_Unit_of_Measure__c; 
                    request.familyLevel = 4;

                    wrp.volAsmpOlg.APTS_VolumeAssumption__c = APTS_VolumeCalculationEngine.getAssumption (request);
                    
                    // Query gross sale and net sales from the agreement line item
                    wrp.volAsmpOlg.APTS_GrossSale__c = lstArgLnItm[0].Apttus_CMConfig__BaseExtendedPrice__c;
                    wrp.volAsmpOlg.APTS_NetSale__c = lstArgLnItm[0].Apttus__NetPrice__c;

                    APTS_VolumeCalculationEngine.VolumeRebateRequest rebateRequest = new APTS_VolumeCalculationEngine.VolumeRebateRequest();
                    rebateRequest.agreementId = agreementId;
                    rebateRequest.volAssumption = wrp.volAsmpOlg.APTS_VolumeAssumption__c;
                    rebateRequest.category = lstArgLnItm[0].Apttus_CMConfig__ClassificationId__c;
                    rebateRequest.grossSale = wrp.volAsmpOlg.APTS_GrossSale__c;
                    rebateRequest.netSale = wrp.volAsmpOlg.APTS_NetSale__c;

                    wrp.volAsmpOlg.APTS_Rebate_Payout__c = APTS_VolumeCalculationEngine.getRebate(rebateRequest);
                }
            }
        }
        Catch(Exception e)
        {
            system.debug(e.getMessage()+ e.getLineNumber());
            //APTS_BIRUtils.logError(null,null,null,e,APEX,'getVolumeAssumptioproduct() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
        }
    }
    
    public void getDrinksProduct()
    {
        String indexStr = ApexPages.currentPage().getParameters().get(INDXCAT);
        string selValue=  ApexPages.currentPage().getParameters().get(SELVALCAT);
        ProductWrapper wrp = prdWrapper[Integer.valueof(indexStr)];
        String prdId= wrp.volAsmpOlg.APTS_Value__c;
        Id agreementId = ApexPages.currentPage().getParameters().get(ID);
        
        list<Apttus__AgreementLineItem__c> lstArgLnItm = [select Id,Apttus_CMConfig__ClassificationId__c,
                                                            APTS_Product_Category__c, APTS_Product_SubCategory__c,
                                                            APTS_Product_SubSubCategory__c,
                                                            Apttus_CMConfig__BaseExtendedPrice__c,
                                                            Apttus__NetPrice__c
                                                          from Apttus__AgreementLineItem__c 
                                                          where Apttus__agreementId__c =:agreementId and Apttus__ProductId__c =:prdId];
        

        if (!lstArgLnItm.isEmpty())
        {
            if (wrp.volAsmpOlg.APTS_VolumeAssumption__c==null)
            {
                wrp.volAsmpOlg.APTS_VolumeAssumption__c = 0.0;
            }
            if (wrp.volAsmpOlg.APTS_Unit_of_Measure__c!=null)
            {
                //Reverse calculation: From Volume Assumption to Drinks
                APTS_VolumeCalculationEngine.DrinksRequest reverseRequest = new APTS_VolumeCalculationEngine.DrinksRequest();
                reverseRequest.category =  lstArgLnItm[0].APTS_Product_Category__c;                  
                reverseRequest.subcategory =  lstArgLnItm[0].APTS_Product_SubCategory__c;
                if (lstArgLnItm[0].APTS_Product_SubSubCategory__c == '')
                {
                    reverseRequest.familyLevel = APTS_VolumeCalculationEngine.SUBCATEGORY_LEVEL;
                    reverseRequest.subSubCategory = NONE;
                }
                else
                {
                    reverseRequest.subSubCategory = lstArgLnItm[0].APTS_Product_SubSubCategory__c;
                    reverseRequest.familyLevel = APTS_VolumeCalculationEngine.SUBSUBCATEGORY_LEVEL;   
                }
                reverseRequest.productId = prdId;
                reverseRequest.agreementId = agreementId;
                reverseRequest.volumeAssumption = wrp.volAsmpOlg.APTS_VolumeAssumption__c;
                reverseRequest.originalUOM = wrp.volAsmpOlg.APTS_Unit_of_Measure__c;
                reverseRequest.category = lstArgLnItm[0].Apttus_CMConfig__ClassificationId__c;
                wrp.volAsmpOlg.APTS_NumberofDrinks__c = APTS_VolumeCalculationEngine.getDrinks(reverseRequest);
                wrp.volAsmpOlg.APTS_Volume_Obligation__c=  (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c * wrp.volAsmpOlg.APTS_VolumeAssumption__c)/100;
            }
        }
    }
     //DQ-2134 - Contract Output Purpose - Populate Category_Hierarchy_Text in VO

 public List<APTS_AgreementTotalVolumeObligation__c> updateCategoryValuesForProduct( list<APTS_AgreementTotalVolumeObligation__c> listVolAsmpObg)
    {
    Set<Id> setprdids = new Set<Id>();
    Map<Id,Apttus_Config2__ProductClassification__c> mapPC = new Map<Id,Apttus_Config2__ProductClassification__c>();
    List<APTS_AgreementTotalVolumeObligation__c> upsertAgreementTotalVolumeObligation = new List<APTS_AgreementTotalVolumeObligation__c>();
        for(APTS_AgreementTotalVolumeObligation__c instprdid : listVolAsmpObg)       
        {
        setprdids.add(instprdid.APTS_Value__c);
        } 
        list<Apttus_Config2__ProductClassification__c> lstClassification = [Select id,Apttus_Config2__ProductId__c,Apttus_Config2__ClassificationId__r.name,Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.name from Apttus_Config2__ProductClassification__c where Apttus_Config2__ProductId__c IN :setprdids];
         for(Apttus_Config2__ProductClassification__c instPC : lstClassification)
        {
            mapPC.put(instPC.Apttus_Config2__ProductId__c,instPC);
        }   
         
        for(APTS_AgreementTotalVolumeObligation__c volAsmpOlg : listVolAsmpObg) 
        {
         if(volAsmpOlg.APTS_Type__c == TYPE_PRODUCT )
         {
         volAsmpOlg.APTS_CategoryName__c = mapPC.get(volAsmpOlg.APTS_Value__c).Apttus_Config2__ClassificationId__r.Apttus_Config2__HierarchyId__r.Name;
         volAsmpOlg.APTS_SubCategoryName__c = mapPC.get(volAsmpOlg.APTS_Value__c).Apttus_Config2__ClassificationId__r.Name;
         }
         upsertAgreementTotalVolumeObligation.add(volAsmpOlg);           
        }
        return upsertAgreementTotalVolumeObligation;
    }
        
    
    //DQ-2134 end
    public void doSelectProduct()
    {
        try
        {
            String productId = ApexPages.currentPage().getParameters().get(system.label.APTS_firstParam);
            String indexStr = ApexPages.currentPage().getParameters().get(system.label.APTS_secondParam);
            Integer index = Integer.valueOf(indexStr);
            //if(!prdWrapper.isEmpty() && index < prdWrapper.size()) {
                ProductWrapper wrp = prdWrapper[index];
                wrp.volAsmpOlg.APTS_Value__c = productId;
            //}
        }
        catch(Exception e)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,system.label.APTS_Error+e);
            ApexPages.addMessage(myMsg);
        }
    } 
    public void getcatObligation()
    {
        try
        {
            String indexStr = ApexPages.currentPage().getParameters().get(INDEX);
            string selValue=  ApexPages.currentPage().getParameters().get(PERCENT);
            categoryWrapper wrp = categorywrap[Integer.valueof(indexStr)];
            wrp.volAsmpOlg.APTS_Volume_Obligation__c=  (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c * wrp.volAsmpOlg.APTS_VolumeAssumption__c)/100;
        }
        catch(Exception e)
        {
            system.debug(e.getMessage()+ e.getLineNumber());
        }
    } 

    public void getSubObligation()
    {
        try
        {
            String indexStr = ApexPages.currentPage().getParameters().get(INDEX);
            string selValue=  ApexPages.currentPage().getParameters().get(PERCENT);
            subcategoryWrapper wrp = subcatWrapper[Integer.valueof(indexStr)];
            if (wrp.volAsmpOlg.APTS_VolumeAssumption__c == null)
            {
                wrp.volAsmpOlg.APTS_Volume_Obligation__c = 0.0;    
            }
            wrp.volAsmpOlg.APTS_Volume_Obligation__c=  (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c * wrp.volAsmpOlg.APTS_VolumeAssumption__c)/100;
        }
        catch(Exception e)
        {
            system.debug(e.getMessage()+ e.getLineNumber());
        }
    }

    public void getSubsubObligation()
    {
        try
        {
            String indexStr = ApexPages.currentPage().getParameters().get(INDEX);
            string selValue=  ApexPages.currentPage().getParameters().get(PERCENT);
            SubSubCategoryWrapper wrp = subsubwrap[Integer.valueof(indexStr)];
            if (wrp.volAsmpOlg.APTS_VolumeAssumption__c == null)
            {
                wrp.volAsmpOlg.APTS_Volume_Obligation__c = 0.0;    
            }
            wrp.volAsmpOlg.APTS_Volume_Obligation__c=  (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c * wrp.volAsmpOlg.APTS_VolumeAssumption__c)/100;
        }
        catch(Exception e)
        {
            system.debug(e.getMessage()+ e.getLineNumber());
        }
    }

    public void getprdObligation()
    {
        try
        {
            String indexStr = ApexPages.currentPage().getParameters().get(INDEX);
            string selValue=  ApexPages.currentPage().getParameters().get(PERCENT);
            ProductWrapper wrp = prdWrapper[Integer.valueof(indexStr)];
            if (wrp.volAsmpOlg.APTS_VolumeAssumption__c == null)
            {
                wrp.volAsmpOlg.APTS_Volume_Obligation__c = 0.0;    
            }
            wrp.volAsmpOlg.APTS_Volume_Obligation__c=  (wrp.volAsmpOlg.APTS_VolumeObligationPercentage__c * wrp.volAsmpOlg.APTS_VolumeAssumption__c)/100;
        }
        catch(Exception e)
        {
            system.debug(e.getMessage()+ e.getLineNumber());
        }
    } 
 
    public PageReference saveasmpObj()
    {
        try{
            if(saveVolAsmpObligation())
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Obligations correctly created.');
                ApexPages.addMessage(myMsg);
            }
            else
            {
                ApexPages.Message myMsg;
                for (String strError : errorList)
                {
                    myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,' ' + strError); 
                    ApexPages.addMessage(myMsg);
                }
            }
             
            return null;
        }
        catch(Exception e)
        {
            system.debug(e.getMessage()+ e.getLineNumber());
            APTS_BIRUtils.logError(null,null,null,e,APEX,'saveasmpObj() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
            return null;
        }
    }

    public PageReference saveClose()
    {
        try{
            if(saveVolAsmpObligation())
            {
             
                string strUrl = system.label.APTS_Slash+ApexPages.currentPage().getParameters().get(system.label.APTS_retId_page_reference);
                
                if(strUrl.startsWith('/')){
                    strUrl=strUrl.replaceFirst('/','');
                }
                PageReference pageRef 
                    = new PageReference('/' + strUrl);
                return pageRef;
                
            }
            else
            {
                ApexPages.Message myMsg;
                for (String strError : errorList)
                {
                    myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,strError); 
                    ApexPages.addMessage(myMsg);
                }
                return null;
            }
        }
        catch(Exception e)
        {
            system.debug(e.getMessage()+ e.getLineNumber());
            APTS_BIRUtils.logError(null,null,null,e,APEX,'saveasmpObj() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
            return null;
        }
    }

    //Rebate Payout change End
    public boolean saveVolAsmpObligation(){
        agreementId = ApexPages.currentPage().getParameters().get(ID);
        
        // Query the language of the agreement

        Apttus__APTS_Agreement__c agree =[SELECT id,RecordType.name,APTS_Language__c FROM Apttus__APTS_Agreement__c WHERE id =:agreementId];
        agreementLanguage = agree.APTS_Language__c;
        // Clean list of errors
        errorList = new List<String>();
       
        boolean upsertSuccess = true;
        String strError;
        /*try
        {*/
            string agreementId = ApexPages.currentPage().getParameters().get(ID);
            list<APTS_AgreementTotalVolumeObligation__c> listVolAsmpObg = new list<APTS_AgreementTotalVolumeObligation__c>(); 
            List<APTS_AgreementTotalVolumeObligation__c> upsertAgreementTotalVolumeObligation = new List<APTS_AgreementTotalVolumeObligation__c>();             
            if (!subcatWrapper.isEmpty()){
                for(SubCategoryWrapper subwrp : subcatWrapper){
                    // Setting of agreement
                    if(subwrp.volAsmpOlg.APTS_Agreement__c == null){
                        subwrp.volAsmpOlg.APTS_Agreement__c = agreementId;
                    }

                    // Modification done to support templates
                    subwrp.volAsmpOlg.APTS_Product_Name__c = getLanguageMessageAnyCategory(agreementLanguage);                                                                
                    // Action validation
                    if (agreementPreferredWayIngredientDelivery == NULL || agreementPreferredWayIngredientDelivery == ''){
                        strError = 'There is no preferred way of ingredient delivery in the agreement. It will affect the calculation of gross sales and net sales for non product volume assumptions.';
                        errorList.add(strError);
                        upsertSuccess = false;
                    }
                    else if (subwrp.volAsmpOlg.APTS_Categoryvalue__c == NONE){
                        strError = 'You must select a Category to save the sub category volume assumption';
                        errorList.add(strError);
                        upsertSuccess = false;
                    }
                    else if (subwrp.volAsmpOlg.APTS_VolumeObligationPercentage__c != null && subwrp.volAsmpOlg.APTS_Action__c == null){
                        strError = 'If there is percentage defined, an action must be set for the obligation';
                        errorList.add(strError);
                        upsertSuccess = false;
                    }
                    else if (subwrp.volAsmpOlg.APTS_NumberofDrinks__c == null || subwrp.volAsmpOlg.APTS_VolumeAssumption__c == null){
                        strError = 'It is not possible to save a Volume Assumption without setting number of drinks and defining assumption.';
                        errorList.add(strError);
                        upsertSuccess = false;
                    }
                    else if (subwrp.volAsmpOlg.APTS_SubCategoryValue__c == NONE){
                        strError = 'When creating a Volume Assumption at Sub Category level you must populate the Sub Category field';
                        errorList.add(strError);
                        upsertSuccess = false;   
                    }
                    else if (subwrp.volAsmpOlg.APTS_VolumeObligationPercentage__c < 0 || subwrp.volAsmpOlg.APTS_VolumeObligationPercentage__c > 100){
                        strError = 'The volume percentage defined is outside of the right range (0-100)';
                        errorList.add(strError);
                        upsertSuccess = false;   
                    }
                    else if (subwrp.volAsmpOlg.APTS_VolumeAssumption__c == 0 ){
                        strError = 'It is not possible to save the record without volume assumption';
                        errorList.add(strError);
                        upsertSuccess = false;   
                    }
                    else if (subwrp.volAsmpOlg.APTS_Action__c == 'Invoice Customer' && subwrp.volAsmpOlg.APTS_Malus_per_Unit__c == NULL){
                        strError = 'If the action is Invoice Customer, the Malus per Unit must be set';
                        errorList.add(strError);
                        upsertSuccess = false;   
                    }
                    else
                    {
                        subwrp.volAsmpOlg.APTS_Type__c = TYPE_SUBCATEGORY;                     
                        subwrp.volAsmpOlg.APTS_Value__c = subwrp.volAsmpOlg.APTS_SubCategoryValue__c;                        
                        subwrp.volAsmpOlg.APTS_Value_Name__c = mapCatSubCat.get(subwrp.volAsmpOlg.APTS_Categoryvalue__c).get(subwrp.volAsmpOlg.APTS_SubCategoryValue__c);     
                        subwrp.volAsmpOlg.APTS_SubCategoryName__c = subwrp.volAsmpOlg.APTS_Value_Name__c;
                        subwrp.volAsmpOlg.APTS_CategoryName__c = mapCategory.get(subwrp.volAsmpOlg.APTS_Categoryvalue__c);     
                        listVolAsmpObg.add(subwrp.volAsmpOlg);
                    }
                }
            }
            if(!subsubwrap.isEmpty()){
                for(SubSubCategoryWrapper subsubwrp : subsubwrap){
                    // Setting of agreement
                    if(subsubwrp.volAsmpOlg.APTS_Agreement__c == null){
                        subsubwrp.volAsmpOlg.APTS_Agreement__c = agreementId;
                    }                    
                                        
                    // Before insertion the different validations are executed
                    // Error validation for categories
                    if (agreementPreferredWayIngredientDelivery == NULL || agreementPreferredWayIngredientDelivery == ''){
                        strError = 'There is no preferred way of ingredient delivery in the agreement. It will affect the calculation of gross sales and net sales for non product volume assumptions.';
                        errorList.add(strError);
                        upsertSuccess = false;
                    }
                    else if (subsubwrp.volAsmpOlg.APTS_Categoryvalue__c == null || subsubwrp.volAsmpOlg.APTS_Categoryvalue__c == NONE){
                        strError = ' You must select a category to save the sub sub volume assumption';
                        errorList.add(strError);
                        upsertSuccess = false;
                    }                    
                    else if (subsubwrp.volasmpOlg.APTS_Unit_of_Measure__c == null || subsubwrp.volasmpOlg.APTS_Unit_of_Measure__c == NONE){
                        strError = ' The Unit of Measure is not correctly set for any of the sub sub category volume assumption and obligations.';
                        errorList.add(strError);
                        upsertSuccess = false;   
                    }
                    else if (subsubwrp.volAsmpOlg.APTS_VolumeObligationPercentage__c != null && subsubwrp.volAsmpOlg.APTS_Action__c == null){
                        strError = 'If there is percentage defined, an action must be set for the obligation';
                        System.debug(strError);
                        errorList.add(strError);
                        upsertSuccess = false;
                    }
                    else if (subsubwrp.volAsmpOlg.APTS_NumberofDrinks__c == null || subsubwrp.volAsmpOlg.APTS_VolumeAssumption__c == null){
                        strError = 'It is not possible to save a Volume Assumption without setting number of drinks and defining assumption.';
                        errorList.add(strError);
                        upsertSuccess = false;
                    }
                    else if (subsubwrp.volAsmpOlg.APTS_VolumeObligationPercentage__c < 0 || subsubwrp.volAsmpOlg.APTS_VolumeObligationPercentage__c > 100){
                        strError = 'The volume percentage defined is outside of the right range (0-100)';
                        errorList.add(strError);
                        upsertSuccess = false;   
                    }
                    else if (subsubwrp.volAsmpOlg.APTS_VolumeAssumption__c == 0 ){
                        strError = 'It is not possible to save the record without volume assumption';
                        errorList.add(strError);
                        upsertSuccess = false;   
                    }
                    else if (subsubwrp.volAsmpOlg.APTS_Action__c == 'Invoice Customer' && subsubwrp.volAsmpOlg.APTS_Malus_per_Unit__c == NULL){
                        strError = 'If the action is Invoice Customer, the Malus per Unit must be set';
                        errorList.add(strError);
                        upsertSuccess = false;   
                    }                    
                    else{
                        // Setting of subcategory
                        if (subsubwrp.volAsmpOlg.APTS_Value__c == null || subsubwrp.volAsmpOlg.APTS_Value__c == NONE){
                            subsubwrp.volAsmpOlg.APTS_Type__c = TYPE_SUBCATEGORY;                     
                            subsubwrp.volAsmpOlg.APTS_Value__c = subsubwrp.volAsmpOlg.APTS_SubCategoryValue__c;                        
                            subsubwrp.volAsmpOlg.APTS_Value_Name__c = mapCatSubCat.get(subsubwrp.volAsmpOlg.APTS_Categoryvalue__c).get(subsubwrp.volAsmpOlg.APTS_SubCategoryValue__c);     
                            subsubwrp.volAsmpOlg.APTS_SubCategoryName__c = subsubwrp.volAsmpOlg.APTS_Value_Name__c;
                            subsubwrp.volAsmpOlg.APTS_CategoryName__c = mapCategory.get(subsubwrp.volAsmpOlg.APTS_Categoryvalue__c);     
                        }
                        else{
                            subsubwrp.volAsmpOlg.APTS_Type__c = TYPE_SUBSUBCATEGORY;       
                            subsubwrp.volAsmpOlg.APTS_Value_Name__c = mapSubCatSubSubCat.get(subsubwrp.volAsmpOlg.APTS_SubCategoryValue__c).get(subsubwrp.volAsmpOlg.APTS_Value__c);
                            subsubwrp.volAsmpOlg.APTS_SubCategoryName__c = mapCatSubCat.get(subsubwrp.volAsmpOlg.APTS_Categoryvalue__c).get(subsubwrp.volAsmpOlg.APTS_SubCategoryValue__c);  
                            subsubwrp.volAsmpOlg.APTS_CategoryName__c = mapCategory.get(subsubwrp.volAsmpOlg.APTS_Categoryvalue__c);                    
                        }
                        // Modification done to support templates
                        subsubwrp.volAsmpOlg.APTS_Product_Name__c = getLanguageMessageAnyCategory(agreementLanguage);
                        listVolAsmpObg.add(subsubwrp.volAsmpOlg);
                    }
                }
            }
            if(!prdWrapper.isEmpty()){
                for(ProductWrapper prdWrp : prdWrapper){
                    prdWrp.volAsmpOlg.APTS_Type__c = TYPE_PRODUCT;    
                    prdWrp.volAsmpOlg.APTS_Value_Name__c = validProducts.get(prdWrp.volAsmpOlg.APTS_Value__c);
                    // Addition done to facilitate template creation
                    prdWrp.volAsmpOlg.APTS_Product_Name__c = prdWrp.volAsmpOlg.APTS_Value_Name__c;       
                    if(prdWrp.volAsmpOlg.APTS_Agreement__c == null){
                        prdWrp.volAsmpOlg.APTS_Agreement__c = agreementId;
                    }
                    // Validations       
                    if (prdWrp.volAsmpOlg.APTS_VolumeObligationPercentage__c != null && prdWrp.volAsmpOlg.APTS_Action__c == null){
                        strError = 'If there is percentage defined, an action must be set for the obligation';
                        errorList.add(strError);
                        upsertSuccess = false;
                    }
                    else if (prdWrp.volAsmpOlg.APTS_VolumeObligationPercentage__c < 0 || prdWrp.volAsmpOlg.APTS_VolumeObligationPercentage__c > 100){
                        strError = 'The volume percentage defined is outside of the right range (0-100)';
                        errorList.add(strError);
                        upsertSuccess = false;   
                    }
                    else if (prdWrp.volAsmpOlg.APTS_NumberofDrinks__c == null || prdWrp.volAsmpOlg.APTS_VolumeAssumption__c == null){
                        strError = 'It is not possible to save a Volume Assumption without estimating number of drinks';
                        errorList.add(strError);
                        upsertSuccess = false;
                    }
                    else if (prdWrp.volAsmpOlg.APTS_Value__c == null){
                        strError = 'It is not possible to save a Volume Assumption if there is no product selected';
                        errorList.add(strError);
                        upsertSuccess = false;
                    }
                    else if (prdWrp.volAsmpOlg.APTS_VolumeAssumption__c == 0 ){
                        strError = 'It is not possible to save the record without volume assumption';
                        errorList.add(strError);
                        upsertSuccess = false;   
                    }
                    else if (prdWrp.volAsmpOlg.APTS_Action__c == 'Invoice Customer' && prdWrp.volAsmpOlg.APTS_Malus_per_Unit__c == NULL){
                        strError = 'If the action is Invoice Customer, the Malus per Unit must be set';
                        errorList.add(strError);
                        upsertSuccess = false;   
                    }
                    else{
                        listVolAsmpObg.add(prdWrp.volAsmpOlg);
                    }
                }
            }
           upsertAgreementTotalVolumeObligation= updateCategoryValuesForProduct(listVolAsmpObg);  
            if(!upsertAgreementTotalVolumeObligation.isEmpty()){
                upsert upsertAgreementTotalVolumeObligation;
               upsertAgreementTotalVolumeObligation.clear();
            }
            return upsertSuccess;
        /*}
        catch(Exception e)
        {
            APTS_BIRUtils.logError(null,null,null,e,APEX,'saveVolAsmpObligation() Method',EMPTY_STRING,false,false,EMPTY_STRING,true);
            return upsertSuccess = false;
        }*/
    }

    public String getLanguageMessageAnyCategory(String agreementLanguage)
    {
        String strResult = '';
        if (agreementLanguage == 'SAP_NL'){
            strResult = 'Elk product in deze categorie'; 
        }
        else if (agreementLanguage == 'SAP_EN'){
            strResult = 'Any product in this category'; 
        }
        else if (agreementLanguage == 'SAP_ES'){
            strResult = 'Cualquier producto de esta categoría';    
        }
        else if (agreementLanguage == 'SAP_DE'){
            strResult = 'Jedes Produkt in dieser Kategorie';       
        }
        else if (agreementLanguage == 'SAP_SV'){
            strResult = 'Alla produkter i denna kategori';       
        }
        else if (agreementLanguage == 'SAP_NO'){
            strResult = 'Ethvert produkt i denne kategorien';       
        }
        else if (agreementLanguage == 'SAP_DK'){
            strResult = 'Ethvert produkt i denne kategori';       
        }        
        else if (agreementLanguage == 'SAP_FR'){
            strResult = 'Tout produit dans cette catégorie';       
        }
        return strResult;
    }

    public PageReference cancelSave()
    {
        string strUrl = system.label.APTS_Slash+ApexPages.currentPage().getParameters().get(system.label.APTS_retId_page_reference);
        if(strUrl.startsWith('/'))
        {
            strUrl=strUrl.replaceFirst('/','');
        }
        PageReference pageRef = new PageReference('/' + strUrl);
        return pageRef;
    }

    public class categoryWrapper{
        public integer index{get;set;}
        public list<SelectOption> category{get;set;}
        public APTS_AgreementTotalVolumeObligation__c volAsmpOlg{get;set;}
        public categoryWrapper(integer index,list<SelectOption> category,APTS_AgreementTotalVolumeObligation__c volAsmpOlg){
            this.index = index;
            this.category = category;
            this.volAsmpOlg = volAsmpOlg;        
        }        

    }
    public class subcategoryWrapper{
        public integer index{get;set;}
        public list<SelectOption> category{get;set;}
        public list<SelectOption> subCategory{get;set;}
        public APTS_AgreementTotalVolumeObligation__c volAsmpOlg{get;set;}
        public Boolean existing{get;set;}
        public Boolean disable{get;set;}
        public subcategoryWrapper(integer index,list<SelectOption> category,
                                list<SelectOption> subCategory,APTS_AgreementTotalVolumeObligation__c volAsmpOlg,
                                Boolean existing,Boolean disable){
            this.index = index;
            this.category = category;
            this.subCategory =subCategory;
            this.volAsmpOlg = volAsmpOlg;
            this.existing = existing; 
            this.disable = disable;       
        }        

    }
    public class SubSubCategoryWrapper{
    
        public integer index{get;set;}
        public list<SelectOption> category{get;set;}
        public list<SelectOption> subCategory{get;set;}
        public list<SelectOption> subSubCategory{get;set;}
        public APTS_AgreementTotalVolumeObligation__c volAsmpOlg{get;set;}
        public Boolean existing{get;set;}
        public Boolean disable{get;set;}
        public SubSubCategoryWrapper(integer index,list<SelectOption> category, 
            list<SelectOption> subCategory,list<SelectOption> subSubCategory,
            APTS_AgreementTotalVolumeObligation__c volAsmpOlg, Boolean existing, Boolean disable)
        {
            this.index = index;
            this.category =category;
            this.subCategory = subCategory;
            this.subSubCategory = subSubCategory;
            this.volAsmpOlg = volAsmpOlg;
            this.existing = existing;       
            this.disable = disable; 
        }
    }
    public class ProductWrapper{
        public integer index{get;set;}
        public list<SelectOption> validProducts{get;set;}
        public APTS_AgreementTotalVolumeObligation__c volAsmpOlg{get;set;}
        public Boolean existing{get;set;}
        public Boolean disable{get;set;}
        public ProductWrapper(integer index,List<SelectOption> validProducts, 
                                APTS_AgreementTotalVolumeObligation__c volAsmpOlg,Boolean existing, Boolean disable){
            this.index = index;
            this.volAsmpOlg = volAsmpOlg;        
            this.validProducts = validProducts;
            this.existing = existing;        
            this.disable = disable;
        }        

    }

    @RemoteAction
    public static list<product2> populateProductByName(String value)
    {
        productList=new List<product2>();
        if(String.isNotBlank(value)){
            value= '%'+value+'%';
            productList = [Select Id,name,APTS_Category__c,toLabel(APTS_Product_Family2__c) from product2 where name LIKE: value];
        }
        return productList;
    }
    
    //v1.4 starts here
    public List<selectOption> getUOMs() {
        List<selectOption> options = new List<selectOption>(); //new list for holding all of the picklist options
        options.add(new selectOption('', '- None -')); //add the first option of '- None -' in case the user doesn't want to select a value or in case no values are returned from query below
        options.add(new selectOption('SAP_KGM', 'Kilogram')); //for all records found - add them to the picklist options
        options.add(new selectOption('SAP_LTR', 'Liter'));
        options.add(new selectOption('SAP_DRKS', 'Drinks'));
        return options; //return the picklist options
    
    }
    
    public List<selectOption> getProductUOMs() {
    
        List<selectOption> options = new List<selectOption>(); //new list for holding all of the picklist options
        options.add(new selectOption('', '- None -'));
        options.add(new selectOption('SAP_KGM', 'Kilogram'));
        options.add(new selectOption('SAP_LTR', 'Liter'));
        options.add(new selectOption('SAP_DRKS', 'Drinks'));
        if(isStandardDealProduct)
        {
            options.add(new selectOption('SAP_PCE', 'Piece'));
            options.add(new selectOption('SAP_BX', 'Box'));
        }
        return options; //return the picklist options
    }
    //v1.4 ends here
}