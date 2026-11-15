Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root to: redirect("/current_program", status: 302)
  get "schedule", to: "schedule#index"

  resources :questions, only: %i[index create]
  resources :topics, only: %i[index create edit update destroy]
  get "spreadsheet_program", to: redirect("/current_program", status: 302)
  resource :current_program, only: :show
  resources :general_documents, only: %i[index create destroy]
  resources :spreadsheet_documents, only: :index
  resources :spreadsheet_copies, only: %i[index create] do
    scope module: :spreadsheet_copies do
      resource :printout, only: :show
      resource :offline_download, only: :show
      resource :program, only: :show
      resources :days, only: :show do
        resources :acts, only: :show do
          resources :documents, only: %i[index create destroy]
        end
        resources :preparations, only: :show
        resources :prior_activities, only: :show
      end
    end
  end
  resources :preparations, only: :show
  resources :operational_activities, only: :show

  resources :activities, only: [] do
    resource :activity_detail, only: %i[new create edit update]
  end

  resources :schedule_entries, only: :show do
    resources :documents, only: %i[index create destroy]
    resources :questions, only: %i[index create edit update destroy], shallow: true do
      resource :answer, only: %i[edit update]
    end
  end
end
