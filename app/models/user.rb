class User < ApplicationRecord
  has_secure_password
  has_one_attached :foto
  has_many :cliente_archivos, dependent: :destroy

  encrypts :google_access_token, :google_refresh_token

  ROLES = { KAM: "KAM", ADMIN: "Administrativo" }.freeze

  PERMISOS_BASE = {
    "KAM" => {
      "verForecast" => true, "gestionarMetas" => false, "ver1a1" => true, "gestionarUsuarios" => false,
      "verClientes" => true, "gestionarClientes" => false, "verInsights" => false
    },
    "Administrativo" => {
      "verForecast" => true, "gestionarMetas" => true, "ver1a1" => true, "gestionarUsuarios" => true,
      "verClientes" => true, "gestionarClientes" => true, "verInsights" => true
    }
  }.freeze

  validates :nombre, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :rol, inclusion: { in: ROLES.values }

  before_save { self.email = email.strip.downcase }
  before_save :capture_plain_password

  attr_reader :raw_password_for_capture

  def password=(val)
    @raw_password_for_capture = val.presence
    super
  end

  def admin?
    rol == "Administrativo"
  end

  def permisos
    return PERMISOS_BASE["Administrativo"].dup if admin?
    base = (PERMISOS_BASE[rol] || PERMISOS_BASE["KAM"]).dup
    base.merge(permisos_custom || {})
  end

  def tiene_permiso?(permiso)
    permisos[permiso.to_s] == true
  end

  def initial
    nombre.chars.first&.upcase || "?"
  end

  def generate_password_reset_token!
    loop do
      self.password_reset_token = SecureRandom.urlsafe_base64(32)
      break unless User.exists?(password_reset_token: password_reset_token)
    end
    self.password_reset_sent_at = Time.current
    save!(validate: false)
  end

  def password_reset_expired?
    password_reset_sent_at.nil? || password_reset_sent_at < 2.hours.ago
  end

  def clear_password_reset!
    update_columns(password_reset_token: nil, password_reset_sent_at: nil)
  end

  def google_conectado?
    google_refresh_token.present?
  end

  def google_calendar_service
    return nil unless google_conectado?
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = Google::Auth::UserRefreshCredentials.new(
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY,
      refresh_token: google_refresh_token,
      access_token: google_access_token,
      expires_at: google_token_expires_at
    )
    service
  end

  # Signet puede refrescar el access token en memoria al hacer la llamada a la
  # API (si ya había expirado) — esto lo persiste para no reautenticar cada vez.
  def sincronizar_token_google!(service)
    creds = service.authorization
    return if creds.access_token == google_access_token
    update_columns(google_access_token: creds.access_token, google_token_expires_at: creds.expires_at)
  end

  def desconectar_google!
    update_columns(
      google_access_token: nil, google_refresh_token: nil,
      google_token_expires_at: nil, google_email: nil
    )
  end

  private

  def capture_plain_password
    self.plain_password = @raw_password_for_capture if @raw_password_for_capture.present?
  end
end
