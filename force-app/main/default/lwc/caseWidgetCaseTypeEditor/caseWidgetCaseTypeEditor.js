import { LightningElement, api, track } from 'lwc';

export default class CaseWidgetCaseTypeEditor extends LightningElement {

    @track _types = [];
    @track showAddForm = false;
    @track validationError = '';

    newValue = '';
    newLabel = '';
    _dragSourceIndex = null;

    // ─── Public API ───────────────────────────────────────────────────────────

    @api
    get caseTypes() {
        return this._types;
    }
    set caseTypes(value) {
        this._types = (value || []).map((ct, i) => ({
            ...ct,
            _key: ct.Id || `new-${i}-${Date.now()}`,
            _editing: false
        }));
    }

    @api
    getValue() {
        return this._types.map((ct, i) => ({
            Id: ct.Id || null,
            Value__c: ct.Value__c,
            Label__c: ct.Label__c,
            Active__c: ct.Active__c,
            Sort_Order__c: i
        }));
    }

    @api
    validate() {
        const activeCount = this._types.filter(ct => ct.Active__c).length;
        if (activeCount === 0) {
            this.validationError = 'At least one active case type is required.';
            return { valid: false, message: this.validationError };
        }
        this.validationError = '';
        return { valid: true, message: '' };
    }

    // ─── Getters ──────────────────────────────────────────────────────────────

    get hasTypes() {
        return this._types.length > 0;
    }

    // ─── Add Form ─────────────────────────────────────────────────────────────

    handleShowAddForm() {
        this.showAddForm = true;
        this.newValue = '';
        this.newLabel = '';
    }

    handleCancelAdd() {
        this.showAddForm = false;
    }

    handleNewValueChange(event) {
        this.newValue = event.target.value;
    }

    handleNewLabelChange(event) {
        this.newLabel = event.target.value;
    }

    handleAdd() {
        const valueInput = this.template.querySelector('[data-id="new-value"]');
        const labelInput = this.template.querySelector('[data-id="new-label"]');

        let valid = true;
        if (!this.newValue || !this.newValue.trim()) {
            valueInput.setCustomValidity('Internal value is required');
            valueInput.reportValidity();
            valid = false;
        } else {
            valueInput.setCustomValidity('');
        }
        if (!this.newLabel || !this.newLabel.trim()) {
            labelInput.setCustomValidity('Visible label is required');
            labelInput.reportValidity();
            valid = false;
        } else {
            labelInput.setCustomValidity('');
        }
        if (!valid) return;

        const newType = {
            Id: null,
            Value__c: this.newValue.trim(),
            Label__c: this.newLabel.trim(),
            Active__c: true,
            Sort_Order__c: this._types.length,
            _key: `new-${Date.now()}`,
            _editing: false
        };
        this._types = [...this._types, newType];
        this.showAddForm = false;
        this.newValue = '';
        this.newLabel = '';
        this.validationError = '';
        this._notifyChange();
    }

    // ─── Delete ───────────────────────────────────────────────────────────────

    handleDelete(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const updated = [...this._types];
        updated.splice(index, 1);
        this._types = updated.map((ct, i) => ({ ...ct, Sort_Order__c: i }));
        this._notifyChange();
    }

    // ─── Active Toggle ────────────────────────────────────────────────────────

    handleToggleActive(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const updated = [...this._types];
        updated[index] = { ...updated[index], Active__c: event.target.checked };
        this._types = updated;
        this._notifyChange();
    }

    // ─── Inline Edit ──────────────────────────────────────────────────────────

    handleStartEdit(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this._types = this._types.map((ct, i) => ({
            ...ct,
            _editing: i === index ? true : ct._editing
        }));
    }

    handleEditChange(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        const field = event.currentTarget.dataset.field;
        const updated = [...this._types];
        updated[index] = { ...updated[index], [field]: event.target.value };
        this._types = updated;
    }

    handleEditBlur(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        this._types = this._types.map((ct, i) => ({
            ...ct,
            _editing: i === index ? false : ct._editing
        }));
        this._notifyChange();
    }

    // ─── Drag & Drop Reorder ──────────────────────────────────────────────────

    handleDragStart(event) {
        this._dragSourceIndex = parseInt(event.currentTarget.dataset.index, 10);
        event.dataTransfer.effectAllowed = 'move';
    }

    handleDragOver(event) {
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
    }

    handleDrop(event) {
        event.preventDefault();
        const targetIndex = parseInt(event.currentTarget.dataset.index, 10);
        if (this._dragSourceIndex === null || this._dragSourceIndex === targetIndex) return;

        const updated = [...this._types];
        const [moved] = updated.splice(this._dragSourceIndex, 1);
        updated.splice(targetIndex, 0, moved);
        this._types = updated.map((ct, i) => ({ ...ct, Sort_Order__c: i }));
        this._dragSourceIndex = null;
        this._notifyChange();
    }

    // ─── Private ──────────────────────────────────────────────────────────────

    _notifyChange() {
        this.dispatchEvent(new CustomEvent('casetypeschange', {
            detail: { caseTypes: this.getValue() }
        }));
    }
}
