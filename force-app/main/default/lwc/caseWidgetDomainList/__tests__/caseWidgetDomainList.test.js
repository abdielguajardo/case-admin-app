import { createElement } from 'lwc';
import CaseWidgetDomainList from 'c/caseWidgetDomainList';
import toggleDomainActive from '@salesforce/apex/CaseWidgetDomainService.toggleDomainActive';
import deleteDomain from '@salesforce/apex/CaseWidgetDomainService.deleteDomain';

jest.mock(
    '@salesforce/apex/CaseWidgetDomainService.toggleDomainActive',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/CaseWidgetDomainService.deleteDomain',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock('lightning/confirm', () => ({ open: jest.fn() }), { virtual: true });

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
        caseTypes: [
            { Id: 'c01', Value__c: 'Bug', Active__c: true }
        ]
    }
];

afterEach(() => {
    while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
});

describe('caseWidgetDomainList', () => {
    it('renders domain cards', () => {
        const el = createElement('c-case-widget-domain-list', { is: CaseWidgetDomainList });
        el.rawDomains = MOCK_WRAPPERS;
        document.body.appendChild(el);
        return Promise.resolve().then(() => {
            const cards = el.shadowRoot.querySelectorAll('.domain-card');
            expect(cards.length).toBe(1);
        });
    });

    it('shows active dot for active domain', () => {
        const el = createElement('c-case-widget-domain-list', { is: CaseWidgetDomainList });
        el.rawDomains = MOCK_WRAPPERS;
        document.body.appendChild(el);
        return Promise.resolve().then(() => {
            const dot = el.shadowRoot.querySelector('.status-dot--active');
            expect(dot).not.toBeNull();
        });
    });

    it('fires editdomain event on Edit click', () => {
        const el = createElement('c-case-widget-domain-list', { is: CaseWidgetDomainList });
        el.rawDomains = MOCK_WRAPPERS;
        document.body.appendChild(el);

        const handler = jest.fn();
        el.addEventListener('editdomain', handler);

        return Promise.resolve()
        .then(() => {
            const editBtn = el.shadowRoot.querySelector('lightning-button[data-testid="edit-button"]');
            editBtn.dispatchEvent(new CustomEvent('click'));
            return Promise.resolve();
        })
        .then(() => {
            expect(handler).toHaveBeenCalled();
            expect(handler.mock.calls[0][0].detail.domainId).toBe('a01');
        });
    });

    it('calls toggleDomainActive on toggle click', async () => {
        toggleDomainActive.mockResolvedValue();
        const el = createElement('c-case-widget-domain-list', { is: CaseWidgetDomainList });
        el.rawDomains = MOCK_WRAPPERS;
        document.body.appendChild(el);

        await Promise.resolve();
        const toggleBtn = el.shadowRoot.querySelector('lightning-button[data-testid="toggle-active-button"]');
        toggleBtn.dispatchEvent(new CustomEvent('click'));

        await Promise.resolve();
        expect(toggleDomainActive).toHaveBeenCalledWith({ domainId: 'a01', active: false });
    });

    it('disables delete button when hasRecentActivity is true', () => {
        const wrapper = { ...MOCK_WRAPPERS[0], hasRecentActivity: true };
        const el = createElement('c-case-widget-domain-list', { is: CaseWidgetDomainList });
        el.rawDomains = [wrapper];
        document.body.appendChild(el);

        return Promise.resolve().then(() => {
            const deleteBtn = el.shadowRoot.querySelector('lightning-button[data-testid="delete-button"]');
            expect(deleteBtn.disabled).toBe(true);
        });
    });
});
