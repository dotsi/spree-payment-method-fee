require 'spec_helper'

describe Spree::PaymentMethodFee do
  let(:payment_method) { create :payment_method }
  before(:each) { Spree::PaymentMethod.any_instance.stub(:payment_profiles_supported?).and_return(payment_profiles_supported) }

  describe 'creating a payment method fee' do
    subject do
      Spree::PaymentMethodFee.new( spree_payment_method_id: payment_method.id, amount: 1, currency: 'USD' )
    end

    context 'with an payment method that supports payment profiles' do
      let(:payment_profiles_supported) { true }
      it { should be_valid }

      context 'when a fee already exists on the payment method with the same currency' do
        before do
          Spree::PaymentMethodFee.create(
            spree_payment_method_id: payment_method.id,
            amount: 1,
            currency: 'USD'
          )
        end
        it { should_not be_valid }
      end
    end

    context 'with an payment method that doesnt support payment profiles' do
      let(:payment_profiles_supported) { false }
      it { should_not be_valid }
    end
  end

  context '#adjust!' do
    let(:order) { create :order }
    let(:payment_profiles_supported) { true }

    before do
      Spree::PaymentMethodFee.create( spree_payment_method_id: payment_method.id, currency: 'USD', amount: 200 )
      # create a 'fee' to verify it gets blown away when we call adjust
      order.adjustments.create amount: 10, label: 'fee'
      order.stub payment_method: payment_method

      Spree::PaymentMethodFee.adjust!(order)
    end

    context "with existing fees" do
      subject { order.adjustments }

      specify { subject.size.should == 1 }
      specify { subject.first.amount.should == 200 }
      specify { subject.first.label.should == 'fee' }
    end
  end
end
