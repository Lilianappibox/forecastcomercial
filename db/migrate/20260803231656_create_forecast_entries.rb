class CreateForecastEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :forecast_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :gmv_real, null: false, default: 0
      t.jsonb :okr_gestion_real, null: false, default: []
      t.jsonb :okr_asistencia_real, null: false, default: []
      t.text :notas

      t.timestamps
    end

    add_index :forecast_entries, [ :user_id, :year, :month ], unique: true
  end
end
