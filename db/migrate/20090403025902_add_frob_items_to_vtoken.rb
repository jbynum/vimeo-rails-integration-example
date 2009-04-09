class AddFrobItemsToVtoken < ActiveRecord::Migration
  def self.up
    add_column :vtokens, :perms, :string
    add_column :vtokens, :nsid, :string
    add_column :vtokens, :fullname, :string
    add_column :vtokens, :username, :string
    add_column :vtokens, :user_id, :string
  end

  def self.down
    remove_column :vtokens, :user_id
    remove_column :vtokens, :username
    remove_column :vtokens, :fullname
    remove_column :vtokens, :nsid
    remove_column :vtokens, :perms
  end
end
