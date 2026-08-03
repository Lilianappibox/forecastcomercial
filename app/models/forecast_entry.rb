class ForecastEntry < ApplicationRecord
  belongs_to :user

  validates :year, :month, presence: true
  validates :month, inclusion: { in: 1..12 }
  validates :gmv_real, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: [ :year, :month ] }

  scope :for_period, ->(year, month) { where(year: year, month: month) }
  scope :ordered, -> { order(year: :asc, month: :asc) }

  def goal
    @goal ||= Goal.find_by(user_id: user_id, year: year, month: month)
  end

  def cumplimiento_gmv
    meta = goal&.gmv_meta.to_f
    return nil if meta.zero?
    gmv_real.to_f / meta
  end

  def utilidad_alcanzada
    gmv_real.to_f * (goal&.income_pct.to_f.nonzero? || 0.15)
  end

  def mes_anterior
    y, m = month == 1 ? [ year - 1, 12 ] : [ year, month - 1 ]
    ForecastEntry.find_by(user_id: user_id, year: y, month: m)
  end

  def crecimiento_gmv
    anterior = mes_anterior&.gmv_real.to_f
    return nil if anterior.zero?
    gmv_real.to_f - anterior
  end

  def crecimiento_gmv_pct
    anterior = mes_anterior&.gmv_real.to_f
    return nil if anterior.nil? || anterior.zero?
    (gmv_real.to_f - anterior) / anterior
  end

  # Cumplimiento OKR ponderado: cruza okr_gestion_real (lo diligenciado por el KAM)
  # con Goal#okr_gestion (participación y meta asignados por el líder) por "nombre".
  def cumplimiento_okr_gestion
    ponderado_de(okr_gestion_real, goal&.okr_gestion)
  end

  def cumplimiento_okr_asistencia
    ponderado_de(okr_asistencia_real, goal&.okr_asistencia)
  end

  private

  def ponderado_de(realizados, metas)
    return nil if metas.blank?
    metas_por_nombre = metas.index_by { |item| item["nombre"] }
    realizados_por_nombre = (realizados || []).index_by { |item| item["nombre"] }

    metas.sum do |item|
      nombre = item["nombre"]
      participacion = item["participacion"].to_f
      meta_valor = item["meta"].to_f
      realizado_valor = realizados_por_nombre[nombre]&.dig("realizado").to_f
      next 0 if meta_valor.zero?

      participacion * (realizado_valor / meta_valor)
    end
  end
end
