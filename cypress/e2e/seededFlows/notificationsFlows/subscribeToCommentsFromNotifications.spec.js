describe('Subscribe to Comments from notifications', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/notificationsUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/notifications');
    });
  });

  it('Subscribes and unsubscribes to comments from notification', () => {
    cy.findByRole('heading', { name: 'Notifications' });

    cy.findByRole('button', { name: 'Subscribe to comments' }).as(
      'subscribeButton',
    );
    cy.get('@subscribeButton').should('have.attr', 'aria-pressed', 'false');
    cy.get('@subscribeButton').click();

    cy.findByRole('button', { name: 'Subscribed to comments' }).as(
      'subscribedButton',
    );
    cy.get('@subscribedButton').contains('Subscribed to comments');
    cy.get('@subscribedButton').should('have.attr', 'aria-pressed', 'true');

    cy.get('@subscribedButton').click();
  });
});
