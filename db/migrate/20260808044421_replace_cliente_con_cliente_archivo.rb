class ReplaceClienteConClienteArchivo < ActiveRecord::Migration[8.1]
  def change
    drop_table :clientes, if_exists: true

    create_table :cliente_archivos do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.string :nombre_archivo
      t.jsonb :filas, null: false, default: []

      t.timestamps
    end
    add_index :cliente_archivos, [ :user_id, :year, :month ], unique: true
  end
end
