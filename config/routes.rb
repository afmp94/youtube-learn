Rails.application.routes.draw do
  root "dashboard#show"

  resource :registration, only: [:new, :create]
  resource :session, only: [:new, :create, :destroy]
  resources :passwords, param: :token

  resources :video_learnings, path: "videos" do
    member do
      post :reprocess
    end
    collection do
      get :search
    end
    resources :tags, only: [:create, :destroy], controller: "video_learning_tags"
  end

  resources :tags, only: [:index, :show]

  resources :channels, only: [:index, :show, :edit, :update] do
    collection do
      post :sync_videos
    end
  end

  resources :bulk_imports, path: "imports", only: [:index, :new, :create, :show]

  resources :conversations, path: "chat" do
    member do
      post :ask
    end
  end

  resources :quotes, only: [:index] do
    collection do
      get :search
    end
  end

  resources :collections do
    member do
      post :add_video
      delete :remove_video
    end
  end

  resources :projects do
    member do
      post :add_video
      delete :remove_video
      patch :archive
      patch :unarchive
    end
    resources :knowledge_entries, only: [:new, :create, :show, :edit, :update, :destroy]
  end

  resources :virality_analyses, path: "lab", only: [:index, :show, :create, :destroy]

  resources :content_pieces, path: "content" do
    member do
      post :regenerate
      patch :update_status
    end
    collection do
      post :generate
    end
  end

  resources :exports, only: [] do
    member do
      get :markdown
      get :pdf
    end
  end

  # API v1
  namespace :api do
    namespace :v1 do
      get :search, to: "search#index"
      resources :videos, only: [:index, :show], controller: "videos" do
        collection do
          get :stats
        end
      end
      resources :channels, only: [:index, :show]
      resources :tags, only: [:index, :show]
      resources :quotes, only: [:index] do
        collection do
          get :search
        end
      end
      resources :concepts, only: [:index]
      resources :content_pieces, only: [:index, :show, :create]
      resources :api_keys, only: [:index, :create, :destroy]
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
