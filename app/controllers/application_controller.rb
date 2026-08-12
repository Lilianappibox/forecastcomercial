class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :require_login
  before_action :set_no_cache_headers

  helper_method :current_user, :logged_in?, :permisos

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def set_no_cache_headers
    response.headers["Cache-Control"] = "no-store, private, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "Debes iniciar sesión para continuar."
    end
  end

  def permisos
    @permisos ||= current_user&.permisos || {}
  end

  def require_permiso(permiso)
    unless current_user&.tiene_permiso?(permiso)
      redirect_to root_path, alert: "No tienes permiso para acceder a esta sección."
    end
  end

  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Esta sección es solo para administradores."
    end
  end

  def fmt(value)
    return "N.A" if value.nil? || value == "N.A" || value == "" || value == 0
    return value.to_s if value.is_a?(String) && !value.match?(/\A-?\d+(\.\d+)?\z/)
    num = value.to_i
    return "N.A" if num == 0
    "$#{num.abs.to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1.").reverse}"
  end
  helper_method :fmt

  def google_calendar_configurado?
    Rails.application.credentials.dig(:google, :client_id).present? &&
      Rails.application.credentials.dig(:google, :client_secret).present?
  end
  helper_method :google_calendar_configurado?
end
