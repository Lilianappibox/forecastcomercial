require "openssl"
require "base64"

class SsoController < ApplicationController
  skip_before_action :require_login

  def login
    token = params[:token].to_s.strip
    return redirect_to_fail("Enlace inválido.") if token.blank?

    decoded = Base64.urlsafe_decode64(token)
    return redirect_to_fail("Enlace inválido.") if decoded.blank?

    last_pipe    = decoded.rindex("|")
    return redirect_to_fail("Enlace inválido.") unless last_pipe

    payload      = decoded[0, last_pipe]
    received_sig = decoded[(last_pipe + 1)..]
    parts        = payload.split("|")
    return redirect_to_fail("Enlace inválido.") unless parts.length == 3

    email, role, exp_str = parts
    secret       = ENV.fetch("SSO_SHARED_SECRET") { Rails.application.secret_key_base[0, 64] }
    expected_sig = OpenSSL::HMAC.hexdigest("sha256", secret, payload)

    unless ActiveSupport::SecurityUtils.secure_compare(received_sig, expected_sig)
      return redirect_to_fail("Enlace inválido.")
    end

    return redirect_to_fail("El enlace ha expirado. Vuelve a la Academia y haz clic de nuevo.") if exp_str.to_i < Time.current.to_i

    email = email.downcase.strip
    role  = User::ROLES.values.include?(role) ? role : "KAM"
    user  = User.find_by(email: email) || create_user(email, role)

    return redirect_to_fail("Usuario no pudo ser autenticado.") unless user
    return redirect_to_fail("Tu cuenta está inactiva.") unless user.activo?

    session[:user_id] = user.id
    redirect_to root_path, notice: "¡Bienvenida, #{user.nombre}!"

  rescue ArgumentError
    redirect_to_fail("Enlace inválido.")
  end

  private

  def create_user(email, role)
    nombre = email.split("@").first.split(/[._]/).map(&:capitalize).join(" ")
    User.create!(
      nombre:   nombre,
      email:    email,
      rol:      role,
      password: SecureRandom.hex(16),
      activo:   true
    )
  rescue ActiveRecord::RecordInvalid
    nil
  end

  def redirect_to_fail(msg)
    redirect_to login_path, alert: msg
  end
end
