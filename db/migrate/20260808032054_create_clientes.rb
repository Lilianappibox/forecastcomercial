class CreateClientes < ActiveRecord::Migration[8.1]
  def change
    create_table :clientes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nombre, null: false
      t.jsonb :gmv_mensual, null: false, default: []

      t.timestamps
    end
  end
end
