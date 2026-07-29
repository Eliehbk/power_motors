import { LightningElement, api } from 'lwc';
import { subscribe } from 'lightning/empApi';
import { RefreshEvent } from 'lightning/refresh';

export default class Listener extends LightningElement {
    @api recordId; 
    loadSpinner=false;
    constructor() {
        super();
        subscribe('/event/Lead_Refresh_Event__e', -1, (response) => {
            this.loadSpinner = true;
            setTimeout(() => {
                this.loadSpinner = false;
                console.log('spinnerrr');
            }, 2000);
            if (response.data.payload.Lead_Id__c === this.recordId) {
                this.dispatchEvent(new RefreshEvent());
            }
        });
    }
}
