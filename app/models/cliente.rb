class Cliente < ApplicationRecord
  belongs_to :user

  validates :nombre, presence: true

  def self.meses_disponibles(clientes)
    clientes.flat_map { |c| (c.gmv_mensual || []).map { |g| g["mes"] } }.uniq.compact.sort
  end

  def gmv_ordenado
    (gmv_mensual || []).sort_by { |g| g["mes"].to_s }
  end

  def gmv_de(mes)
    (gmv_mensual || []).find { |g| g["mes"] == mes }&.dig("valor")
  end

  def gmv_total
    (gmv_mensual || []).sum { |g| g["valor"].to_f }
  end
end
