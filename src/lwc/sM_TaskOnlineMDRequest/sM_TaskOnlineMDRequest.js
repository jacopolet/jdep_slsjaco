import { LightningElement, api, wire, track } from 'lwc';
import { getSObjectValue } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getTaskRecord from '@salesforce/apex/SM_TaskOnlineMDReqController.getTaskRecord';
import getRelatedWhatId from '@salesforce/apex/SM_TaskOnlineMDReqController.getRelatedWhatId';
import requestedOperation from '@salesforce/apex/SM_TaskOnlineMDReqController.requestedOperation';

//import task fields
import TASK_OBJECT from '@salesforce/schema/Task';
import RECORDTYPE_ID from '@salesforce/schema/Task.RecordTypeId';
import TOUCHPOINT_TYPE from '@salesforce/schema/Task.Touchpoint_Type__c';
import REQ_OPERATION from '@salesforce/schema/Task.Requested_Operation__c';
import REQ_ACC_NAME from '@salesforce/schema/Task.Requested_Account_Name__c';
import REQ_SECOND_NAME from '@salesforce/schema/Task.Requested_Second_Name__c';
import REQ_THIRD_NAME from '@salesforce/schema/Task.Requested_Third_Name__c';
import REQ_FOURTH_NAME from '@salesforce/schema/Task.Requested_Fourth_Name__c';
import REQ_MAIN_STREET_ONLY from '@salesforce/schema/Task.Requested_Main_Street_Only__c';
import REQ_MAIN_HOUSE_NO from '@salesforce/schema/Task.Requested_Main_House_Number__c';
import REQ_MAIN_HOUSE_NO_SUPP from '@salesforce/schema/Task.Requested_Main_House_Number_Supplement__c';
import REQ_MAIN_POSTAL_CODE from '@salesforce/schema/Task.Requested_Main_Postal_Code__c';
import REQ_MAIN_STATE from '@salesforce/schema/Task.Requested_Main_State__c';
import REQ_MAIN_CITY from '@salesforce/schema/Task.Requested_Main_City__c';
import REQ_MAIN_COUNTRY from '@salesforce/schema/Task.Requested_Main_Country__c';
import REQ_MAIN_COUNTRY_ISO from '@salesforce/schema/Task.Requested_Main_Country_ISO__c';
import REQ_MAIN_POSTAL_BOX from '@salesforce/schema/Task.Requested_Main_Postal_Box__c';
import REQ_MAIN_POSTAL_BOX_CITY from '@salesforce/schema/Task.Requested_Main_Postal_Box_City__c';
import REQ_COMMERCIAL_REG_NO from '@salesforce/schema/Task.Requested_Commercial_Register_Number__c';
import REQ_VAT_NO from '@salesforce/schema/Task.Requested_VAT_Number__c';
import REQ_ADD_VALIDATION_STAMP from '@salesforce/schema/Task.Requested_AddressValidationTimestamp__c';
import REQ_ACC_LOC_NAME from '@salesforce/schema/Task.Requested_Account_Location_Name__c';
import REQ_SHIP_STREET from '@salesforce/schema/Task.Requested_Shipping_Street__c';
import REQ_SHIP_HOUSE_NO from '@salesforce/schema/Task.Requested_Shipping_House_number__c';
import REQ_SHIP_HOUSE_NO_SUPP from '@salesforce/schema/Task.Requested_Shipping_House_No_Supplement__c';
import REQ_SHIP_POSTAL_CODE from '@salesforce/schema/Task.Requested_Shipping_Postal_Code__c';
import REQ_SHIP_CITY from '@salesforce/schema/Task.Requested_Shipping_City__c';
import REQ_SHIP_STATE from '@salesforce/schema/Task.Requested_State__c';
import REQ_SHIP_COUNTRY from '@salesforce/schema/Task.Requested_Shipping_Country__c';
import REQ_COUNTRYISO from '@salesforce/schema/Task.Requested_CountryISO__c';
import COMMENTS from '@salesforce/schema/Task.Description';

import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ACCLOC_OBJECT from '@salesforce/schema/Apttus_Config2__AccountLocation__c';


export default class SM_TaskOnlineMDRequest extends LightningElement {
    @api recordId;
    @track relatedAccId;
    @track relatedAccLocId;
    @track relatedObjId;

    taskObject = TASK_OBJECT;
    accountObject = ACCOUNT_OBJECT;
    acclocObject = ACCLOC_OBJECT;

    @track selectedOperation;

    @wire(requestedOperation, {taskId: '$recordId'})
    reqoperationvalue({error,data}){
        if(data){
            this.selectedOperation = data;
        }
    }

    @wire(getTaskRecord, {taskId: '$recordId'})
    taskrecord;

    @wire(getRelatedWhatId, {taskId: '$recordId'})
    relatedId({error,data}){
        if(data){
            this.relatedObjId = data;
            console.log('relatedId: ' + this.relatedObjId);
            if(this.relatedObjId.startsWith('001')){
                this.relatedAccId = this.relatedObjId;
                if(this.selectedOperation == "Update Account Location"){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'There is no related Account Location to this task.',
                            variant: 'error',
                        }),
                    );
                }
            }else if(this.relatedObjId.startsWith('a2R')){
                this.relatedAccLocId = this.relatedObjId;
                if(this.selectedOperation == "Update Account"){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'There is no related Account to this task.',
                            variant: 'error',
                        }),
                    );
                }
            }
        }
    }
    
    get relatedWhatId(){
        return this.relatedObjId;
    }

    get updateAccount(){
        if(this.selectedOperation == 'Update Account'){
            if(this.relatedAccId != null){
                return this.selectedOperation == "Update Account";
            } 
        }
    }
    get createAccountLocation(){
        return this.selectedOperation == "Create Account Location";
    }
    get updateAccountLocation(){
        if(this.selectedOperation == 'Update Account Location'){
            if(this.relatedAccLocId != null){
                return this.selectedOperation == "Update Account Location";
            }
        }
    }

    //get task fields
    get reqAccountName() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_ACC_NAME) : '';
    }
    get touchpointType() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, TOUCHPOINT_TYPE) : '';
    }
    get reqOperation() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_OPERATION) : '';
    }
    get recordtypeId() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, RECORDTYPE_ID) : '';
    }
    get reqSecondName() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_SECOND_NAME) : '';
    }
    get reqThirdName() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_THIRD_NAME) : '';
    }
    get reqFourthName() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_FOURTH_NAME) : '';
    }
    get reqMainStreetOnly() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_MAIN_STREET_ONLY) : '';
    }
    get reqMainHouseNo() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_MAIN_HOUSE_NO) : '';
    }
    get reqMainHouseNoSupp() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_MAIN_HOUSE_NO_SUPP) : '';
    }
    get reqMainPostalCode() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_MAIN_POSTAL_BOX) : '';
    }
    get reqMainState() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_MAIN_STATE) : '';
    }
    get reqMainCity() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_MAIN_CITY) : '';
    }
    get reqMainCountry() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_MAIN_COUNTRY) : '';
    }
    get reqMainCountryISO() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_MAIN_COUNTRY_ISO) : '';
    }
    get reqMainPostalBox() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_MAIN_POSTAL_BOX) : '';
    }
    get reqMainPostalBoxCity() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_MAIN_POSTAL_BOX_CITY) : '';
    }
    get reqCommercialRegNo() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_COMMERCIAL_REG_NO) : '';
    }
    get reqVATNo() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_VAT_NO) : '';
    }
    get reqAddValidationStamp() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_ADD_VALIDATION_STAMP) : '';
    }
    get reqAccLocName() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_ACC_LOC_NAME) : '';
    }
    get reqShipStreet() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_SHIP_STREET) : '';
    }
    get reqShipHouseNo() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_SHIP_HOUSE_NO) : '';
    }
    get reqShipHouseNoSupp() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_SHIP_HOUSE_NO_SUPP) : '';
    }
    get reqShipPostalCode() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_SHIP_POSTAL_CODE) : '';
    }
    get reqShipCity() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_SHIP_CITY) : '';
    }
    get reqShipState() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_SHIP_STATE) : '';
    }
    get reqShipCountry() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_SHIP_COUNTRY) : '';
    }
    get reqCountryISO() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, REQ_COUNTRYISO) : '';
    }
    get comments() {
        return this.taskrecord.data ? getSObjectValue(this.taskrecord.data, COMMENTS) : '';
    }
    

}