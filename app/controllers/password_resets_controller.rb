class PasswordResetsController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token, only: [ :create, :update ]

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    user&.generate_password_reset_token!
    if Rails.env.development? && user
      @reset_url = edit_password_reset_url(token: user.password_reset_token)
    end
    render :create
  end

  def edit
    @user = User.find_by(password_reset_token: params[:token])
    if @user.nil? || @user.password_reset_expired?
      redirect_to new_password_reset_path, alert: "El link expiró o no es válido. Solicita uno nuevo."
    end
  end

  def update
    @user = User.find_by(password_reset_token: params[:token])
    if @user.nil? || @user.password_reset_expired?
      return redirect_to new_password_reset_path, alert: "El link expiró o no es válido. Solicita uno nuevo."
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      @user.clear_password_reset!
      redirect_to login_path, notice: "✓ Contraseña actualizada. Ya puedes iniciar sesión."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
