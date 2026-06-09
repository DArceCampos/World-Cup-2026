# ApplicationController — controlador base de la API.
#
# Centraliza el manejo de errores de dominio y de ActiveRecord para que los
# controladores concretos se mantengan delgados (delegan en servicios y no
# repiten lógica de manejo de excepciones).
class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable
  rescue_from MatchResultRecorder::InvalidResult, with: :unprocessable_message
  rescue_from KnockoutAdvancer::NotReady, with: :conflict_message

  private

  def render_data(data, status: :ok)
    render json: { data: data }, status: status
  end

  def render_error(code, message, status)
    render json: { error: { code: code, message: message } }, status: status
  end

  def not_found(exception)
    render_error("NOT_FOUND", exception.message, :not_found)
  end

  def unprocessable(exception)
    render_error("VALIDATION_ERROR", exception.record.errors.full_messages.join(", "), :unprocessable_entity)
  end

  def unprocessable_message(exception)
    render_error("VALIDATION_ERROR", exception.message, :unprocessable_entity)
  end

  def conflict_message(exception)
    render_error("CONFLICT", exception.message, :conflict)
  end
end
