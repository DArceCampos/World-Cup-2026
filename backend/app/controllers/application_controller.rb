# ApplicationController es la clase base de todos los controladores de la API.
# Su función principal es centralizar el manejo de errores para que los
# controladores concretos no tengan que repetir la misma lógica de rescue
# en cada acción. Eso sí, sin este controlador base cada controlador tendría
# que capturar sus propias excepciones y armar el JSON de error manualmente.
class ApplicationController < ActionController::API
  # rescue_from registra un manejador para cada tipo de excepción. Cuando
  # cualquier controlador que hereda de este lanza una de estas excepciones,
  # Rails la captura automáticamente y llama al método indicado con :with.
  rescue_from ActiveRecord::RecordNotFound,         with: :not_found
  rescue_from ActiveRecord::RecordInvalid,          with: :unprocessable
  rescue_from MatchResultRecorder::InvalidResult,   with: :unprocessable_message
  rescue_from KnockoutAdvancer::NotReady,           with: :conflict_message

  private

  # Este método es el formato estándar de respuesta exitosa de toda la API.
  # Envuelve los datos en { data: ... } para que el cliente sepa siempre
  # dónde encontrar la información útil.
  def render_data(data, status: :ok)
    render json: { data: data }, status: status
  end

  # Este método es el formato estándar de respuesta de error. El código y el
  # mensaje permiten al cliente saber qué pasó y mostrar un mensaje útil.
  def render_error(code, message, status)
    render json: { error: { code: code, message: message } }, status: status
  end

  # Se activa cuando se busca un registro por ID que no existe en la BD.
  # Responde con HTTP 404.
  def not_found(exception)
    render_error("NOT_FOUND", exception.message, :not_found)
  end

  # Se activa cuando una validación de ActiveRecord falla al guardar.
  # Recopila todos los mensajes de error del modelo y responde con HTTP 422.
  def unprocessable(exception)
    render_error("VALIDATION_ERROR", exception.record.errors.full_messages.join(", "), :unprocessable_entity)
  end

  # Se activa cuando MatchResultRecorder lanza InvalidResult (marcador inválido).
  # Responde con HTTP 422 usando el mensaje de la excepción directamente.
  def unprocessable_message(exception)
    render_error("VALIDATION_ERROR", exception.message, :unprocessable_entity)
  end

  # Se activa cuando KnockoutAdvancer lanza NotReady (condiciones no cumplidas).
  # Responde con HTTP 409 porque hay un conflicto con el estado actual del torneo.
  def conflict_message(exception)
    render_error("CONFLICT", exception.message, :conflict)
  end
end
