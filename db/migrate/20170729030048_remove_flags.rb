class RemoveFlags < ActiveRecord::Migration
  def change
  	drop_table :flags
  end
end
