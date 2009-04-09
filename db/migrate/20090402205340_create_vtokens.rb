class CreateVtokens < ActiveRecord::Migration
  def self.up
    create_table :vtokens do |t|
      t.text :token

      t.timestamps
    end
  end

  def self.down
    drop_table :vtokens
  end
end
