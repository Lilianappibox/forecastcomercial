module ForecastHelper
  MESES = %w[Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre].freeze

  def mes_nombre(numero)
    MESES[numero.to_i - 1] || "?"
  end

  def fmt_pct(value)
    return "—" if value.nil?
    "#{(value.to_f * 100).round(1)}%"
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
end
