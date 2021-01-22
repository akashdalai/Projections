// Note if you are running these tests locallly, this test will fail
// if the first admin has already gone through the onboarding process.

describe('User Change Password', () => {
  beforeEach(() => {
    cy.request('/cypress_rails_reset_state');
  });

  it('should change the password of a user', () => {
    cy.fixture('users/changePasswordUser.json').as('user');

    // Go to home page
    cy.visit('/enter');

    cy.findByTestId('login-form').as('loginForm');

    cy.get('@user').then((user) => {
      // Enter credentials for the initial administrator user
      cy.get('@loginForm').findByText('Email').type(user.email);
      cy.get('@loginForm').findByText('Password').type(user.password);
    });

    // Submit the form
    cy.get('@loginForm').findByText('Continue').click();

    cy.visit('/settings/account');

    cy.findByTestId('update-password-form').as('updatePasswordForm');

    const newPassword = 'drowssap';

    cy.get('@user').then((user) => {
      // Enter credentials for the initial administrator user
      cy.get('@updatePasswordForm')
        .findByText(/^Current Password$/i)
        .type(user.password);
      cy.get('@updatePasswordForm')
        .findByText(/^Password$/i)
        .type(newPassword);
      cy.get('@updatePasswordForm')
        .findByText(/^Confirm new password$/)
        .type(newPassword);
    });

    // Submit the form
    cy.get('@updatePasswordForm').findByText('Set New Password').click();

    cy.findByTestId('login-form').as('loginForm');

    cy.get('@user').then((user) => {
      // Enter credentials for the initial administrator user
      cy.get('@loginForm').findByText('Email').type(user.email);
      cy.get('@loginForm').findByText('Password').type(newPassword);
    });

    // Submit the form
    cy.get('@loginForm').findByText('Continue').click();

    const { baseUrl } = Cypress.config();
    cy.url().should('equal', `${baseUrl}settings/account?signin=true`);
  });
});
