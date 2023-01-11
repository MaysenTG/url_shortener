class CreateUrls < ActiveRecord::Migration[7.0]
  def change
    create_table :urls do |t|
      t.string :original_url
      t.string :shortened_url
      t.integer :clicks, default: 0

      t.timestamps
    end
  end
end
