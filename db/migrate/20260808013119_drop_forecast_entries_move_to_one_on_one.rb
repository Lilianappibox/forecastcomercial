class DropForecastEntriesMoveToOneOnOne < ActiveRecord::Migration[8.1]
  def change
    drop_table :forecast_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :year, null: false
      t.integer :month, null: false
      t.decimal :gmv_real, null: false, default: 0
      t.text :notas
      t.timestamps
      t.index [ :user_id, :year, :month ], unique: true
    end

    add_column :one_on_one_entries, :gmv_real, :decimal, null: false, default: 0
    add_column :one_on_one_entries, :notas, :text
  end
end
