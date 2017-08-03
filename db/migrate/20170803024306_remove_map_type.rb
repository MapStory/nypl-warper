class RemoveMapType < ActiveRecord::Migration
  def change
  	remove_column :maps, :map
  	remove_column :maps, :map_type

  end
end
