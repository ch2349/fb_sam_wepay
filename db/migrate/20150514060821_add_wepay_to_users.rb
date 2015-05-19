class AddWepayToUsers < ActiveRecord::Migration
  def change
    add_column :users, :wepay_access_token, :string
    add_column :users, :donate_amount, :integer
    add_column :users, :wepay_account_id, :integer
  end
end
