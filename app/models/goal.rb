class Goal < ApplicationRecord
  belongs_to :user
  belongs_to :assigned_by, class_name: "User"

  validates :year, :month, presence: true
  validates :month, inclusion: { in: 1..12 }
  validates :gmv_meta, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: [ :year, :month ] }

  scope :for_period, ->(year, month) { where(year: year, month: month) }
  scope :ordered, -> { order(year: :desc, month: :desc) }

  def income_esperado
    gmv_meta.to_f * income_pct.to_f
  end

  def forecast_entry
    ForecastEntry.find_by(user_id: user_id, year: year, month: month)
  end

  def one_on_one_entry
    OneOnOneEntry.find_by(user_id: user_id, year: year, month: month)
  end

  # Cruza los OKR asignados (meta, participación) con lo "realizado" que el KAM
  # diligencia en su 1:1 (OneOnOneEntry#okr_gestion_real / #okr_asistencia_real),
  # por "nombre". Devuelve un array de filas listas para tabla: nombre, participación,
  # meta, realizado, cumplimiento.
  def okr_rows(tipo, realizados)
    items = tipo == :gestion ? okr_gestion : okr_asistencia
    realizados_por_nombre = (realizados || []).index_by { |r| r["nombre"] }

    items.map do |item|
      meta_valor = item["meta"].to_f
      realizado_item = realizados_por_nombre[item["nombre"]]
      realizado_valor = realizado_item&.dig("realizado")
      cumplimiento = meta_valor.zero? || realizado_valor.nil? ? nil : realizado_valor.to_f / meta_valor

      {
        nombre: item["nombre"],
        participacion: item["participacion"].to_f,
        meta: item["meta"],
        unidad: item["unidad"],
        realizado: realizado_valor,
        cumplimiento: cumplimiento
      }
    end
  end

  def total_ponderado(tipo, realizados)
    okr_rows(tipo, realizados).sum { |row| row[:cumplimiento].to_f * row[:participacion] }
  end
end
