class SessionsController < ApplicationController
  skip_before_action :require_login, only: [ :new, :create ]
  skip_before_action :verify_authenticity_token, only: [ :create, :destroy ]

  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.activo? && user.authenticate(params[:password].to_s)
      session[:user_id] = user.id
      redirect_to root_path, notice: "✓ Bienvenido, #{user.nombre}"
    else
      flash.now[:alert] = "Contraseña incorrecta."
      @email = params[:email]
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Sesión cerrada."
  end
end
