/*************************************************************
@Name: APTS_ResetApprovalController
@Author: Sneha Jaiwant
@CreateDate: 25-9-2020
@Description: Reset the Approval frm the order header
@UsedBy: Reset Approval button on Order page
******************************************************************/
public with sharing class APTS_ResetApprovalController {

private static final String NOTSUBMITTED= 'Not Submitted';


public Id passingId {get;set;}
public APTS_ResetApprovalController(){
passingId = ApexPages.currentPage().getParameters().get('id');
}

public PageReference redirectURL(){
List<Apttus_Approval__Approval_Request__c> caList= new List<Apttus_Approval__Approval_Request__c>();
caList =[select id,Apttus_Approval__Approval_Status__c, APTS_Related_Order__c,Apttus_Approval__ParentRequestId__r.Apttus_Approval__Approval_Status__c, APTS_Related_Order__r.Approval_Status__c,APTS_Related_Order__r.APTS_Lock_Order__c  from Apttus_Approval__Approval_Request__c where Apttus_Approval__Approval_Status__c=:NOTSUBMITTED AND APTS_Related_Order__c =:passingId ];
try{
 Apttus_Config2__Order__c order=new Apttus_Config2__Order__c();
for(Apttus_Approval__Approval_Request__c appReqList:caList ){
if (appReqList.APTS_Related_Order__r.APTS_Lock_Order__c && appReqList.APTS_Related_Order__r.Approval_Status__c=='Approval Pending' ){


 order.id= appReqList.APTS_Related_Order__c;
 order.APTS_Lock_Order__c =False;
 order.Approval_Status__c=NOTSUBMITTED;

}
}
 database.update(order,false);
}
catch(Exception e){
    }
PageReference page = new PageReference('/'+passingId);
return page;


}

}