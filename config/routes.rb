Rails.application.routes.draw do

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
  
  resources :reports do 
    collection do
      get :sales
      get :vat_sales
      get :sales_by_user
      get :collections
      get :collections_by_user
      get :overdue_invoices
      get :upcoming_renewals
    end
  end

  resources :system_settings do  
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
      get :print
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
    sessions: 'users/sessions'
  }

  resources :welcome do 
    collection do
      get :index
      get :refresh
      get :dashboard
      post :register_device
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
