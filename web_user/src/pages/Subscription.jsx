
import React, { useState, useEffect } from 'react';
import { Check, Shield, Zap, Smartphone } from 'lucide-react';
import api from '../utils/api';

const Subscription = () => {
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchPlans = async () => {
      try {
        const res = await api.get('/plans');
        setPlans(res.data);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };
    fetchPlans();
  }, []);

  if (loading) return <div className="h-screen flex items-center justify-center"><div className="w-10 h-10 border-4 border-purple-600 border-t-transparent rounded-full animate-spin"></div></div>;

  return (
    <div className="pt-32 pb-20 px-4 md:px-8 max-w-7xl mx-auto">
      <div className="text-center mb-16">
        <h1 className="text-4xl md:text-6xl font-black text-white mb-4 uppercase tracking-tight">Choose Your Plan</h1>
        <p className="text-gray-400 text-lg">Unlimited movies and TV shows on your favorite devices.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {plans.map((plan) => (
          <div key={plan._id} className="bg-[#1f1f1f] rounded-3xl p-8 border border-white/5 flex flex-col hover:border-purple-600/50 transition-all group">
            <h2 className="text-2xl font-black text-white uppercase mb-2">{plan.name}</h2>
            <div className="flex items-baseline mb-8">
              <span className="text-5xl font-black text-white">${plan.price}</span>
              <span className="text-gray-500 ml-2 font-bold lowercase">/ {plan.interval}</span>
            </div>

            <div className="space-y-4 mb-10 flex-1">
              <div className="flex items-center text-gray-300 font-medium"><Check className="text-purple-600 mr-3" size={20} /> {plan.devicesAllowed} {plan.devicesAllowed === 1 ? 'Device' : 'Devices'}</div>
              <div className="flex items-center text-gray-300 font-medium"><Check className="text-purple-600 mr-3" size={20} /> {plan.has4K ? '4K + HDR' : '1080p Full HD'}</div>
              <div className="flex items-center text-gray-300 font-medium"><Check className="text-purple-600 mr-3" size={20} /> {plan.downloadLimit === 0 ? 'Unlimited Downloads' : `${plan.downloadLimit} Downloads`}</div>
              <div className="flex items-center text-gray-300 font-medium"><Check className="text-purple-600 mr-3" size={20} /> {plan.hasAds ? 'With Ads' : 'Ad-Free'}</div>
            </div>

            <button className="w-full py-4 bg-purple-600 hover:bg-purple-700 text-white font-black rounded-xl transition-all shadow-lg shadow-purple-600/20 uppercase tracking-widest text-sm">
              Get Started
            </button>
          </div>
        ))}
      </div>

      <div className="mt-20 p-10 bg-white/5 rounded-3xl border border-white/5 grid grid-cols-1 md:grid-cols-3 gap-8">
         <div className="flex flex-col items-center text-center">
            <Shield className="text-purple-500 mb-4" size={40} />
            <h4 className="text-white font-bold mb-2">Secure Payment</h4>
            <p className="text-gray-500 text-xs">Your transaction is protected by 256-bit encryption.</p>
         </div>
         <div className="flex flex-col items-center text-center">
            <Zap className="text-purple-500 mb-4" size={40} />
            <h4 className="text-white font-bold mb-2">Instant Access</h4>
            <p className="text-gray-500 text-xs">Start streaming immediately after your payment is confirmed.</p>
         </div>
         <div className="flex flex-col items-center text-center">
            <Smartphone className="text-purple-500 mb-4" size={40} />
            <h4 className="text-white font-bold mb-2">Watch Anywhere</h4>
            <p className="text-gray-500 text-xs">Available on Web, iOS, Android, and Smart TVs.</p>
         </div>
      </div>
    </div>
  );
};

export default Subscription;
