class RemoveOauth < ActiveRecord::Migration
  def change
  	remove_column :users, :provider
  	drop_table :client_applications
  	drop_table :oauth_nonces
  	drop_table :oauth_tokens
  end
end
