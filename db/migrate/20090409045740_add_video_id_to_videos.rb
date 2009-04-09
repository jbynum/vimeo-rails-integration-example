class AddVideoIdToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :video_id, :string
  end

  def self.down
    remove_column :videos, :video_id
  end
end
