describe('Edit listing category', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(user, '/admin/apps/listings/categories/1/edit');
    });
  });

  it('Changes the social preview color', () => {
    // Both a button and an input should exist
    cy.findByRole('button', { name: 'Social preview color' });
    cy.findByRole('textbox', { name: 'Social preview color' })
      .clear()
      .type('#32a852')
      .blur();
    cy.findByRole('button', { name: 'Update Listing Category' }).click();
    cy.findByText('Listing Category has been updated!').should('exist');
    // Check the table entry reflects the new color
    cy.findByRole('cell', { name: '#32a852' });
  });
});
