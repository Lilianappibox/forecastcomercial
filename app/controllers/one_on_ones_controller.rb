class OneOnOnesController < ApplicationController
  before_action :check_permiso
  before_action :set_entry, only: [ :show, :edit, :update, :guardar_en_historial, :reuniones_calendar ]

  def index
    if current_user.admin?
      @kams = User.where(rol: "KAM").order(:nombre)
      @entries_by_kam = OneOnOneEntry.where(user_id: @kams.map(&:id)).group_by(&:user_id)
    else
      @entries = OneOnOneEntry.where(user_id: current_user.id).ordered
    end
  end

  def evolucion
    @kams = User.where(rol: "KAM").order(:nombre) if current_user.admin?
    @kam_id = current_user.admin? ? (params[:kam_id].presence&.to_i || @kams.first&.id) : current_user.id
    @kam = User.find_by(id: @kam_id)
    @year = (params[:year] || Date.current.year).to_i
    resumen = OneOnOneEntry.resumen_anual(@kam_id, @year)
    @meses_data = resumen[:meses]
    @totales = resumen[:total]
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

  # Guarda lo diligenciado en la hoja bajo el mes/año que elija el KAM en el
  # diálogo de confirmación, en vez del mes del registro que se estaba
  # editando — permite archivar los mismos resultados en el mes que
  # corresponda sin depender de por cuál entrada se haya entrado a la hoja.
  def guardar_en_historial
    target_year = params[:target_year].presence&.to_i
    target_month = params[:target_month].presence&.to_i

    if target_year.blank? || target_month.blank? || !(1..12).cover?(target_month)
      redirect_to edit_one_on_one_path(@entry), alert: "Selecciona un mes y año válidos." and return
    end

    destino = OneOnOneEntry.find_or_initialize_by(user_id: @entry.user_id, year: target_year, month: target_month)
    if destino.update(entry_params)
      redirect_to one_on_ones_path, notice: "✓ Guardado en el historial — #{mes_nombre(target_month)} #{target_year}"
    else
      redirect_to edit_one_on_one_path(@entry), alert: destino.errors.full_messages.to_sentence
    end
  end

  # Trae las reuniones del calendario de Google del propio KAM para el mes de
  # esta hoja — solo el dueño del calendario puede consultarlo (el admin no
  # tiene el token OAuth de otro KAM).
  def reuniones_calendar
    unless @entry.user_id == current_user.id && current_user.google_conectado?
      head :forbidden and return
    end

    service = current_user.google_calendar_service
    inicio = Date.new(@entry.year, @entry.month, 1).beginning_of_day
    fin = inicio.end_of_month.end_of_day
    respuesta = service.list_events(
      "primary", time_min: inicio.rfc3339, time_max: fin.rfc3339,
      single_events: true, order_by: "startTime", max_results: 100
    )
    current_user.sincronizar_token_google!(service)

    eventos = (respuesta.items || []).select { |e| e.summary.present? }.map do |e|
      inicio_evento = e.start&.date_time || e.start&.date
      {
        titulo: e.summary,
        fecha: inicio_evento&.strftime("%d/%m %H:%M") || "",
        invitados: (e.attendees || []).filter_map(&:email).join(", ")
      }
    end

    render partial: "one_on_ones/eventos_calendar", locals: { eventos: eventos }
  rescue Signet::AuthorizationError, Google::Apis::AuthorizationError
    render html: '<p class="text-xs text-red-600">Tu conexión con Google expiró — vuelve a conectar tu calendario.</p>'.html_safe
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
      :data, :puntos_fuertes, :puntos_mejora, :okr_gestion_real, :okr_asistencia_real,
      :gmv_real, :notas
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
