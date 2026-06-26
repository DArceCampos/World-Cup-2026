# ApplicationRecord es la clase base abstracta de la que heredan todos los
# modelos del sistema. Su función es ser el punto de entrada común de
# ActiveRecord para este proyecto. Sin ella, cada modelo tendría que heredar
# directamente de ActiveRecord::Base, lo que haría más difícil agregar
# comportamiento compartido en el futuro.
#
# La declaración primary_abstract_class le dice a Rails que esta clase no
# corresponde a ninguna tabla en la base de datos — solo existe para ser heredada.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
