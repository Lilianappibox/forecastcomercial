class ForecastEntriesController < ApplicationController
  before_action :check_permiso

  def index
    if current_user.admin?
      @year = (params[:year] || Date.current.year).to_i
      @month = (params[:month] || Date.current.month).to_i
      @kams = User.where(rol: "KAM").order(:nombre)
      @one_on_ones_by_user = OneOnOneEntry.where(year: @year, month: @month).index_by(&:user_id)
      @goals_by_user = Goal.where(year: @year, month: @month).index_by(&:user_id)
    else
      @entries = OneOnOneEntry.where(user_id: current_user.id).ordered
      @goals_by_period = Goal.where(user_id: current_user.id).index_by { |g| [ g.year, g.month ] }
    end
  end

  private

  def check_permiso
    require_permiso("verForecast")
  end
end
