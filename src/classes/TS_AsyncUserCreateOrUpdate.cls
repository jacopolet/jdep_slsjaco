/**
* @author        Paul Aguiling
* @date          7.04.2018           
* @description   Class responsible to asynchronously update resource record due to issue
*				 of Apex does not allow DML operations of a non-setup sObject and a setup sObject 
*				 in a single Apex transaction. (User is the setup sobject)
* @revision(s)   
*/
public without sharing class TS_AsyncUserCreateOrUpdate implements Queueable { 
	public Set<Id> resourceList = new Set<Id>();
	public Map<String, Id> map_profile = new Map<String, Id>();
	public List<User> userToUpdate = new List<User>();
	public List<Integration_Log__c> integLogList = new List<Integration_Log__c>();

	//Map of company code to country name
	private static Map<String, String> countryName_map {
	    get {
	        if (countryName_map == null) {
	            countryName_map = new Map<String, String>{
	                    '0202' => 'Belgium', 
	                    '6864' => 'Norway',
	                    '0067' => 'Denmark',
	                    '0160' => 'Sweden',
	                    '6706' => 'France',
	                    '0079' => 'Netherlands',
	                    '0154' => 'Spain',
	                    '6709' => 'Ireland',
	                    '6712' => 'Germany',
	                    '6750' => 'United Kingdom'
	                    };
	        }

	        return countryName_map;
	    }
	    set;
	}

	//Map of country name to country locale
	private static Map<String, String> countryLocale_map {
	    get {
	        if (countryLocale_map == null) {
	            countryLocale_map = new Map<String, String>{
	                    'Belgium' => 'nl_BE', 
	                    'Norway' => 'no_NO',
	                    'Denmark' => 'da_DK',
	                    'Sweden' => 'sv_SE',
	                    'France' => 'fr_FR',
	                    'Netherlands' => 'nl_NL',
	                    'Spain' => 'es_ES',
	                    'Ireland' => 'en_IE',
	                    'Germany' => 'de_DE',
	                    'United Kingdom' => 'cy_GB'
	                    };
	        }

	        return countryLocale_map;
	    }
	    set;
	}

	//Map of country name to country language
	/*private static Map<String, String> countryLanguage_map {
	    get {
	        if (countryLanguage_map == null) {
	        	//changed the belgium language to nl_BE to en_US. By Ritesh Kumar
	            countryLanguage_map = new Map<String, String>{
	                    'Belgium' => 'nl_BE', 
	                    'Norway' => 'no',
	                    'Denmark' => 'da',
	                    'Sweden' => 'sv',
	                    'France' => 'fr',
	                    'Netherlands' => 'nl_NL',
	                    'Spain' => 'es',
	                    'Ireland' => 'en_IE',
	                    'Germany' => 'de',
	                    'United Kingdom' => 'en_US'
	                    };
	        }
            
            /* SUPPORTED LANGUAGES
			https://help.salesforce.com/articleView?id=faq_getstart_what_languages_does.htm&type=5
			
	        Chinese (Simplified): zh_CN
			Chinese (Traditional): zh_TW
			Danish: da
			Dutch: nl_NL
			English: en_US
			Finnish: fi
			French: fr
			German: de
			Italian: it
			Japanese: ja
			Korean: ko
			Norwegian: no
			Portuguese (Brazil): pt_BR
			Russian: ru
			Spanish: es
			Spanish (Mexico): es_MX
			Swedish: sv
			Thai: th

			

	        return countryLanguage_map;
	    }
	    set;
	}*/

	//Map of country name to country currency
	private static Map<String, String> countryCurrency_map {
	    get {
	        if (countryCurrency_map == null) {
	            countryCurrency_map = new Map<String, String>{
	                    'Belgium' => 'EUR', 
	                    'Norway' => 'NOK',
	                    'Denmark' => 'DKK',
	                    'Sweden' => 'SEK',
	                    'France' => 'EUR',
	                    'Netherlands' => 'EUR',
	                    'Spain' => 'EUR',
	                    'Ireland' => 'EUR',
	                    'Germany' => 'EUR',
	                    'United Kingdom' => 'GBP'
	                    };
	        }

	        return countryCurrency_map;
	    }
	    set;
	}

    /**
    * @author        Paul Jarred Aguiling
    * @date          07.05.2018            
    * @description   [KTS-1933]: Method use to update resource due to issue with setup 
    *                            and non-setup object inserted/updated at the same transaction
    * @revision(s)
    */
    public void execute(QueueableContext context) {
        CustomLogging.push('execute', 'TS_AsyncUserCreateOrUpdate');
        System.debug('### resourceList ###' + resourceList);
        Map<Id, User> userMap = new Map<Id, User>();
        List<Resource__c> resourceNew = new List<Resource__c>();
        List<Resource__c> resourceNewToUpdate = new List<Resource__c>();
        List<Resource__c> resourceNoNeedUserList = new List<Resource__c>();

        //Use resourcelist of Ids to get details of the resource recprd in process
        //Added SalesOrg__c field in SOQL BY Ritesh Kumar.
        //Added Sales_Organization__c in soql by Karen Hung
        for (Resource__c rsrce : [SELECT Id, UserProfile__c, Sales_Organization__c,RequiresClickUser__c, RelatedContact__c, RelatedContact__r.AccountId, 
                                EmployeeLastName__c, EmployeeFirstName__c, EmployeeMiddleName__c, EmailAddress__c, Name, CompanyCode__c,
                                Click__c, TeamNumber__c,SalesOrg__c, Username__c, NickName__c
                         FROM  Resource__c
                         WHERE Id IN :resourceList]) {
        	//Add all resource record
        	resourceNew.add(rsrce);

    		System.debug('### CommunityNickname ### : ' + rsrce.Name);
    		System.debug('### EmailAddress__c ### : ' + rsrce.EmailAddress__c);
    		System.debug('### EmployeeFirstName__c ### : ' + rsrce.EmployeeFirstName__c);

            //Get 2nd level field for related account from resrouce contact
            String accId = rsrce.RelatedContact__c != null? rsrce.RelatedContact__r.AccountId : null;

            /* 
            //Scenario 1: If Template 3 && User Profile = Third Party Capacity and Requires Click User = TRUE then create a portal user & Click user
            if (rsrce.Click__c && Label.TS_ResourceUsrProf_ThirdParty.equals(rsrce.UserProfile__c) && rsrce.RequiresClickUser__c) {
                userMap.put(rsrce.Id, createUser(rsrce, rsrce.RelatedContact__c, map_profile.get(Label.TS_ResourceUsrProf_ThirdParty), accId));
            
            //Scenario 2: If Template 3 && User Profile = Third Party Capacity && Requires Click User = FALSE  then create a portal user & click third party record (manually)
            } else if (rsrce.Click__c && Label.TS_ResourceUsrProf_ThirdParty.equals(rsrce.UserProfile__c) && !rsrce.RequiresClickUser__c) {
                userMap.put(rsrce.Id, createUser(rsrce, rsrce.RelatedContact__c, map_profile.get(Label.TS_ResourceUsrProf_ThirdParty), accId));
            
            //Scenario 3 and 4: If Template 3 && User Profile = TS Resource or Operator or Routesales Resource 
            //&& Requires Click User = TRUE then only create click user
            } else if (rsrce.Click__c && (Label.TS_ResourceUsrProf_Operator.equals(rsrce.UserProfile__c) 
                || Label.TS_ResourceUsrProf_TSRes.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_RoutesalesRes.equals(rsrce.UserProfile__c))
                && rsrce.RequiresClickUser__c) {
                userMap.put(rsrce.Id, createUser(rsrce, rsrce.RelatedContact__c, map_profile.get(Label.TS_ResourceUsrProf_TSRes), accId));

            //Scenario 5: If Template 3 && User Profile = Planner or Supervisor or BI Analyst or Admin
            //Requires Click User = TRUE then only create click user
            } else if (rsrce.Click__c && (Label.TS_ResourceUsrProf_Planner.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_BiAnalyst.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_Admin.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_Supervisor.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_RoutesalesRes.equals(rsrce.UserProfile__c)
                )
                && rsrce.RequiresClickUser__c) {
                
                userMap.put(rsrce.Id, createUser(rsrce, rsrce.RelatedContact__c, map_profile.get(Label.TS_ResourceUsrProf_ThirdParty), accId));

            //Scenario 6:If Template 2 && Third Party Capacity then create portal user 
            //(also having access to mobile arranged via portal members using a permission set)
            //Template 2 means resource country = ES, SE and UK
            } else if (!rsrce.Click__c && Label.TS_ResourceUsrProf_ThirdParty.equals(rsrce.UserProfile__c)) {
                userMap.put(rsrce.Id, createUser(rsrce, rsrce.RelatedContact__c, map_profile.get(Label.TS_ResourceUsrProf_ThirdParty), accId));
            
            //Scenario 7: If Template 2 && TS Resource then create mobile user only
            } else if (!rsrce.Click__c && Label.TS_ResourceUsrProf_TSRes.equals(rsrce.UserProfile__c)) {
                userMap.put(rsrce.Id, createUser(rsrce, rsrce.RelatedContact__c, map_profile.get(Label.TS_ResourceUsrProf_TSRes), accId));
            }
            */

            //REDESIGNED SCENARIOS Nov. 27, 2018
            //COMBINE SCENARIO 1/2/6/7 FOR THIRD PARTY/TS RESOURCE - These profiles will always have a portal user.
            //Karen Hung Jan. 15, 2019 - If TS Resource Requires Click User = true, do not create portal user. If Requires Click User = false, create portal user only.
            if (Label.TS_ResourceUsrProf_ThirdParty.equals(rsrce.UserProfile__c)) {
                userMap.put(rsrce.Id, createUser(rsrce, rsrce.RelatedContact__c, map_profile.get(Label.TS_ResourceUsrProf_ThirdParty), accId));

           	} else if (Label.TS_ResourceUsrProf_TSRes.equals(rsrce.UserProfile__c) && !rsrce.RequiresClickUser__c) {
                userMap.put(rsrce.Id, createUser(rsrce, rsrce.RelatedContact__c, map_profile.get(Label.TS_ResourceUsrProf_TSRes), accId));

            //SCENARIO 3/4/5 - Portal user is not required for these profiles. Only Click user.
            } else if (rsrce.Click__c && (Label.TS_ResourceUsrProf_Planner.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_BiAnalyst.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_Admin.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_Supervisor.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_RoutesalesRes.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_Operator.equals(rsrce.UserProfile__c)
                || Label.TS_ResourceUsrProf_TSRes.equals(rsrce.UserProfile__c) //Jan 14, 2019 - If Requires Click User = false, create portal user only.
                )
                && rsrce.RequiresClickUser__c) {
                
                resourceNoNeedUserList.add(rsrce);
            }

        }

        try {

			//GET THE MANAGE PACKAGE ID THAT SHOULD ASSIGN TO THIS USER - Xen Reyes Oct. 2, 2019 - DOO-1811
			Map<String, Id> MANAGE_PACKAGE_RESULT = new Map<String, Id>();
			MANAGE_PACKAGE_RESULT = getManagedPackageId();

			//Assign Permission to Portal User - Xen Reyes Oct. 2, 2019 (Moved outside loop)
			Map<String, Id> permSet = new Map<String, Id>();
			permSet = getPermisstionSet();

			//Check if user has access to insert User records
            if (!userMap.isEmpty() && Schema.sObjectType.User.isCreateable()) {
				
	            insert userMap.values();
	            System.debug('### userMap @future ###' + userMap);

	            //Once 'community plus user' is created we will need to update the 
	            //resource record to indicate the related user there. 
	            List<PermissionSetAssignment> psaToInsert = new List<PermissionSetAssignment>();
				List<UserPackageLicense> USERPACKLICENSE_LIST = new List<UserPackageLicense>();
	            for (Resource__c rsrce : (List<Resource__c>) resourceNew) {
	                //if (userMap.get(rsrce.Id) != null) {
	                if (userMap.get(rsrce.Id) != null) {
	                    Resource__c resourceToUpdate = new Resource__c();
	                    resourceToUpdate.Id = rsrce.Id;
	                    resourceToUpdate.RelatedUser__c = userMap.get(rsrce.Id).Id;
	                    resourceToUpdate.TeamNumber__c = rsrce.TeamNumber__c;
	                    resourceToUpdate.UserProfile__c = rsrce.UserProfile__c;
	                    resourceNewToUpdate.add(resourceToUpdate);

	                    /* 
							if (!permSet.isEmpty() 
	                    	&& (permSet.get(Label.TS_ResourceUsrProf_ThirdParty) != null
	                    	|| permSet.get(Label.TS_ResourceUsrProf_TSRes) != null)) {
	                    */

	                    //XEN REYES 21.8.2018
	                    if (!permSet.isEmpty()){

	                    	if(permSet.containsKey(Label.TS_ResourceUsrProf_ThirdParty)){
	                    		PermissionSetAssignment psa = new PermissionSetAssignment();
	                    		psa.PermissionSetId = permSet.get(Label.TS_ResourceUsrProf_ThirdParty);

	                    		System.debug('### userMap.get(rsrce.Id).Id @future ###' + userMap.get(rsrce.Id).Id);
	                    		psa.AssigneeId = userMap.get(rsrce.Id).Id;
	                    		psaToInsert.add(psa);
	                    	}

	                    	if(permSet.containsKey(Label.TS_ResourceUsrProf_TSRes)){
	                    		PermissionSetAssignment psa2 = new PermissionSetAssignment();
	                    		psa2.PermissionSetId = permSet.get(Label.TS_ResourceUsrProf_TSRes);

	                    		System.debug('### userMap.get(rsrce.Id).Id @future ###' + userMap.get(rsrce.Id).Id);
	                    		psa2.AssigneeId = userMap.get(rsrce.Id).Id;
	                    		psaToInsert.add(psa2);
	                    	}
	                    	
	                    	/* psa.PermissionSetId = getPermisstionSet().get(Label.TS_ResourceUsrProf_ThirdParty);
	                    	System.debug('### userMap.get(rsrce.Id).Id @future ###' + userMap.get(rsrce.Id).Id);
	                    	psa.AssigneeId = userMap.get(rsrce.Id).Id; */
	                    }

						//ASSIGN APTTUS PACKAGE LICENSE - Xen Reyes Oct. 2, 2019 - DOO-1811
						if(!MANAGE_PACKAGE_RESULT.isEmpty()){
							for(String STR_VAR : MANAGE_PACKAGE_RESULT.values()){
								USERPACKLICENSE_LIST.add(new UserPackageLicense(UserId = userMap.get(rsrce.Id).Id, PackageLicenseId = STR_VAR));
							}
						}
	                }
	            }
				
				//insert userMap.values();
	            if (!psaToInsert.isEmpty()) {
	            	insert psaToInsert;
	            }

				if(!USERPACKLICENSE_LIST.isEmpty()){
					insert USERPACKLICENSE_LIST;
				}
		
	            System.debug('#### resourceNewToUpdate ### :' + resourceNewToUpdate);
	            System.debug('#### Limits.getQueueableJobs() UNDER Create ### :' + Limits.getQueueableJobs());

	            //Check if user has access to update resource records
	            /* if (!resourceNewToUpdate.isEmpty() && Schema.sObjectType.Resource__c.isUpdateable()) {
	    	    	TS_AsyncResourceUpdate resUpdate = new TS_AsyncResourceUpdate();
			    	resUpdate.resSet = resourceNewToUpdate;
			    	resUpdate.integLogList = integLogList;
			    	System.enqueueJob(resUpdate);
	            } */

	        //[KTS-1933]: Scenario used to deactivate user record in SF
	        } else if (!userToUpdate.isEmpty() && Schema.sObjectType.User.isUpdateable()){
	        	update userToUpdate;
	        }

	        //XEN REYES Nov. 26, 2018
	        //Send resources to click that do not need portal users.
	        if(!resourceNoNeedUserList.isEmpty()){
	        	for (Resource__c rsrce : (List<Resource__c>) resourceNoNeedUserList) {
	        		resourceNewToUpdate.add(rsrce);
	        	}
	        }

	        if ((!resourceNewToUpdate.isEmpty() || !resourceNoNeedUserList.isEmpty()) && Schema.sObjectType.Resource__c.isUpdateable()) {
    	    	TS_AsyncResourceUpdate resUpdate = new TS_AsyncResourceUpdate();
		    	resUpdate.resSet = resourceNewToUpdate;
		    	resUpdate.integLogList = integLogList;
		    	System.enqueueJob(resUpdate);
            }

        } catch (Exception ex) {
            /* CustomLogging.debugException(ex);
            CustomLogging.pop(); */
            System.debug('### ' + ex.getMessage() + '\n' + ex.getStackTraceString());
        }

        //CustomLogging.pop();
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          07.05.2018           
    * @description   Method used to retrieve permissionSet involved
    * @revision(s)
    */
    private Map<String, Id> getPermisstionSet() {
        CustomLogging.push('getPermisstionSet', 'TS_AsyncUserCreateOrUpdate');
        Map<String, Id> resultMap = new Map<String, Id>();

		for (PermissionSet permSet : [SELECT Id, Label, Name
										FROM PermissionSet
										WHERE Name IN ('JDE_STC_3rd_Party_Field_Service', 'JDE_STC_Basic_Permission')]) {
            //Customer portal user
            if ('JDE_STC_3rd_Party_Field_Service'.equals(permSet.Name)) {
                resultMap.put(Label.TS_ResourceUsrProf_ThirdParty, permSet.Id);
            //Mobile user
            } else if ('JDE_STC_Basic_Permission'.equals(permSet.Name)) {
                resultMap.put(Label.TS_ResourceUsrProf_TSRes, permSet.Id);
            }
		}

        Customlogging.pop();
        return resultMap;
    }

	/**
    * @author        Abram Vixen Reyes
    * @date          Oct. 2, 2019    
    * @description   Method used to retrieve manage package id
    * @revision(s)
    */
    private Map<String, Id> getManagedPackageId() {
        CustomLogging.push('getManagedPackageId', 'TS_AsyncUserCreateOrUpdate');
        Map<String, Id> resultMap = new Map<String, Id>();

		//List<String> PACKAGE_LICENSE_SET = new List<String>{'Apttus_Config2', 'Apttus_OrderMgt'};
		List<String> PACKAGE_LICENSE_SET = System.label.TS_ManagePackageToAssign.split(',');
		for (PackageLicense PACK_SET_VAR : [SELECT Id, NamespacePrefix FROM PackageLicense 
											WHERE NamespacePrefix IN: PACKAGE_LICENSE_SET]) {

            resultMap.put(PACK_SET_VAR.NamespacePrefix, PACK_SET_VAR.Id);
		}

        Customlogging.pop();
        return resultMap;
    }

    /**
    * @author        Paul Jarred Aguiling
    * @date          07.05.2018           
    * @description   [KTS-1931]: Method used to create user record
    * @revision(s)
    */
    private static User createUser(Resource__c res, String conId, Id profId, String accId) {
        CustomLogging.push('createUser', 'TS_AsyncUserCreateOrUpdate');
        //Locale = Dynamic on basis of company code (mapping to be build in trigger)
        //Time Zone = Dynamic on basis of company code (mapping to be build in trigger)
        //Language = English
        //Currency = Dynamic on basis of company code (mapping to be build in trigger)
        //Generate new password and notify user immediately = TRUE
        //Assign permissions “JDE - STC 3rd Party Field Service” and “JDE - STC Basic Permission” if profile is “
        User usr = new user(); 
        //usr.Username = res.EmailAddress__c; 
        //usr.Username = res.EmailAddress__c+'.workorder';//Added postfix ".workorder" By Ritesh Kumar
        usr.Username = res.Username__c; //XEN REYES
        usr.LastName = res.EmployeeLastName__c;
        usr.FirstName = res.EmployeeFirstName__c;
        usr.MiddleName = res.EmployeeMiddleName__c;
        usr.Email = res.EmailAddress__c;
        //usr.CommunityNickname = res.Name;
        usr.CommunityNickname = res.NickName__c; //XEN REYES Dec. 10, 2018
        usr.ProfileId = profId; 
        usr.IsActive = true;
        //usr.FederationIdentifier = res.EmailAddress__c;
        usr.Company_Code__c = 'SAP_' + res.CompanyCode__c;
        //usr.Sales_Organization__c = 'SAP_' + res.CompanyCode__c;
        usr.Sales_Organization__c = res.Sales_Organization__c;
        usr.EmailEncodingKey = 'UTF-8';

        //Get dynamic value for locale, language, currency, and timezone based on company code
        String countryName = countryName_map.get(res.CompanyCode__c);
        if (countryName != null) {
	        usr.LocaleSidKey = countryLocale_map.get(countryName);
	        //usr.LanguageLocaleKey = countryLanguage_map.get(countryName);
	        usr.CurrencyIsoCode = countryCurrency_map.get(countryName);
	        //usr.LocaleSidKey = 'en_US';
	        usr.LanguageLocaleKey = 'en_US';
	        //usr.CurrencyIsoCode = 'EUR';
    	}

        usr.TimeZoneSidKey = 'GMT'; //Default for now is GMT
         usr.Alias = res.EmployeeFirstName__c.left(8); //update the alias up to 8 charcters of the first name  By Ritesh Kumar 24.08.2018
        usr.ContactId = conId;

        //Send notification email when user is created
    	Database.DMLOptions dlo = new Database.DMLOptions();
		dlo.EmailHeader.triggerUserEmail = true;
		usr.setOptions(dlo);
        CustomLogging.pop();

        //return Site.createExternalUser(usr, accId, null, true);
        //return Site.createPortalUser(usr, accId, null, true);
        return usr;
    }
}