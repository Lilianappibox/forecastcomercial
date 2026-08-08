# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "html2canvas" # @1.4.1

# UMD build (auto-registra Chart en window, sin imports relativos a chunks —
# la build ESM de npm parte helpers en un archivo aparte que importmap-rails
# no descarga, así que rompía en el navegador). Se referencia como `Chart` global.
pin "chart.js", to: "chart.js.js" # @4.5.1 (UMD)
