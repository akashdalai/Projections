require "rails_helper"

RSpec.describe "ArticlesUpdate", type: :request do
  let(:organization) { create(:organization) }
  let(:organization2) { create(:organization) }
  let(:user) { create(:user, organization_id: organization.id) }
  let(:user2) { create(:user, organization_id: organization2.id) }
  let(:article) { create(:article, user_id: user.id) }

  before do
    sign_in user
  end

  it "updates ordinary article with proper params" do
    new_title = "NEW TITLE #{rand(100)}"
    put "/articles/#{article.id}", params: {
      article: { title: new_title, body_markdown: "Yo ho ho#{rand(100)}", tag_list: "yo" }
    }
    expect(Article.last.title).to eq(new_title)
  end

  it "updates article with front matter params" do
    put "/articles/#{article.id}", params: {
      article: {
        title: "hello",
        body_markdown: "---\ntitle: hey hey hahuu\npublished: false\n---\nYo ho ho#{rand(100)}",
        tag_list: "yo"
      }
    }
    expect(Article.last.edited_at).to be > 5.seconds.ago
    expect(Article.last.title).to eq("hey hey hahuu")
  end

  it "adds organization ID when user updates" do
    put "/articles/#{article.id}", params: {
      article: { post_under_org: true }
    }
    expect(article.reload.organization_id).to eq organization.id
  end

  it "does not modify the organization ID when updating someone else's article as an admin" do
    article.update_columns(organization_id: organization2.id, user_id: user2.id)
    user.add_role(:super_admin)
    put "/articles/#{article.id}", params: {
      article: { post_under_org: true }
    }
    expect(article.reload.organization_id).to eq user2.organization_id
  end 
end
