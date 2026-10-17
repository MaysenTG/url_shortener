class AddUrlFeaturesAndFixIndexes < ActiveRecord::Migration[7.0]
  def up
    add_column :urls, :expires_at, :datetime
    add_column :urls, :custom, :boolean, default: false, null: false

    # schema.rb previously dumped a composite unique on (shortened_url, original_url).
    # Enforce uniqueness on shortened_url alone, with a covering INCLUDE when possible.
    execute "DROP INDEX IF EXISTS index_urls_on_shortened_url"
    execute <<~SQL.squish
      CREATE UNIQUE INDEX index_urls_on_shortened_url
      ON urls (shortened_url) INCLUDE (original_url, expires_at)
    SQL
  end

  def down
    execute "DROP INDEX IF EXISTS index_urls_on_shortened_url"
    add_index :urls, :shortened_url, unique: true

    remove_column :urls, :custom
    remove_column :urls, :expires_at
  end
end
