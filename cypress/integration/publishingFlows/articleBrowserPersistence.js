describe('Article Editor', () => {
  describe('v1 Editor', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV1User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.visit('/new');
        });
      });
    });

    describe(`revert changes`, () => {
      it('should revert to the initial v1 editor template if it is a new article', () => {
        cy.findByRole('form', { name: /^Edit an article$/i }).as('articleForm');

        // Fill out the title, tags, and content for an article.
        cy.get('@articleForm')
          .findByLabelText('Post Content')
          .as('postContent')
          // Clearing out the whole content area as this seemed simpler than finding where to add the fields in the v1 editor
          .clear()
          // The v1 editor has all the post info in one textarea
          .type(
            `---\ntitle: \npublished: true\ndescription: some description\ntags: tag1, tag2,tag3\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is some text that should be reverted`,
          );

        cy.get('@postContent').should(
          'have.value',
          `---\ntitle: \npublished: true\ndescription: some description\ntags: tag1, tag2,tag3\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is some text that should be reverted`,
        );

        cy.findByRole('button', { name: /^Revert new changes$/i }).click();

        // The article editor should reset to it's initial values
        cy.get('@postContent').should(
          'have.value',
          `---\ntitle: \npublished: false\ndescription: \ntags: \n//cover_image: https://direct_url_to_image.jpg\n---\n\n`,
        );
      });

      it('should revert to the previously saved version of the article if the article was previously edited', () => {
        // Create an article and edit it.
        cy.createArticle({
          content: `---\ntitle: Test Article\npublished: false\ndescription: \ntags: beginner, ruby, go\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is a test article's contents.`,
          published: true,
          editorVersion: 'v1',
        }).then((response) => {
          cy.visit(response.body.current_state_path);

          cy.findByText(/^Edit$/i).click();

          cy.findByRole('form', { name: /^Edit an article$/i }).as(
            'articleForm',
          );

          cy.get('@articleForm')
            .findByLabelText('Post Content')
            .as('postContent')
            .should(
              'have.value',
              `---\ntitle: Test Article\npublished: false\ndescription: \ntags: beginner, ruby, go\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is a test article's contents.`,
            )
            // Clearing out the whole content area as this seemed simpler than finding where to add the fields in the v1 editor
            .clear()
            // Update the title, tags, and content for an article.
            .type(
              `---\ntitle: \npublished: true\ndescription: some description\ntags: tag1, tag2,tag3\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is some text that should be reverted`,
            );
          cy.get('@postContent').should(
            'have.value',
            `---\ntitle: \npublished: true\ndescription: some description\ntags: tag1, tag2,tag3\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is some text that should be reverted`,
          );

          cy.findByRole('button', { name: /^Revert new changes$/i }).click();

          // The article editor should reset to it's saved version from the server that was initially loaded into the editor.
          cy.get('@postContent').should(
            'have.value',
            `---\ntitle: Test Article\npublished: false\ndescription: \ntags: beginner, ruby, go\n//cover_image: https://direct_url_to_image.jpg\n---\n\nThis is a test article's contents.`,
          );
        });
      });
    });
  });

  describe('v2 Editor', () => {
    beforeEach(() => {
      cy.testSetup();
      cy.fixture('users/articleEditorV2User.json').as('user');

      cy.get('@user').then((user) => {
        cy.loginUser(user).then(() => {
          cy.visit('/new');
        });
      });
    });

    describe(`revert changes`, () => {
      it('should revert to empty content if it is a new article', () => {
        cy.findByRole('form', { name: /^Edit an article$/i }).as('articleForm');

        // Fill out the title, tags, and content for an article.
        cy.get('@articleForm')
          .findByLabelText(/^Post Title$/i)
          .as('postTitle')
          .type('This is some title that should be reverted');
        cy.get('@articleForm')
          .findByLabelText(/^Post Tags$/i)
          .as('postTags')
          .type('tag1, tag2, tag3');
        cy.get('@articleForm')
          .findByLabelText(/^Post Content$/i)
          .as('postContent')
          .type('This is some text that should be reverted');

        cy.get('@postTitle').should(
          'have.value',
          'This is some title that should be reverted',
        );
        cy.get('@postTags').should('have.value', 'tag1, tag2, tag3');
        cy.get('@postContent').should(
          'have.value',
          'This is some text that should be reverted',
        );

        cy.findByRole('button', { name: /^Revert new changes$/i }).click();

        // The article editor should reset to it's initial values
        cy.get('@postTitle').should('have.value', '');
        cy.get('@postTags').should('have.value', '');
        cy.get('@postContent').should('have.value', '');
      });

      it('should revert to the previously saved version of the article if the article was previously edited', () => {
        // Create an article and edit it.
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then((response) => {
          cy.visit(response.body.current_state_path);

          cy.findByText(/^Edit$/i).click();

          cy.findByRole('form', { name: /^Edit an article$/i }).as(
            'articleForm',
          );

          // Update the title, tags, and content for an article.
          cy.get('@articleForm')
            .findByLabelText(/^Post Title$/i)
            .as('postTitle')
            .should('have.value', 'Test Article') // checking for original value first
            .clear()
            .type('This is some title that should be reverted');
          cy.get('@articleForm')
            .findByLabelText(/^Post Tags$/i)
            .as('postTags')
            .should('have.value', 'beginner, ruby, go') // checking for original value first
            .clear()
            .type('tag1, tag2, tag3');
          cy.get('@articleForm')
            .findByLabelText(/^Post Content$/i)
            .as('postContent')
            .should('have.value', `This is a test article's contents.`) // checking for original value first
            .clear()
            .type('This is some text that should be reverted');

          cy.get('@postTitle').should(
            'have.value',
            'This is some title that should be reverted',
          );
          cy.get('@postTags').should('have.value', 'tag1, tag2, tag3');
          cy.get('@postContent').should(
            'have.value',
            'This is some text that should be reverted',
          );

          cy.findByRole('button', { name: /^Revert new changes$/i }).click();

          // The article editor should reset to it's saved version from the server that was initially loaded into the editor.
          cy.get('@postTitle').should('have.value', 'Test Article');
          cy.get('@postTags').should('have.value', 'beginner, ruby, go');
          cy.get('@postContent').should(
            'have.value',
            `This is a test article's contents.`,
          );
        });
      });
    });
  });
});
