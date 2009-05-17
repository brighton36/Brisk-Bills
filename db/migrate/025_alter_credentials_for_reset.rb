class AlterCredentialsForReset < ActiveRecord::Migration
  # This adds/removs support for restting passwords on columns
  def self.up
    add_column :credentials, :reset_password_token, :string, :default => nil, :null => true
  end
  
  def self.down
    remove_column :credentials, :reset_password_token
  end
  
end