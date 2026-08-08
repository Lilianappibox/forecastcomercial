class ForecastEntriesController < ApplicationController
  before_action :check_permiso
  before_action :set_entry, only: [ :edit, :update ]

  def index
    if current_user.admin?
      @year = (params[:year] || Date.current.year).to_i
      @month = (params[:month] || Date.current.month).to_i
      @kams = User.where(rol: "KAM").order(:nombre)
      @entries_by_user = ForecastEntry.where(year: @year, month: @month).index_by(&:user_id)
      @goals_by_user = Goal.where(year: @year, month: @month).index_by(&:user_id)
    else
      @entries = ForecastEntry.where(user_id: current_user.id).ordered
      @goals_by_period = Goal.where(user_id: current_user.id).index_by { |g| [ g.year, g.month ] }
    end
  end

  def new
    @entry = ForecastEntry.new(user_id: target_user_id, year: params[:year], month: params[:month])
    @goal = Goal.find_by(user_id: @entry.user_id, year: @entry.year, month: @entry.month)
  end

  def create
    @entry = ForecastEntry.new(entry_params)
    @entry.user_id = target_user_id unless current_user.admin?
    if @entry.save
      redirect_to forecast_entries_path, notice: "✓ Forecast guardado — #{mes_nombre(@entry.month)} #{@entry.year}"
    else
      @goal = Goal.find_by(user_id: @entry.user_id, year: @entry.year, month: @entry.month)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @goal = Goal.find_by(user_id: @entry.user_id, year: @entry.year, month: @entry.month)
  end

  def update
    if @entry.update(entry_params.except(:user_id))
      redirect_to forecast_entries_path, notice: "✓ Forecast actualizado"
    else
      @goal = Goal.find_by(user_id: @entry.user_id, year: @entry.year, month: @entry.month)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def check_permiso
    require_permiso("verForecast")
  end

  def set_entry
    @entry = ForecastEntry.find(params[:id])
    unless current_user.admin? || @entry.user_id == current_user.id
      redirect_to forecast_entries_path, alert: "No puedes editar el forecast de otro KAM."
    end
  end

  def target_user_id
    current_user.admin? ? params[:user_id] : current_user.id
  end

  def entry_params
    params.require(:forecast_entry).permit(:user_id, :year, :month, :gmv_real, :notas)
  end

  def mes_nombre(numero)
    ForecastHelper::MESES[numero.to_i - 1]
  end
end
