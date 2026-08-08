class OneOnOneEntry < ApplicationRecord
  belongs_to :user

  SECCIONES = %i[prospeccion reuniones pipeline cierres clientes_gestion alertas plan_accion].freeze

  validates :year, :month, presence: true
  validates :month, inclusion: { in: 1..12 }
  validates :gmv_real, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: [ :year, :month ] }

  scope :for_period, ->(year, month) { where(year: year, month: month) }
  scope :ordered, -> { order(year: :asc, month: :asc) }

  def seccion(nombre)
    (data || {})[nombre.to_s]
  end

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
    OneOnOneEntry.find_by(user_id: user_id, year: y, month: m)
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

  # Cumplimiento OKR ponderado: cruza lo diligenciado (okr_gestion_real/okr_asistencia_real)
  # con Goal#okr_gestion/okr_asistencia (meta y participación) por "nombre".
  def cumplimiento_okr_gestion
    return nil if goal&.okr_gestion.blank?
    goal.total_ponderado(:gestion, okr_gestion_real)
  end

  def cumplimiento_okr_asistencia
    return nil if goal&.okr_asistencia.blank?
    goal.total_ponderado(:asistencia, okr_asistencia_real)
  end
end
