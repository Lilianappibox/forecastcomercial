class OneOnOneEntry < ApplicationRecord
  belongs_to :user

  SECCIONES = %i[prospeccion reuniones pipeline cierres clientes_gestion alertas plan_accion].freeze

  validates :year, :month, presence: true
  validates :month, inclusion: { in: 1..12 }
  validates :user_id, uniqueness: { scope: [ :year, :month ] }

  scope :for_period, ->(year, month) { where(year: year, month: month) }
  scope :ordered, -> { order(year: :desc, month: :desc) }

  def seccion(nombre)
    (data || {})[nombre.to_s]
  end
end
