# No es un ActiveRecord: cruza Goal + OneOnOneEntry + ClienteArchivo por KAM
# para armar el comparativo de "Insights Equipo" (no hay una tabla propia,
# solo se combinan datos que ya existen en los otros módulos).
class InsightEquipo
  DESTACADOS = [
    { key: :cumplimiento_gmv, label: "🏆 Mayor cumplimiento de GMV", tipo: :pct },
    { key: :pct_utilidad, label: "💰 Mayor % de utilidad", tipo: :pct },
    { key: :tasa_conversion, label: "🎯 Mayor tasa de conversión", tipo: :pct },
    { key: :clientes_nuevos, label: "🆕 Más clientes nuevos", tipo: :entero },
    { key: :crecimiento_gmv_pct, label: "📈 Mayor crecimiento de GMV", tipo: :pct }
  ].freeze

  def self.generar(year, month, kam_ids = nil)
    kams = kam_ids ? User.where(id: kam_ids) : User.where(rol: "KAM")
    filas = kams.order(:nombre).map { |kam| fila_kam(kam, year, month) }
    { filas: filas, destacados: destacados_de(filas) }
  end

  def self.fila_kam(kam, year, month)
    goal = Goal.find_by(user_id: kam.id, year: year, month: month)
    entry = OneOnOneEntry.find_by(user_id: kam.id, year: year, month: month)
    archivo = ClienteArchivo.find_by(user_id: kam.id, year: year, month: month)

    prospeccion = entry&.prospeccion_total
    cierres = entry&.cierres_count

    {
      kam: kam,
      gmv_meta: goal&.gmv_meta&.to_f,
      gmv_real: entry&.gmv_real&.to_f,
      cumplimiento_gmv: entry&.cumplimiento_gmv,
      okr_gestion: entry&.cumplimiento_okr_gestion,
      okr_asistencia: entry&.cumplimiento_okr_asistencia,
      crecimiento_gmv_pct: entry&.crecimiento_gmv_pct,
      prospeccion: prospeccion,
      reuniones: entry&.reuniones_cantidad,
      pipeline_negocios: entry&.pipeline_negocios_total,
      cierres: cierres,
      tasa_conversion: prospeccion.to_f.zero? ? nil : cierres.to_f / prospeccion,
      clientes_activos: archivo&.filas&.size,
      clientes_nuevos: archivo&.clientes_nuevos&.size,
      clientes_perdidos: archivo&.clientes_perdidos&.size,
      pct_utilidad: archivo&.pct_utilidad_total
    }
  end

  # Para cada métrica de DESTACADOS, el KAM con el mejor valor ese mes —
  # la vista arma las tarjetas de "esto se destacó" a partir de esto.
  def self.destacados_de(filas)
    destacados = DESTACADOS.filter_map do |metrica|
      candidatos = filas.select { |f| f[metrica[:key]].present? && f[metrica[:key]].to_f.positive? }
      next if candidatos.empty?
      mejor = candidatos.max_by { |f| f[metrica[:key]] }
      { label: metrica[:label], tipo: metrica[:tipo], kam: mejor[:kam], value: mejor[metrica[:key]] }
    end

    con_perdidos = filas.select { |f| f[:clientes_perdidos].to_i.positive? }
    if con_perdidos.any?
      peor = con_perdidos.max_by { |f| f[:clientes_perdidos] }
      destacados << { label: "⚠️ Más clientes perdidos", tipo: :entero, kam: peor[:kam], value: peor[:clientes_perdidos] }
    end

    destacados
  end
end
