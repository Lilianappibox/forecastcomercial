class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :nombre, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :rol, null: false
      t.boolean :activo, null: false, default: true
      t.string :cargo
      t.string :celular
      t.jsonb :permisos_custom, null: false, default: {}
      t.string :password_reset_token
      t.datetime :password_reset_sent_at
      t.string :plain_password

      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :password_reset_token, unique: true, where: "(password_reset_token IS NOT NULL)"
  end
end
