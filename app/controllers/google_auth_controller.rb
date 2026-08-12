class GoogleAuthController < ApplicationController
  def connect
    unless google_calendar_configurado?
      redirect_to one_on_ones_path, alert: "Google Calendar todavía no está configurado en la app." and return
    end

    url = oauth_client.authorization_uri(access_type: "offline", prompt: "consent").to_s
    redirect_to url, allow_other_host: true
  end

  def callback
    if params[:error].present?
      redirect_to one_on_ones_path, alert: "No se pudo conectar Google Calendar: #{params[:error]}" and return
    end

    client = oauth_client
    client.code = params[:code]
    client.fetch_access_token!

    current_user.update!(
      google_access_token: client.access_token,
      google_refresh_token: client.refresh_token.presence || current_user.google_refresh_token,
      google_token_expires_at: Time.at(client.expires_at),
      google_email: obtener_email(client.access_token)
    )

    redirect_to one_on_ones_path, notice: "✓ Google Calendar conectado"
  end

  def disconnect
    current_user.desconectar_google!
    redirect_to one_on_ones_path, notice: "Google Calendar desconectado"
  end

  private

  def oauth_client
    Signet::OAuth2::Client.new(
      client_id: Rails.application.credentials.dig(:google, :client_id),
      client_secret: Rails.application.credentials.dig(:google, :client_secret),
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      token_credential_uri: "https://oauth2.googleapis.com/token",
      redirect_uri: google_callback_url,
      scope: [ Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY, "email" ]
    )
  end

  def obtener_email(access_token)
    uri = URI("https://www.googleapis.com/oauth2/v2/userinfo")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{access_token}"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    JSON.parse(res.body)["email"]
  rescue StandardError
    nil
  end
end
