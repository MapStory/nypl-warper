class CreateApikeys < ActiveRecord::Migration
  def change
    create_table :apikeys do |t|
      t.string :key
      t.boolean :enabled

      t.timestamps null: false
    end
  end
end
