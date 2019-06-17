Rails.application.routes.draw do
  resources :policies
  resources :companies do 
    collection do
      get :import_form
      post :import_employees
    end
  end
  resources :employees

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
