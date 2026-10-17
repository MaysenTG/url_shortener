class OptimizeClicksAndAddLinkClicks < ActiveRecord::Migration[7.0]
  def up
    add_column :urls, :unique_clicks, :integer, default: 0, null: false
    add_column :urls, :first_clicked_at, :datetime
    add_column :urls, :last_clicked_at, :datetime

    create_table :link_clicks do |t|
      t.references :url, null: false, foreign_key: true
      t.datetime :clicked_at, null: false
      t.string :referrer
      t.string :user_agent
      t.string :ip_hash
      t.string :country, limit: 8
      t.boolean :bot, null: false, default: false

      t.timestamps
    end

    add_index :link_clicks, [:url_id, :clicked_at]
    add_index :link_clicks, [:url_id, :ip_hash]

    # Covering unique index so redirect lookups can be index-only.
    remove_index :urls, :shortened_url
    execute <<~SQL.squish
      CREATE UNIQUE INDEX index_urls_on_shortened_url
      ON urls (shortened_url) INCLUDE (original_url)
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_urls_on_shortened_url"
    add_index :urls, :shortened_url, unique: true

    drop_table :link_clicks

    remove_column :urls, :last_clicked_at
    remove_column :urls, :first_clicked_at
    remove_column :urls, :unique_clicks
  end
end
