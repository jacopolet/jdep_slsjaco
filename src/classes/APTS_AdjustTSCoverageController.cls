/**
* Class Name: APTS_AdjustTSCoverageController
* @author: Lavanya 
* Date: 27/2/2018
* @description As part of Product Model CRP FD, to save Coverage % fields for System Admin 
*/

public with sharing class APTS_AdjustTSCoverageController{
    
    public Id agreementID {get;set;}
    public List<Apttus_Config2__ProductAttributeValue__c> listPAVA = new List<Apttus_Config2__ProductAttributeValue__c>();
    public List<Apttus_Config2__ProductAttributeValue__c> listPAVB = new List<Apttus_Config2__ProductAttributeValue__c>();
    public List<Apttus_CMConfig__AgreementProductAttributeValue__c> agrLineItemPAVUpdateList = new List<Apttus_CMConfig__AgreementProductAttributeValue__c>();
    public List<Apttus__AgreementLineItem__c> lstAgreementLineItem{get;set;}
    public Apttus__APTS_Agreement__c AgreementItem;
    public List<Apttus_CMConfig__AgreementProductAttributeValue__c> lstagreementAttributeValues{get;set;}
    public Decimal allspare{get;set;}
    public Decimal alllabour{get;set;}
    public Decimal allcall{get;set;}
    public Decimal bspare{get;set;}
    public Decimal blabour{get;set;}
    public Decimal bcall{get;set;}
    public Boolean all{get;set;}
    public Boolean basic{get;set;}
    
    public APTS_AdjustTSCoverageController()
    {
    // Modified by Saranya Rajagopal Date: 14th sep 2018
        agreementId = ApexPages.currentPage().getParameters().get(APTS_CPQConstants.LABEL_ID);
        
        all=false;
        basic=false;
        //From agreement get Agreement Line Items 
        //From Agreement LIne Item , get Line Items,  their attribute values and update them 
        //Update product Attribute , Agreement Attribute
        
        lstAgreementLineItem = new  List<Apttus__AgreementLineItem__c>([Select id,Apttus__AgreementId__c,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__OptionId__r.Name,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c,Apttus_CMConfig__AttributeValueId__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: agreementId]); 
        
        AgreementItem = [Select Id, Name, APTS_TS_Coverage_Applied__c from Apttus__APTS_Agreement__c where Id = :agreementId];
       
        for(Apttus__AgreementLineItem__c instALI : [Select id,Apttus__AgreementId__c,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__OptionId__r.Name,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c,Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c,Apttus_CMConfig__AttributeValueId__c from Apttus__AgreementLineItem__c where Apttus__AgreementId__c =: agreementId])
        {
            
            
       if(instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__OptionId__r.Name!= NULL) {     
              
            if(instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__OptionId__r.Name.containsIgnoreCase(System.Label.APTS_All_in_Coverage_Draft))
            {
                all = true;
                allspare = instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c;
                alllabour = instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c;
                allcall = instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c;
                
            }
            else if(instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__OptionId__r.Name.containsIgnoreCase(System.Label.APTS_Basic_Coverage_Draft))
            {
                basic = true;
                bspare = instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Spare_Parts_Coverage_Percent__c;
                blabour = instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Labour_Coverage_Percent__c;
                bcall = instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r.APTS_Call_Out_Coverage_Percent__c;  
                
            }
            }
            
        }
        if(!all && !basic){
             //add error message if no Technical Service Config is present
            
       // Modified by Saranya Rajagopal Date: 14th sep 2018
          ApexPages.Message myMsg1 = new ApexPages.Message(ApexPages.Severity.INFO,APTS_CPQConstants.LABEL_AGREEMENTMESSAGE);
          ApexPages.addMessage(myMsg1); 
         
        
            
         
        }
    }
    /*
    Aftab: Agreement indicator added
    */
    public PageReference save()
    {
     /* PI fix # 190202 
     if(String.valueOf(agreementId).contains('/')){
     agreementId = String.valueOf(agreementId).replaceFirst('/','');
      } */

        PageReference pg = new PageReference('/'+agreementId);
       
        
        for(Apttus__AgreementLineItem__c instALI : lstAgreementLineItem)
        { //check for all in option product attribute and basic attribute 
            
              Apttus_Config2__ProductAttributeValue__c pavb = new Apttus_Config2__ProductAttributeValue__c();  
               Apttus_Config2__ProductAttributeValue__c pava = new Apttus_Config2__ProductAttributeValue__c();   
            if(instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__OptionId__r.Name!= NULL && instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__OptionId__r.Name==System.Label.APTS_Basic_Coverage_Draft)
            { 
                // pav.APTS_Spare_Parts_Coverage_Percent__c= bspare;
              //  Apttus_Config2__ProductAttributeValue__c pav = new Apttus_Config2__ProductAttributeValue__c();
                pavb = instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r;
                pavb.APTS_Labour_Coverage_Percent__c=blabour;
                pavb.APTS_Call_Out_Coverage_Percent__c=bcall;
                listPAVB.add(pavb);    
                
                if(instALI.Apttus_CMConfig__AttributeValueId__c!=null){   
                    Apttus_CMConfig__AgreementProductAttributeValue__c pavAgreementLI = new Apttus_CMConfig__AgreementProductAttributeValue__c(id = instALI.Apttus_CMConfig__AttributeValueId__c);
                    pavAgreementLI.APTS_Labour_Coverage_Percent__c=blabour;
                    pavAgreementLI.APTS_Call_Out_Coverage_Percent__c=bcall;
                    agrLineItemPAVUpdateList.add(pavAgreementLI);
                }
             
            }
            if(instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__OptionId__r.Name!= NULL && instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__OptionId__r.Name==System.Label.APTS_All_in_Coverage_Draft)
            { 
                Apttus_Config2__ProductAttributeValue__c pav = new Apttus_Config2__ProductAttributeValue__c();
                pava = instALI.Apttus_CMConfig__DerivedFromId__r.Apttus_Config2__AttributeValueId__r;
                pava.APTS_Spare_Parts_Coverage_Percent__c=allspare;
                pava.APTS_Labour_Coverage_Percent__c=alllabour;
                pava.APTS_Call_Out_Coverage_Percent__c=allcall;
                listPAVA.add(pava);
                
                if(instALI.Apttus_CMConfig__AttributeValueId__c!=null){
                    Apttus_CMConfig__AgreementProductAttributeValue__c pavAgreementLI = new Apttus_CMConfig__AgreementProductAttributeValue__c(id = instALI.Apttus_CMConfig__AttributeValueId__c);
                    pavAgreementLI.APTS_Spare_Parts_Coverage_Percent__c=allspare;
                    pavAgreementLI.APTS_Labour_Coverage_Percent__c=alllabour;
                    pavAgreementLI.APTS_Call_Out_Coverage_Percent__c=allcall;
                    agrLineItemPAVUpdateList.add(pavAgreementLI);
                }
                
            }         
        } 
        try
        {
        if(listPAVA!=NULL & listPAVA.size()>0){
            update listPAVA;
        }if(listPAVB!=NULL & listPAVB.size()>0){
            update listPAVB;
        }if(!agrLineItemPAVUpdateList.isEmpty()){
            update agrLineItemPAVUpdateList;
            AgreementItem.APTS_TS_Coverage_Applied__c = TRUE;
            update AgreementItem;
        }
        }
        catch(Exception e)
        {       
// Modified by Saranya Rajagopal Date: 14th sep 2018        
        APTS_CustomLogging.createErrorLog(e.getTypeName(),APTS_CPQConstants.APEX_NAME, e.getStackTraceString() ,APTS_CPQConstants.LABEL_ADJUSTSCOERAGECONTROLLER, ApexPages.currentPage().getParameters().get(APTS_CPQConstants.BSN_OBJ_ID),APTS_CPQConstants.CPQ,false,true,APTS_CPQConstants.CPQ_ERROR_EMAIL,true);
        }
        
        return pg;
    }
    
}