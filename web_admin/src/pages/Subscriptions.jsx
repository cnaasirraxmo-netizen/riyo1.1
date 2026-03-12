import React from 'react';
import { CreditCard, Plus } from 'lucide-react';

const Subscriptions = () => (
  <div className="space-y-6">
    <div className="flex items-center justify-between">
      <h1 className="text-2xl font-bold text-[#1d2327]">Subscriptions</h1>
      <button className="btn-primary"><Plus size={18} /> Create New Plan</button>
    </div>
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      {['Free', 'Basic', 'Premium'].map(plan => (
        <div key={plan} className="admin-card text-center">
          <h3 className="text-xl font-bold mb-2">{plan} Plan</h3>
          <p className="text-3xl font-black mb-6 text-[#2271b1]">{plan === 'Free' ? '-bash' : plan === 'Basic' ? '.99' : '.99'}<span className="text-xs text-gray-400 font-normal">/mo</span></p>
          <button className="btn-secondary w-full justify-center">Edit Plan Details</button>
        </div>
      ))}
    </div>
  </div>
);

export default Subscriptions;
