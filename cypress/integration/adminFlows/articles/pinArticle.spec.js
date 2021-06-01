describe('Pin an article', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then(() => {
          cy.createArticle({
            title: 'Test Another Article',
            tags: ['beginner', 'ruby', 'go'],
            content: `This is another test article's contents.`,
            published: true,
          }).then(() => {
            cy.visit('/admin/content_manager/articles');
          });
        });
      });
    });
  });

  it('should pin an article when no other article is currently pinned', () => {
    cy.intercept(`${Cypress.config().baseUrl}/stories/feed/pinned_article`, {
      statusCode: 404,
    });

    cy.findAllByRole('checkbox', { name: 'Pinned' }).first().check();
    cy.findAllByRole('button', { name: 'Submit' }).first().click();

    cy.findAllByRole('checkbox', { name: 'Pinned' })
      .first().should('be.checked');
  });

  it('should change the pinned article', () => {
    cy.intercept(`${Cypress.config().baseUrl}/stories/feed/pinned_article`, {
      statusCode: 404,
    });

    cy.findAllByRole('checkbox', { name: 'Pinned' }).first().check();
    cy.findAllByRole('button', { name: 'Submit' }).first().click();

    cy.visit('/admin/content_manager/articles');

    cy.findAllByRole('checkbox', { name: 'Pinned' }).last().check();
    cy.findAllByRole('button', { name: 'Submit' }).last().click();

    cy.findAllByRole('checkbox', { name: 'Pinned' })
      .first()
      .as('pinnedCheckbox');
    cy.get('@pinnedCheckbox').should('be.checked');
  });
});
