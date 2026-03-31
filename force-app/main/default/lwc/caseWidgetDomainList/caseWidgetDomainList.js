import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import toggleDomainActive from '@salesforce/apex/CaseWidgetDomainService.toggleDomainActive';
import deleteDomain from '@salesforce/apex/CaseWidgetDomainService.deleteDomain';

export default class CaseWidgetDomainList extends LightningElement {

    @api rawDomains = []; // List<DomainWrapper> from parent

    // ─── Getters ──────────────────────────────────────────────────────────────

    get domains() {
        return (this.rawDomains || []).map(wrapper => {
            const active = wrapper.domain.Active__c;
            const caseTypeCount = wrapper.caseTypes ? wrapper.caseTypes.length : 0;
            const hasRecentActivity = wrapper.hasRecentActivity === true;

            return {
                ...wrapper,
                activeDotClass: active ? 'status-dot status-dot--active' : 'status-dot status-dot--inactive',
                activeLabel: active ? 'Active' : 'Inactive',
                toggleLabel: active ? 'Deactivate' : 'Activate',
                toggleIcon: active ? 'utility:pause' : 'utility:play',
                caseTypeCount,
                hasRecentActivity,
                deleteTitle: hasRecentActivity
                    ? 'This domain has recent activity and cannot be deleted'
                    : 'Delete domain',
                createdDateFormatted: wrapper.domain.CreatedDate
                    ? new Date(wrapper.domain.CreatedDate).toLocaleDateString('en-US', {
                        month: 'short', day: 'numeric', year: 'numeric'
                      })
                    : ''
            };
        });
    }

    // ─── Actions ──────────────────────────────────────────────────────────────

    handleEdit(event) {
        const domainId = event.currentTarget.dataset.domainId;
        this.dispatchEvent(new CustomEvent('editdomain', { detail: { domainId } }));
    }

    async handleToggleActive(event) {
        const domainId = event.currentTarget.dataset.domainId;
        const currentActive = event.currentTarget.dataset.active === 'true';
        const newActive = !currentActive;

        try {
            await toggleDomainActive({ domainId, active: newActive });
            this.dispatchEvent(new CustomEvent('domainupdated'));
        } catch (error) {
            this._showError('Error updating domain', error);
        }
    }

    async handleDelete(event) {
        const domainId = event.currentTarget.dataset.domainId;

        const confirmed = await LightningConfirm.open({
            message: 'Are you sure you want to delete this domain? This action cannot be undone.',
            variant: 'headerless',
            label: 'Confirm Delete'
        });

        if (!confirmed) return;

        try {
            await deleteDomain({ domainId });
            this.dispatchEvent(new CustomEvent('domaindeleted'));
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Domain deleted successfully.',
                variant: 'success'
            }));
        } catch (error) {
            this._showError('Cannot delete domain', error);
        }
    }

    // ─── Private ──────────────────────────────────────────────────────────────

    _showError(title, error) {
        const message = error?.body?.message || error?.message || 'An unexpected error occurred.';
        this.dispatchEvent(new ShowToastEvent({ title, message, variant: 'error' }));
    }
}
