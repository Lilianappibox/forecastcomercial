class UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  PERMISOS_CONFIGURABLES = [
    { id: "verForecast",       label: "Ver Forecast Comercial" },
    { id: "gestionarMetas",    label: "Asignar Metas (líder comercial)" },
    { id: "ver1a1",            label: "Ver 1:1 KAM" },
    { id: "verClientes",       label: "Ver Clientes" },
    { id: "gestionarClientes", label: "Gestionar Clientes (subir/eliminar archivos de cualquier KAM)" }
  ].freeze

  def index
    @users = User.order(:nombre)
  end

  def show; end

  def new
    @user = User.new(activo: true, rol: "KAM")
    @permisos_configurables = PERMISOS_CONFIGURABLES
  end

  def create
    @user = User.new(base_params)
    @user.permisos_custom = build_permisos_custom
    if @user.save
      redirect_to users_path, notice: "✓ Usuario creado: #{@user.nombre}"
    else
      @permisos_configurables = PERMISOS_CONFIGURABLES
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @permisos_configurables = PERMISOS_CONFIGURABLES
  end

  def update
    attrs = base_params
    attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?
    @user.assign_attributes(attrs)
    @user.permisos_custom = build_permisos_custom
    if @user.save
      session[:user_id] = @user.id if @user.id == current_user.id
      redirect_to users_path, notice: "✓ Usuario actualizado: #{@user.nombre}"
    else
      @permisos_configurables = PERMISOS_CONFIGURABLES
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.id == current_user.id
      redirect_to users_path, alert: "No puedes eliminar tu propia cuenta."
    else
      @user.destroy
      redirect_to users_path, notice: "🗑️ Usuario eliminado"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def base_params
    params.require(:user).permit(
      :nombre, :email, :password, :password_confirmation,
      :rol, :activo, :cargo, :celular, :foto
    )
  end

  def build_permisos_custom
    submitted = params.dig(:user, :permisos_custom) || {}
    PERMISOS_CONFIGURABLES.each_with_object({}) do |p, h|
      h[p[:id]] = submitted[p[:id]].to_s == "true"
    end
  end
end
