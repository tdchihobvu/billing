Rails.application.routes.draw do
  get "quick_search", to: "quick_search#index"
  resource :password_change, only: [:edit, :update]

  resources :user_management do  
    collection do  
      get :index
      get :new
      get :details
      get :edit
      get :reset
      post :save
      patch :update
    end
  end
  resources :stock_counts

  resources :exchange_rates
  resources :tenant_locales
  resources :districts
  resources :tarrifs
  resources :devices
  resources :regional_offices
  resources :goods_receiveds
  get 'inventory/index'
  resources :measuring_units
  resources :brands
  resources :products
  resources :vat_types
  resources :product_types
  resources :product_categories
  resources :suppliers
  
  resources :reports, only: [:index] do 
    collection do
      get :sales
      get :vat_sales
      get :sales_by_user
      get :collections
      get :collections_by_user
      get :overdue_invoices
      get :upcoming_renewals
      get :inspector_report
    end
  end

  resources :system_settings, only: [:index] do  
    collection do   
      get :index
    end
  end

  resources :licenses do   
    collection do  
      get :generate 
      get :generate_new
      get :print
      get :print_plain
      get :print_multiple
      get :branch_license
      get :download_all
    end
    member do
      patch :vehicles, action: :assign_vehicles
      get :vehicle_discs
    end
  end
  resources :vehicles, only: %i[create update destroy]
  resources :void_requests, only: %i[index] do
    member do
      post :approve
      post :reject
    end
  end
  get "system_health", to: "system_health#index", as: :system_health
  post "system_health/events/:id/resolve", to: "system_health#resolve", as: :resolve_system_event
  post "system_health/events/resolve_all", to: "system_health#resolve_all", as: :resolve_all_system_events
  post "system_health/balances/check", to: "system_health#check_balances", as: :check_balances_system_health
  post "system_health/balances/issues/:id/fix", to: "system_health#fix_issue", as: :fix_balance_issue
  post "system_health/balances/fix_all", to: "system_health#fix_all", as: :fix_all_balance_issues
  resources :roles do
    member do
      post :assign
    end
  end
  resources :license_approvals, only: %i[index show] do
    member do
      post :approve
      post :reject
      post :resubmit
    end
  end
  resources :license_options
  resources :license_categories

  namespace :api do
    namespace :v1 do
      get 'fdms/register_device'
      resources :receipting do      
        collection do   
          
        end
      end
      resources :billing do      
        collection do  
          get :index 
          get :customers_list
          get :regions_list
          get :districts_list
          get :company_details
          get :users
          get :device_status
          get :tariffs
          get :industries_list
          get :client_types
          get :license_options
          get :license_categories
          get :register_devise
          get :exchange_rate
          get :client_invoices
          get :user_invoices
          get :user_receipts
          get :open_invoices
          get :license_status
          get :license_statuses
          get :app_version
          post :open_shift
          post :new_receipt
          post :new_invoice
          post :close_shift
          post :upload_invoices
          post :upload_receipts
          patch :void_invoice
          patch :void_receipt
          post :client_registration
          post :new_branch
        end
      end
    end

    # namespace :v2 do
    #   resources :receipting do      
    #     collection do   
    #       get :customers_list
    #       post :new
    #     end
    #   end
    # end
  end

  resources :receipts do  
    collection do   
      get :print
      get :shifts
      get :shift
      get :invoices
      get :record_receipt
      post :close_shift
    end
  end
  resources :payment_forms
  resources :invoices do
    collection do    
      get :print
      get :receipt
      get :send
      get :proforma
      get :license
      get :credit_note      
      get :credit_notes
      get :disable
      get :print_credit_note
      get :delivery_note
      get :edit_license
      get :license_vehicles
      get :inactive
      get :sms_reminder
      get :email_reminder
      get :fiscalise
      get :assign_branches
      get :void_invoice
      get :duplicate
      post :save_credit_note
      patch :save_fiscal_invoice
    end
    member do
      get :setoff
      post :setoff
    end    
  end

  resources :setting_categories

  resources :quotations do
    collection do    
      get :print
      get :send
    end
  end
  resources :banks
  resources :currencies
  resources :clients do    
    collection do  
      get :post_receipt  
      get :account_statement
      get :print_by_date
      get :add_branches
      get :reset_statement
      get :delete_branch
      get :takeon_balances
      get :edit_journal
      patch :update_journal
      post :save_journal
      post :upload_branches
    end
  end
  resources :industries
  resources :client_types
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    passwords: 'users/passwords'
  }

  resources :welcome, only: [:index] do 
    collection do
      get :index
      get :refresh
      get :dashboard
    end
  end

  resources :tenants do 
    collection do
      get :settings
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: "welcome#index"
end
