class DashboardController < ApplicationController
  def index
    @year = Date.current.year
    @month = Date.current.month

    if current_user.admin?
      @kams = User.where(rol: "KAM")
      @total_kams = @kams.count
      @goals_count = Goal.where(year: @year, month: @month, user_id: @kams.select(:id)).count
      @one_on_ones_count = OneOnOneEntry.where(year: @year, month: @month, user_id: @kams.select(:id)).count
      @gmv_diligenciado_count = OneOnOneEntry.where(year: @year, month: @month, user_id: @kams.select(:id)).where("gmv_real > 0").count
      @usuarios_activos = User.where(activo: true).count
      @kams_con_clientes_count = Cliente.where(user_id: @kams.select(:id)).distinct.count(:user_id)

      @evo_year = (params[:evo_year] || @year).to_i
      @evo_month = params[:evo_month].presence
      resumen_equipo = OneOnOneEntry.resumen_equipo(@evo_year, @kams.pluck(:id))
      @evo_meses = resumen_equipo[:meses]
      @evo_resumen = @evo_month.present? ? @evo_meses.find { |m| m[:mes] == @evo_month.to_i } : resumen_equipo[:total]
    else
      @mi_goal = Goal.find_by(user_id: current_user.id, year: @year, month: @month)
      @mi_one_on_one = OneOnOneEntry.find_by(user_id: current_user.id, year: @year, month: @month)
      @mis_clientes_count = Cliente.where(user_id: current_user.id).count
    end
  end
end
