public with sharing class APTS_Displayplis{
    
    public String PDFData {get; set;} 
    
    Public APTS_Displayplis(){
        PDFData = '';
    }
    
    public PageReference downloadPDF(){
        System.PageReference pageRef = new System.PageReference('/apex/APTS_ListPricePDF');
    
        //ensure pdf downloads and is assigned with defined name
        pageRef.getHeaders().put('content-disposition', 'attachment; filename=TestPDF.pdf');
     
        return pageRef;
    }
    
    @AuraEnabled
    public static List<Apttus_Config2__PriceListItem__c> getplis() {

        // Perform isAccessible() checks here 
        return [SELECT Id, Name,Apttus_Config2__ProductCode__c,APTS_Default_Selling_Uom__c,
        Apttus_Config2__ProductId__c,Apttus_Config2__PriceUom__c,APTS_Tax_per_UOM__c,APTS_VAT_percentage__c,
        Apttus_Config2__Description__c,Apttus_Config2__ListPrice__c FROM Apttus_Config2__PriceListItem__c];
    }
    
    Public class createuoms{
    
    }
}