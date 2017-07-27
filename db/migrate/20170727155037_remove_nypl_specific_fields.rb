class RemoveNyplSpecificFields < ActiveRecord::Migration
  def change

  	remove_column :maps, :filename
  	remove_column :maps, :thumbnail
  	remove_column :maps, :size
  	remove_column :maps, :issue_year
  	remove_column :maps, :uuid
  	remove_column :maps, :parent_uuid
  	remove_column :maps, :catnyp
  	remove_column :maps, :nypl_digital_id
  	

  	remove_column :layers, :catnyp
  	remove_column :layers, :uuid
  	remove_column :layers, :parent_uuid
  	remove_column :layers, :depicts_year

  end
end
