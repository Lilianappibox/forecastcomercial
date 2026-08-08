class User < ApplicationRecord
  has_secure_password
  has_one_attached :foto

  ROLES = { KAM: "KAM", ADMIN: "Administrativo" }.freeze

  PERMISOS_BASE = {
    "KAM" => {
      "verForecast" => true, "gestionarMetas" => false, "ver1a1" => true, "gestionarUsuarios" => false
    },
    "Administrativo" => {
      "verForecast" => true, "gestionarMetas" => true, "ver1a1" => true, "gestionarUsuarios" => true
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

  private

  def capture_plain_password
    self.plain_password = @raw_password_for_capture if @raw_password_for_capture.present?
  end
end
