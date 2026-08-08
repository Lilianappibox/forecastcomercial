class MoveOkrRealToOneOnOne < ActiveRecord::Migration[8.1]
  def change
    remove_column :forecast_entries, :okr_gestion_real, :jsonb, null: false, default: []
    remove_column :forecast_entries, :okr_asistencia_real, :jsonb, null: false, default: []

    add_column :one_on_one_entries, :okr_gestion_real, :jsonb, null: false, default: []
    add_column :one_on_one_entries, :okr_asistencia_real, :jsonb, null: false, default: []
  end
end
