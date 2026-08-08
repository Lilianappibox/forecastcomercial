class ClienteArchivosController < ApplicationController
  before_action :check_permiso
  before_action :set_kams

  def index
    @kam_id = current_user.admin? ? (params[:kam_id].presence&.to_i || @kams.first&.id) : current_user.id
    @archivos = @kam_id ? ClienteArchivo.where(user_id: @kam_id).ordered : ClienteArchivo.none
    @puede_subir = @kam_id.present? && (current_user.id == @kam_id || current_user.tiene_permiso?("gestionarClientes"))
  end

  def show
    @archivo = ClienteArchivo.find(params[:id])
    authorize_ver!(@archivo.user_id)
    @puede_eliminar = current_user.id == @archivo.user_id || current_user.tiene_permiso?("gestionarClientes")
    @filas = @archivo.filas_con_analisis
    @categorias = ClienteArchivo.categorias_resumen(@filas)
    @nuevos = @archivo.clientes_nuevos
    @perdidos = @archivo.clientes_perdidos
  end

  def create
    kam_id = current_user.admin? ? params[:kam_id].presence&.to_i : current_user.id
    authorize_gestionar!(kam_id)

    if params[:file].blank?
      redirect_to clientes_path(kam_id: kam_id), alert: "Selecciona un archivo para subir." and return
    end

    resultado = ClienteArchivo.parse_xlsx(params[:file])
    if resultado[:error]
      redirect_to clientes_path(kam_id: kam_id), alert: resultado[:error] and return
    end

    archivo = ClienteArchivo.find_or_initialize_by(user_id: kam_id, year: resultado[:year], month: resultado[:month])
    archivo.filas = resultado[:filas]
    archivo.nombre_archivo = params[:file].original_filename

    if archivo.save
      redirect_to cliente_path(archivo), notice: "✓ Archivo cargado — #{mes_nombre(resultado[:month])} #{resultado[:year]}"
    else
      redirect_to clientes_path(kam_id: kam_id), alert: archivo.errors.full_messages.to_sentence
    end
  end

  def destroy
    archivo = ClienteArchivo.find(params[:id])
    authorize_gestionar!(archivo.user_id)
    kam_id = archivo.user_id
    archivo.destroy
    redirect_to clientes_path(kam_id: kam_id), notice: "🗑️ Archivo eliminado"
  end

  private

  def check_permiso
    require_permiso("verClientes")
  end

  def set_kams
    @kams = User.where(rol: "KAM").order(:nombre)
  end

  def authorize_ver!(user_id)
    return if current_user.admin? || current_user.id == user_id
    redirect_to clientes_path, alert: "No puedes ver los clientes de otro KAM."
  end

  def authorize_gestionar!(user_id)
    return if user_id.present? && (current_user.id == user_id || current_user.tiene_permiso?("gestionarClientes"))
    redirect_to clientes_path, alert: "No tienes permiso para esta acción."
  end

  def mes_nombre(numero)
    ForecastHelper::MESES[numero.to_i - 1]
  end
end
