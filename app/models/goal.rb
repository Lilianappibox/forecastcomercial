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

  def forecast_entry
    ForecastEntry.find_by(user_id: user_id, year: year, month: month)
  end
end
