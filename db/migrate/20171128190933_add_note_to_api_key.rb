class AddNoteToApiKey < ActiveRecord::Migration
  def change
  	add_column :apikeys, :notes, :string
  end
end
