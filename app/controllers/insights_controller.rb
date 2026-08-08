class InsightsController < ApplicationController
  before_action :check_permiso

  def index
    @year = (params[:year] || Date.current.year).to_i
    @month = (params[:month] || Date.current.month).to_i
    resultado = InsightEquipo.generar(@year, @month)
    @filas = resultado[:filas]
    @destacados = resultado[:destacados]
  end

  private

  def check_permiso
    require_permiso("verInsights")
  end
end
