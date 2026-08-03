class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assigned_by, null: false, foreign_key: { to_table: :users }
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :gmv_meta, null: false, default: 0
      t.decimal :income_pct, null: false, default: 0.15
      t.jsonb :okr_gestion, null: false, default: []
      t.jsonb :okr_asistencia, null: false, default: []
      t.text :comentarios

      t.timestamps
    end

    add_index :goals, [ :user_id, :year, :month ], unique: true
  end
end
