class Addpaperclipfields < ActiveRecord::Migration
  def up
    add_attachment :maps, :upload
  end

  def down
    remove_attachment :maps, :upload
  end
end
