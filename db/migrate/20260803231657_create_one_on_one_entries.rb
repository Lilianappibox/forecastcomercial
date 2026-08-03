class CreateOneOnOneEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :one_on_one_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.jsonb :data, null: false, default: {}
      t.text :puntos_fuertes
      t.text :puntos_mejora

      t.timestamps
    end

    add_index :one_on_one_entries, [ :user_id, :year, :month ], unique: true
  end
end
