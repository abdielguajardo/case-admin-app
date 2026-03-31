import { createElement } from 'lwc';
import CaseWidgetAdmin from 'c/caseWidgetAdmin';
import getDomains from '@salesforce/apex/CaseWidgetDomainService.getDomains';

jest.mock(
    '@salesforce/apex/CaseWidgetDomainService.getDomains',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock('c/caseWidgetDomainForm', () => ({ open: jest.fn() }), { virtual: true });

const MOCK_WRAPPERS = [
    {
        domain: {
            Id: 'a01',
            Name: 'Main Blog',
            Domain__c: 'mainblog.com',
            Active__c: true,
            CreatedDate: '2026-01-01T00:00:00.000Z'
        },
        config: { Id: 'b01' },
        hasSecretKey: true,
        hasRecentActivity: false,
        caseTypes: []
    }
];

afterEach(() => {
    while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
});

describe('caseWidgetAdmin', () => {
    it('shows loading spinner initially', () => {
        getDomains.mockReturnValue(new Promise(() => {})); // never resolves
        const el = createElement('c-case-widget-admin', { is: CaseWidgetAdmin });
        document.body.appendChild(el);
        return Promise.resolve().then(() => {
            const spinner = el.shadowRoot.querySelector('lightning-spinner');
            expect(spinner).not.toBeNull();
        });
    });

    it('renders domain list after data loads', async () => {
        getDomains.mockResolvedValue(MOCK_WRAPPERS);
        const el = createElement('c-case-widget-admin', { is: CaseWidgetAdmin });
        document.body.appendChild(el);
        await Promise.resolve();
        await Promise.resolve();
        const list = el.shadowRoot.querySelector('c-case-widget-domain-list');
        expect(list).not.toBeNull();
    });

    it('shows empty state when no domains', async () => {
        getDomains.mockResolvedValue([]);
        const el = createElement('c-case-widget-admin', { is: CaseWidgetAdmin });
        document.body.appendChild(el);
        await Promise.resolve();
        await Promise.resolve();
        const emptyState = el.shadowRoot.querySelector('.empty-state');
        expect(emptyState).not.toBeNull();
    });

    it('shows error state on getDomains failure', async () => {
        getDomains.mockRejectedValue({ body: { message: 'Server error' } });
        const el = createElement('c-case-widget-admin', { is: CaseWidgetAdmin });
        document.body.appendChild(el);
        await Promise.resolve();
        await Promise.resolve();
        const errorState = el.shadowRoot.querySelector('.error-state');
        expect(errorState).not.toBeNull();
    });

    it('opens form on New Domain click', async () => {
        const { open } = require('c/caseWidgetDomainForm');
        open.mockResolvedValue({ saved: false });
        getDomains.mockResolvedValue(MOCK_WRAPPERS);

        const el = createElement('c-case-widget-admin', { is: CaseWidgetAdmin });
        document.body.appendChild(el);
        await Promise.resolve();
        await Promise.resolve();

        const newBtn = el.shadowRoot.querySelector('lightning-button[label="New Domain"]');
        newBtn.dispatchEvent(new CustomEvent('click'));

        await Promise.resolve();
        expect(open).toHaveBeenCalledWith(expect.objectContaining({ domainData: null }));
    });
});
