require 'spec_helper'

RSpec.describe Alchemy::PagesController, 'OnPageLayout mixin', type: :controller do
  before(:all) do
    ApplicationController.send(:extend, Alchemy::OnPageLayout)
  end

  let(:page) { create(:public_page, page_layout: 'standard') }

  describe '.on_page_layout' do
    context 'with :all as argument for page_layout' do
      context 'and block given' do
        before do
          ApplicationController.class_eval do
            on_page_layout(:all) do
              @successful_for_all = true
              @the_page_instance = @page
            end
          end
        end

        it 'runs on all page layouts' do
          alchemy_get :show, urlname: page.urlname
          expect(assigns(:successful_for_all)).to eq(true)
        end

        it 'has @page instance' do
          alchemy_get :show, urlname: page.urlname
          expect(assigns(:the_page_instance)).to eq(page)
        end
      end

      context 'and method name instead of block given' do
        before do
          ApplicationController.class_eval do
            on_page_layout :all, :my_all_callback_method

            def my_all_callback_method
              @successful_for_all_callback_method = true
              @the_all_page_instance = @page
            end
          end
        end

        it 'runs on all page layouts' do
          alchemy_get :show, urlname: page.urlname
          expect(assigns(:successful_for_all_callback_method)).to eq(true)
        end

        it 'has @page instance' do
          alchemy_get :show, urlname: page.urlname
          expect(assigns(:the_all_page_instance)).to eq(page)
        end
      end
    end

    context 'with :standard as argument for page_layout' do
      before do
        ApplicationController.class_eval do
          on_page_layout(:standard) do
            @successful_for_standard = true
          end
        end
      end

      context 'and page having standard layout' do
        it 'runs the callback' do
          alchemy_get :show, urlname: page.urlname
          expect(assigns(:successful_for_standard)).to eq(true)
        end
      end

      context 'and page not having standard layout' do
        let(:page) { create(:public_page, page_layout: 'news') }

        it "doesn't run the callback" do
          alchemy_get :show, urlname: page.urlname
          expect(assigns(:successful_for_standard)).to eq(nil)
        end
      end
    end

    context 'when defining two callbacks for different page_layouts' do
      before do
        ApplicationController.class_eval do
          on_page_layout(:standard) do
            @successful_for_page = true
          end

          on_page_layout(:news) do
            @successful_for_page = true
          end
        end
      end

      it 'runs both callbacks' do
        [:standard, :news].each do |page_layout|
          alchemy_get :show, urlname: create(:public_page, page_layout: page_layout).urlname
          expect(assigns(:successful_for_page)).to eq(true)
        end
      end
    end

    context 'when defining two callbacks for the same page_layout' do
      before do
        ApplicationController.class_eval do
          on_page_layout(:standard) do
            @successful_for_standard_first = true
          end

          on_page_layout(:standard) do
            @successful_for_standard_second = true
          end
        end
      end

      it 'runs both callbacks' do
        alchemy_get :show, urlname: page.urlname
        expect(assigns(:successful_for_standard_first)).to eq(true)
        expect(assigns(:successful_for_standard_second)).to eq(true)
      end
    end
  end
end

RSpec.describe ApplicationController, 'OnPageLayout mixin', type: :controller do
  before(:all) do
    ApplicationController.send(:extend, Alchemy::OnPageLayout)
  end

  controller do
    def index
      @another_controller = true
      render nothing: true
    end
  end

  context 'in another controller' do
    before do
      ApplicationController.class_eval do
        on_page_layout(:standard) do
          @successful_for_another_controller = true
        end
      end
    end

    it 'callback does not run' do
      get :index
      expect(assigns(:another_controller)).to eq(true)
      expect(assigns(:successful_for_another_controller)).to eq(nil)
    end
  end
end
