import { LightningElement, api, wire, track} from 'lwc';
import { refreshApex } from '@salesforce/apex';

//call apex method
import getTaskHistory from '@salesforce/apex/SM_TaskHistoryRecord.getTaskHistory';

const columns = [
    { label: 'Task', fieldName: 'Task_Name__c', type: 'text'},
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Touchpoint Type', fieldName: 'Touchpoint_Type__c'},
    { label: 'Type', fieldName: 'Type__c'},
    { label: 'Task Source', fieldName: 'Task_Source__c'},
    { label: 'Owner Name', fieldName: 'Owner.Name', type: 'text'},
    { label: 'Valid From', fieldName: 'Valid_From__c', type: 'date', typeAttributes: {day: "2-digit", month: "2-digit", year: "numeric", hour: '2-digit', minute: '2-digit'}},
    { label: 'Valid To', fieldName: 'Valid_To__c', type: 'date', typeAttributes: {day: "2-digit", month: "2-digit", year: "numeric", hour: '2-digit', minute: '2-digit'}}
];

export default class SM_TaskHistoryView extends LightningElement {
    @api recordId;
    @track allTaskHistory = [];
    @track columns = columns;
    //@api isLoaded = false;
    //wiredTH;

    columns = columns;

    @wire(getTaskHistory, { taskId: '$recordId' })
    TaskHistories({ error, data }) {
        //this.wiredTH = data;
        //this.isLoaded = false;
        if(data) {
           //this is the final array into which the flattened response will be pushed. 
           let thArray = [];
            
           for (let row of data) {
                // this const stroes a single flattened row. 
                const flattenedRow = {}
                
                // get keys of a single row — Name, Phone, LeadSource and etc
                let rowKeys = Object.keys(row); 
               
                //iterate 
                rowKeys.forEach((rowKey) => {
                    
                    //get the value of each key of a single row. John, 999-999-999, Web and etc
                    const singleNodeValue = row[rowKey];
                    
                    //check if the value is a node(object) or a string
                    if(singleNodeValue.constructor === Object){
                        
                        //if it's an object flatten it
                        this._flatten(singleNodeValue, flattenedRow, rowKey)        
                    }else{
                        
                        //if it’s a normal string push it to the flattenedRow array
                        flattenedRow[rowKey] = singleNodeValue;
                    }
                    
                });
               
                //push all the flattened rows to the final array 
                thArray.push(flattenedRow);
            }
            
            //assign the array to an array that's used in the template file
            this.allTaskHistory = thArray;
        } else if (error) {
            this.error = error;
        }
    }
    
    _flatten = (nodeValue, flattenedRow, nodeName) => {        
        let rowKeys = Object.keys(nodeValue);
        rowKeys.forEach((key) => {
            let finalKey = nodeName + '.'+ key;
            flattenedRow[finalKey] = nodeValue[key];
        })
    }

    /*handleRefresh() {
        //this.isLoaded = !this.isLoaded;
        window.console.log('HERE4');
        return refreshApex(this.wiredTH);
        
    }*/
}