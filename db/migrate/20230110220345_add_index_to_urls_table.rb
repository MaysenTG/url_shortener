class AddIndexToUrlsTable < ActiveRecord::Migration[7.0]
  def change
    add_index :urls, :shortened_url, unique: true
  end
end
