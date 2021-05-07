describe('Post sidebar actions', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/articleEditorV2User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then((response) => {
          cy.visit(response.body.current_state_path);
        });
      });
    });
  });

  it('should open the share menu for the post', () => {
    // TODO: Get this working
    cy.findByRole('button', { name: /^Toggle dropdown menu$/i }).click();

    cy.findByTitle(/^Copy article link to the clipboard$/i);
    cy.findByRole('link', { name: /^Share to Twitter$/i });
    cy.findByRole('link', { name: /^Share to LinkedIn$/i });
    cy.findByRole('link', { name: /^Share to Reddit$/i });
    cy.findByRole('link', { name: /^Share to Hacker News$/i });
    cy.findByRole('link', { name: /^Share to Facebook$/i });
    cy.findByRole('link', { name: /^Share Post$/i });
    cy.findByRole('link', { name: /^Report Abuse$/i });
  });
});
