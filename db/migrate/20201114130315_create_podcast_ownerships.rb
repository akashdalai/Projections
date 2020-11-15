class CreatePodcastOwnerships < ActiveRecord::Migration[6.0]
  def change
    create_table :podcast_ownerships do |t|
      t.references :podcast, index: true, foreign_key: true, null: false
      t.references :user, index: true, foreign_key: true, null: false
      t.timestamps
    end
  end
end
