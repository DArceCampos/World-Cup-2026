# ApplicationController es la clase base de todos los controladores del frontend.
# Su función es incluir ApiPresenter (para tener los helpers de transformación
# disponibles en todos los controladores) y activar la protección CSRF.
# Eso sí, sin la protección CSRF cualquier sitio externo podría hacer requests
# maliciosos usando la sesión del usuario — es una medida de seguridad esencial.
class ApplicationController < ActionController::Base
  # Al incluir ApiPresenter aquí, todos los métodos del concern (build_group,
  # build_match, team_code, etc.) quedan disponibles en cada controlador
  # que hereda de este, sin necesidad de incluirlo individualmente.
  include ApiPresenter
  protect_from_forgery with: :exception
end
