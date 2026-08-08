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

  def one_on_one_entry
    OneOnOneEntry.find_by(user_id: user_id, year: year, month: month)
  end

  # Cruza los OKR asignados (meta, participación) con lo "realizado" que el KAM
  # diligencia en su 1:1 (OneOnOneEntry#okr_gestion_real / #okr_asistencia_real),
  # por "nombre". Devuelve un array de filas listas para tabla: nombre, participación,
  # meta, realizado, cumplimiento (avance del ítem, tope 100%) y ponderado (lo que
  # ese ítem aporta al total: cumplimiento × participación — la suma de "ponderado"
  # de todas las filas da el "Total cumplimiento OKR").
  def okr_rows(tipo, realizados)
    items = tipo == :gestion ? okr_gestion : okr_asistencia
    realizados_por_nombre = (realizados || []).index_by { |r| r["nombre"] }

    items.map do |item|
      meta_valor = item["meta"].to_f
      realizado_item = realizados_por_nombre[item["nombre"]]
      realizado_valor = realizado_item&.dig("realizado")
      participacion = item["participacion"].to_f
      cumplimiento = meta_valor.zero? || realizado_valor.nil? ? nil : [ realizado_valor.to_f / meta_valor, 1.0 ].min

      {
        nombre: item["nombre"],
        participacion: participacion,
        meta: item["meta"],
        unidad: item["unidad"],
        realizado: realizado_valor,
        cumplimiento: cumplimiento,
        ponderado: cumplimiento.nil? ? nil : cumplimiento * participacion
      }
    end
  end

  def total_ponderado(tipo, realizados)
    okr_rows(tipo, realizados).sum { |row| row[:ponderado].to_f }
  end
end
