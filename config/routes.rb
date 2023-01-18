NtqTools::Engine.routes.draw do
  resource :translation, only: [:update, :show]
end
