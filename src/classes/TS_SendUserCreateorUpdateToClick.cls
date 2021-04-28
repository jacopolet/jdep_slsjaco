/**
* @author        Paul Aguiling
* @date          7.16.2018
* @description   Class used to send the user creation and deactivation callout to Click this must be 
*				 limited to 100 records as the batch class has been executed with 100 records per batch.
* @revision(s)
*/
public with sharing class TS_SendUserCreateorUpdateToClick {

    public Boolean hasException = false;
    public class TS_SendUserCreateorUpdateToClickException extends Exception {}
	
    /**
    * @author         Paul Jarred Aguiling
    * @date           7.16.2018
    * @description    Method responsible for executing the user creation or update
    * @revision(s)
    */ 
	public void executeUserCreateOrUpdate(List<Integration_Log__c> currentILogList) {
        CustomLogging.push('executeUserCreateOrUpdate', 'TS_SendUserCreateorUpdateToClick');
        
        try{
            
            //Collect list of logs from IntegrationLogTriggerHandler
            List<Integration_Log__c> updatedIlogList = [Select Id, Integration_Status__c, Work_Order_Line_Item__c ,
            												   Object__c, Object_Id__c
                                                        From Integration_Log__c Where Id IN: currentILogList];

            //Collect list of resource records based for object__Id__c of integ logs from IntegrationLogTriggerHandler                                  
            Set<Id> resourceIds = new Set<Id>();
            Map<Id,Integration_Log__c> iLogMap = new Map<Id,Integration_Log__c>();
            for (Integration_Log__c ilog : updatedIlogList) {
                resourceIds.add(ilog.Object_Id__c);      
                iLogMap.put(ilog.Object_Id__c, ilog);      
            }

            //Get all resource records to be sent to click 
            //updateded the SOQL to get Country Code. By Ritesh Kumar
            List<Resource__c> resourceList = [SELECT Id, ActiveUser__c, UserProfile__c, EmployeeLastName__c, EmployeeFirstName__c, 
                                                     EmployeeMiddleName__c, EmailAddress__c, Name, CompanyCode__c,
                                                     Click__c, Country__c, countrycode__c, Username__c, Enable_SSO__c, Sales_Organization__c
                                                    FROM  Resource__c
                                                    WHERE Id IN :resourceIds];
            
            List<JDEServicesCallout.UserCreate_element> elem = new List<JDEServicesCallout.UserCreate_element>();
            List<Integration_Log__c> updatableIlogList = new List<Integration_Log__c>();

            //Karen Hung 12.07.2019 DOO-262 mapping to get the template name per country
           /* TS_MobileProfileTemplate__c mpt = TS_MobileProfileTemplate__c.getInstance();
            Schema.DescribeSObjectResult templateObj = TS_MobileProfileTemplate__c.sObjectType.getDescribe();
            Set<String> apiNames =  templateObj.fields.getMap().keySet();*/

            ////Karen Hung DOO-4228 10.03.2020 get mapping of mobile profile templates from custom setting
            TS_SendUserCreateorUpdateToClick.MobileProfile mp = new TS_SendUserCreateorUpdateToClick.MobileProfile();
            Map<String, String> orgProfileTemplateMap = mp.getMobileTemplateName();

            //Map UserCreate_element to be sent to click
            for (Resource__c resourceRec : resourceList) {
                JDEServicesCallout.UserCreate_element userType = new JDEServicesCallout.UserCreate_element();
                //String email = resourceRec.EmailAddress__c != null? resourceRec.EmailAddress__c : '';
                String email = resourceRec.Username__c != null? resourceRec.Username__c : ''; //XEN REYES Nov. 27, 2018
                String middleName = resourceRec.EmployeeMiddleName__c != null? ' ' + resourceRec.EmployeeMiddleName__c + ' ' : ' ';
                if(email != ''){//checker Added by Karen Hung 12/13/2018
                    userType.UserID = email.substring(0, email.indexOf('@'));
                }
                userType.ToDelete = resourceRec.ActiveUser__c? false : true;
                userType.UserFullName = resourceRec.EmployeeFirstName__c + middleName + resourceRec.EmployeeLastName__c;    
                //Karen Hung DOO-272  convert email to lower case
                if(resourceRec.EmailAddress__c != null ){
                    String emailStr = String.valueOf(resourceRec.EmailAddress__c);
                    userType.UserEmail = emailStr.toLowerCase();
                    userType.ExternalUserName = emailStr.toLowerCase(); //Karen Hung DOO-262 10.07.2019
                }       

                userType.IsSSO_SO = resourceRec.Enable_SSO__c; //Karen Hung DOO-272 25.06.2019 

                //Karen Hung DOO-262 12.07.2019, DOO-4228 10.03.2020 added user profile in getting template value from custom setting
                //String orgToApi = resourceRec.Sales_Organization__c +'__c';
                /*String userProfile = (resourceRec.UserProfile__c != null ? resourceRec.UserProfile__c : '').replace(' ','_');
                String orgProfileToApi = resourceRec.Sales_Organization__c + userProfile + '__c';
                if(resourceRec.Sales_Organization__c != null && apiNames.contains(orgProfileToApi.toLowerCase())){
                   userType.MobileProfile = (String)mpt.get(orgProfileToApi);
                }*/
                //Karen Hung DOO-4228 10.03.2020 added user profile in getting template value from custom setting
                String orgProfile = resourceRec.Sales_Organization__c + (resourceRec.UserProfile__c != null ? resourceRec.UserProfile__c : 'Default');
                if(orgProfileTemplateMap.containsKey(orgProfile)){
                    userType.MobileProfile = orgProfileTemplateMap.get(orgProfile);
                }
         
                userType.Profile = resourceRec.UserProfile__c;
                //userType.Country = resourceRec.Country__c;
                userType.Country = resourceRec.countrycode__c;//Change the filed API name Country__c to countrycode__c By Ritesh Kumar
                userType.UserHRID = resourceRec.Name;
                //userType.UserPhone = resourceRec.;         
                elem.add(userType);           
                updatableIlogList.add(iLogMap.get(resourceRec.Id) );
            }

            //Invoke ExecuteQueueableCallOut to start the callout to click
            if (!elem.isEmpty()) {
                ExecuteQueueableCallOut eqc = new ExecuteQueueableCallOut();
                eqc.iLogList = updatableIlogList;
                eqc.userElem = elem;            
                System.enqueueJob(eqc);   
            }

            //Exception for test class purposes
            if (Test.isRunningTest() && hasException) {
                throw new TS_SendUserCreateorUpdateToClickException('Force to throw an exception');
            }

        } catch (Exception e){
            System.debug(e);
            CustomLogging.debugException(e);
            CustomLogging.pop();
        }
    
        CustomLogging.pop();       
    }

    //Karen Hung 10.03.2020 DOO-4228 Profile mobile profile based on country setting
    public without sharing class MobileProfile {
        public Map<String, String> getMobileTemplateName(){
            CustomLogging.push('getMobileTemplateName', 'TS_SendUserCreateorUpdateToClick');

            Map<String, String> comboTemplateMap = new Map<String, String>();
            try{

                //get all mobile profile templates and put in the map
                List<CountrySetting__c> cSetList = [SELECT Id, User_Profile__c, Country__c, Mobile_Profile_Template__c FROM CountrySetting__c WHERE Recordtype.Name = :TS_Constants.TS_COUNTRYSETTING_RECORDTYPE_MOBILEPROFILETEMPLATE];
                if(!cSetList.isEmpty()){
                    for(CountrySetting__c cset : cSetList){
                        comboTemplateMap.put(cset.Country__c + cset.User_Profile__c, cset.Mobile_Profile_Template__c);       
                    }
                }
                
            }catch(Exception e){
                System.debug(e);
                CustomLogging.debugException(e);
                CustomLogging.pop();
            }
            CustomLogging.pop();
            return comboTemplateMap;
        }
    }
}