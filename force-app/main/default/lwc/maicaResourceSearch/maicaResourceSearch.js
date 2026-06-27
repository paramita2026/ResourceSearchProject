import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import searchResources from '@salesforce/apex/MaicaResourceSearchController.searchResources';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MaicaResourceSearch extends NavigationMixin(LightningElement) {
    @track resourceName = '';
    @track resources = [];
    @track isSearching = false;
    @track showResults = false;
    @track showNoResults = false;
    
    // Define columns for the data table
    columns = [
        { 
            label: 'Resource Name', 
           // fieldName: 'ResourceURL', 
           fieldName: 'Name', 
            //type: 'text'
           // type: 'url',
           type: 'button',
            typeAttributes: {
            label: { fieldName: 'Name' },
            variant: 'base',
            name: 'view_record' 
            //target: '_self'
            }
        },
        { label: 'Resource Type', fieldName: 'maica_cc__Type__c', type: 'text' },
        { label: 'Supplier Email', fieldName: 'Supplier_Email__c', type: 'email' }
    ];
    // Handle row action (button click) added to navigate to record page when multiple results appear.
handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    
    if (actionName === 'view_record') {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                actionName: 'view'
            }
        });
    }
}
    // Handle input changes
    handleResourceNameChange(event) {
        this.resourceName = event.target.value;
    }
 
    // Handle search button click
    handleSearch() {
        // Reset states
        this.showResults = false;
        this.showNoResults = false;
        this.resources = [];
        this.isSearching = true;

        // Call Apex method to search resources
        searchResources({ 
            resourceName: this.resourceName
        })
        .then(result => {
            this.isSearching = false;
            
            if (result && result.length > 0) {
                this.resources = result.map(record => {
                    return {
                        ...record,
                        //ResourceURL: '/maica_cc__Resource__c/' + record.Id
                       // ResourceURL: '/ahsupport/s/resource/' + record.Id + '/' + record.Name.toLowerCase().replace(/\s+/g, '-')
                        ResourceURL: '/ahsupport/s/resource/' + '/detail/' + record.Id
                    };
                });
                
                // Check if only one record is returned
                if (result.length === 1) {
                    // Navigate to the single account record
                    //this.navigateToRecord(result[0].Id);
                    this.navigateToRecord(result[0].Id, result[0].Name);
                } else {
                    // Show results table for multiple records
                    this.showResults = true;
                }
            } else {
                // No results found
                this.showNoResults = true;
            }
        })
        .catch(error => {
            this.isSearching = false;
            this.showToast('Error', this.getErrorMessage(error), 'error');
        });
    }

   // Navigate to resource record page
    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'maica_cc__Resource__c',
               actionName: 'view'
             }
        });
    }
//     navigateToRecord(recordId, recordName) {
//     const slug = recordName.toLowerCase().replace(/\s+/g, '-');
//     const url = '/ahsupport/s/resource/' + recordId + '/' + slug;
//     console.log(url);
//     this[NavigationMixin.Navigate]({
//         type: 'standard__webPage',
//         attributes: { url: url }
//     });
// }

    // Handle row selection
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows && selectedRows.length > 0) {
            // Navigate to the first selected account
            this.navigateToRecord(selectedRows[0].Id);
        }
    }

    // Handle back button click
    handleBack() {
        this.showResults = false;
        this.showNoResults = false;
        this.resources = [];
    }

    // Handle new search button click
    handleNewSearch() {
        this.resourceName = '';
        this.showResults = false;
        this.showNoResults = false;
        this.resources = [];
    }

    // Show toast notification
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Extract error message from error object
    getErrorMessage(error) {
        if (error.body && error.body.message) {
            return error.body.message;
        } else if (error.message) {
            return error.message;
        } else if (Array.isArray(error.body)) {
            return error.body.map(e => e.message).join(', ');
        }
        return 'Unknown error occurred';
    }

    // Computed properties
    get hasResults() {
        return this.resources && this.resources.length > 0;
    }

    get showSearchForm() {
        return !this.showResults && !this.showNoResults;
    }
}