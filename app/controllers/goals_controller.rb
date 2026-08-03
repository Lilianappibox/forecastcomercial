class GoalsController < ApplicationController
  before_action :check_permiso
  before_action :set_goal, only: [ :show, :edit, :update, :destroy, :image ]

  def index
    @year = (params[:year] || Date.current.year).to_i
    @month = params[:month].presence&.to_i
    @goals = Goal.includes(:user).where(year: @year)
    @goals = @goals.where(month: @month) if @month
    @goals = @goals.joins(:user).order("users.nombre, goals.month")
    @kams = User.where(rol: "KAM").order(:nombre)
  end

  def show
  end

  def new
    @goal = Goal.new(year: params[:year] || Date.current.year, month: params[:month] || Date.current.month)
    @kams = User.where(rol: "KAM").order(:nombre)
  end

  def create
    @goal = Goal.new(goal_params)
    @goal.assigned_by = current_user
    if @goal.save
      redirect_to goals_path, notice: "✓ Meta asignada a #{@goal.user.nombre} — #{mes_nombre(@goal.month)} #{@goal.year}"
    else
      @kams = User.where(rol: "KAM").order(:nombre)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @kams = User.where(rol: "KAM").order(:nombre)
  end

  def update
    if @goal.update(goal_params.except(:user_id))
      redirect_to goals_path, notice: "✓ Meta actualizada"
    else
      @kams = User.where(rol: "KAM").order(:nombre)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @goal.destroy
    redirect_to goals_path, notice: "🗑️ Meta eliminada"
  end

  def image
  end

  private

  def check_permiso
    require_permiso("gestionarMetas")
  end

  def set_goal
    @goal = Goal.find(params[:id])
  end

  def goal_params
    attrs = params.require(:goal).permit(
      :user_id, :year, :month, :gmv_meta, :income_pct, :comentarios,
      :okr_gestion, :okr_asistencia
    )
    attrs[:okr_gestion] = parse_json(attrs[:okr_gestion]) if attrs.key?(:okr_gestion)
    attrs[:okr_asistencia] = parse_json(attrs[:okr_asistencia]) if attrs.key?(:okr_asistencia)
    attrs
  end

  def parse_json(raw)
    raw.is_a?(String) ? (JSON.parse(raw) rescue []) : raw
  end

  def mes_nombre(numero)
    ForecastHelper::MESES[numero.to_i - 1]
  end
end
