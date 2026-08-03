# Seeds — Admin Comercial Pibox (base de datos local, aislada de otras apps)
puts "Seeding users..."

admin_pw = ENV.fetch("SEED_ADMIN_PASSWORD", "local-dev-2026")
kam_pw   = ENV.fetch("SEED_KAM_PASSWORD", "local-dev-2026")

users_data = [
  { nombre: "Liliana Andrea Peña", email: "lpena@pibox.app", password: admin_pw,
    rol: "Administrativo", activo: true, cargo: "Head of Sales", celular: "3107872609",
    permisos_custom: {} },
  { nombre: "Jaime Girón", email: "jgiron@pibox.app", password: kam_pw,
    rol: "KAM", activo: true, cargo: "Key Account Manager", celular: "3154051883",
    permisos_custom: {} },
  { nombre: "Juliana Rojas", email: "jrojas@pibox.app", password: kam_pw,
    rol: "KAM", activo: true, cargo: "Key Account Manager", celular: "3232278047",
    permisos_custom: {} },
  { nombre: "Johana Navarrete", email: "jnavarrete@pibox.app", password: kam_pw,
    rol: "KAM", activo: true, cargo: "Key Account Manager", celular: "",
    permisos_custom: {} },
  { nombre: "Natalia Olivera", email: "nolivera@pibox.app", password: kam_pw,
    rol: "KAM", activo: true, cargo: "Key Account Manager", celular: "",
    permisos_custom: {} }
]

users_data.each do |u|
  user = User.find_or_initialize_by(email: u[:email].downcase)
  user.assign_attributes(u)
  user.save!
  puts "  ✓ #{u[:nombre]} (#{u[:rol]})"
end

puts "\nDone! Seeds complete."
puts "\n=== USUARIO ADMIN (solo local) ==="
puts "Email: lpena@pibox.app"
puts "Password: #{admin_pw}"
