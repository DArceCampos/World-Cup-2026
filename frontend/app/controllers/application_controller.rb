class ApplicationController < ActionController::Base
  include ApiPresenter
  protect_from_forgery with: :exception
end
