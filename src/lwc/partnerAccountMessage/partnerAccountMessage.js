import { LightningElement, api, wire, track} from 'lwc';
import fetchGTM from '@salesforce/apex/SM_DataAccessObjectLWC.fetchAccount';
const FIELDS = [
    'Account.Name',
    'Account.GTM_Ingredients__c'
];

export default class PartnerAccountMessage extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track error;
    @track gtmName;

    @wire(fetchGTM, {accId: '$recordId'})
    account({error, data}){
        if(data){
            var gtmRecord = JSON.parse(JSON.stringify(data));
            this.gtmName = gtmRecord.GTM_Ingredients__r.Name;
        } else if(error) {
            this.error = error;
        }
    };
}