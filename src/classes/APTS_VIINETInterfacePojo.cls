/*******************************************************************************************
Name            : APTS_VIINETInterfacePojo 
Created By      : Amit
Created Date    : 02/22/2018
Description     : Pojo calss will be used to generate JSON resonse for VIANET
Test Class      : APTS_MachineDataRestResourceTest 
				  Pojo classv- Add Few more comment - For GIT Merge Test
********************************************************************************************/

global class APTS_VIINETInterfacePojo {
	/* BEGIN : Property declaration */
    global string SerialNumber{get;set;}
    global string Manufacturer{get;set;}
    global string MachineModel{get;set;}
    global string OrganisationName{get;set;}
    global string TelemetrySerial{get;set;}
    global string PlanogramID{get;set;}
    global string Status{get;set;}
    global string SiteName{get;set;} 
    global string OnsiteLocation{get;set;}
    global string SiteReference{get;set;}
    global string SiteType{get;set;}
    global string Channel{get;set;}
    global string City{get;set;}
    global string PostCode{get;set;}
    global string Country{get;set;}
    global string CompanyCode{get;set;}
    global string customErrorMessage{get;set;}
    //global string DatetimeResponse{get;set;}
    //global string ResponseSize{get;set;}
    /* END : Property Declaration */

    

}