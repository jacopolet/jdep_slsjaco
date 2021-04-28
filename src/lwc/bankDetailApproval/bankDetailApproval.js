import { LightningElement, api, track} from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import userId from '@salesforce/user/Id';
import PENDING_BANKACCOUNT from '@salesforce/schema/Bank_Details__c.Approval_Bank_Account__c';
import PENDING_BANKCOUNTRY from '@salesforce/schema/Bank_Details__c.Approval_Bank_Country__c';
import PENDING_BANKKEY from '@salesforce/schema/Bank_Details__c.Approval_Bank_Key__c';
import PENDING_COLLECTIONAUTH from '@salesforce/schema/Bank_Details__c.Approval_Collection_Authorization__c';
import PENDING_CONTROLKEY from '@salesforce/schema/Bank_Details__c.Approval_Control_Key__c';
import PENDING_IBAN from '@salesforce/schema/Bank_Details__c.Approval_IBAN__c';

import fetchFinanceControllerBnk from '@salesforce/apex/RequestApproval.fetchFinanceControllerBnk';
import submitApproval from '@salesforce/apex/ApprovalProcessService.submitApproval';

export default class BankDetailApproval extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api isLoaded = false;
    @track currentUserId = userId;

    fields = [PENDING_BANKKEY, PENDING_BANKACCOUNT, PENDING_BANKCOUNTRY, PENDING_COLLECTIONAUTH, PENDING_CONTROLKEY, PENDING_IBAN];

    formatDate(date) {
        var d = new Date(date),
        month = '' + (d.getMonth() + 1),
        day = '' + d.getDate(),
        year = d.getFullYear();
    
        if (month.length < 2) 
            month = '0' + month;
        if (day.length < 2) 
            day = '0' + day;
    
        return [year, month, day].join('-');
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isLoaded = !this.isLoaded;
        fetchFinanceControllerBnk({recordId : this.recordId})
        .then(result => {
            if (result){
            window.console.log(JSON.stringify(result));
            const fields = event.detail.fields;
            // modify a field
            fields.Finance_Controller_BD_Validation__c = result[0]; 
            fields.Finance_Controller_BD_Validation_2__c = result[1];
            fields.Approval_Submitter__c = this.currentUserId;
            fields.Sent_for_Approval_Date__c = this.formatDate(Date.now());
            fields.Updated_Request_Validation__c = 'Approval Pending';
            fields.Approval_Required__c = true;
            this.template.querySelector('lightning-record-form').submit(fields);
            } 
        })
        .catch(error => {
            this.isLoaded = false;
            window.console.log(JSON.stringify(error));
        });
    }

    handleSubmitApproval(){
        submitApproval({recordId : this.recordId})
        .then(approvalResult => {
            if (approvalResult){
                this.isLoaded = false;
                eval("$A.get('e.force:refreshView').fire();");
            }
        }) 
        .catch(error => {
            this.isLoaded = false;
            window.console.log(JSON.stringify(error));
        });
    }

    handleError() { 
        this.isLoaded = false;
    }
}