class RemoveDevise < ActiveRecord::Migration
	def change
		remove_column :users, :encrypted_password
		remove_column :users, :password_salt
		remove_column :users, :remember_token
		remove_column :users, :remember_token_expires_at
		remove_column :users, :confirmation_token
		remove_column :users, :confirmed_at
		remove_column :users, :reset_password_token
		remove_column :users, :updated_by
		remove_column :users, :confirmation_sent_at
		remove_column :users, :remember_created_at
		remove_column :users, :reset_password_sent_at
		remove_column :users, :uid
	end
end
