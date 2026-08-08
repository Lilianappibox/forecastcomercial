class OneOnOnesController < ApplicationController
  before_action :check_permiso
  before_action :set_entry, only: [ :show, :edit, :update ]

  def index
    if current_user.admin?
      @kams = User.where(rol: "KAM").order(:nombre)
      @entries_by_kam = OneOnOneEntry.where(user_id: @kams.map(&:id)).group_by(&:user_id)
    else
      @entries = OneOnOneEntry.where(user_id: current_user.id).ordered
    end
  end

  def entrar
    user_id = current_user.admin? ? params[:user_id] : current_user.id
    year = params[:year] || Date.current.year
    month = params[:month] || Date.current.month
    entry = OneOnOneEntry.find_or_create_by!(user_id: user_id, year: year, month: month)
    redirect_to edit_one_on_one_path(entry)
  end

  def show
    redirect_to edit_one_on_one_path(@entry)
  end

  def edit
  end

  def update
    if @entry.update(entry_params)
      redirect_to edit_one_on_one_path(@entry), notice: "✓ 1:1 guardado — #{mes_nombre(@entry.month)} #{@entry.year}"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def check_permiso
    require_permiso("ver1a1")
  end

  def set_entry
    @entry = OneOnOneEntry.find(params[:id])
    unless current_user.admin? || @entry.user_id == current_user.id
      redirect_to one_on_ones_path, alert: "No puedes ver el 1:1 de otro KAM."
    end
  end

  def entry_params
    attrs = params.require(:one_on_one_entry).permit(
      :data, :puntos_fuertes, :puntos_mejora, :okr_gestion_real, :okr_asistencia_real
    )
    attrs[:data] = parse_json(attrs[:data], {}) if attrs.key?(:data)
    attrs[:okr_gestion_real] = parse_json(attrs[:okr_gestion_real], []) if attrs.key?(:okr_gestion_real)
    attrs[:okr_asistencia_real] = parse_json(attrs[:okr_asistencia_real], []) if attrs.key?(:okr_asistencia_real)
    attrs
  end

  def parse_json(raw, fallback)
    raw.is_a?(String) ? (JSON.parse(raw) rescue fallback) : raw
  end

  def mes_nombre(numero)
    ForecastHelper::MESES[numero.to_i - 1]
  end
end
