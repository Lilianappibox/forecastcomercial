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

  def prospeccion_total
    (seccion(:prospeccion) || {}).values.compact.sum { |v| v.to_f }
  end

  def reuniones_cantidad
    (seccion(:reuniones) || {})["cantidad"].to_f
  end

  def pipeline_negocios_total
    s = seccion(:pipeline) || {}
    %w[negocios_mkt negocios_referidos negocios_propios].sum { |k| s[k].to_f }
  end

  def pipeline_valor_total
    s = seccion(:pipeline) || {}
    %w[valor_mkt valor_referidos valor_propios].sum { |k| s[k].to_f }
  end

  def cierres_count
    (seccion(:cierres) || []).size
  end

  def cierres_gmv_total
    (seccion(:cierres) || []).sum { |c| c["gmv"].to_f }
  end

  # Arma la fila mes a mes (Ene..Dic) + el total/promedio anual, usada tanto por la
  # tabla de acumulado como por las gráficas de evolución en app/views/one_on_ones/evolucion.
  def self.resumen_anual(user_id, year)
    entries_by_month = where(user_id: user_id, year: year).index_by(&:month)
    goals_by_month = Goal.where(user_id: user_id, year: year).index_by(&:month)

    meses = (1..12).map do |m|
      entry = entries_by_month[m]
      goal = goals_by_month[m]
      {
        mes: m,
        meta_gmv: goal&.gmv_meta&.to_f,
        gmv_real: entry&.gmv_real&.to_f,
        cumplimiento_gmv: entry&.cumplimiento_gmv,
        okr_gestion: entry&.cumplimiento_okr_gestion,
        okr_asistencia: entry&.cumplimiento_okr_asistencia,
        prospeccion: entry&.prospeccion_total,
        prospeccion_propios: entry&.seccion(:prospeccion)&.dig("propios")&.to_f,
        prospeccion_referidos: entry&.seccion(:prospeccion)&.dig("referidos")&.to_f,
        prospeccion_mkt: entry&.seccion(:prospeccion)&.dig("mkt")&.to_f,
        reuniones: entry&.reuniones_cantidad,
        pipeline_negocios: entry&.pipeline_negocios_total,
        pipeline_valor: entry&.pipeline_valor_total,
        pipeline_valor_mkt: entry&.seccion(:pipeline)&.dig("valor_mkt")&.to_f,
        pipeline_valor_referidos: entry&.seccion(:pipeline)&.dig("valor_referidos")&.to_f,
        pipeline_valor_propios: entry&.seccion(:pipeline)&.dig("valor_propios")&.to_f,
        cierres_count: entry&.cierres_count,
        cierres_gmv: entry&.cierres_gmv_total
      }
    end

    { meses: meses, total: combinar_filas(meses) }
  end

  # Mismo resumen que resumen_anual, pero sumando todos los KAM del equipo
  # (o el subconjunto de kam_ids dado) — para el resumen agregado del home.
  def self.resumen_equipo(year, kam_ids = nil)
    kam_ids ||= User.where(rol: "KAM").pluck(:id)
    resumenes = kam_ids.map { |uid| resumen_anual(uid, year) }

    meses = (1..12).map do |m|
      combinar_filas(resumenes.map { |r| r[:meses][m - 1] }).merge(mes: m)
    end

    { meses: meses, total: combinar_filas(meses) }
  end

  # Combina varias filas (de distintos meses o distintos KAM, misma forma que
  # resumen_anual#meses) en una sola: suma montos/conteos y promedia los % de OKR
  # ya ponderados (cumplimiento_gmv se recalcula como Σreal/Σmeta, no como promedio
  # de razones, para no distorsionar el resultado con meses/KAM sin meta).
  def self.combinar_filas(filas)
    meta_gmv = filas.sum { |f| f[:meta_gmv].to_f }
    gmv_real = filas.sum { |f| f[:gmv_real].to_f }

    {
      meta_gmv: meta_gmv,
      gmv_real: gmv_real,
      cumplimiento_gmv: meta_gmv.zero? ? nil : gmv_real / meta_gmv,
      okr_gestion: promedio(filas.map { |f| f[:okr_gestion] }),
      okr_asistencia: promedio(filas.map { |f| f[:okr_asistencia] }),
      prospeccion: filas.sum { |f| f[:prospeccion].to_f },
      prospeccion_propios: filas.sum { |f| f[:prospeccion_propios].to_f },
      prospeccion_referidos: filas.sum { |f| f[:prospeccion_referidos].to_f },
      prospeccion_mkt: filas.sum { |f| f[:prospeccion_mkt].to_f },
      reuniones: filas.sum { |f| f[:reuniones].to_f },
      pipeline_negocios: filas.sum { |f| f[:pipeline_negocios].to_f },
      pipeline_valor: filas.sum { |f| f[:pipeline_valor].to_f },
      pipeline_valor_mkt: filas.sum { |f| f[:pipeline_valor_mkt].to_f },
      pipeline_valor_referidos: filas.sum { |f| f[:pipeline_valor_referidos].to_f },
      pipeline_valor_propios: filas.sum { |f| f[:pipeline_valor_propios].to_f },
      cierres_count: filas.sum { |f| f[:cierres_count].to_i },
      cierres_gmv: filas.sum { |f| f[:cierres_gmv].to_f }
    }
  end

  def self.promedio(vals)
    vals.compact.presence&.then { |v| v.sum / v.size }
  end
end
