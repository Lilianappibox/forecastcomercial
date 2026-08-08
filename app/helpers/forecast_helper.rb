module ForecastHelper
  MESES = %w[Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre].freeze

  def mes_nombre(numero)
    MESES[numero.to_i - 1] || "?"
  end

  # Formatea una clave "YYYY-MM" (la que produce <input type="month">) como "Ene 2026".
  def mes_corto(clave)
    year, month = clave.to_s.split("-")
    return clave.to_s if year.blank? || month.blank?
    "#{mes_nombre(month)[0, 3]} #{year}"
  end

  def fmt_pct(value)
    return "—" if value.nil?
    "#{(value.to_f * 100).round(1)}%"
  end

  # Formatea un valor de OKR (meta o realizado) según su unidad: $ / % / cantidad plana.
  def fmt_meta(valor, unidad)
    return "—" if valor.nil? || valor == ""
    case unidad
    when "monto" then fmt(valor)
    when "porcentaje" then "#{valor}%"
    else valor.to_s
    end
  end

  CATEGORIA_BADGE = {
    "big_sale" => "bg-amber-100 text-amber-700",
    "growth" => "bg-green-100 text-green-700",
    "pyme" => "bg-blue-100 text-blue-700",
    "vaiven" => "bg-gray-100 text-gray-500"
  }.freeze

  def categoria_badge_class(id)
    CATEGORIA_BADGE[id] || "bg-gray-100 text-gray-500"
  end

  def pct_badge_class(value)
    return "bg-gray-100 text-gray-500" if value.nil?
    if value >= 1
      "bg-green-100 text-green-700"
    elsif value >= 0.8
      "bg-yellow-100 text-yellow-700"
    else
      "bg-red-100 text-red-700"
    end
  end

  # Para valores con signo (crecimiento $/%): verde si sube, rojo si baja.
  def signo_badge_class(value)
    return "bg-gray-100 text-gray-500" if value.nil?
    value >= 0 ? "bg-green-100 text-green-700" : "bg-red-100 text-red-700"
  end

  def fmt_signed_pct(value)
    return "—" if value.nil?
    signo = value >= 0 ? "+" : ""
    "#{signo}#{(value.to_f * 100).round(1)}%"
  end
end
