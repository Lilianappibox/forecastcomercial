class ClientesController < ApplicationController
  before_action :check_permiso
  before_action :check_gestionar, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_kams, only: [ :index, :new, :create, :edit, :update ]
  before_action :set_cliente, only: [ :edit, :update, :destroy ]

  def index
    if current_user.admin?
      @kam_id = params[:kam_id].presence&.to_i || @kams.first&.id
      @clientes = @kam_id ? Cliente.where(user_id: @kam_id).order(:nombre) : Cliente.none
    else
      @kam_id = current_user.id
      @clientes = Cliente.where(user_id: current_user.id).order(:nombre)
    end
    @meses = Cliente.meses_disponibles(@clientes)
  end

  def new
    @cliente = Cliente.new(user_id: params[:kam_id])
  end

  def create
    @cliente = Cliente.new(cliente_params)
    if @cliente.save
      redirect_to clientes_path(kam_id: @cliente.user_id), notice: "✓ Cliente agregado"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @cliente.update(cliente_params.except(:user_id))
      redirect_to clientes_path(kam_id: @cliente.user_id), notice: "✓ Cliente actualizado"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    kam_id = @cliente.user_id
    @cliente.destroy
    redirect_to clientes_path(kam_id: kam_id), notice: "🗑️ Cliente eliminado"
  end

  private

  def check_permiso
    require_permiso("verClientes")
  end

  def check_gestionar
    require_permiso("gestionarClientes")
  end

  def set_kams
    @kams = User.where(rol: "KAM").order(:nombre)
  end

  def set_cliente
    @cliente = Cliente.find(params[:id])
  end

  def cliente_params
    attrs = params.require(:cliente).permit(:user_id, :nombre, :gmv_mensual)
    attrs[:gmv_mensual] = parse_json(attrs[:gmv_mensual]) if attrs.key?(:gmv_mensual)
    attrs
  end

  def parse_json(raw)
    raw.is_a?(String) ? (JSON.parse(raw) rescue []) : raw
  end
end
