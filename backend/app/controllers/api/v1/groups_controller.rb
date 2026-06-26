module Api
  module V1
    # GroupsController maneja el CRUD de grupos y la consulta de tablas de posiciones.
    # Su función es permitir crear, leer, actualizar y eliminar grupos, y exponer
    # las posiciones de sus equipos. Eso sí, el ordenamiento de posiciones no ocurre
    # aquí — lo hace GroupSerializer usando la lógica del modelo Group.
    class GroupsController < ApplicationController
      # before_action ejecuta set_group antes de las acciones que necesitan el grupo.
      # Esto evita repetir Group.find(params[:id]) en show, update y destroy.
      before_action :set_group, only: %i[show update destroy]

      # GET /api/v1/groups
      # Este método devuelve los 12 grupos ordenados alfabéticamente con sus
      # tablas de posiciones. Usa includes(:teams) para evitar N+1 queries —
      # carga los equipos de todos los grupos en una sola consulta SQL.
      def index
        groups = Group.includes(:teams).order(:name)
        render_data(groups.map { |g| GroupSerializer.new(g).as_json })
      end

      # GET /api/v1/groups/:id
      # Este método devuelve el detalle de un grupo incluyendo sus partidos.
      # La diferencia con index es include_matches: true, que le dice al
      # serializer que también incluya los partidos en la respuesta.
      def show
        render_data(GroupSerializer.new(@group, include_matches: true).as_json)
      end

      # POST /api/v1/groups
      # Este método crea un nuevo grupo. Si no se envía tournament_id, usa el
      # torneo activo. El .save! lanza RecordInvalid si hay errores de validación,
      # que ApplicationController captura y convierte en una respuesta 422.
      def create
        group = Group.new(group_params)
        group.tournament ||= current_tournament
        group.save!
        render_data(GroupSerializer.new(group).as_json, status: :created)
      end

      # PUT/PATCH /api/v1/groups/:id
      # Este método actualiza el nombre del grupo. update! lanza RecordInvalid
      # si el nombre ya existe en el mismo torneo (validación de unicidad).
      def update
        @group.update!(group_params)
        render_data(GroupSerializer.new(@group).as_json)
      end

      # DELETE /api/v1/groups/:id
      # Este método elimina el grupo junto con sus equipos y partidos en cascada
      # (por el dependent: :destroy del modelo). head :no_content responde con
      # HTTP 204 sin cuerpo, que es el estándar para eliminaciones exitosas.
      def destroy
        @group.destroy!
        head :no_content
      end

      private

      # Busca el grupo por ID. Si no existe, ActiveRecord lanza RecordNotFound
      # que ApplicationController captura y convierte en una respuesta 404.
      def set_group
        @group = Group.find(params[:id])
      end

      # Strong parameters: solo permite name y tournament_id del body del request.
      # Esto protege contra mass assignment attacks.
      def group_params
        params.require(:group).permit(:name, :tournament_id)
      end

      def current_tournament
        Tournament.first || Tournament.create!(name: "Copa Mundial FIFA 2026", status: "setup")
      end
    end
  end
end
