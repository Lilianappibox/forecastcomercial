class ClienteArchivo < ApplicationRecord
  belongs_to :user

  COLUMNAS_REQUERIDAS = %w[Month GroupByDetail GMV].freeze

  CATEGORIAS = [
    { id: "big_sale", label: "Big Sale" },
    { id: "growth", label: "Growth" },
    { id: "pyme", label: "Pyme" },
    { id: "vaiven", label: "Vaivén" }
  ].freeze

  validates :year, :month, presence: true
  validates :month, inclusion: { in: 1..12 }
  validates :user_id, uniqueness: { scope: [ :year, :month ] }

  scope :ordered, -> { order(year: :desc, month: :desc) }

  def self.categoria_de(gmv)
    valor = gmv.to_f
    return "big_sale" if valor > 10_000_000
    return "growth" if valor > 5_000_000
    return "pyme" if valor > 2_000_000
    "vaiven"
  end

  def total_gmv
    (filas || []).sum { |f| f["gmv"].to_f }
  end

  def total_utilidad
    (filas || []).sum { |f| f["utilidad"].to_f }
  end

  def pct_utilidad_total
    total_gmv.zero? ? nil : total_utilidad / total_gmv
  end

  # Junta cada fila con su % de utilidad, categoría y comparación contra el mes
  # anterior (mismo KAM) — es la fuente única para la tabla y el resumen de
  # categorías en la vista de detalle.
  def filas_con_analisis
    gmv_anterior_por_cliente = (mes_anterior&.filas || []).index_by { |f| f["cliente"] }

    (filas || []).map do |f|
      gmv = f["gmv"].to_f
      utilidad = f["utilidad"].to_f
      previo = gmv_anterior_por_cliente[f["cliente"]]
      gmv_previo = previo && previo["gmv"].to_f

      {
        cliente: f["cliente"],
        gmv: gmv,
        utilidad: utilidad,
        pct_utilidad: gmv.zero? ? nil : utilidad / gmv,
        categoria: self.class.categoria_de(gmv),
        gmv_anterior: gmv_previo,
        crecimiento: gmv_previo.nil? ? nil : gmv - gmv_previo,
        crecimiento_pct: gmv_previo.nil? || gmv_previo.zero? ? nil : (gmv - gmv_previo) / gmv_previo
      }
    end.sort_by { |f| -f[:gmv] }
  end

  def self.categorias_resumen(filas_con_analisis)
    CATEGORIAS.map do |cat|
      items = filas_con_analisis.select { |f| f[:categoria] == cat[:id] }
      cat.merge(count: items.size, gmv_total: items.sum { |f| f[:gmv] })
    end
  end

  def mes_anterior
    y, m = month == 1 ? [ year - 1, 12 ] : [ year, month - 1 ]
    ClienteArchivo.find_by(user_id: user_id, year: y, month: m)
  end

  # Suma el GMV de cada cliente ese mes entre TODOS los KAM (no solo el actual) —
  # es lo que permite detectar nuevos/perdidos "independientemente del KAM".
  def self.mapa_gmv(year, month)
    mapa = Hash.new(0.0)
    where(year: year, month: month).find_each do |archivo|
      (archivo.filas || []).each { |f| mapa[f["cliente"]] += f["gmv"].to_f }
    end
    mapa
  end

  def self.restar_meses(year, month, cantidad)
    total = (year * 12 + (month - 1)) - cantidad
    [ total / 12, (total % 12) + 1 ]
  end

  # Clientes que facturan este mes pero no tuvieron GMV (con ningún KAM) en
  # ninguno de los 3 meses inmediatamente anteriores.
  def clientes_nuevos
    mapas_previos = (1..3).map { |i| self.class.mapa_gmv(*self.class.restar_meses(year, month, i)) }
    (filas || []).select { |f| f["gmv"].to_f > 0 }.map { |f| f["cliente"] }.uniq.select do |cliente|
      mapas_previos.all? { |mapa| mapa[cliente].to_f.zero? }
    end
  end

  # Clientes que tenían GMV el mes inmediatamente anterior (con cualquier KAM)
  # pero no facturan nada este mes (con ningún KAM).
  def clientes_perdidos
    y, m = self.class.restar_meses(year, month, 1)
    mapa_anterior = self.class.mapa_gmv(y, m)
    mapa_actual = self.class.mapa_gmv(year, month)
    mapa_anterior.select { |cliente, gmv| gmv > 0 && mapa_actual[cliente].to_f.zero? }.keys
  end

  # Lee el archivo .xlsx exportado (columnas Month, GroupByDetail, GMV, Service
  # Income) y arma { year:, month:, filas: } listo para guardar. Si el mismo
  # cliente aparece en varias filas se suman (por si el export viene sin agrupar).
  def self.parse_xlsx(uploaded_file)
    sheet = Roo::Spreadsheet.open(uploaded_file.tempfile.path, extension: :xlsx)
    sheet.default_sheet = sheet.sheets.first
    headers = sheet.row(1).map { |h| h.to_s.strip }

    idx = {
      mes: headers.index("Month"),
      cliente: headers.index("GroupByDetail"),
      gmv: headers.index("GMV"),
      utilidad: headers.index("Service Income")
    }
    faltantes = COLUMNAS_REQUERIDAS.select { |c| headers.index(c).nil? }
    return { error: "Al archivo le faltan las columnas: #{faltantes.join(', ')}." } if faltantes.any?

    filas_por_cliente = Hash.new { |h, k| h[k] = { "cliente" => k, "gmv" => 0.0, "utilidad" => 0.0 } }
    fecha = nil

    (2..sheet.last_row).each do |i|
      row = sheet.row(i)
      cliente = row[idx[:cliente]]
      next if cliente.blank?

      fecha ||= row[idx[:mes]]
      filas_por_cliente[cliente]["gmv"] += row[idx[:gmv]].to_f
      filas_por_cliente[cliente]["utilidad"] += idx[:utilidad] ? row[idx[:utilidad]].to_f : 0.0
    end

    return { error: "El archivo no tiene filas de datos." } if filas_por_cliente.empty?

    fecha = Date.parse(fecha.to_s) unless fecha.is_a?(Date) || fecha.is_a?(Time)
    { year: fecha.year, month: fecha.month, filas: filas_por_cliente.values }
  rescue => e
    { error: "No se pudo leer el archivo: #{e.message}" }
  end
end
