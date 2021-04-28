import { LightningElement, api, wire, track} from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

//get the account fields
import PENDING_PAYMENTTERM from '@salesforce/schema/Account.Approval_Pending_Payment_Term__c';
import PENDING_PAYMENT_METHOD from '@salesforce/schema/Account.Approval_Pending_Payment_Method__c';
import PENDING_COMMERCIAL_REGISTER_NR from '@salesforce/schema/Account.Approval_Pending_Commercial_Register_No__c';
import PENDING_REMOVE_PAYMENT_METHOD from '@salesforce/schema/Account.Remove_Payment_Method__c'
import PENDING_PARTNER from '@salesforce/schema/Account.Approval_Pending_Partner__c';
import PENDING_CUSTOMERPRICINGPROCEDURE from '@salesforce/schema/Account.Approval_Pending_Customer_Pricing_Proc__c';
import WHOLESALER from '@salesforce/schema/Account.Wholesaler__c';
import FSD from '@salesforce/schema/Account.FSD__c';
import FOODSERVICE from '@salesforce/schema/Account.Foodservice_Wholesaler__c';
import OFFICE_SUPPLIER from '@salesforce/schema/Account.Office_Supplier__c';
import VENDING from '@salesforce/schema/Account.Vending__c';
import CASH_CARRY from '@salesforce/schema/Account.Cash_Carry__c';

//call apex methods
import fetchFinanceController from '@salesforce/apex/RequestApproval.fetchFinanceController';
import fetchCustomerRelations from '@salesforce/apex/RequestApproval.fetchCustomerRelations';
import submitApproval from '@salesforce/apex/ApprovalProcessService.submitApproval';
//import customerValidationRT from '@salesforce/apex/ApprovalProcessService.accountRecordType';
import getBankDetailList from '@salesforce/apex/RequestApproval.getBankDetailList';

const columns = [
    { label: 'Bank Detail Name', fieldName: 'LinkToRecord__c', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank', tooltip: { fieldName: 'Name' }}, wraptext: true,  initialWidth: 160},
    { label: 'Approval Bank Account', fieldName: 'Approval_Bank_Account__c', initialWidth: 200},
    { label: 'Approval Bank Country', fieldName: 'Approval_Bank_Country__c', initialWidth: 200},
    { label: 'Approval Bank Key', fieldName: 'Approval_Bank_Key__c', initialWidth: 200},
    { label: 'Approval Collection Authorization', fieldName: 'Approval_Collection_Authorization__c', initialWidth: 200},
    { label: 'Approval Control Key', fieldName: 'Approval_Control_Key__c', initialWidth: 200},
    { label: 'Approval IBAN', fieldName: 'Approval_IBAN__c', initialWidth: 200},
    { label: 'Approval Status', fieldName: 'Updated_Request_Validation__c', initialWidth: 200}
];

export default class AccountApproval extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api isLoaded = false;
    //@track financeController;
    @track error;
    @track bankList;
    @api showDataTable = false;
   
    columns = columns;

    @wire(getBankDetailList, {accountId: '$recordId'})
    bankDetail({error, data}){
        if (data) {
            var dataResult = JSON.parse(JSON.stringify(data));
            dataResult.forEach(function(dataResult){
                dataResult.LinkToRecord__c = '/'+dataResult.Id;
            });
            this.bankList = dataResult;
            if(this.bankList.length === 0){
                this.showDataTable = false;
            } else {
                this.showDataTable = true;
            }
        } else if (error) {
            this.error = error;
            this.showDataTable = false;
        }
    };

    fields = [PENDING_PAYMENTTERM, PENDING_PAYMENT_METHOD, PENDING_COMMERCIAL_REGISTER_NR, PENDING_REMOVE_PAYMENT_METHOD, PENDING_CUSTOMERPRICINGPROCEDURE, PENDING_PARTNER, WHOLESALER, FSD, FOODSERVICE, OFFICE_SUPPLIER, VENDING, CASH_CARRY];

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
        fetchFinanceController({recordId : this.recordId})
        .then(result => {
            if (result){
                fetchCustomerRelations({recordId : this.recordId})
                .then(result2 => {
                    if (result2){
                        window.console.log(JSON.stringify(result2));
                        const fields = event.detail.fields;
                        // modify a field
                        fields.Finance_Controller_for_Account_Validatio__c = result[0]; 
                        fields.Finance_Controller_2__c = result[1];
                        fields.Customer_Relations_Approval_1__c = result2[0];
                        fields.Customer_Relations_Approval_2__c = result2[1];
                        fields.Sent_for_Approval_Date__c = this.formatDate(Date.now());
                        fields.Approval_Status__c = 'Approval Pending';
                        this.template.querySelector('lightning-record-form').submit(fields);
                    } 
                })
                .catch(error => {
                    this.isLoaded = false;
                    window.console.log(JSON.stringify(error));
                });  
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